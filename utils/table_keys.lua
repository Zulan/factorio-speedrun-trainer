-- Not even sticks and stones...
-- https://stackoverflow.com/questions/12674345/lua-retrieve-list-of-keys-in-a-table
local table_keys = function(tab)
    local keyset = {}
    local n = 0

    for k, v in pairs(tab) do
        n = n + 1
        keyset[n] = k
    end
end

return table_keys
