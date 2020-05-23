local mod_gui = require("mod-gui")

function gui_create(player)
    -- TODO regenerate gui
    global.gui[player.index] = {}
    local gui = global.gui[player.index]
    local frame_flow = mod_gui.get_frame_flow(player)

    local frame_control = frame_flow.add {
        type = "frame",
        direction = "vertical",
        caption = "Training History"
    }

    gui.label_status = frame_control.add {type = "label", caption = ""}

    local table_info = frame_control.add {type = "table", column_count = 2}

    width = 160

    table_info.add {type = "label", caption = "Task"}
    gui.input_task = table_info.add {type = "textfield", text = "default task"}
    gui.input_task.style.width = width

    table_info.add {type = "label", caption = "Method"}
    gui.input_method = table_info.add {
        type = "textfield",
        text = "default method"
    }
    gui.input_method.style.width = width

    table_info.add {type = "label", caption = "Entities"}
    gui.label_entities = table_info.add {
        type = "label",
        style = "caption_label"
    }
    gui.label_entities.style.horizontal_align = "right"
    gui.label_entities.style.width = width

    table_info.add {type = "label", caption = "Mistakes"}
    gui.label_mistakes = table_info.add {
        type = "label",
        style = "caption_label"
    }
    gui.label_mistakes.style.horizontal_align = "right"
    gui.label_mistakes.style.width = width

    table_info.add {type = "label", caption = "Time"}
    gui.label_time = table_info.add {
        type = "label",
        style = "large_caption_label"
    }
    gui.label_time.style.horizontal_align = "right"
    gui.label_time.style.width = width

    flow_buttons = frame_control.add {type = "flow", direction = "horizontal"}

    button_width = 70
    gui.button_history = flow_buttons.add {type = "button", caption = "history"}
    gui.button_history.style.width = button_width
    gui.button_start = flow_buttons.add {type = "button", caption = "start"}
    gui.button_start.style.width = button_width
    gui.button_cancel = flow_buttons.add {type = "button", caption = "cancel"}
    gui.button_cancel.style.width = button_width
    gui.button_stop = flow_buttons.add {type = "button", caption = "stop"}
    gui.button_stop.style.width = button_width
    gui.button_reset = flow_buttons.add {type = "button", caption = "reset"}
    gui.button_reset.style.width = button_width

    gui_control_update(player)

    -- History gui

    gui.frame_history = player.gui.screen.add {
        type = "frame",
        direction = "vertical",
        visible = "false",
        caption = "Training History"
    }
    gui.pane_history = gui.frame_history.add {type = "scroll-pane"}
    gui.pane_history.style.maximal_height = 800

    local gui_flow_history_controls = gui.frame_history.add {
        type = "flow",
        direction = "horizontal"
    }
    gui.button_history_clear = gui_flow_history_controls.add {
        type = "button",
        caption = "clear"
    }

    gui_history_update(player)
    gui.frame_history.force_auto_center()
end

function show_time(label, ticks)
    label.caption = string.format("%.1f", ticks / 60.0)
end

function gui_control_update(player)
    local gui = global.gui[player.index]
    local state = global.state[player.index]
    if state.running then
        show_time(gui.label_time, game.tick - state.tick_start)
    else
        show_time(gui.label_time, state.tick_active - state.tick_start)
    end
    gui.label_mistakes.caption = string.format("%d", state.mistakes)
    gui.label_entities.caption = string.format("%d", table_size(state.entities))

    if state.waiting_for_events then
        gui.button_start.visible = false
        gui.button_stop.visible = false
        gui.button_cancel.visible = true
        gui.button_reset.visible = false
        gui.label_status.caption = "waiting for events"
    elseif state.running then
        gui.button_start.visible = false
        gui.button_cancel.visible = true
        gui.button_stop.visible = true
        gui.button_reset.visible = false
        gui.label_status.caption = "GO!"
    elseif table_size(state.entities) > 0 then
        gui.button_start.visible = false
        gui.button_cancel.visible = false
        gui.button_stop.visible = false
        gui.button_reset.visible = true
        gui.label_status.caption = string.format("placed %d entities",
                                                 table_size(state.entities))
    else
        gui.button_start.visible = true
        gui.button_cancel.visible = false
        gui.button_stop.visible = false
        gui.button_reset.visible = false
        gui.label_status.caption = "ready"
    end
end

function gui_history_update(player)
    local gui = global.gui[player.index]
    if gui.table_history then
        gui.table_history.destroy()
    end
    gui.table_history = gui.pane_history.add {
        type = "table",
        column_count = #history_properties,
        style = "bordered_table"
    }
    for _, property in pairs(history_properties) do
        gui.table_history.add {
            type = "label",
            caption = property,
            style = "caption_label"
        }
    end
    for _, entry in pairs(global.history) do
        for _, property in pairs(history_properties) do
            local caption = entry[property]
            if property == "time" then
                caption = string.format("%.1f", caption)
            end
            gui.table_history.add {type = "label", caption = caption}
        end
    end
end

function player_init(player)
    global.state[player.index] = {}
    state_reset(global.state[player.index])
    gui_create(player)
end

script.on_init(function()
    global.gui = {}
    global.state = {}
    global.history = {}
    for _, player in pairs(game.players) do
        player_init(player)
    end
end)

function state_reset(state)
    state.waiting_for_events = false
    state.running = false
    state.tick_start = 0
    state.tick_active = 0
    state.mistakes = 0
    state.entities = {}
    state.entity_count = 0
    state.starting_position = nil
end

history_properties = {
    "player",
    "task",
    "method",
    "entities",
    "mistakes",
    "time"
}

function history_collect(player)
    local state = global.state[player.index]
    local gui = global.gui[player.index]

    entry = {
        player = player.name,
        task = gui.input_task.text,
        method = gui.input_method.text,
        time = (state.tick_active - state.tick_start) / 60,
        entities = table_size(state.entities),
        mistakes = state.mistakes
    }
    table.insert(global.history, entry)
    gui_history_update(player)
end

script.on_event(defines.events.on_player_created, function(event)
    player_init(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_gui_click, function(event)
    local clicked_element = event.element
    local state = global.state[event.player_index]
    local gui = global.gui[event.player_index]
    local player = game.get_player(event.player_index)
    if clicked_element == gui.button_start then
        state_reset(state)
        state.starting_position = player.position
        state.waiting_for_events = true
    elseif clicked_element == gui.button_cancel then
        state.running = false
    elseif clicked_element == gui.button_stop then
        state.running = false
        history_collect(player)
    elseif clicked_element == gui.button_reset then
        local inventory = player.get_main_inventory()
        for _, entity in pairs(state.entities) do
            if entity.valid then
                inventory.insert({name = entity.name})
                entity.destroy()
            end
        end
        player.teleport(state.starting_position)
        state_reset(state)
    elseif clicked_element == gui.button_history then
        gui.frame_history.visible = not gui.frame_history.visible
    elseif clicked_element == gui.button_history_clear then
        global.history = {}
        gui_history_update(player)
    end
    gui_control_update(player)
end)

script.on_nth_tick(1, function(event)
    for _, player in pairs(game.players) do
        gui_control_update(player)
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
    local player = game.get_player(event.player_index)

    if state.waiting_for_events then
        gui.label_status.caption = "GO!"
        state.waiting_for_events = false
        state.running = true
        state.tick_start = game.tick
    end

    -- NOT elseif! First entity placed does count!
    if state.running then
        state.tick_active = game.tick
        if event.name == defines.events.on_player_mined_entity then
            local entity = event.entity
            if state.entities[entity.unit_number] then
                state.mistakes = state.mistakes + 1
                state.entities[entity.unit_number] = nil
                state.entity_count = state.entity_count - 1
            end
        elseif event.name == defines.events.on_built_entity then
            local entity = event.created_entity
            state.entities[entity.unit_number] = entity
            state.entity_count = state.entity_count + 1
        end
    end
end)
