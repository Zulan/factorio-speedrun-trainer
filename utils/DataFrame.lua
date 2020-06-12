local table_keys = require("utils.table_keys")
local DataFrame = {}
-- DataFrame.__index = DataFrame

function DataFrame:new()
    self.__index = self
    return setmetatable({data = {}}, self)
end

function DataFrame:refresh(o)
    setmetatable(o, self)
end

function DataFrame:clear()
    self.data = {}
end

function DataFrame:pairs()
    return pairs(self.data)
end

function DataFrame:append(kwargs)
    table.insert(self.data, kwargs)
end

function DataFrame:size()
    return table_size(self.data)
end

function DataFrame:sum(field)
    local sum = 0
    for _, v in pairs(self.data) do
        sum = sum + v[field]
    end
    return sum
end

function DataFrame:min(field)
    -- not even sticks and stones...
    local min = math.huge
    for _, v in pairs(self.data) do
        min = math.min(min, v[field])
    end
    return min
end

function DataFrame:max(field)
    local max = -math.huge
    for _, v in pairs(self.data) do
        max = math.max(max, v[field])
    end
    return max
end

function DataFrame:mean(field)
    return self:sum(field) / self:size()
end

function DataFrame:summary(field)
    if table_size(self.data) == 0 then
        return "{}"
    end
    if type(self.data[1][field]) == "string" then
        local counts = {}
        for _, row in pairs(self.data) do
            local v = row[field]
            counts[v] = (counts[v] or 0) + 1
        end
        local entries = {}
        for value, count in pairs(counts) do
            table.insert(entries, string.format("%s (%d)", value, count))
        end
        return table.concat(entries, ",")
    end
    -- Must be number
    return string.format("%.1f, %.1f, %.1f", self:min(field), self:mean(field),
                         self:max(field))
end

local DataFrameGroup = DataFrame:new()

function DataFrameGroup:new(tags)
    self.__index = self
    o = DataFrame:new()
    o["tags"] = tags
    return setmetatable(o, self)
end

function DataFrame:group_by(fields)
    local groups = {}
    for _, entry in pairs(self.data) do
        -- What an utterly ugly hack for the lack of a basic fucking tuple type
        local key = ""
        local tags = {}
        for _, field in pairs(fields) do
            key = key .. tostring(entry[field]) .. ";"
            tags[field] = entry[field]
        end
        groups[key] = groups[key] or DataFrameGroup:new(tags)
        groups[key]:append(entry)
    end
    return groups
end

return DataFrame
