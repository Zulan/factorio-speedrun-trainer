local history_properties = {
    {name = "player", groupable = true},
    {name = "task", groupable = true},
    {name = "method", groupable = true},
    {name = "entities", groupable = false},
    {name = "mistakes", groupable = false},
    {
        name = "time",
        groupable = false,
        format = function(value)
            return string.format("%.1f", value)
        end
    }
}

return history_properties
