Gridfinity.InventorySerivce = Gridfinity.InventorySerivce or {}

Gridfinity.Cache.InventorySerivce_InventoryInstances = Gridfinity.Cache.InventorySerivce_InventoryInstances or {}

local InventoryInstances = Gridfinity.Cache.InventorySerivce_InventoryInstances

--- @class Gridfinity.InventorySerivce.Inventory
--- @field ItemStacks table[Gridfinity.ItemStack.ItemStack]
--- @field Index number
local inventory_meta = {}
inventory_meta.__index = inventory_meta

function inventory_meta:GetItemStacks()
    return self.ItemStacks
end

--- @param index number
--- @param key string
--- @param value number|string
--- @param data_length? number When sending a binary/json data, the data length for compression
function inventory_meta:SetItemStackData(index, key, value, data_length)
    if CLIENT then
        self.ItemStacks[index]:SetData(key, value)

        return
    end

    self.ItemStacks[index]:SetData(key, value)

    RiceLib.Protobuf.Send("Gridfinity.Inventory.SetItemStackData", {
        InventoryIndex = self.Index,
        ItemStackIndex = index,
        Key = key,
        
        Number = (isnumber(value) and value) or nil,
        String = (isstring(value) and value) or nil,

        DataLength = data_length
    })
end

--- @return Gridfinity.InventorySerivce.Inventory?
function Gridfinity.InventorySerivce.CreateInventory(inventory_index)
    if CLIENT and not inventory_index then return end

    inventory_index = inventory_index or #InventoryInstances + 1

    local inventory_instance = {}
    inventory_instance.ItemStacks = {}
    inventory_instance.Index = inventory_index

    setmetatable(inventory_instance, inventory_meta) --- @cast inventory_instance Gridfinity.InventorySerivce.Inventory

    InventoryInstances[inventory_index] = inventory_instance

    if CLIENT then return inventory_instance end

    RiceLib.Protobuf.Send("Gridfinity.Inventory.CreateAndRemove", {
        Index = inventory_index
    })

    return inventory_instance
end

function Gridfinity.InventorySerivce.RemoveInventory(inventory_index)
    table.remove(InventoryInstances, inventory_index)

    if CLIENT then end

    RiceLib.Protobuf.Send("Gridfinity.Inventory.CreateAndRemove", {
        Index = inventory_index,
        IsRemove = true
    })
end

function Gridfinity.InventorySerivce.GetAllInstances()
    return InventoryInstances
end

if CLIENT then
    RiceLib.Protobuf.Receive("Gridfinity.Inventory.CreateAndRemove", function(message)
        if message.IsRemove then
            Gridfinity.InventorySerivce.RemoveInventory(message.Index)

            return
        end

        Gridfinity.InventorySerivce.CreateInventory(message.Index)
    end)

    RiceLib.Protobuf.Receive("Gridfinity.Inventory.SetItemStackData", function(message)
        --- @type Gridfinity.InventorySerivce.Inventory
        local inventory = InventoryInstances[message.InventoryIndex]

        if not inventory then return end

        local value = message.Number or message.String

        if message.DataLength then
            value = util.Decompress(value, message.DataLength)
        end

        inventory:SetItemStackData(message.ItemStackIndex, message.Key, value)
    end)
end
