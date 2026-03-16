--[[
comdoc "Client Plum" 3 LastUpdated

	[ Properties ]
	
		.Data : {}
		
			The data table of the plum.
		
		
		.Clients : {Player}
		
			The array of clients that have been added to the plum.
			
		
		.ClassName : string
		
			The class name that the plum was created with.
			
		
		.Id : number
		
			The unique id of the plum (e.g. 1, 2, 3, ...).
	
	
		.IsDestroyed : boolean?
		
			Will be true if 'plum:Destroy()' has been called.
	
	
	[ Methods ]
	
		:IsClient(player : Player) -> boolean
	
			Returns true if the 'player' is currently in the 'plum.Clients' array.
	
		
		:WaitFor(path : {string | number}) -> any?
		
			Yields until the value at 'path' is not nil and returns the value.
			
		
		:InvokeServer(...any?) -> ...any?
		
			Invokes the '.OnServerInvoke' callback function on the server with the provided args and returns what the callback returns.

	
	[ Events ]
		
		.ValueChanged(path : {string | number})
		
			:Observe() -- Collects current value at 'path' and listens for new changes to it
			:Connect() -- Listens for new changes to 'path'
			
			```lua
			Plums.PlumReceived("Player"):Observe(function(playerPlum)
				playerPlum.ValueChanged({"Money"}):Observe(function(newValue, oldValue)
					print("Money changed! New value:", newValue, "Old value:", oldValue)
				end)
			end)
			```
			
			
		.OnArrayInsert(path : {string | number})
		
			:Observe() -- Collects current values in the array at 'path' and listens for new inserts into it
			:Connect() -- Listens for new inserts into the array at 'path'
			
			```lua
			Plums.PlumReceived("Player"):Observe(function(playerPlum)
				playerPlum.OnArrayInsert({"Items"}):Observe(function(newValue, index)
					print("Item added! New value:", newValue, "Index:", index)
				end)
			end)
			```
			
			
		.OnArrayRemove(path : {string | number})
		
			:Connect() -- Listens for removals from the array at 'path'
			
			```lua
			Plums.PlumReceived("Player"):Observe(function(playerPlum)
				playerPlum.OnArrayRemove({"Items"}):Connect(function(oldValue, index)
					print("Item removed! Old value:", oldValue, "Index:", index)
				end)
			end)
			```
			
			
		.OnRaw
		
			:Connect() -- Listens to events from the server fired on ':SetValue()'/':ArrayInsert()'/':ArrayRemove()'
			
			```lua
			Plums.PlumReceived("Player"):Observe(function(playerPlum)
				playerPlum.OnRaw:Connect(function(methodName, path, ...)
					print("On raw! Method name:", methodName, "Path array:", path, "Args:", ...)
				end)
			end)
			```
		
		.OnBroadcast
		
			:Connect() -- Listens to events from the server fired on ':Broadcast()'/':BroadcastTo()'
		
			```lua
			Plums.PlumReceived("Player"):Observe(function(playerPlum)
				playerPlum.OnBroadcast:Connect(function(...)
					print("On broadcast! Args:", ...)
				end)
			end)
			```
			
			
		.ClientAdded
		
			:Observe() -- Collects the current clients in the 'plum.Clients' array and listens for new ones added
			:Connect() -- Listens for new clients added to the 'plum.Clients' array
			
		
		.ClientRemoved
		
			:Connect() -- Listens for a client removed from the 'plum.Clients' array
			
			
		.LocalClientAdded
		
			:Connect() -- Listens for when the 'LocalPlayer' has been re-added to the plum (does not fire the first time they are added)
			
		
		.LocalClientRemoved
		
			:Connect() -- Listens for when the 'LocalPlayer' has been removed from the plum
			
		
		.Destroyed
		
			:Connect() -- Listens for when the server calls ':Destroy()'
			

]]

local PathUtil = require(script.Parent.Parent.Util.PathUtil)
local Signal = require(script.Parent.Parent.Util.Signal)
local Squash = require(script.Parent.Parent.Util.Squash)
local t = require(script.Parent.Parent.Util.t)
local Maid = require(game.ReplicatedStorage.Util.Maid)
local PlumBase = require(script.Parent.Parent.Util.PlumBase)
local IsPlum = require(script.Parent.Parent.Util.IsPlum)

local invokeFromClientRF = script.Parent.Parent.InvokeFromClientRF

local ClientPlum = PlumBase

-------------
-- Private --
-------------
function ClientPlum.new(plumId, plumClassName, plumData, plumClients)
	local self = setmetatable({}, ClientPlum)

	local maid = Maid.new()

	self.Clients = plumClients
	self.ClassName = plumClassName
	self.Data = plumData
	self.Id = plumId

	self.LocalClientAdded = maid:Add(Signal.new())
	self.LocalClientRemoved = maid:Add(Signal.new())
	self.OnBroadcast = maid:Add(Signal.new())
	self.OnRaw = maid:Add(Signal.new())
	self.ClientAdded = maid:Add(Signal.new {
		OnObserve = function(observe)
			for _, client in self.Clients do
				task.spawn(observe, client, true)
			end
		end,
	})
	self.ClientRemoved = maid:Add(Signal.new())
	self.Destroyed = maid:Add(Signal.new())

	self._bubbleTo = {}
	self._path_to_signal = { ["ValueChanged"] = {}, ["OnArrayInsert"] = {}, ["OnArrayRemove"] = {} }
	self._valueChangedSignalTrie = {}
	self._maid = maid

	self.ValueChanged = function(pathArray)
		local pathString = PathUtil.toString(pathArray)
		local signal = self._path_to_signal["ValueChanged"][pathString]
		if not signal then
			signal = maid:Add(Signal.new {
				OnObserve = function(handler)
					local currValue = PathUtil.get(self.Data, pathArray)
					task.spawn(handler, currValue, currValue, true)
				end,
			})
			self._path_to_signal["ValueChanged"][pathString] = signal
			
			table.insert(pathArray, "_signal")
			PathUtil.ensure(self._valueChangedSignalTrie, pathArray, signal)
			pathArray[#pathArray] = nil
		end
		return signal
	end

	self.OnArrayInsert = function(pathArray)
		local pathString = PathUtil.toString(pathArray)
		local signal = self._path_to_signal["OnArrayInsert"][pathString]
		if not signal then
			signal = maid:Add(Signal.new {
				OnObserve = function(handler)
					local array = PathUtil.get(self.Data, pathArray)
					if array then
						for i, v in array do
							task.spawn(handler, v, i, true)
						end
					end
				end,
			})
			self._path_to_signal["OnArrayInsert"][pathString] = signal
		end
		return signal
	end

	self.OnArrayRemove = function(pathArray)
		local pathString = PathUtil.toString(pathArray)
		local signal = self._path_to_signal["OnArrayRemove"][pathString]
		if not signal then
			signal = maid:Add(Signal.new())
			self._path_to_signal["OnArrayRemove"][pathString] = signal
		end
		return signal
	end

	return self
end

------------
-- Public --
------------
function ClientPlum:IsClient(player)
	t.strict(t.tuple(t.instanceOf("Player")))(player)
	
	return not not table.find(self.Clients, player)
end

function ClientPlum:WaitFor(path)
	t.strict(t.tuple(t.array(t.union(t.string, t.number))))(path)
	
	local val = PathUtil.get(self.Data, path)
	if not val then
		return self.ValueChanged(path):Wait()
	end
	return val
end

function ClientPlum:InvokeServer(...)
	return invokeFromClientRF:InvokeServer(self.Id, ...)
end

return ClientPlum