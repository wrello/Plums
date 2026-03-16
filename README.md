<img src="Images/plums_icon.png" alt="plums icon" width="150">
<h1>Plums</h1>

API: [wrello.github.io/Plums/](https://wrello.github.io/Plums/)

⚠️Currently in beta. Not recommended for use in production.⚠️

- Supports nested plums
- Includes server-side plum events
- Propogates value changed events from sub-tables
- Supports `Event:Observe()` to collect prior values
- Uses [Squash](https://github.com/Data-Oriented-House/Squash/) to compress overhead plum data

<h2>Quick Start</h2>

Initialize server & client first:
```lua
-- Server
local Plums = require(game.ReplicatedStorage.Plums.PlumsServer)
Plums:Init()
```
```lua
-- Client
local Plums = require(game.ReplicatedStorage.Plums.PlumsClient)
Plums:Init()
```

Then create a plum:
```lua
-- Server
local playerPlum = Plums.new("Player", {
  Coins = 0
}):AddAllClients():EnableAutoAddClient()

playerPlum:SetValue({"Coins"}, 5)
```

And listen to its changes:
```lua
-- Client
Plums.PlumReceived("Player"):Observe(function(playerPlum)
  print("Player plum received:", playerPlum.Data)

  playerPlum.ValueChanged({"Coins"}):Observe(function(newVal, oldVal)
    print("Coins:", newVal)
  end)
end)
```

<h2>Comparing to Replica</h2>
loleris's original ReplicaService (now Replica) was the inspiration for this library, here's some comparisons...
<h3>Speed</h3>

The entirity of Replica's server-side compute time is taken up by the following path resolution algorithm:
```lua
local pointer = self.Data
for i = 1, #path - 1 do
  pointer = pointer[path[i]]
end
pointer[path[#path]] = value
```

Plums' server-side needs to do much more work to account for nested plums and server-side event listeners, which can make table modification calls up to 10x slower than that algorithm.
<h3>Packet Size</h3>

Results with a small table:

| Packet Type | Replica Size | Plum Size (compressed) |
| --- | --- | --- |
| Instantiation | 88 bytes | 82 bytes |
| Method | 63 bytes | 62 bytes |


