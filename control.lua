local mod_gui = require("mod-gui")

function gui_create(player)
    -- TODO regenerate gui
    global.gui[player.index] = {}
    local gui = global.gui[player.index]
    local frame_flow = mod_gui.get_frame_flow(player)

    local control_frame = frame_flow.add {
        type = "frame",
        direction = "vertical"
    }
    control_frame.add {type = "label", caption = "Speedrun Trainer"}

    gui.button_start = control_frame.add {type = "button", caption = "start"}
    gui.button_stop = control_frame.add {
        type = "button",
        caption = "stop",
        visible = false
    }
    gui.label_status = control_frame.add {type = "label", caption = ""}

    gui.label_time_active = control_frame.add {
        type = "label",
        caption = "0.0",
        style = "large_caption_label"
    }
    gui.label_time_active.style.horizontal_align = "right"
    gui.label_time_active.style.minimal_width = 120

    gui.label_time_real = control_frame.add {
        type = "label",
        caption = "0.0",
        style = "large_caption_label"
    }
    gui.label_time_real.style.horizontal_align = "right"
    gui.label_time_real.style.minimal_width = 120
end

function show_time(label, ticks)
    label.caption = string.format("%.1f", ticks / 60.0)
end

function gui_update(player)
    local gui = global.gui[player.index]
    local state = global.state[player.index]
    if state.running then
        show_time(gui.label_time_active, state.tick_active - state.tick_start)
        show_time(gui.label_time_real, game.tick - state.tick_start)
    end
end

script.on_init(function()
    global.gui = {}
    global.state = {}
    for _, player in pairs(game.players) do
        gui_create(player)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    gui_create(game.get_player(event.player_index))
    global.state[event.player_index] = {}
end)

script.on_event(defines.events.on_gui_click, function(event)
    local clicked_element = event.element
    local state = global.state[event.player_index]
    local gui = global.gui[event.player_index]
    if clicked_element == gui.button_start then
        gui.button_start.visible = false
        gui.button_stop.visible = true
        gui.label_status.caption = "waiting for events"
        state.waiting_for_events = true
    elseif clicked_element == gui.button_stop then
    end
end)

script.on_nth_tick(1, function(event)
    for _, player in pairs(game.players) do
        gui_update(player)
    end
end)

script.on_event({
    defines.events.on_built_entity,
    defines.events.on_entity_settings_pasted,
    defines.events.on_marked_for_deconstruction,
    defines.events.on_marked_for_upgrade,
    defines.events.on_picked_up_item,
    defines.events.on_player_ammo_inventory_changed,
    defines.events.on_player_armor_inventory_changed,
    defines.events.on_player_changed_position,
    defines.events.on_player_crafted_item,
    defines.events.on_player_dropped_item,
    defines.events.on_player_fast_transferred,
    defines.events.on_player_main_inventory_changed,
    defines.events.on_player_mined_entity,
    defines.events.on_player_mined_item,
    defines.events.on_player_mined_tile,
    defines.events.on_player_rotated_entity,
    defines.events.on_player_pipette
}, function(event)
    if event.player_index == nil then
        return
    end

    local state = global.state[event.player_index]
    local gui = global.gui[event.player_index]

    if state.waiting_for_events then
        gui.label_status.caption = "GO!"
        state.waiting_for_events = false
        state.running = true
        state.tick_start = game.tick
        state.tick_active = game.tick
    elseif state.running then
        state.tick_active = game.tick
    end
end)
