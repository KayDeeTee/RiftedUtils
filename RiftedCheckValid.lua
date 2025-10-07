local riftedCheckValid = {}

local ecs = require "system.game.Entities"
local camera = require "necro.render.Camera"
local riftedBeatmap = require "Rifted.RiftedBeatmap"
local transformationMatrix = require "system.gfx.TransformationMatrix"
local render = require "necro.render.Render"
local utils = require "system.utils.Utilities"
local menu = require "necro.menu.Menu"
local riftedCamera = require "Rifted.RiftedCamera"
local gfx = require "system.gfx.GFX"
local riftedFormat = require "Rifted.RiftedFormat"
local riftedTimeScale = require "Rifted.RiftedTimeScale"
local ui = require "necro.render.UI"
local riftedUI = require "Rifted.RiftedUI"
local color = require "system.utils.Color"
local riftedSchema = require "Rifted.RiftedSchema"
local riftedEntities = require "Rifted.RiftedEntities"
local riftedSim = require "Rifted.RiftedSim"
local riftedInput = require "Rifted.RiftedInput"
local controls = require "necro.config.Controls"

local col = color.hex(0xFF4422)

local toggle = true

local customActions = require "necro.game.data.CustomActions"

local function draw_invalid_at(x,y,a,b,c, fontScale)

	ui.drawText {
				buffer = render.Buffer.UI_EDITOR,
				uppercase = false,
				font = riftedUI.Font.MEDIUM,
				x = x,
				y = y,
				text = string.format("Invalid %s spawning on beat %.2f\nEnsure charts subdiv is multiple of %d", a, b+1, c),
				alignX = 0,
				alignY = 0,
				size = 18,
				fillColor = col,
				z = -100000,
	}

end


customActions.registerHotkey {
    id = "TOGGLE_ARMADILLO_CHECJ",
    category = "Rifted Utils",
    name = "Toggle Armadillo Check",
    keyBinding = "lcontrol+lshift+a",
    callback = function ()
        toggle = not toggle
    end,
}


event.render.add("checkValid", {order = "objects", sequence = 1}, function ()

	if toggle then
		return
	end

	local mtx = transformationMatrix.inverse(render.getCameraOptions(render.Transform.EDITOR).transform)
		.combine(render.getCameraOptions(render.Transform.CAMERA).transform)
	local fontScale = utils.clamp(0.25, math.max(mtx.transformVector(1, 0)), 1)


	local check_halfs 	= riftedBeatmap.getSubdiv() % 2 ~= 0
	local check_thirds 	= riftedBeatmap.getSubdiv() % 3 ~= 0

	local y = 0
	local y_scale = 48
	
	if check_halfs or check_thirds then
		for entity in ecs.entitiesWithComponents {"Rifted_object"} do
			if y >= 5 then
				break
			end
			local e = ecs.getEntityByID(entity.id)
		 	if entity.Rifted_object.data.parameters.EnemyId then
				if riftedSchema.getType(entity.Rifted_object.data.parameters.EnemyId).friendlyName then
					local ename = riftedSchema.getType(entity.Rifted_object.data.parameters.EnemyId).friendlyName.name
					if e.Rifted_object.data.type == riftedFormat.EventType.SPAWN_ENEMY then
						local etype = e.Rifted_object.data.parameters.EnemyId or false
						if check_halfs then

							if etype == "Rifted_E1911" then
								draw_invalid_at(8,64+y*y_scale, ename, e.Rifted_object.data.start, 2, fontScale)
								y = y+1
							end

							if etype == "Rifted_E6471" then
								draw_invalid_at(8,64+y*y_scale, ename, e.Rifted_object.data.start, 2, fontScale)
								y = y+1
							end

							if etype == "Rifted_E4871" then
								draw_invalid_at(8,64+y*y_scale, ename, e.Rifted_object.data.start, 2, fontScale)
								y = y+1
							end

							if etype == "Rifted_E3307" then
								draw_invalid_at(8,64+y*y_scale, ename, e.Rifted_object.data.start, 2, fontScale)
								y = y+1
							end

						end

						if check_thirds then

							if etype == "Rifted_E7831" then
								draw_invalid_at(8,64+y*y_scale, ename, e.Rifted_object.data.start, 3, fontScale)
								y = y+1
							end

							if etype == "Rifted_E1707" then
								draw_invalid_at(8,64+y*y_scale, ename, e.Rifted_object.data.start, 3, fontScale)
								y = y+1
							end

							if etype == "Rifted_E6311" then
								draw_invalid_at(8,64+y*y_scale, ename, e.Rifted_object.data.start, 3, fontScale)
								y = y+1
							end
						end
					end
				end
			end
		end
	end

end)

return riftedCheckValid