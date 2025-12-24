local riftedGoTo = {}

local render = require "necro.render.Render"
local chat = require "necro.client.Chat"
local enum = require "system.utils.Enum"
local gfx = require "system.gfx.GFX"
local riftedCamera = require "Rifted.RiftedCamera"
local riftedMusic = require "Rifted.RiftedMusic"
local riftedCamera = require "Rifted.RiftedCamera"
local riftedBeatmap = require "Rifted.RiftedBeatmap"
local menu = require "necro.menu.Menu"
local customActions = require "necro.game.data.CustomActions"
local riftedTimeline = require "Rifted.RiftedTimeline"
local riftedTimeScale = require "Rifted.RiftedTimeScale"
local riftedUI = require "Rifted.RiftedUI"
local settings = require "necro.config.Settings"

local floor = math.floor

local active = false
local defaultX, defaultY = 0, render.TILE_SIZE

function riftedGoTo.beat_to_time( beat )
	local spb = 60 / riftedBeatmap.getBPM()
	if beat < 0 then
		return 0
	end
	return floor(riftedTimeScale.getRawTimeForScaledTime((beat-1) * spb) * 1000 + 0.5) / 1000
end

local function seekOffset()
	return select(riftedCamera.isRotated() and 1 or 2, gfx.getSize()) * riftedCamera.getZoom() * 0.5
end

function riftedGoTo.seekBeat( beat )
	local h =  defaultY * riftedBeatmap.getSubdiv()
	riftedTimeline.setSpawnRow( -(beat-1) * riftedBeatmap.getSubdiv() - riftedBeatmap.getSubdiv()/2)
	riftedCamera.moveAbsolute(riftedCamera.getViewCenter(), -h*(beat-8), true)
end

local function seekTime( time )
	if time < 0 then
		return 0
	end
	local spb = 60 / riftedBeatmap.getBPM()
	local initial_guess = floor(time / spb)
	
	local current_guess = initial_guess
	local current_time = beat_to_time(current_guess)

	if current_time > time then
		while current_time > time do
			current_guess = current_guess - 1
			current_time = beat_to_time(current_guess)
		end
		current_guess = current_guess + 1
	else
		while current_time < time do
			current_guess = current_guess + 1
			current_time = riftedGoTo.beat_to_time(current_guess)
		end
		current_guess = current_guess - 1
	end

	riftedGoTo.seekBeat( current_guess )
end

local goToBeatPromptID = chat.Prompt.extend("GO_TO_BEAT", enum.data {
	writeHistory = true,
	func = function (text)
		if text:match("s$") then
			text = text:sub(0, #text-1)
			if text:match("^%-?%d*%.?%d*$") then -- float
				seekTime( tonumber(text) )
			end
		else
			if text:match("^%-?%d*%.?%d*$") then -- float
				riftedGoTo.seekBeat( tonumber(text) )
			end
		end
		

	end,
	cancelFunc = function (text)
	end,
	blockInput = true,
})

customActions.registerHotkey {
    id = "GO_TO_BEAT",
    category = "Rifted Utils",
    name = "Go to beat",
    keyBinding = "lcontrol+g",
    callback = function ()
        chat.openChatbox(L"Go to", goToBeatPromptID)
    end,
}

--event.renderUI.add("hookTextRendering", {order = "objects", sequence = -1}, function (ev)
--    local buffer = render.getBuffer(render.Buffer.UI_EDITOR)
--    buffer.hook(buffer.drawText, function (args)
--        args.text = string.format("%s test", args.text)
--    end)
--end)

return riftedGoTo
