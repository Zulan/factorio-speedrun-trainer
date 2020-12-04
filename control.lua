local util = require("util") -- from data\core\lualib\
local gui = require("gui")
local DataFrame = require("utils.DataFrame")
local migrations = require("migrations")

function player_init(player)
    global.state[player.index] = {}
    global.history_grouping[player.index] = {}
    state_reset(global.state[player.index])
    gui.regen(player)
end

function init()
    global.state = {}
    global.history = DataFrame:new()
    global.history_grouping = {}

    gui.init()

    for _, player in pairs(game.players) do
        player_init(player)
    end

end

script.on_init(init)

script.on_load(function()
    DataFrame:refresh(global.history)
end)

script.on_configuration_changed(function(configuration_changed_data)
    local mod_data = configuration_changed_data.mod_changes['speedrun-trainer']
    if (mod_data == nil or mod_data.old_version == nil) then
        -- We don't care about vanilla saves, that's taken care by on_init
        return
    end

    local old_major_str, old_minor_str, old_patch_str =
        string.match(mod_data.old_version, "(%d+)%.(%d+)%.(%d+)")
    local old_version = {
        major = tonumber(old_major_str),
        minor = tonumber(old_minor_str),
        patch = tonumber(old_patch_str)
    }

    if old_version.major < 1 then
        migrations["1.0.0"]()
    end

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

script.on_event(defines.events.on_player_created, function(event)
    if not global.state[event.player_index] then
        player_init(game.get_player(event.player_index))
    end
end)

function history_collect(player)
    local state = global.state[player.index]

    entry = util.merge({
        {
            player = player.name,
            time = (state.tick_active - state.tick_start) / 60,
            entities = table_size(state.entities),
            mistakes = state.mistakes
        },
        gui.input_properties(player)
    })

    global.history:append(entry)

    gui.render_history(player)
end

script.on_event(defines.events.on_gui_click, function(event)
    local clicked_element = event.element
    local state = global.state[event.player_index]
    local gui_elements = global.gui_elements[event.player_index]
    local history_grouping = global.history_grouping[event.player_index]
    local player = game.get_player(event.player_index)
    if clicked_element == gui_elements.button_start then
        state_reset(state)
        state.starting_position = player.position
        state.waiting_for_events = true
    elseif clicked_element == gui_elements.button_cancel then
        state.running = false
    elseif clicked_element == gui_elements.button_stop then
        state.running = false
        history_collect(player)
    elseif clicked_element == gui_elements.button_reset then
        local inventory = player.get_main_inventory()
        for _, entity in pairs(state.entities) do
            if entity.valid then
                local items = entity.prototype.items_to_place_this
                if items then
                    for _, item in pairs(items) do
                        inventory.insert(item)
                    end
                end
                entity.destroy()
            end
        end
        player.teleport(state.starting_position)
        state_reset(state)
    elseif clicked_element == gui_elements.button_history then
        gui.toggle_history(player)
    elseif clicked_element == gui_elements.button_history_clear then
        global.history:clear()
        gui.render_history(player)
    else
        for property, checkbox in pairs(gui_elements.table_history_grouping) do
            if clicked_element == checkbox then
                if checkbox.state then
                    history_grouping[property.name] = property.name
                else
                    history_grouping[property.name] = nil
                end
                gui.render_history(player)
                break
            end
        end
    end
    gui.render_controls(player)
end)

script.on_event(defines.events.on_tick, function(event)
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
    -- Other mods may cause one of these events before our on_player_created is called, e.g. the crash site cutscene
    if not state then
        player_init(game.get_player(event.player_index))
        state = global.state[event.player_index]
    end

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
