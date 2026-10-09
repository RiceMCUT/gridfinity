Gridfinity.ItemStack = Gridfinity.ItemStack or {}

Gridfinity.Cache.ItemStack_ItemStackMetaTable = Gridfinity.Cache.ItemStack_ItemStackMetaTable or {}

local inheritCopy = RiceLib.Table.InheritCopy

--- @class Gridfinity.ItemStack.ItemStackValues
local item_stack_base_values = {
    Count = 1,
}

--- @class Gridfinity.ItemStack.ItemStack : Gridfinity.ItemStack.ItemStackValues
--- @field ItemDefinition Gridfinity.ItemDefinition.ItemClass
--- @field Inventory Gridfinity.InventorySerivce.Inventory?
--- @field InventoryIndex number?
local item_stack_meta = Gridfinity.Cache.ItemStack_ItemStackMetaTable
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

    self.Inventory:SetItemStackData(self.InventoryIndex, key, value)
end

function item_stack_meta:GetData(key)
    return self[key]
end

--- @return Gridfinity.ItemStack.ItemStack
function Gridfinity.ItemStack.Create(item_id, data)
    local item = Gridfinity.ItemDefinition.GetItem(item_id)

    if not item then
        RiceLib.Error(Format("Item %s does not exists", item_id), "Gridfinity")

        return
    end

    local item_stack = inheritCopy(data or {}, item_stack_base_values)
    item_stack.ItemDefinition = item

    setmetatable(item_stack, item_stack_meta) --- @cast item_stack Gridfinity.ItemStack.ItemStack

    return item_stack
end
