<img src="Images/plums_icon.png" alt="plums icon" width="150">
<h1>Plums</h1>

API: [wrello.github.io/Plums/](https://wrello.github.io/Plums/)

⚠️Currently in beta. Not recommended for use in production.⚠️

- Supports nested plums
- Includes server-side plum events
- Propagates value changed events from sub-tables
- Supports `Event:Observe()` to collect prior values
- Uses [Squash](https://github.com/Data-Oriented-House/Squash/) to compress overhead plum data

<h2>Install</h2>

- Roblox model: https://create.roblox.com/store/asset/112997442485158
- Wally: `Plums = "wrello/plums@0.1.0"`
- Pesde: `Plums = { name = "wrello/plums", version = "^0.1.0" }`

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

<h2>Comparing With Replica</h2>
loleris's ReplicaService (now Replica) was the inspiration for this library, here are some comparisons with Replica...

<h3>Boilerplate</h3>

```lua
local replica = Replica.new({Token = Replica.Token("Replica"), Data = {
  Value = 0
}})
replica:Replicate()

-- becomes

local plum = Plums.new("Plum", {
  Value = 0
}):AddAllClients():EnableAutoAddClient()
```

```lua
replica.OnNew("Replica", function(replica)

end)
replica.RequestData()

-- becomes

Plums.PlumReceived("Plum"):Observe(function(plum)
  
end)
```
<h3>Speed</h3>

Replica resolves a single path in its table modification methods:
```lua
local pointer = self.Data
for i = 1, #path - 1 do
  pointer = pointer[path[i]]
end
pointer[path[#path]] = value
```
Plums performs additional path resolutions for:
- nested plums
- server-side event listeners
- propagation of value-change events through nested structures

This can cause table modification methods to be up to `~10×` slower depending on how complex the plum is. **This speed tradeoff should not be noticable in practice** (e.g. `10,000` table modification calls on a deeply nested plum with lots of event listeners takes `0.05` seconds).
<h3>Packet Size</h3>

Results with a small data table:

| Packet Type | Replica Size | Plum Size (compressed with Squash) |
| --- | --- | --- |
| Initial object send | 88 bytes | 82 bytes |
| Method replication | 63 bytes | 62 bytes |


