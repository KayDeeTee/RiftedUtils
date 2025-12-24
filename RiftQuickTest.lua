local riftedStorage = require "necro.game.data.resource.RiftedStorage"
local riftedFileMenu = require "Rifted.RiftedFileMenu"
local riftedBeatmap = require "Rifted.RiftedBeatmap"
local riftedFieldType = require "Rifted.RiftedFieldType"
local riftedTimeline = require "Rifted.RiftedTimeline"
local customActions = require "necro.game.data.CustomActions"

local currentLevel = require "necro.game.level.CurrentLevel"


customActions.registerHotkey {
    id = "QUICK_TEST",
    category = "Rifted Utils",
    name = "Quick Test",
    keyBinding = "f5",
    callback = function()
        riftedFileMenu.quickSave()
        
        local activeLevel = currentLevel.getNumber() - 1
        
        local song_name = riftedFileMenu.getSaveName()
        
        local name = riftedStorage.validateName("rifted_utils_quick_test")
        
        if not riftedStorage.exists(name) and not riftedStorage.create(name) then
			log.error("Failed to create directory")
			return
		end
		
		local to_save = song_name .. "\n" .. activeLevel  .. "\n" .. (math.floor((riftedTimeline.getSpawnRow() * -1) / riftedBeatmap.getSubdiv()))
        
        riftedStorage.write(name, "quick_test.txt", to_save)
    end,
}
