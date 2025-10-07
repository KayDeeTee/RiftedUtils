local riftedWheel = {}

local riftedBeatmap = require "Rifted.RiftedBeatmap"
local riftedCamera = require "Rifted.RiftedCamera"
local riftedInput = require "Rifted.RiftedInput"
local riftedBrush = require "Rifted.RiftedBrush"
local riftedTool = require "Rifted.RiftedTool"
local riftedCommand = require "Rifted.RiftedCommand"
local riftedShape = require "Rifted.RiftedShape"
local riftedFormat = require "Rifted.RiftedFormat"
local riftedSchema = require "Rifted.RiftedSchema"
local riftedRenderer = require "Rifted.RiftedRenderer"

local camera = require "necro.render.Camera"
local input = require "system.game.Input"
local render = require "necro.render.Render"
local color = require "system.utils.Color"
local transformationMatrix = require "system.gfx.TransformationMatrix"
local gfx = require "system.gfx.GFX"
local controls = require "necro.config.Controls"

local tileSize = render.TILE_SIZE
local cx, cy = nil, nil

local facing = true


local ring_radii = { 32, 64, 96, 128, 160}

local lut = {
	{"Rifted_E1722", "Rifted_E4355", "Rifted_E9189"}, --slimes
	{"Rifted_E2202", "Rifted_E1911", "Rifted_E6471"}, --w skeletons
	{"Rifted_E6803", "Rifted_E4871", nil}, --y skeletons
	{"Rifted_E2716", "Rifted_E3307", nil}, --b skeletons
	{"Rifted_E8675309", "Rifted_E717", "Rifted_E911"}, --bats
	{"Rifted_E1234", "Rifted_E1235", "Rifted_E1236"}, --zombies
	{"Rifted_E7831", "Rifted_E1707", "Rifted_E6311"}, --armadillos
	{"Rifted_E929", "Rifted_E3685", "Rifted_E7288"}, --blademasters
	{"Rifted_E8519", "Rifted_E8156", "Rifted_E3826"}, --harpies
	{"Rifted_E4601", "Rifted_E3543", "Rifted_E7685"}, --skulls
}


local function select_enemy(depth, type)
	if depth == 0 or depth == 4 then
		return
	end
	if type < 0 or type > 9 then
		return
	end
	local v = lut[type+1][depth]
	if v == nil then
		return
	end

	local f = facing
	if type >=1 and type <= 3 then --skeletons
		f = not f
	end

	--v = v .. "R"
	local attributes = {}
	local parameters = {
		EnemyId = v,
		ShouldStartFacingRight = f,
	}

	attributes.Rifted_object = {}
	attributes.Rifted_object.data = { type = riftedFormat.EventType.SPAWN_ENEMY}

	if type >= 1 and type <= 3 then --skeletons again lmao
		parameters.ShouldMoveOnDupletMeter = true
	end
	if type == 7 then
		parameters.BlademasterAttackRow = 4
	end

	attributes.Rifted_object.data.parameters = parameters

	local brush = { cmd = riftedCommand.Type.ENTITY_ADD, type = "Rifted_Object", attr = attributes, selID = v .. (f and "L" or "R"), shape = riftedShape.Type.POINT, stack = true }

	riftedTool.setBrush(brush)
end

local function rotate_point( radius, rotation )
	local cosAngle = math.cos( rotation )
	local sinAngle = math.sin( rotation )

	return radius * cosAngle - 0 * sinAngle,  radius * sinAngle + 0 * cosAngle
end



local function draw_circle( buffer, radius_inner, radius_outer, steps, start_highlight, end_highlight, ring )

   	local rot = (math.pi * 2) * (1 / (steps))
   	local offset = -(math.pi / 2) 
   	local idx = 1
    for x = 1, steps do

    	local r1 = rot * (x-1) + offset
    	local r2 = rot * (x) + offset


    	local x1, y1 = rotate_point(radius_inner, r1)
    	local x2, y2 = rotate_point(radius_inner, r2)
    	local x3, y3 = rotate_point(radius_outer, r1)
    	local x4, y4 = rotate_point(radius_outer, r2)

    	local c = color.rgba(0,0,0,192)
    	if x >= start_highlight and x < end_highlight then
    		c = color.rgba(255, 255, 255, 128)
    	end

	   	local vert = {
	   	}
	   	local vertices = {
	   		{x=cx+x1, y=cy+y1, color=c},
	   		{x=cx+x2, y=cy+y2, color=c},
	   		--outer 2
	   		{x=cx+x3, y=cy+y3, color=c},
	   		{x=cx+x4, y=cy+y4, color=c},
	   	}

	   	vert.vertices = vertices 
	   	buffer.drawQuad( vert, 0 )

	   	if (x-1) % 3 == 1 then

	   		local v = lut[idx][ring]
	   		if v ~= nil then 
			   	local average_x = cx + (x1 + x2 + x3 + x4) / 4
			   	local average_y = cy + (y1 + y2 + y3 + y4) / 4

			   	local texture = riftedRenderer.getDefaultTexture( riftedSchema.getType( v ) )

			   	local flip = -1
		   		if idx >=2 and idx <= 4 then --skeletons
					flip = flip * -1
				end
				if not facing then
					flip = flip * -1
				end
			   	
				local drawArgs = {
					rect = { average_x-12*flip, average_y-12, 24*flip, 24 },
					texture = texture,
					color = color.opacity(1),
					z = 1,
				}
				buffer.draw(drawArgs)
			end
			idx = idx + 1
		end
   	end
end

local function draw_wheel()

	if not input.keyDown("g") then
		if cx ~= nil then
		   	local cx2, cy2 = riftedInput.getCursorPosition()
		   	local ox, oy = cx2-cx, cy2-cy --offset x, offset y
		   	local dist = ox*ox + oy*oy
		   	dist = math.sqrt(dist)

		   	local angle = math.atan2(oy,ox)
		   	if angle < 0 then
		   		angle = angle + math.pi * 2
		   	end

		   	local depth = 0
		   	for x=1,4 do
		   		if dist > ring_radii[x] then
		   			depth = depth + 1
		   		end
		   	end

		   	local enemy_type = (math.floor((angle / (math.pi * 2)) * 10 + 0.5) + 2) % 10
		   	select_enemy( depth, enemy_type )
		end


		cx, cy = nil, nil
		return 
	end

	if cx == nil then
		facing = not riftedInput.checkHold(controls.Misc.EDITOR_MODIFIER)
		cx, cy = riftedInput.getCursorPosition()
	end

	local buffer = render.getBuffer(render.Buffer.UI_CUSTOM)

    local c = color.opacity(1)
    
    --[[
    for x = 1, 5 do

	    local box = {
	        rect = { cx, cy, 256, 1 },
	        color = c,
	        z = -10000,
	        angle = (math.pi * 2) * (x/5) - math.pi/2,
	        origin = {0,0},
	    }

	    buffer.draw(box)

   	end
   	]] --

   	local steps = 30
   	local radius_inner = 64
   	local radius_outer = 128

   	local cx2, cy2 = riftedInput.getCursorPosition()
   	local ox, oy = cx2-cx, cy2-cy --offset x, offset y
   	local dist = ox*ox + oy*oy
   	dist = math.sqrt(dist)

   	local angle = math.atan2(oy,ox)
   	if angle < 0 then
   		angle = angle + math.pi * 2
   	end

   	for x=1, 3 do
   		local inner = ring_radii[x]
   		local outer = ring_radii[x+1]

		local selected_region = -1
	   	if dist >= inner and dist < outer then
   		selected_region = (math.floor((angle / (math.pi * 2)) * 10 + 0.5) + 2) % 10
   		end
   		draw_circle(buffer, inner, outer, steps, selected_region*3+1, selected_region*3+4, x)
   	end

   	--[[
   	local selected_region = -1
   	if dist >= 64 and dist < 128 then
   		selected_region = (math.floor((angle / (math.pi * 2)) * 10 + 0.5) + 2) % 10
   	end
   	draw_circle(buffer, 64, 128, steps, selected_region*3+1, selected_region*3+4, 1)

   	selected_region = -1
   	if dist >= 128 and dist < 180 then
   		selected_region = (math.floor((angle / (math.pi * 2)) * 10 + 0.5) + 2) % 10
   	end
   	draw_circle(buffer, 128, 180, steps, selected_region*3+1, selected_region*3+4, 2)

   	selected_region = -1
   	if dist >= 180 and dist < 236 then
   		selected_region = (math.floor((angle / (math.pi * 2)) * 10 + 0.5) + 2) % 10
   	end
   	draw_circle(buffer, 180, 236, steps, selected_region*3+1, selected_region*3+4, 3)
	]]--


end

event.render.add("renderWheel", "objects", function()
    draw_wheel()
end)