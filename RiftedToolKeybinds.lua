local customActions = require "necro.game.data.CustomActions"
local riftedTool = require "Rifted.RiftedTool"

customActions.registerHotkey {
    id = "TOOL_SCROLL",
    category = "Rifted Utils",
    name = "Scroll tool",
    keyBinding = "lshift+1",
    callback = function ()
      	riftedTool.setTool(riftedTool.Type.VIEW_SCROLL)
    end,
}

customActions.registerHotkey {
    id = "TOOL_PEN",
    category = "Rifted Utils",
    name = "Pen tool",
    keyBinding = "lshift+2",
    callback = function ()
      	riftedTool.setTool(riftedTool.Type.PEN)
    end,
}

customActions.registerHotkey {
    id = "TOOL_LINE",
    category = "Rifted Utils",
    name = "Line tool",
    keyBinding = "lshift+3",
    callback = function ()
      	riftedTool.setTool(riftedTool.Type.LINE)
    end,
}

customActions.registerHotkey {
    id = "TOOL_RECTANGLE_OUTLINE",
    category = "Rifted Utils",
    name = "Rectangle outline tool",
    keyBinding = "lshift+4",
    callback = function ()
      	riftedTool.setTool(riftedTool.Type.RECTANGLE_OUTLINE)
    end,
}

customActions.registerHotkey {
    id = "TOOL_RECTANGLE_FILLED",
    category = "Rifted Utils",
    name = "Rectangle filled tool",
    keyBinding = "lshift+5",
    callback = function ()
      	riftedTool.setTool(riftedTool.Type.RECTANGLE_FILLED)
    end,
}

customActions.registerHotkey {
    id = "TOOL_SELECT_RECTANGLE",
    category = "Rifted Utils",
    name = "Rectangle selection tool",
    keyBinding = "lshift+6",
    callback = function ()
      	riftedTool.setTool(riftedTool.Type.SELECT_RECTANGLE)
    end,
}

customActions.registerHotkey {
    id = "TOOL_MOVE_OBJECT",
    category = "Rifted Utils",
    name = "Move tool",
    keyBinding = "lshift+7",
    callback = function ()
      	riftedTool.setTool(riftedTool.Type.MOVE_OBJECT)
    end,
}

customActions.registerHotkey {
    id = "TOOL_EDIT_LEVEL_SETTINGS",
    category = "Rifted Utils",
    name = "Edit level settings tool",
    keyBinding = "lshift+8",
    callback = function ()
      	riftedTool.setTool(riftedTool.Type.EDIT_LEVEL_SETTINGS)
    end,
}





