local mod_gui = require("mod-gui")

for _, player in pairs(game.players) do
    mod_gui.get_frame_flow(player).clear()
end

for _, player_gui in pairs(global.gui) do
    for _, gui_element in pairs(player_gui) do
        gui_element.destroy()
    end
end
global.gui = nil
