local mod_gui = require("mod-gui")
local history_properties = require("history-properties")

-- Helpers
function show_time(label, ticks)
    label.caption = string.format("%.1f", ticks / 60.0)
end

-- gui module
local gui = {}

gui.kill = function(player)
    if global.gui_frames and global.gui_frames[player.index] then
        for _, frame in pairs(global.gui_frames[player.index]) do
            frame.destroy()
        end
    end
    global.gui_frames = global.gui_frames or {}
    global.gui_frames[player.index] = global.gui_frames[player.index] or {}
    global.gui_frames[player.index] = {}
    global.gui_elements = global.gui_elements or {}
    global.gui_elements[player.index] = global.gui_elements[player.index] or {}
    global.gui_elements[player.index] = {}
end

gui.init = function()
    global.gui_elements = {}
    global.gui_frames = {}
end

gui.regen = function(player)
    gui.kill(player)

    local gui_frames = global.gui_frames[player.index]
    local gui_elements = global.gui_elements[player.index]
    local frame_flow = mod_gui.get_frame_flow(player)

    gui_frames.control = frame_flow.add {
        name = "srt-control-frame",
        type = "frame",
        direction = "vertical",
        caption = "Speedrun Trainer"
    }

    gui_elements.label_status = gui_frames.control.add {
        type = "label",
        caption = ""
    }

    local table_info = gui_frames.control.add {type = "table", column_count = 2}

    width = 160

    table_info.add {type = "label", caption = "Task"}
    gui_elements.input_task = table_info.add {
        type = "textfield",
        text = "default task"
    }
    gui_elements.input_task.style.width = width

    table_info.add {type = "label", caption = "Method"}
    gui_elements.input_method = table_info.add {
        type = "textfield",
        text = "default method"
    }
    gui_elements.input_method.style.width = width

    table_info.add {type = "label", caption = "Entities"}
    gui_elements.label_entities = table_info.add {
        type = "label",
        style = "caption_label"
    }
    gui_elements.label_entities.style.horizontal_align = "right"
    gui_elements.label_entities.style.width = width

    table_info.add {type = "label", caption = "Mistakes"}
    gui_elements.label_mistakes = table_info.add {
        type = "label",
        style = "caption_label"
    }
    gui_elements.label_mistakes.style.horizontal_align = "right"
    gui_elements.label_mistakes.style.width = width

    table_info.add {type = "label", caption = "Time"}
    gui_elements.label_time = table_info.add {
        type = "label",
        style = "caption_label"
    }
    gui_elements.label_time.style.horizontal_align = "right"
    gui_elements.label_time.style.width = width

    flow_buttons = gui_frames.control.add {
        type = "flow",
        direction = "horizontal"
    }

    button_width = 70
    gui_elements.button_history = flow_buttons.add {
        type = "button",
        caption = "history"
    }
    gui_elements.button_history.style.width = button_width
    gui_elements.button_start = flow_buttons.add {
        type = "button",
        caption = "start"
    }
    gui_elements.button_start.style.width = button_width
    gui_elements.button_cancel = flow_buttons.add {
        type = "button",
        caption = "cancel"
    }
    gui_elements.button_cancel.style.width = button_width
    gui_elements.button_stop = flow_buttons.add {
        type = "button",
        caption = "stop"
    }
    gui_elements.button_stop.style.width = button_width
    gui_elements.button_reset = flow_buttons.add {
        type = "button",
        caption = "reset"
    }
    gui_elements.button_reset.style.width = button_width

    gui.render_controls(player)

    -- History gui
    gui_frames.history = player.gui.screen.add {
        type = "frame",
        direction = "vertical",
        visible = "false",
        caption = "Training History"
    }
    gui_elements.pane_history = gui_frames.history.add {type = "scroll-pane"}
    gui_elements.pane_history.style.maximal_height = 800

    local gui_flow_history_controls = gui_frames.history.add {
        type = "flow",
        direction = "horizontal"
    }
    gui_elements.button_history_clear = gui_flow_history_controls.add {
        type = "button",
        caption = "clear"
    }

    gui.render_history(player)
    gui_frames.history.force_auto_center()
end

gui.render_controls = function(player)
    local gui_elements = global.gui_elements[player.index]
    local state = global.state[player.index]

    if state.running then
        show_time(gui_elements.label_time, game.tick - state.tick_start)
    else
        show_time(gui_elements.label_time, state.tick_active - state.tick_start)
    end
    gui_elements.label_mistakes.caption = string.format("%d", state.mistakes)
    gui_elements.label_entities.caption =
        string.format("%d", table_size(state.entities))

    if state.waiting_for_events then
        gui_elements.button_start.visible = false
        gui_elements.button_stop.visible = false
        gui_elements.button_cancel.visible = true
        gui_elements.button_reset.visible = false
        gui_elements.label_status.caption = "waiting for events"
    elseif state.running then
        gui_elements.button_start.visible = false
        gui_elements.button_cancel.visible = true
        gui_elements.button_stop.visible = true
        gui_elements.button_reset.visible = false
        gui_elements.label_status.caption = "GO!"
    elseif table_size(state.entities) > 0 then
        gui_elements.button_start.visible = false
        gui_elements.button_cancel.visible = false
        gui_elements.button_stop.visible = false
        gui_elements.button_reset.visible = true
        gui_elements.label_status.caption =
            string.format("placed %d entities", table_size(state.entities))
    else
        gui_elements.button_start.visible = true
        gui_elements.button_cancel.visible = false
        gui_elements.button_stop.visible = false
        gui_elements.button_reset.visible = false
        gui_elements.label_status.caption = "ready"
    end
end

gui.render_history = function(player)
    local gui_elements = global.gui_elements[player.index]
    local history_grouping = global.history_grouping[player.index]

    if gui_elements.table_history then
        gui_elements.table_history.destroy()
    end
    gui_elements.table_history = gui_elements.pane_history.add {
        type = "table",
        column_count = #history_properties,
        style = "bordered_table"
    }
    gui_elements.table_history_grouping = {}
    for _, property in pairs(history_properties) do
        if property.groupable then
            gui_elements.table_history_grouping[property] =
                gui_elements.table_history.add {
                    type = "checkbox",
                    caption = property.name,
                    -- toboolean would be too hard to be in the standard library
                    state = (history_grouping[property.name] and true) or false
                }
        else
            gui_elements.table_history.add {
                type = "label",
                caption = property.name,
                style = "caption_label"
            }
        end
    end
    if table_size(history_grouping) == 0 then
        for _, entry in global.history:pairs() do
            for _, property in pairs(history_properties) do
                local caption = entry[property.name]
                if property.format ~= nil then
                    caption = property.format(caption)
                end
                gui_elements.table_history.add {
                    type = "label",
                    caption = caption
                }
            end
        end
    else
        for _, entry in pairs(global.history:group_by(history_grouping)) do
            for _, property in pairs(history_properties) do
                local caption = entry:summary(property.name, property.format)
                gui_elements.table_history.add {
                    type = "label",
                    caption = caption
                }
            end
        end
    end
end

gui.toggle_history = function(player)
    local gui_frames = global.gui_frames[player.index]
    gui_frames.history.visible = not gui_frames.history.visible
end

gui.input_properties = function(player)
    local gui_elements = global.gui_elements[player.index]
    return {
        task = gui_elements.input_task.text,
        method = gui_elements.input_method.text
    }
end

return gui
