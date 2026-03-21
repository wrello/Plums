<img src="Images/plums_icon.png" alt="plums icon" width="150">
<h1>Plums</h1>

API: [wrello.github.io/Plums/](https://wrello.github.io/Plums/)

⚠️Currently in beta. Not recommended for use in production.⚠️

<h2>Why Plums Exists</h2>

I made Plums because ReplicaService was no longer being maintained and was missing built-in server-side events that mirrored the client-side ones. loleris has since released [Replica](https://github.com/MadStudioRoblox/Replica) which is greatly improved, but I never stopped working on my ReplicaService-inspired version. Plums offers a Replica-like API with some additional features:
- server-side events
- nested replicated objects in data tables
- serialized data to decrease packet size
- internal handling of non-ready clients on replication
- propogated ValueChanged events to nested listeners 
  - e.g. if we `listen(path.to.value)` then `set(path.to, {value = 1})` should fire the listener

###### You also get to name your replicated objects "somethingPlum" which is not only fun, but helps distinguish them from other Replica... nomenclature.

<h2>Install</h2>

Roblox model: https://create.roblox.com/store/asset/112997442485158 <br>
Wally: `Plums = "wrello/plums@0.2.1"` <br>
Pesde: `Plums = { name = "wrello/plums", version = "^0.2.1" }`

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
}):AddClient(player)

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

<h3>Boilerplate</h3>

Creating a plum and replicating it to specific players:
```lua
-- Replica
local replica = Replica.New({Token = Replica.Token("Replica"), Data = {
  Value = 0
}})

while not table.find(replica.ReadyPlayers, player) do
  replica.NewReadyPlayer:Wait()
end

replica:Subscribe(player)
```
```lua
-- Plum
local plum = Plums.new("Plum", {
  Value = 0
}):AddClients(player)
```
Creating a plum and replicating it to all players:
```lua
-- Replica
local replica = Replica.New({Token = Replica.Token("Replica"), Data = {
  Value = 0
}})
replica:Replicate()
```
```lua
-- Plum
local plum = Plums.new("Plum", {
  Value = 0
}):AddAllClients():EnableAutoAddClient()
```
Listening for a new plum and updating a text label's value:
```lua
-- Replica
Replica.RequestData()

Replica.OnNew("Player", function(playerReplica)
  local function updateCoinsText(newCoins)
    textLabel.Text = newCoins .. " Coins"
  end
  
  updateCoinsText(playerReplica.Data.Coins) -- Run once on load
  playerReplica:OnSet({"Coins"}, updateCoinsText)
end)
```
```lua
-- Plum
Plums:Init()

Plums.PlumReceived("Player"):Observe(function(playerPlum)
  local function updateCoinsText(newCoins)
    textLabel.Text = newCoins .. " Coins"
  end

  playerPlum.ValueChanged({"Coins"}):Observe(updateCoinsText) -- ':Observe()' runs once on load automatically
end)
```
<h3>Packet Size</h3>

Packet sizes of initial replication of each object using the data table below:
- Replica: 1949 bytes (no serialization)
- Plum: **1024 bytes** (auto-serialization using BufferEncoder)

<details>
  <summary>
    Data (real player data from 
    <a href="https://www.roblox.com/games/17618988439/Pro-Junk-Hauler">
      Pro Junk Hauler
    </a>)
  </summary>

```lua
local data = {
  Tycoon = {
    BuiltItems = {
      "Parking Cover",
      "VehicleSpawner - Wagon",
      "Gloves Seller",
      "Hammer Seller",
      "Worker Bunker",
      "Bunker Lights",
      "Worker - 1",
      "VehicleSpawner - Bike",
      "Asphalt",
      "Grass"
    },
    SignText = "",
    PurchasedItemInfo = {
      Grass = { BuildProgress = 20, MaxBuildProgress = 20 },
      ["Parking Cover"] = { BuildProgress = 5, MaxBuildProgress = 5 },
      ["Worker - 1"] = { BuildProgress = 15, MaxBuildProgress = 15 },
      ["Bunker Lights"] = { BuildProgress = 15, MaxBuildProgress = 15 },
      ["Worker - 2"] = { BuildProgress = 4, MaxBuildProgress = 25 },
      ["Hammer Seller"] = { BuildProgress = 10, MaxBuildProgress = 10 },
      ["VehicleSpawner - Bike"] = { BuildProgress = 15, MaxBuildProgress = 15 },
      ["Worker Bunker"] = { BuildProgress = 10, MaxBuildProgress = 10 },
      ["Gloves Seller"] = { BuildProgress = 5, MaxBuildProgress = 5 },
      Asphalt = { BuildProgress = 20, MaxBuildProgress = 20 },
      ["VehicleSpawner - Wagon"] = { BuildProgress = 5, MaxBuildProgress = 5 }
    },
    PurchasedItems = {
      "Parking Cover",
      "VehicleSpawner - Wagon",
      "Gloves Seller",
      "Hammer Seller",
      "Worker Bunker",
      "Bunker Lights",
      "Worker - 1",
      "VehicleSpawner - Bike",
      "Asphalt",
      "Grass",
      "Worker - 2"
    },
    PurchasedWorkers = {
      Worker_1 = {
        SleepTime = 30
      }
    }
  },
  EnabledGamePasses = {},
  JunkSoldCount = 23,
  NumSold = {
    Sofa = 0,
    Tank = 0,
    ["Big Trash"] = 0,
    AWP = 0,
    Piano = 0,
    Matress = 0,
    Fridge = 0,
    Safe = 0,
    Boots = 7,
    Papers = 13,
    ["Gaming PC"] = 0,
    Plant = 3,
    ["Dead Body"] = 0,
    Motorcycle = 0,
    Boat = 0,
    Toilet = 0,
    Sarcophagus = 0,
    ["Grandfather Clock"] = 0
  },
  EquippedBadges = {},
  OwnedBadges = {},
  Money = 500,
  UnlockedTitles = {},
  EquippedGloves = "Common",
  CompletedTutorial = true,
  Storage = {
    Tycoon = {
      BuiltItems = {},
      PurchasedItems = {},
      PurchasedItemInfo = {}
    }
  },
  Settings = {
    ["Background Music"] = {
      On = true
    }
  },
  Notifs = {
    NewTitle = 0
  },
  EquippedHammer = "WoodHammer",
  SentNotifications = {},
  Scraps = 2,
  ClosedUpdateLog = "Update 3!"
}
```
</details>

*Data serialization is possible thanks to [BufferEncoder](https://devforum.roblox.com/t/bufferencoder-very-efficient-table-to-buffer-serializer-that-doesn%E2%80%99t-use-schemas/3584699/32), [Squash](https://github.com/Data-Oriented-House/Squash/) (for overhead plum data), and [PacketSizeCounter](https://github.com/Pyseph/RemotePacketSizeCounter) (to determine if auto-serialization is advantageous for a given table).*

<h3>Speed</h3>

Replica resolves a single path in its table modification methods:
```lua
local pointer = self.Data
for i = 1, #path - 1 do
  pointer = pointer[path[i]]
end
pointer[path[#path]] = value
```
Plums does this and also fires server-side events for all ancestor/descendant plums listening for changes at that path. There is also a significant amount of recursion necessary for propogating ValueChanged events to nested listeners on each plum. This can cause table modification methods to be up to `~10×` slower depending on how complex the plum is. **This speed tradeoff should not be noticable in practice** (e.g. `10,000` table modification calls on a deeply nested plum with lots of event listeners takes `0.05` seconds).
