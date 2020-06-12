-- I don't use the "migrations" of Factorio because they are also applied when loading vanilla saves
-- That doens't make sense when trying to cleanup old stuff, so I have to do it myself.
-- Careful, this uses control.lua functions :/
local mod_gui = require("mod-gui")

local migrations = {}

migrations["1.0.0"] = function()
    -- GUI
    for _, player in pairs(game.players) do
        mod_gui.get_frame_flow(player).clear()
    end

    for _, player_gui in pairs(global.gui) do
        for _, gui_element in pairs(player_gui) do
            gui_element.destroy()
        end
    end
    global.gui = nil

    -- HISTORY and STATE will just be taken care of init()
    init()
    game.print("[Speedrun Trainer] clearing old gui, state and history.")
end

return migrations
