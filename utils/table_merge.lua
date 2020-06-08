-- Of course lua woudln't just have something nice like **python
local table_merge = function(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

return table_merge
