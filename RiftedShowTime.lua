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
local riftedInput = require "Rifted.RiftedInput"
local riftedTool = require "Rifted.RiftedTool"
local customActions = require "necro.game.data.CustomActions"
local controls = require "necro.config.Controls"
local riftedLevelOptions = require "Rifted.RiftedLevelOptions"
local tileSize = render.TILE_SIZE
local max = math.max
local min = math.min
local abs = math.abs
local floor = math.floor
local ceil = math.ceil

local number_type = 0

local highlight_beat = 0
local rowCount = riftedFormat.Row.SPAWN - riftedFormat.Row.ACTION

local function getVisibleTileRect()
    local subdiv = riftedBeatmap.getSubdiv()
    local invTileSize = 1 / render.TILE_SIZE
    local inverse = transformationMatrix.inverse(render.getTransform(render.Transform.CAMERA))
    local rect = inverse.transformRect(gfx.getScreenRect())
    local x1 = rect[1] * invTileSize - 1.001
    local y1 = (rect[2] * invTileSize - 2.001 * subdiv)
    local x2 = (rect[1] + rect[3]) * invTileSize + 1.001
    local y2 = ((rect[2] + rect[4]) * invTileSize + 2.001 * subdiv)
    return floor(x1), floor(y1), ceil(x2 - x1), ceil(y2 - y1)
end

local function draw_text()
    if number_type == 0 then
        return
    end

    local subdiv = riftedBeatmap.getSubdiv()

    local x, y, w, h = getVisibleTileRect()
    y = floor(y / subdiv) * subdiv


    local snap = camera.getViewScale() * subdiv >= 1.5 and subdiv or 4 * subdiv
    local mtx = transformationMatrix.inverse(render.getCameraOptions(render.Transform.EDITOR).transform)
        .combine(render.getCameraOptions(render.Transform.CAMERA).transform)
    local fontScale = utils.clamp(0.25, math.max(mtx.transformVector(1, 0)), 1)
    --- @diagnostic disable-next-line: undefined-field
    local fontOpacity = menu.isOpen() and not menu.getCurrent().Rifted_noFade and 0.4 or 1
    local alignX, alignY = riftedCamera.isRotated() and 0.5 or 1, riftedCamera.isRotated() and 1 or 0.5
    local spb = 60 / riftedBeatmap.getBPM()
    for row = floor(y / snap) * snap, y + h - 1, snap do
        local tx, ty = mtx.transformPoint(-1.5 * tileSize - 12, (row - 0.5) * tileSize)
        local tx2, ty2 = mtx.transformPoint(-3.5 * tileSize - 12, (row - 0.5) * tileSize)
        local index = -row / subdiv + rowCount + 1
        local t = 0.0
        local s = 1.0

        local str = ""
        if number_type == 1 then
            if index >= 0 then
                t = floor(riftedTimeScale.getRawTimeForScaledTime((index - riftedBeatmap.getCountdownTicks() - 1) * spb) * 1000 + 0.5) / 1000
                str = string.format("%.3fs", t)
            end
        else
            t = floor(riftedTimeScale.getRawTimeForScaledTime((index - riftedBeatmap.getCountdownTicks() - 1) * spb) * 1000 + 0.5) / 10
            t = t / spb
            t = (math.floor(t + 0.5) / 100)
            str = string.format("%.2f", t)
        end

        if not riftedCamera.isRotated() then
            ui.drawText {
                buffer = render.Buffer.UI_EDITOR,
                uppercase = false,
                font = riftedUI.Font.MEDIUM,
                x = tx2,
                y = ty,
                text = str,
                alignX = 1,
                alignY = alignY,
                size = fontScale * ((index + 2) % 4 == 3 and 24 or 16),
                fillColor = color.opacity(fontOpacity * ((index + 2) % 4 == 3 and .8 or .3)),
                z = -100000,
            }
        end
    end
    local tx3, ty3 = mtx.transformPoint(4.5 * tileSize - 12, (-highlight_beat * riftedBeatmap.getSubdiv() - 0.5) *
        tileSize)
    local highlight_t = floor(riftedTimeScale.getRawTimeForScaledTime((highlight_beat + 8) * spb) * 1000 + 0.5) / 1000

    local str = ""
    if number_type == 1 then
        if highlight_beat >= 0 then
            local t = floor(riftedTimeScale.getRawTimeForScaledTime((highlight_beat + 8) * spb) * 1000 + 0.5) / 1000
            str = string.format("%.3fs", t)
        end
    else
        if highlight_beat >= 0 then
            highlight_t = floor(riftedTimeScale.getRawTimeForScaledTime((highlight_beat + 8) * spb) * 1000 + 0.5) / 10
            highlight_t = highlight_t / spb
            highlight_t = (math.floor(highlight_t + 0.5) / 100) + 1
            str = string.format("%.2f", highlight_t)
        end
    end

    if not riftedCamera.isRotated() then
        ui.drawText {
            buffer = render.Buffer.UI_EDITOR,
            uppercase = false,
            font = riftedUI.Font.MEDIUM,
            x = tx3 + 4,
            y = ty3,
            text = str,
            alignX = 0,
            alignY = alignY,
            size = 12,
            fillColor = color.YELLOW,
            outlineColor = color.BLACK,
            z = -10000,
        }
    end
end

customActions.registerHotkey {
    id = "CHANGE_EXTRA_TIME_FORMAT",
    category = "Rifted Utils",
    name = "Change extra time info format",
    keyBinding = "lshift+n",
    callback = function()
        number_type = (number_type + 1) % 3
    end,
}

--event.render.add("hookTextRendering", {order = "objects", sequence = -1}, function (ev)
--    local buffer = render.getBuffer(render.Buffer.UI_EDITOR)
--    buffer.hook(buffer.drawText, function (args)
--        args.text = string.format("%s test", args.text)
--    end)
--end)

event.render.add("renderTimes", { order = "objects", sequence = -1 }, function()
    local cursorX, cursorY = riftedInput.getCursorPosition()
    local x, y = riftedTool.transformCursorPosition(cursorX, cursorY)

    local denominator = riftedBeatmap.getSubdiv()

    if riftedLevelOptions.isFineTuneModeEnabled() then
        denominator = 48
    else
        if not riftedInput.checkHold(controls.Misc.EDITOR_MODIFIER) then
            y = riftedTool.snapY(y)
        end
    end

    local numerator = y % riftedBeatmap.getSubdiv()
    local base = -((y / denominator))
    local sum = math.floor(base) + ((denominator - numerator) / denominator)
    if numerator == 0 then
        sum = sum - 1
    end

    highlight_beat = sum

    draw_text()
end)
