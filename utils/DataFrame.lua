local DataFrame = {}
-- DataFrame.__index = DataFrame

function DataFrame:new()
    self.__index = self
    return setmetatable({data = {}}, self)
end

function DataFrame:refresh(o)
    setmetatable(o, self)
end

function DataFrame:append(kwargs)
    table.insert(self.data, kwargs)
end

function DataFrame:sum(field)
    local sum = 0
    for _, v in pairs(self.data) do
        sum = sum + v[field]
    end
    return sum
end

function DataFrame:mean(field)
    return self:sum(field) / self:count(field)
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
