Gridfinity.ItemDefinition = Gridfinity.ItemDefinition or {}
Gridfinity.Cache.ItemDefinitionTable = Gridfinity.Cache.ItemDefinitionTable or {}
Gridfinity.Cache.ItemDefinitionBaseClass = Gridfinity.Cache.ItemDefinitionBaseClass or {}

local ItemDefinitionTable = Gridfinity.Cache.ItemDefinitionTable
local ItemBaseClass = Gridfinity.Cache.ItemDefinitionBaseClass

--- @class Gridfinity.ItemDefinition.RegisterData
local item_base_values = {
    DisplayName = "Unknown Item",
    Description = "Unknown Item Description",
}

--- @class Gridfinity.ItemDefinition.ItemClass : Gridfinity.ItemDefinition.RegisterData
local item_baseclass = {}
item_baseclass.__index = item_baseclass

function item_baseclass:GetDisplayName(item_stack)
    return item_stack.DisplayName
end

function item_baseclass:GetDescription(item_stack)
    return item_stack.Description
end

--- @param item_id string
--- @param item_data Gridfinity.ItemDefinition.RegisterData
--- @param base_values? Gridfinity.ItemDefinition.RegisterData
--- @param baseclass? Gridfinity.ItemDefinition.ItemClass
--- @return Gridfinity.ItemDefinition.ItemClass
function Gridfinity.ItemDefinition.RegisterItem(item_id, item_data, base_values, baseclass)
    local item = RiceLib.Table.InheritCopy(item_data, base_values or item_base_values)

    item.ID = item_id

    setmetatable(item, item_baseclass) --- @cast item Gridfinity.ItemDefinition.ItemClass

    ItemDefinitionTable[item_id] = item

    return item
end

function Gridfinity.ItemDefinition.GetItem(item_id)
    return ItemDefinitionTable[item_id]
end
