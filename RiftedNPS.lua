local riftedNPS = {}

local riftedGoto = require "RiftedUtils.RiftedGoTo"
local camera = require "necro.render.Camera"
local transformationMatrix = require "system.gfx.TransformationMatrix"
local riftedCamera = require "Rifted.RiftedCamera"
local gfx = require "system.gfx.GFX"
local chat = require "necro.client.Chat"
local menu = require "necro.menu.Menu"
local riftedSchema = require "Rifted.RiftedSchema"
local riftedBeatmap = require "Rifted.RiftedBeatmap"
local riftedRenderer = require "Rifted.RiftedRenderer"
local riftedSim = require "Rifted.RiftedSim"
local riftedFormat = require "Rifted.RiftedFormat"
local riftedMusic = require "Rifted.RiftedMusic"
local riftedTimeline = require "Rifted.RiftedTimeline"
local riftedTool = require "Rifted.RiftedTool"
local render = require "necro.render.Render"
local color = require "system.utils.Color"
local ecs = require "system.game.Entities"
local ui = require "necro.render.UI"
local input = require "system.game.Input"
local riftedUI = require "Rifted.RiftedUI"
local customActions = require "necro.game.data.CustomActions"
local tile = require "necro.game.tile.Tile"
local settings = require "necro.config.Settings"
local settingsStorage = require "necro.config.SettingsStorage"

local tileSize = render.TILE_SIZE
local screen_y = 0
local screen_x = 0
local screen_x2 = 0

local function makeNPSOtions(args)
	settings.user.group {
		id = ("nps_graph.%s"):format(args.group),
		name = args.name,
		order = args.order,
		desc = args.desc,
		autoRegister = true,
	}
	return {
		id = args.group,
		offset = settings.user.number {
			autoRegister = true,
			id = ("nps.%s.offsetx"):format(args.group),
			name = "NPS Offset X",
			default = 32,
			step = 1,
			minimum = 0,
			maximum = 1280,
			order = 20,
		},
		offsetY = settings.user.number {
			autoRegister = true,
			id = ("nps.%s.offsety"):format(args.group),
			name = "NPS Offset Y",
			default = 64,
			step = 1,
			minimum = 0,
			maximum = 720,
			order = 20,
		},
		width = settings.user.number {
			autoRegister = true,
			id = ("nps.%s.width"):format(args.group),
			name = "NPS Width",
			default = 10,
			step = 1,
			minimum = 1,
			maximum = 50,
			order = 20,
		},
		window = settings.user.number {
			autoRegister = true,
			id = ("nps.%s.window"):format(args.group),
			name = "NPS Window",
			default = 1.0,
			step = .1,
			minimum = .1,
			maximum = 5,
			order = 20,
		},
		render = settings.user.bool {
			autoRegister = true,
			id = ("nps.%s.render"):format(args.group),
			name = "Show NPS Graph",
			default = true,
			order = 20,
		},
	}
end

local mapOpts = makeNPSOtions {
	name = "NPS options",
	group = "main",
	desc = "Configure the settings of the nps graph",
	order = 1500,
	defaults = {
		color = color.hex(0x2288AA),
		scale = 1,
		offset = 0,
		mirror = false,
	},
}

local cfg = settingsStorage.get



function riftedNPS.get_nps_at_subdiv( subdiv, window )
	
	local t = riftedGoto.beat_to_time( subdiv / riftedBeatmap.getSubdiv() - riftedBeatmap.getCountdownTicks() + 1)
	if t == 0 then
		return 0
	end

	local t2 = t - window
	if t2 <= 0 then
		t2 = 0
	end

	local b2 = subdiv
	while riftedGoto.beat_to_time( b2 / riftedBeatmap.getSubdiv() - riftedBeatmap.getCountdownTicks() + 1) >= t2 do
		b2 = b2 - 1
	end
	
	t2 = riftedGoto.beat_to_time( b2 / riftedBeatmap.getSubdiv() - riftedBeatmap.getCountdownTicks() + 1)
	
	local notes = 0
	for i = b2, subdiv do
		local state = riftedSim.getState(i)
		if state then
			for _, entity in ipairs(state.hits) do
				local edata = entity.data
				local proto = riftedSchema.getType(entity.type)
				--local friendlyName = proto.friendlyName and proto.friendlyName.name or etype or "???"

				--log.info( friendlyName ) 
				if proto then
					if proto.enemy or proto.consumableHeal then
						notes = notes + 1
					end
				end
			end
		end
	end
	
	return notes / (window)
end


function draw_nps_graph()
	local offsetX = cfg(mapOpts.offset)
	local offsetY = cfg(mapOpts.offsetY)
	local width = cfg(mapOpts.width)
	local window = cfg(mapOpts.window)
	
	local spawnRow = -riftedTimeline.getSpawnRow() - 1
	local steps = width
	local hop = window
	
	spawnRow = math.floor( spawnRow / riftedBeatmap.getSubdiv() ) * riftedBeatmap.getSubdiv()  
	
	local nps = {}
	local max_nps = 1
	local step_beat = spawnRow
	for i=0,steps do
		local t_step = riftedGoto.beat_to_time( spawnRow / riftedBeatmap.getSubdiv() - riftedBeatmap.getCountdownTicks() + 1)
		t_step = t_step - i * hop
		if t_step <= 0 then
			t_step = 0
		end
		while riftedGoto.beat_to_time( step_beat / riftedBeatmap.getSubdiv() - riftedBeatmap.getCountdownTicks() + 1) > t_step do
			step_beat = step_beat - 1
		end
		step_beat = spawnRow - i * riftedBeatmap.getSubdiv() 
		nps[ #nps +1 ] = riftedNPS.get_nps_at_subdiv( step_beat + 1, 2.0 )
		if nps[#nps] > max_nps then
			max_nps = nps[#nps]
		end
	end 
	
	local buffer = render.getBuffer(render.Buffer.UI_EDITOR)

    local mtx = transformationMatrix.inverse(render.getCameraOptions(render.Transform.EDITOR).transform)
        .combine(render.getCameraOptions(render.Transform.CAMERA).transform)

    local scaleFactor = riftedUI.getScaleFactor()

    local cx, cy = riftedCamera.getViewCenter()
    
	local ey = cy - 160
	
	local size = 4 * steps
	
	local world_x = offsetX
	ey = offsetY
	
	
	local cy = 0
	
	buffer.draw( {
		rect = { world_x, ey, size+1, size+1 },
		color = color.hex("#00000080"),
		z = -10000
	})
	
	
	draw_box_outline( buffer, world_x-1, ey-1, size+2, (size+2) )
	for i=1, #nps do
		local n = size-((nps[i] / max_nps ) * size)
		if i == 1 then
			cy = ey + n
		end
		
		local x1 = world_x + size - (i-1) * (size/steps)
		local y1 = ey + n
		
		if i < #nps then
			local n2 = size-((nps[i+1] / max_nps ) * size)
			local x2 = world_x + size - (i) * (size/steps)
			local y2 = ey + n2
			draw_line(buffer, x1, y1, x2, y2)
		end
		
		--local box = {
		--	rect = { world_x + size - (i-1) * (size/steps), ey + n , 1, 1 },
		--	color = color.opacity(1),
		--	z = -10000,
		--}
		--buffer.draw( box )
	end
	
	ui.drawText {
		buffer = render.Buffer.UI_EDITOR,
		uppercase = false,
		font = riftedUI.Font.MEDIUM,
		x = world_x + size + 4,
		y = ey,
		text = string.format( "%.1f", max_nps),
		alignX = 0,
		alignY = 0.5,
		size = 12,
		fillColor = color.WHITE,
		outlineColor = color.BLACK,
		z = -10000,
	}
	
	ui.drawText {
		buffer = render.Buffer.UI_EDITOR,
		uppercase = false,
		font = riftedUI.Font.MEDIUM,
		x = world_x + size + 4,
		y = cy,
		text = string.format( "%.1f", nps[1]),
		alignX = 0,
		alignY = 0.5,
		size = 12,
		fillColor = color.WHITE,
		outlineColor = color.BLACK,
		z = -10000,
	}

end

function draw_line( buffer, x1, y1, x2, y2 )
	local dist = math.sqrt( (x2-x1) * (x2-x1) + (y2-y1)*(y2-y1) )
	local box = {
		rect = { x1, y1, dist, 1 },
		color = color.opacity(1),
		z = -10000,
		angle = math.atan2( y2-y1, x2-x1 ),
		origin = {0, 0}
	}
	buffer.draw( box )
end

function draw_box_outline( buffer, x, y, w, h )
	local box = {
		rect = { x, y, w, 1},
		color = color.opacity(.5),
		z = -10000,
	}
	buffer.draw(box)
	
	box.rect[2] = y + h
	buffer.draw(box)
	
	box.rect = {x,y,1,h}
	buffer.draw(box)
	
	box.rect[1] = x + w
	buffer.draw(box)
end


event.render.add("renderNPSGraph", "objects", function()
	if cfg(mapOpts.render) then
		draw_nps_graph()
    end
end)

return riftedNPS
