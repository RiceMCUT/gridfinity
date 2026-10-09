Gridfinity.ItemStack = Gridfinity.ItemStack or {}

local inheritCopy = RiceLib.Table.InheritCopy
local uniqueID = RiceLib.Util.UniqueID

--- @class Gridfinity.ItemStack.ItemStackValues
local item_stack_base_values = {
    Count = 0,
}

--- @class Gridfinity.ItemStack.ItemStack : Gridfinity.ItemStack.ItemStackValues
--- @field ItemDefinition Gridfinity.ItemDefinition.ItemClass
--- @field UniqueID string
--- @field Inventory Gridfinity.InventorySerivce.Inventory
local item_stack_meta = {}
item_stack_meta.__index = item_stack_meta

function item_stack_meta:GetDisplayName()
    return self.ItemDefinition:GetDisplayName(self)
end

function item_stack_meta:GetDescription()
    return self.ItemDefinition:GetDescription(self)
end

function item_stack_meta:SetData(key, value, no_network)
    self[key] = value

    if CLIENT then return end
    if no_network then return end
    if not self.Inventory then return end

    local data_length

    if istable(value) then
        value = util.Compress(util.TableToJSON(value))

        data_length = #value
    end

    self.Inventory:SetItemStackData(self.InventoryIndex, key, value, data_length)
end

function item_stack_meta:GetData(key)
    return self[key]
end

--- @return Gridfinity.ItemStack.ItemStack?
function Gridfinity.ItemStack.Create(item_id, data, unique_id)
    local item = Gridfinity.ItemDefinition.GetItem(item_id)
    if not item then return end

    unique_id = unique_id or uniqueID()

    local item_stack = inheritCopy(data or {}, item_stack_base_values)
    item_stack.UniqueID = unique_id
    item_stack.ItemDefinition = item

    setmetatable(item_stack, item_stack_meta) --- @cast item_stack Gridfinity.ItemStack.ItemStack

    return item_stack
end
