RiceLib.Protobuf.Define("Gridfinity.Inventory.CreateAndRemove", {
    {1, "Index", "int32"},
    {2, "IsRemove", "bool"}
})

RiceLib.Protobuf.Define("Gridfinity.Inventory.SetItemStackData", {
    {1, "InventoryIndex", "int32"},
    {2, "ItemStackIndex", "int32"},
    {3, "Key", "string"},

    {Oneof = "Value",
        {4, "Number", "float"},
        {5, "String", "string"},
        {7, "Boolean", "bool"}
    },

    {6, "DataLength", "uint32"},
    {8, "IsTable", "bool"}
})

RiceLib.Protobuf.Define("Gridfinity.Inventory.AddItemStack", {
    {1, "InventoryIndex", "int32"},
    {2, "ItemStackIndex", "int32"},
    {3, "ItemID", "string"},
    {4, "Data", "string"}
})

RiceLib.Protobuf.Define("Gridfinity.Inventory.RemoveItemStack", {
    {1, "InventoryIndex", "int32"},
    {2, "ItemStackIndex", "int32"}
})
