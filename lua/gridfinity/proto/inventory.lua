RiceLib.Protobuf.Define("Gridfinity.Inventory.CreateAndRemove", {
    {1, "Index", "int32"},
    {2, "IsRemove", "bool"}
})

RiceLib.Protobuf.Define("Gridfinity.Inventory.SetItemStackData", {
    {1, "InventoryIndex", "int32"},
    {2, "ItemStackIndex", "int32"},
    {3, "Key", "string"},

    {Oneof = "Value",
        {4, "Number", "int32"},
        {5, "String", "string"}
    },

    {6, "DataLength", "uint32"}
})
