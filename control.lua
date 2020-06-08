local gui = require("gui")

-- Of course lua woudln't just have something nice like **python
function table_merge(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

function player_init(player)
    global.state[player.index] = {}
    state_reset(global.state[player.index])
    gui.regen(player)
end

script.on_init(function()
    gui.init()
    global.state = {}
    global.history = {}
    for _, player in pairs(game.players) do
        player_init(player)
    end
end)

script.on_configuration_changed(function(configuration_changed_data)
    for _, player in pairs(game.players) do
        gui.regen(player)
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

    entry = table_merge({
        player = player.name,
        time = (state.tick_active - state.tick_start) / 60,
        entities = table_size(state.entities),
        mistakes = state.mistakes
    }, gui.input_properties(player))
    table.insert(global.history, entry)
    gui.render_history(player)
end

script.on_event(defines.events.on_player_created, function(event)
    player_init(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_gui_click, function(event)
    gui.on_click(event)
end)

script.on_nth_tick(1, function(event)
    for _, player in pairs(game.players) do
        gui.render_controls(player)
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

    if state.waiting_for_events then
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
