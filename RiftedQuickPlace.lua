local customActions = require "necro.game.data.CustomActions"
local input = require "system.game.Input"
local render = require "necro.render.Render"
local gfx = require "system.gfx.GFX"
local gameWindow = require "necro.config.GameWindow"
local camera = require "necro.render.Camera"
local transformationMatrix = require "system.gfx.TransformationMatrix"
local ui = require "necro.render.UI"
local color = require "system.utils.Color"
local controls = require "necro.config.Controls"

local enum = require "system.utils.Enum"


local riftedBeatmap = require "Rifted.RiftedBeatmap"
local riftedCamera = require "Rifted.RiftedCamera"
local riftedTimeline = require "Rifted.RiftedTimeline"
local riftedTool = require "Rifted.RiftedTool"
local riftedMusic = require "Rifted.RiftedMusic"
local riftedInput = require "Rifted.RiftedInput"
local riftedUI = require "Rifted.RiftedUI"
local riftedShape = require "Rifted.RiftedShape"
local riftedObject = require "Rifted.RiftedObject"
local riftedFormat = require "Rifted.RiftedFormat"
local riftedSchema = require "Rifted.RiftedSchema"
local riftedCommand = require "Rifted.RiftedCommand"

local cursorX = 0
local cursorY = 0
local subdiv = 1

local tileSize = render.TILE_SIZE
local max = math.max
local min = math.min
local abs = math.abs
local floor = math.floor
local ceil = math.ceil

local function insert_enemy(id, x, y, facing, is_skeleton, blademaster_row )

	if y < 0 then
		return
	end

	local data = {}

	--for _, entity in ipairs(riftedSchema.listTypes()) do
	--	print( entity.name )
	--end
	
	data.parameters = {
		EnemyId = id,
		ShouldStartFacingRight = facing,
	}
	if is_skeleton then
		data.parameters.ShouldMoveOnDupletMeter = true
	end

	if blademaster_row >= 0 then
		data.parameters.BlademasterAttackRow = blademaster_row
		--this says 4 but i'm pretty sure its inverted and i don't want to figure out what it actually thinks 4 is
		y = y + 2
	end

	-- no idea why left is -1 and right is 1 instead of 012, or 123
	local x2 = x - 1

	-- i love lua and i love that arrays start at 1
	local y2 = (y - 9) * riftedBeatmap.getSubdiv() * -1

	data.type = riftedFormat.EventType.SPAWN_ENEMY
	local command = { 
		cmd = riftedCommand.Type.ENTITY_ADD,		
		--type = riftedObject.Name,
		type = "Rifted_Object",
		attr = {
			Rifted_object = {
				data = data,
			},
		},
		selID = id .. (facing and "R" or "L"), --probably not even important lol

		shape = riftedShape.Type.POINT,
		x = x2,
		y = y2,
		x2 = x2,
		y2 = y2,
		s = 0,
		yp = riftedBeatmap.getSubdiv(),
		yi = y2,
		stack = true,

	}
	riftedCommand.perform( command )
end


local function getVisibleTileRect()
	local invTileSize = 1 / render.TILE_SIZE
	local inverse = transformationMatrix.inverse(render.getTransform(render.Transform.CAMERA))
	local rect = inverse.transformRect(gfx.getScreenRect())
	local x1 = rect[1] * invTileSize - 1.001
	local y1 = (rect[2] * invTileSize - 2.001 * subdiv)
	local x2 = (rect[1] + rect[3]) * invTileSize + 1.001
	local y2 = ((rect[2] + rect[4]) * invTileSize + 2.001 * subdiv)
	return floor(x1), floor(y1), ceil(x2 - x1), ceil(y2 - y1)
end

local function get_timeline_position( lane )
	local squish = riftedCamera.getSquishRatio()
	subdiv = riftedBeatmap.getSubdiv()
	local buffer = render.getBuffer(render.Buffer.FLOOR)
	local x, y, w, h = getVisibleTileRect()
	local sx, sy = camera.getViewScale()
	sx, sy = 0.5 / sx / squish * subdiv, 0.5 / sy * subdiv
	if camera.getViewScale() * subdiv < 1.01 and gameWindow.getEffectiveScale() > 1 then
		sx, sy = sx / 4, sy / 4
	elseif camera.getViewScale() * subdiv < 2.01 then
		sx, sy = sx / 2, sy / 2
	end
	local lx, ly = sx / subdiv * 2, sy / subdiv * 2
	local timeRow = riftedTimeline.getActionRow() + 1-- - subdiv + 2

	y = floor(y / subdiv) * subdiv

	local _x = (lane - 1.5) * tileSize + lx
	local _y = (timeRow - 0.5) * tileSize + ly

	local matrix = render.getTransform(render.Transform.CAMERA)
	local _x, _y = matrix.transformPoint(_x, _y)

	return _x, _y
end

local numerator = 1.0
local denominator = 1.0

local function adjust_snap(amt, shift)
	if shift then
		numerator = numerator + amt
		if numerator <= 0 then
			numerator = 48
		end
		if numerator > 48 then
			numerator = 1
		end
	else
		denominator = denominator + amt
		if denominator <= 0 then
			denominator = 48
		end
		if denominator > 48 then
			denominator = 1
		end
	end
end

local function move_cursor(dx, dy)
	local speed = (riftedBeatmap.getSubdiv() * numerator) / denominator
	dx, dy = dx * speed, dy * speed
	if riftedMusic.isPreviewing() then
		dy = -riftedMusic.seekBeats(-dy)
	end
	riftedCamera.moveRelative(dx * 24, dy * 24, true)
	--riftedTool.move(cursorX, cursorY)
end

customActions.registerHotkey {
    id = "INC_QUICK_NUMER",
    category = "Rifted Utils",
    name = "AdjustQuickSnapDown",
    keyBinding = "lshift+J",
    callback = function ()
    	adjust_snap(-1, true)
    end,
}

customActions.registerHotkey {
    id = "DEC_QUICK_NUMER",
    category = "Rifted Utils",
    name = "AdjustQuickSnapUp",
    keyBinding = "lshift+L",
    callback = function ()
    	adjust_snap(1, true)
    end,
}

customActions.registerHotkey {
    id = "INC_QUICK_DENOM",
    category = "Rifted Utils",
    name = "AdjustQuickSnapDown",
    keyBinding = "J",
    callback = function ()
    	adjust_snap(-1, false)
    end,
}

customActions.registerHotkey {
    id = "DEC_QUICK_DENOM",
    category = "Rifted Utils",
    name = "AdjustQuickSnapUp",
    keyBinding = "L",
    callback = function ()
    	adjust_snap(1, false)
    end,
}

customActions.registerHotkey {
    id = "MOVE_CURSOR_UP",
    category = "Rifted Utils",
    name = "QuickMoveUp",
    keyBinding = "I",
    callback = function ()
    	move_cursor(0,-1)
    end,
}

customActions.registerHotkey {
    id = "MOVE_CURSOR_DOWN",
    category = "Rifted Utils",
    name = "QuickMoveDown",
    keyBinding = "K",
    callback = function ()
    	move_cursor(0,1)
    end,
}

local function brush_is_enemy()
	return riftedTool.getBrush( riftedTool.Mode.PAINT ).attr.Rifted_object.data.type == "SpawnEnemy"
end

local function get_brush_info()
	return riftedTool.getBrush( riftedTool.Mode.PAINT ).attr.Rifted_object.data.parameters
end

function click_brush_track( track )
  	local brush = get_brush_info()
  	local pos = ((riftedTimeline.getActionRow() * -1)-1) / riftedBeatmap.getSubdiv()
  	if brush_is_enemy() then
  		insert_enemy( brush.EnemyId, track, pos + 9, brush.ShouldStartFacingRight, brush.ShouldMoveOnDupletMeter or false, brush.BlademasterAttackRow or -1)
  	end
end

customActions.registerHotkey {
    id = "QUICK_PLACE_1",
    category = "Rifted Utils",
    name = "Quick Place (1)",
    keyBinding = "Z",
    callback = function ()
      	--click_lane(0)
      	click_brush_track(0)
    end,
}

customActions.registerHotkey {
    id = "QUICK_PLACE_2",
    category = "Rifted Utils",
    name = "Quick Place (2)",
    keyBinding = "X",
    callback = function ()
      	click_brush_track(1)
    end,
}

customActions.registerHotkey {
    id = "QUICK_PLACE_3",
    category = "Rifted Utils",
    name = "Quick Place (3)",
    keyBinding = "C",
    callback = function ()
      	click_brush_track(2)
    end,
}

local function draw_text()
	local x,y = get_timeline_position(0)
	if numerator ~= denominator then
		ui.drawText {
			buffer = render.Buffer.UI_EDITOR,
			uppercase = false,
			font = riftedUI.Font.MEDIUM,
			x = x + 4,
			y = y,
			text = string.format("%d/%d", numerator, denominator),
			alignX = 0,
			alignY = 0,
			size = 12,
			fillColor = color.YELLOW,
			outlineColor = color.BLACK,
			z = -10000,
		}
	end
end

local highlight_beat = 0
event.render.add("renderCursorSnap", { order = "objects", sequence = -1 }, function()
    local cursorX, cursorY = riftedInput.getCursorPosition()
    local x, y = riftedTool.transformCursorPosition(cursorX, cursorY)

    draw_text()
end)
