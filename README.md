<img src="plums_icon.png" alt="plums icon" width="150">
<h1>Plums</h1>

⚠️Currently in beta. Not recommended for use in production.⚠️

__Replicates table changes from server to client:__

Server:
```lua
local playerPlum = Plums.new("Player", {
  Coins = 0
}):AddAllClients():EnableAutoAddClient()

playerPlum:SetValue({"Coins"}, 5)
```

Client:
```lua
Plums.PlumReceived("Player"):Observe(function(playerPlum)
  print("Player plum received:", playerPlum.Data)

  playerPlum.ValueChanged({"Coins"}):Observe(function(newVal, oldVal)
    print("Coins:", newVal)
  end)
end)
```

__Supports nested plums:__

Server:
```lua
local nestedPlum = Plums.new("Nested", {
  NestedValue = 5
})
local playerPlum = Plums.new("Player", {
  NestedPlum = nestedPlum
}):AddAllClients():EnableAutoAddClient()

playerPlum:SetValue({"NestedPlum", "NestedValue"}, 5)
```

Client:
```lua
Plums.PlumReceived("Player"):Observe(function(playerPlum)
  print("Player plum received:", playerPlum.Data)

  playerPlum.ValueChanged({"NestedPlum", "NestedValue"}):Observe(function(newVal, oldVal)
    print("NestedValue:", newVal)
  end)
end)
```

__Includes server side events:__

Server:
```lua
local plum = Plums.new("Plum")

plum.ValueChanged({"TestValue"}):Connect(function(newVal, oldVal)
  print("TestValue changed:", newVal)
end)

plum:SetValue({"TestValue"})
```

__Replicated client addition and removal:__

Server:
```lua
local partyPlum = Plums.new("Party"):AddAllClients():EnableAutoAddClients()
```

Client:
```lua
Plum.PlumReceived("Party"):Observe(function(partyPlum)
  print("Party plum received:", partyPlum.Data)

  partyPlum.ClientAdded:Observe(function(client)
    print("Client added:", client)
  end)

  partyPlum.ClientRemoved:Connect(function(client)
    print("Client removed:", client)
  end)
end)
```

__Cascaded value changed events in sub-tables:__

Server:
```lua
local plum = Plums.new("Plum", {
  Items = {"ItemA", "ItemB", "ItemC"}
})

plum.ValueChanged({"Items", 1}):Connect(function(newVal, oldVal)
  print("Items[1] changed:", newVal)
end)

plum:SetValue({"Items"}, nil)
```

Inspired by loleris's ReplicaService.
