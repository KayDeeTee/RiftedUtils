local riftedRenderer = {}

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

local floor = math.floor
local ceil = math.ceil

local getColor = riftedRenderer.getColor

local tileSize = render.TILE_SIZE

local screen_y = 0
local screen_x = 0
local screen_x2 = 0

local final_beat = 0

local offset = 9

local vibe_bg = color.hex("#ffff0060")

local max_density = 2

local minimap_mode = 0

local state_cache = {}
local cached_chart = ""
local state_length = 0
local state_index = 0

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


local function lerp(a, b, t) return a * (1 - t) + b * t end

local function col_lerp(amt)
    if amt < .5 then
        local r = lerp(0x0d, 0xb9, amt * 2)
        local g = lerp(0x08, 0x32, amt * 2)
        local b = lerp(0x47, 0x89, amt * 2)
        return color.rgb(r, g, b)
    else
        amt = (amt - 0.5) * 2
        local r = lerp(0xb9, 0xf0, amt)
        local g = lerp(0x32, 0xf9, amt)
        local b = lerp(0x89, 0x21, amt)
        return color.rgb(r, g, b)
    end
end

function draw_minimap()
    if minimap_mode == 0 then
        return
    end
    if riftedCamera.isRotated() then
        return
    end
    local buffer = render.getBuffer(render.Buffer.OBJECT)

    local mtx = transformationMatrix.inverse(render.getCameraOptions(render.Transform.EDITOR).transform)
        .combine(render.getCameraOptions(render.Transform.CAMERA).transform)

    local world_x = tileSize * 3.5 + ((0.5 * 4) / camera.getViewScale() / riftedBeatmap.getSubdiv())
    local world_x2 = tileSize * 3.5 + ((4 * 4) / camera.getViewScale() / riftedBeatmap.getSubdiv())

    local scaleFactor = riftedUI.getScaleFactor()

    screen_x, screen_y = mtx.transformPoint(world_x, 0)
    screen_x2, screen_y = mtx.transformPoint(world_x2, 0)
    screen_y = 56 * scaleFactor

    local cx, cy = riftedCamera.getViewCenter()

    cy = cy + (gfx.getHeight() / 2) / camera.getViewScale()

    local enemy_hits = 0
    local food_hits = 0
    local wyrm_hits = 0

    local last_bpm = -1
    local bpm_offset = 0

    local maxBeat = offset

    

    for entity in ecs.entitiesWithComponents { "Rifted_object" } do
        local data = entity.Rifted_object.data

        local ex, ey = data.track, data.start
        local c = color.opacity(1)

        ex = tileSize * 3.5 + ((ex * 4) / camera.getViewScale() / riftedBeatmap.getSubdiv())
        ey = cy - 2 + ((-ey / final_beat) * (gfx.getHeight() - screen_y)) / camera.getViewScale()
        local typename = data.type

        if data.type == riftedFormat.EventType.SPAWN_ENEMY then
            local start = entity.Rifted_object.data.start
            if start then
                maxBeat = math.max(maxBeat, start + (tonumber(entity.Rifted_object.data.length) or 0))
            end

            local etype = data.parameters.EnemyId or false
            typename = etype
        elseif data.type == riftedFormat.EventType.SPAWN_TRAP then
            local proto = riftedSchema.lookUpTrap(data.parameters.TrapTypeToSpawn) or emptyProto
            local ttype = proto.name
            typename = ttype
        else
            local etype = riftedSchema.resolveMisc(data.type)
            --data.parameters.bpm
            if etype == "AdjustBPM" then
                if bpm_offset == 0 then
                    last_bpm = data.start
                    bpm_offset = 1
                else
                    if data.start - last_bpm > 6 then
                        last_bpm = data.start
                        bpm_offset = 1
                    else
                        bpm_offset = bpm_offset + 1
                    end
                end

                local bpm = tonumber(data.parameters.Bpm)

                ui.drawText {
                    buffer = render.Buffer.UI_EDITOR,
                    uppercase = false,
                    font = riftedUI.Font.SMALL,
                    x = screen_x2 + 4 + (16 * (bpm_offset - 1)),
                    y = gfx.getHeight() - ((data.start + offset) / final_beat) * (gfx.getHeight() - screen_y),
                    text = string.format("%d", bpm),
                    alignX = 0,
                    alignY = 1,
                    size = 6,
                    fillColor = color.opacity(1),
                    z = -100000,
                }
            elseif etype == "VibeChain" then
                ey = cy +
                    ((-(data.start + offset + (data.length + 1)) / final_beat) * (gfx.getHeight() - screen_y)) /
                    camera.getViewScale()
                local ey2 = cy +
                    ((-(data.start + offset) / final_beat) * (gfx.getHeight() - screen_y)) / camera.getViewScale()

                local box = {
                    rect = { world_x, ey, world_x2 - world_x, ey2 - ey },
                    color = vibe_bg,
                    z = -10000,
                }

                buffer.draw(box)
            end
            --log.info(etype)
        end
    end

    if maxBeat + offset > final_beat then
        riftedBeatmap.merge {
            maximumBeat = maxBeat,
        }
        final_beat = maxBeat + offset
    end

    --draw minimap

    if cached_chart ~= (riftedMusic.getLoadedFileName() .. riftedBeatmap.getDifficulty()) then
        cached_chart = (riftedMusic.getLoadedFileName() .. riftedBeatmap.getDifficulty())
        state_cache = {}
        state_length = 0
        max_density = 2
    end

    if state_length == 0 then
        for i = 0, (final_beat) * riftedBeatmap.getSubdiv() do
            state_cache[i] = riftedSim.getState(i)
            state_length = state_length + 1
        end
    end

    local x,y,w,h = getVisibleTileRect()
    y = -y - ( (riftedBeatmap.getCountdownTicks() + 4) * riftedBeatmap.getSubdiv() )
    y = floor( y )
    h = ceil( h + 4 * riftedBeatmap.getSubdiv() )
    
    for i = y, y+h do
        state_cache[i] = riftedSim.getState(i)
    end

    --for _ = 0, 64 do
    --    state_index = state_index + 1
    --    state_index = state_index % ((final_beat) * riftedBeatmap.getSubdiv())
    --    state_cache[state_index] = riftedSim.getState(state_index)
    --end

    if minimap_mode == 1 then --draw hit events
        for i = 0, (final_beat) * riftedBeatmap.getSubdiv() do
            local state = state_cache[i]
            if state then
                for _, entity in ipairs(state.hits) do
                    local edata = entity.data
                    local proto = riftedSchema.getType(entity.type)
                    --local friendlyName = proto.friendlyName and proto.friendlyName.name or etype or "???"

                    --log.info( friendlyName )
                    if proto then
                        if proto.enemy or proto.consumableHeal then
                            if proto.consumableHeal then
                                food_hits = food_hits + 1
                            else
                                if proto.name == "Rifted_E9888" then
                                    wyrm_hits = wyrm_hits + 1
                                    enemy_hits = enemy_hits + 1
                                    goto continue --this is fucking insane who designs a language without continues wtf???????
                                else
                                    enemy_hits = enemy_hits + 1
                                end
                            end

                            local ex, ey = entity.x, i / riftedBeatmap.getSubdiv()
                            ex = tileSize * 3.5 + ((ex * 4) / camera.getViewScale() / riftedBeatmap.getSubdiv())
                            ey = cy - 2 + ((-ey / final_beat) * (gfx.getHeight() - screen_y)) / camera.getViewScale()


                            local c = color.opacity(1)

                            c = getColor(proto.name)

                            local box = {
                                rect = { ex, ey - riftedBeatmap.getSubdiv(), (2 / riftedBeatmap.getSubdiv()) / camera.getViewScale(), 2 / camera.getViewScale() },
                                color = c,
                                z = -10000,
                            }

                            buffer.draw(box)
                        elseif proto.trap then

                        else
                        end
                    end
                    ::continue::
                end
            end
        end

        ui.drawText {
            buffer = render.Buffer.UI_EDITOR,
            uppercase = false,
            font = riftedUI.Font.MEDIUM,
            x = screen_x - 2,
            y = gfx.getHeight()/ scaleFactor - 32 ,
            text = string.format("%d enemies (%.1f%% wyrms)", enemy_hits, (wyrm_hits / enemy_hits) * 100),
            alignX = 1,
            alignY = 0,
            size = 12,
            fillColor = color.opacity(1),
            outlineColor = color.BLACK,
            z = -100000,
        }

        ui.drawText {
            buffer = render.Buffer.UI_EDITOR,
            uppercase = false,
            font = riftedUI.Font.MEDIUM,
            x = screen_x - 2,
            y = gfx.getHeight()/ scaleFactor - 44,
            text = string.format("%d heals", food_hits),
            alignX = 1,
            alignY = 0,
            size = 12,
            fillColor = color.opacity(1),
            outlineColor = color.BLACK,
            z = -10000,
        }
    else -- draw density
        for i = 0, (final_beat) * riftedBeatmap.getSubdiv() do
            local from = i - riftedBeatmap.getSubdiv()
            local to = i + riftedBeatmap.getSubdiv()
            if from < 0 then
                from = 0
            end
            if to > (final_beat) * riftedBeatmap.getSubdiv() then
                to = (final_beat) * riftedBeatmap.getSubdiv()
            end
            local event_count = 0
            for j = from, to do
                local state = state_cache[j]
                if state then
                    for _, entity in ipairs(state.hits) do
                        local edata = entity.data
                        local proto = riftedSchema.getType(entity.type)
                        local friendlyName = proto.friendlyName and proto.friendlyName.name or etype or "???"

                        --log.info( friendlyName )
                        if proto then
                            if proto.enemy or proto.consumableHeal then
                                if proto.consumableHeal then
                                    event_count = event_count + 1
                                else
                                    if proto.name == "Rifted_E9888" then
                                        wyrm_hits = wyrm_hits + 1
                                        goto continue2 --this is fucking insane who designs a language without continues wtf???????
                                    else
                                        event_count = event_count + 1
                                    end
                                end
                            elseif proto.trap then

                            else
                            end
                        end
                        ::continue2::
                    end
                end
            end
            if event_count > max_density then
                max_density = event_count
            end
            local ex = tileSize * 3.5 + ((0.5 * 4) / camera.getViewScale() / riftedBeatmap.getSubdiv())
            local ey = i / riftedBeatmap.getSubdiv()
            ey = cy - 2 + ((-ey / final_beat) * (gfx.getHeight() - screen_y)) / camera.getViewScale()

            local density = event_count / (max_density + 1)

            local box = {
                rect = { ex, ey - riftedBeatmap.getSubdiv(), (16 / riftedBeatmap.getSubdiv()) / camera.getViewScale(), 2 / camera.getViewScale() },
                color = col_lerp(density * density),
                z = -10000,
            }
            buffer.draw(box)
        end
    end

    local spawnRow = riftedTimeline.getSpawnRow()
    local spawn_x = world_x
    local spawn_y = cy +
        (((spawnRow / riftedBeatmap.getSubdiv()) / (final_beat)) * (gfx.getHeight() - screen_y)) / camera.getViewScale()
    spawn_y = spawn_y - riftedBeatmap.getSubdiv()
    local box = {
        rect = { spawn_x, spawn_y, world_x2 - world_x, 1 / camera.getViewScale() },
        color = color.opacity(1.0),
        z = -10000,
    }

    buffer.draw(box)

    --log.info( state )
    --for _, ghost in ipairs(ghostMap) do
    --log.info( ghost )
    --end
end

local dragging = false

event.tick.add("checkInput", { order = "customHotkeys", sequence = 2 }, function(ev)
    if minimap_mode == 0 then
        return
    end
    if input.mouseRelease() then
        dragging = false
    end

    if riftedCamera.isRotated() then
        return
    end

    final_beat = riftedBeatmap.getMaximumBeat() + offset


    local inputBlocked = chat.isBlockingInput() or menu.isOpen() or not not riftedUI.getActiveTextPrompt()
    local cursorX, cursorY = input.mouseX(), input.mouseY()

    local percent = (gfx.getHeight() - cursorY) / (gfx.getHeight() - screen_y)
    --local extra_scale = (riftedBeatmap.getSubdiv() / 4)-1

    local scaleFactor = riftedUI.getScaleFactor()

    if not inputBlocked then
        if cursorX > screen_x * scaleFactor and cursorX < screen_x2 * scaleFactor and cursorY > screen_y then
            if input.mousePress() then
                dragging = true
            end
        end
        if dragging then
            riftedGoto.seekBeat((percent * (final_beat)))
        end
    end
end)

event.render.add("renderMinimap", "objects", function()
    draw_minimap()
end)


customActions.registerHotkey {
    id = "TOGGLE_MINIMAP",
    category = "Rifted Utils",
    name = "Minimap Toggle",
    keyBinding = "lshift+m",
    callback = function()
        minimap_mode = (minimap_mode + 1) % 3
        max_density = 2
    end,
}

return riftedRenderer
