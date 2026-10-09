Gridfinity.InventorySerivce = Gridfinity.InventorySerivce or {}

Gridfinity.Cache.InventorySerivce_InventoryInstances = Gridfinity.Cache.InventorySerivce_InventoryInstances or {}
Gridfinity.Cache.InventorySerivce_InventoryMetaTable = Gridfinity.Cache.InventorySerivce_InventoryMetaTable or {}

--- @type table<number, Gridfinity.InventorySerivce.Inventory>
local InventoryInstances = Gridfinity.Cache.InventorySerivce_InventoryInstances

--- @class Gridfinity.InventorySerivce.Inventory
--- @field ItemStacks table<number, Gridfinity.ItemStack.ItemStack>
--- @field Index number
local inventory_meta = Gridfinity.Cache.InventorySerivce_InventoryMetaTable
inventory_meta.__index = inventory_meta

function inventory_meta:GetItemStacks()
    return self.ItemStacks
end

--- @param item_stack Gridfinity.ItemStack.ItemStack
--- @param index? number Server-assigned index when applying a client update
--- @return number? index
function inventory_meta:AddItemStack(item_stack, index)
    if InventoryInstances[self.Index] ~= self then
        RiceLib.Error(Format("Inventory Instance #%s Collision, Preventing AddItemStack", self.Index), "Gridfinity")

        return
    end

    if not item_stack or item_stack.Inventory then return end
    if CLIENT and not index then return end

    local data = {}

    for key, value in pairs(item_stack) do
        if key ~= "ItemDefinition" and key ~= "UniqueID" and key ~= "Inventory" and key ~= "InventoryIndex" then
            data[key] = value
        end
    end

    index = index or 1

    if SERVER then
        while self.ItemStacks[index] do
            index = index + 1
        end
    end

    self.ItemStacks[index] = item_stack

    item_stack.Inventory = self
    item_stack.InventoryIndex = index

    if SERVER then
        RiceLib.Protobuf.Send("Gridfinity.Inventory.AddItemStack", {
            InventoryIndex = self.Index,
            ItemStackIndex = index,

            ItemID = item_stack.ItemDefinition.ID,
            UniqueID = item_stack.UniqueID,
            Data = util.TableToJSON(data)
        })
    end

    return index
end

--- @param index number
--- @return Gridfinity.ItemStack.ItemStack? item_stack
function inventory_meta:RemoveItemStack(index)
    local item_stack = self.ItemStacks[index]
    if not item_stack then return end

    self.ItemStacks[index] = nil
    item_stack.Inventory = nil
    item_stack.InventoryIndex = nil

    if SERVER then
        RiceLib.Protobuf.Send("Gridfinity.Inventory.RemoveItemStack", {
            InventoryIndex = self.Index,
            ItemStackIndex = index
        })
    end

    return item_stack
end

--- @param index number
--- @param key string
--- @param value number|string|table|boolean|nil
--- @param data_length? number When sending a binary/json data, the data length for compression
function inventory_meta:SetItemStackData(index, key, value, data_length)
    local item_stack = self.ItemStacks[index]
    if not item_stack then return end

    item_stack:SetData(key, value, true)

    if CLIENT then return end

    if istable(value) then
        value = util.TableToJSON(value)
        data_length = #value

        value = util.Compress(value)
    end

    RiceLib.Protobuf.Send("Gridfinity.Inventory.SetItemStackData", {
        InventoryIndex = self.Index,
        ItemStackIndex = index,
        Key = key,
        
        Number = (isnumber(value) and value) or nil,
        String = (isstring(value) and value) or nil,
        Boolean = (isbool(value) and value) or nil,

        DataLength = data_length
    })
end

--- @return Gridfinity.InventorySerivce.Inventory
function Gridfinity.InventorySerivce.CreateInventory(inventory_index)
    if CLIENT and not inventory_index then
        RiceLib.Error("Faild to create inventory with nil inventory_index", "Gridfinity")

        return
    end

    if SERVER then
        if inventory_index then
            RiceLib.Error("You should not assign a inventory_index manually on SERVER", "Gridfinity")

            return
        end

        inventory_index = 1

        while InventoryInstances[inventory_index] do
            inventory_index = inventory_index + 1
        end
    end

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
    local inventory = InventoryInstances[inventory_index]
    if not inventory then return end

    for index, item_stack in pairs(inventory.ItemStacks) do
        item_stack.Inventory = nil
        item_stack.InventoryIndex = nil

        inventory.ItemStacks[index] = nil
    end

    InventoryInstances[inventory_index] = nil

    if CLIENT then return end

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

    RiceLib.Protobuf.Receive("Gridfinity.Inventory.AddItemStack", function(message)
        local inventory = InventoryInstances[message.InventoryIndex]
        if not inventory then return end

        local data = util.JSONToTable(message.Data)
        if not data then return end

        local item_stack = Gridfinity.ItemStack.Create(message.ItemID, data, message.UniqueID)
        if not item_stack then return end

        inventory:AddItemStack(item_stack, message.ItemStackIndex)
    end)

    RiceLib.Protobuf.Receive("Gridfinity.Inventory.RemoveItemStack", function(message)
        local inventory = InventoryInstances[message.InventoryIndex]
        if not inventory then return end

        inventory:RemoveItemStack(message.ItemStackIndex)
    end)

    RiceLib.Protobuf.Receive("Gridfinity.Inventory.SetItemStackData", function(message)
        --- @type Gridfinity.InventorySerivce.Inventory
        local inventory = InventoryInstances[message.InventoryIndex]

        if not inventory then return end

        local value = message.Number or message.String or message.Boolean

        if message.DataLength > 0 then
            value = util.Decompress(value, message.DataLength)
            if not value then return end

            value = util.JSONToTable(value)
        end

        inventory:SetItemStackData(message.ItemStackIndex, message.Key, value)
    end)
end
