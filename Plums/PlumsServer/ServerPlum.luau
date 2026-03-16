--[[
comdoc "Server Plum" 4 LastUpdated

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
	
	
		.OnServerInvoke = function(player: Player, ...any?) -> ...any?
		
			Set this to a function in order to listen to 'clientPlum:InvokeServer()' calls.
		
			```lua
			playerPlum.OnServerInvoke = function(player, ...)
				print("On server invoke! Player:", player, "Args:", ...)
				return "response from server"
			end)
			```	

	
	[ Methods ]
	
		:SetValue(path : {string | number}, newValue : any?) -> any?
		
			Replaces the old value at 'path' with 'newValue' and returns the old value.
	
			':SetValueServerOnly()' doesn't replicate to clients.
	
			Number-based ':SetValue()' wrappers:
	
				:IncValue(path : {string | number}, increment : number?) -> any?
				
					Increments the old value at 'path' by 1 and returns the old value.
					
					':IncValueServerOnly()' doesn't replicate to clients.
				
				
				:DecValue(path : {string | number}, decrement : number?) -> any?
				
					Decrements the old value at 'path' by 1 and returns the old value.
					
					':DecValueServerOnly()' doesn't replicate to clients.
				
				
				:MultiplyValue(path : {string | number}, multiplier : number?) -> any?
			
					Multiplies the old value at 'path' by 'multiplier' and returns the old value.
					
					':MultiplyValueServerOnly()' doesn't replicate to clients.
	
	
		:ArrayInsert(path : {string | number}, newValue : any?, index : integer?)
			
			Inserts the 'newValue' at a position of 'index' or at the end of the target array found at 'path'.
		
			':ArrayInsertServerOnly()' doesn't replicate to clients.
		
		
		:ArrayRemove(path : {string | number}, index : integer) -> any?
	
			Removes the old value at the position of 'index' in the target array found at 'path' and returns the old value.
			
			':ArrayRemoveServerOnly()' doesn't replicate to clients.
	
	
		:IsClient(player : Player) -> boolean
		
			Returns true if the 'player' is in the 'plum.Clients' array.
			

		:AddClients(clients : Player | {Player}) -> self
		
			Adds the 'clients' to the 'plum.Clients' array.
		
		
		:AddAllClients() -> self
		
			Adds all in-game players to the 'plum.Clients' array.
			
			
		:EnableAutoAddClients() -> self
		
			Starts adding clients to the 'plum.Clients' array whenever the 'Players.PlayerAdded' event fires.
		
		
		:DisableAutoAddClients()
		
			Stops adding clients to the 'plum.Clients' array whenever the 'Players.PlayerAdded' event fires.
		
		
		:RemoveClients(clients : Player | {Player})
		
			Removes the 'clients' from the 'plum.Clients' array.


		:WaitFor(path : {string | number}) -> any
			
			Yields until the value at 'path' is not nil and returns the value.


		:Broadcast(...any?)
		
			Sends all 'plum.Clients' some arguments.
			
		
		:BroadcastTo(clients : Player | {Player}, ...any?)

			Sends 'clients' some arguments.
		

		:BindToInstance(instance : Instance) -> self
		
			Destroys the plum when 'instance' is destroyed.
	
		
		:WaitFor(path : {string | number}) -> any?
		
			Yields until the value at 'path' is not nil and returns the value.
			
	
		:Destroy()
		
			Destroys the plum, disconnecting all connections to its events.
	
	
	[ Events ]
		
		
		.ValueChanged(path : {string | number})
		
			:Observe() -- Collects current value at 'path' and listens for new changes to it
			:Connect() -- Listens for new changes to 'path'
			
			```lua
			playerPlum.ValueChanged({"Money"}):Observe(function(newValue, oldValue)
				print("Money changed! New value:", newValue, "Old value:", oldValue)
			end)
			```
			
			
		.OnArrayInsert(path : {string | number})
		
			:Observe() -- Collects current values in the array at 'path' and listens for new inserts into it
			:Connect() -- Listens for new inserts into the array at 'path'
			
			```lua
			playerPlum.OnArrayInsert({"Items"}):Observe(function(newValue, index)
				print("Item added! New value:", newValue, "Index:", index)
			end)
			```
			
			
		.OnArrayRemove(path : {string | number})
		
			:Connect() -- Listens for removals from the array at 'path'
			
			```lua
			playerPlum.OnArrayRemove({"Items"}):Connect(function(oldValue, index)
				print("Item removed! Old value:", oldValue, "Index:", index)
			end)
			```
			
			
		.OnRaw
		
			:Connect() -- Listens to events fired on ':SetValue()'/':ArrayInsert()'/':ArrayRemove()'
			
			```lua
			playerPlum.OnRaw:Connect(function(methodName, path, ...)
				print("On raw! Method name:", methodName, "Path array:", path, "Args:", ...)
			end)
			```
			
			
		.OnBroadcast
		
			:Connect() -- Listens to events fired on ':Broadcast()'/':BroadcastTo()'
		
			```lua
			playerPlum.OnBroadcast:Connect(function(...)
				print("On broadcast! Args:", ...)
			end)
			```
			
			
		.ClientAdded
		
			:Observe() -- Collects the current clients in the 'plum.Clients' array and listens for new ones added
			:Connect() -- Listens for new clients added to the 'plum.Clients' array
			
		
		.ClientRemoved
		
			:Connect() -- Listens for a client removed from the 'plum.Clients' array
			

		.Destroyed
		
			:Connect() -- Listens for when the server calls ':Destroy()'
			
			
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PlumValueChangedUtil = require(script.Parent.Parent.Util.PlumValueChangedUtil)
local Squash = require(script.Parent.Parent.Util.Squash)
local Signal = require(script.Parent.Parent.Util.Signal)
local PathUtil = require(script.Parent.Parent.Util.PathUtil)
local PlumsCache = require(script.Parent.Parent.Util.PlumsCache)
local Maid = require(script.Parent.Parent.Util.Maid)
local t = require(script.Parent.Parent.Util.t)
local ClientReady = require(script.Parent.Parent.Util.ClientReady)
local SquashCodec = require(script.Parent.Parent.Util.SquashCodec)
local PlumBase = require(script.Parent.Parent.Util.PlumBase)
local IsPlum = require(script.Parent.Parent.Util.IsPlum)

local IS_STUDIO = RunService:IsStudio()

local SQ_CURSOR = Squash.cursor
local SQ_TO_BUFF = Squash.tobuffer
local SQ_STR_SER = Squash.string().ser
local SQ_U32_SER = Squash.uint(4).ser

local plumMethodCallRE do
	plumMethodCallRE = Instance.new("RemoteEvent")
	plumMethodCallRE.Name = "PlumMethodCallRE"
	plumMethodCallRE.Parent = script.Parent.Parent
end

local plumReceivedRE do
	plumReceivedRE = Instance.new("RemoteEvent")
	plumReceivedRE.Name = "PlumReceivedRE"
	plumReceivedRE.Parent = script.Parent.Parent
end

local typeCheck = {} do
	local pathType = t.array(t.union(t.number, t.string))

	typeCheck._setValueServerOnly = t.strict(t.tuple(pathType, t.optional(t.any)))
	typeCheck._arrayInsertServerOnly = t.strict(t.tuple(pathType, t.optional(t.any), t.optional(t.integer)))
	typeCheck._arrayRemoveServerOnly = t.strict(t.tuple(pathType, t.integer))
	
	typeCheck.IsClient = t.strict(t.tuple(t.instanceOf("Player")))
	typeCheck.IncValue = t.strict(t.tuple(pathType, t.optional(t.number)))
	typeCheck.MultiplyValue = t.strict(t.tuple(pathType, t.optional(t.number)))
	typeCheck.AddClients = t.strict(t.tuple(t.union(t.instanceOf("Player"), t.array(t.instanceOf("Player")))))
	typeCheck.RemoveClients = t.strict(t.tuple(t.union(t.instanceOf("Player"), t.array(t.instanceOf("Player")))))
	typeCheck.BroadcastTo = t.strict(t.tuple(t.union(t.array(t.instanceIsA("Player")), t.instanceIsA("Player"))))
	typeCheck.BindToInstance = t.strict(t.tuple(t.Instance))
	typeCheck.WaitFor = t.strict(t.tuple(t.array(t.union(t.string, t.number))))
end

local currentServerPlumId = 0

local function plumToIdBuf(plum)
	local cur = SQ_CURSOR()
	SQ_STR_SER(cur, "P" .. plum.Id)
	return SQ_TO_BUFF(cur)
end

local function compressSubPlumsShallowest(t, callback, visited)
	visited = visited or {}

	local existing = visited[t]
	if existing then
		return existing
	end

	local result = {}
	visited[t] = result -- Prevent cycles

	for k, v in t do
		if type(v) ~= "table" then
			result[k] = v
		else
			if not IsPlum(v) then
				result[k] = compressSubPlumsShallowest(v, callback, visited)
			else
				if callback then
					callback(v)
				end
				
				-- Replace sub-plum with its id for replication to client
				result[k] = plumToIdBuf(v)
			end
		end
	end

	return result
end

local function forEachSubPlumDeepToShallow(t, callback, visited)
	visited = visited or {}

	if visited[t] then
		return
	end
	visited[t] = true -- Prevent cycles

	for k, v in t do
		if IsPlum(v) then
			-- First go as deep as possible
			forEachSubPlumDeepToShallow(v.Data, callback, visited)
			callback(v)
		elseif type(v) == "table" then
			forEachSubPlumDeepToShallow(v, callback, visited)
		end
	end
end

-- Shallowest because it doesn't go into sub-plums for sub-sub-plums
local function forEachSubPlumShallowest(t, callback, visited)
	visited = visited or {}

	if visited[t] then
		return
	end
	visited[t] = true -- Prevent cycles

	for k, v in t do
		if IsPlum(v) then
			callback(v)
		elseif type(v) == "table" then
			forEachSubPlumShallowest(v, callback, visited)
		end
	end
end

local ServerPlum = PlumBase

-------------
-- Private --
-------------
function ServerPlum:_processNewSubPlums(t)
	if IsPlum(t) then
		t:AddClients(self.Clients)
		t:_bubbleEventsTo(self)
		t = plumToIdBuf(t)
	elseif type(t) == "table" then
		t = compressSubPlumsShallowest(t, function(subPlum)
			subPlum:AddClients(self.Clients)
			subPlum:_bubbleEventsTo(self)
		end)
	end
	return t
end

function ServerPlum:_processRemovedSubPlums(oldValue, isDestroying)
	if IsPlum(oldValue) then
		oldValue:_updateBubbleEventsTo(self)
	elseif type(oldValue) == "table" then
		forEachSubPlumShallowest(oldValue, function(subPlum)
			if isDestroying then
				subPlum:_stopBubbleEventsTo(self)
			else
				subPlum:_updateBubbleEventsTo(self)
			end
		end)
	end
end

function ServerPlum:_addClients(clients)
	local beforeClients = table.clone(self.Clients)

	local isFirstTimeAdded = {}
	local addedClients = {}

	-- Insert the clients into the 'self.Clients' table (and send them the plum if they haven't received it)
	for _, client in clients do
		if self:IsClient(client) then
			continue
		end

		if not self._hasBeenAddedOnce[client] then
			self._hasBeenAddedOnce[client] = true
			isFirstTimeAdded[client] = true
		end

		table.insert(self.Clients, client)
		table.insert(addedClients, client)

		-- Fire server-only plumObject.Event
		self.ClientAdded:Fire(client)

		-- Remove the client automatically when they leave the game
		self._maid:Add(client.Destroying:Connect(function()
			self._hasReceivedPlum[client] = nil
			self._hasBeenAddedOnce[client] = nil
			self:RemoveClients(client)
		end), nil, client.UserId .. "_LeavingConnection")

		-- Send them the plum asynchronously
		if not self:_hasReceived(client) then
			ClientReady.awaitClientReady(client, "Plums"):andThen(function()
				if self:IsClient(client) and not self:_hasReceived(client) then -- Could have changed by now
					self:_markHasReceived(client)

					local cursor = SQ_CURSOR()
					SQ_U32_SER(cursor, self.Id)
					SQ_STR_SER(cursor, self.ClassName)

					plumReceivedRE:FireClient(client, SQ_TO_BUFF(cursor), self.Clients, compressSubPlumsShallowest(self.Data))
				end
			end, warn)
		end
	end

	if #addedClients == 0 then
		return self
	end

	-- All of the 'beforeClients' need to receive all of the 'addedClients'
	for _, client in beforeClients do
		self:_replicateTo(client, "AddClients", addedClients)
	end

	-- Go back through the clients and let them know of 'ClientAdded' events in batches
	for _, client in table.clone(addedClients) do -- Replicate to each client the added clients that come after it (and itself added if not the first time it's receiving)
		local foundIndex = table.find(addedClients, client)

		-- Don't want to replicate method to the client if first time
		if isFirstTimeAdded[client] then
			table.remove(addedClients, foundIndex)
		end

		if #addedClients == 0 then
			return self
		end

		self:_replicateTo(client, "AddClients", addedClients)

		if not isFirstTimeAdded[client] then
			table.remove(addedClients, foundIndex)
		end
	end
end

function ServerPlum:_replicateTo(client, methodName, ...)
	plumMethodCallRE:FireClient(client, SquashCodec[methodName:gsub("Bubble", "")].Serialize(methodName, self.Id, ...))
end

function ServerPlum:_replicate(methodName, ...)
	for _, client in self.Clients do
		self:_replicateTo(client, methodName, ...)
	end
end

function ServerPlum:_setValueServerOnly(pathArray, newValue)
	typeCheck._setValueServerOnly(pathArray, newValue)
	local oldValue, subPaths = self:_setValueInternal(pathArray, newValue)
	self:_processRemovedSubPlums(oldValue)
	return oldValue, subPaths
end
function ServerPlum:_arrayInsertServerOnly(pathArray, newValue, index)
	typeCheck._arrayInsertServerOnly(pathArray, newValue, index)
	return self:_arrayInsertInternal(pathArray, newValue, index)
end
function ServerPlum:_arrayRemoveServerOnly(pathArray, index)
	typeCheck._arrayRemoveServerOnly(pathArray, index)
	local oldValue, subPaths = self:_arrayRemoveInternal(pathArray, index)
	self:_processRemovedSubPlums(oldValue)
	return oldValue, subPaths
end

function ServerPlum:_hasReceived(client)
	return self._hasReceivedPlum[client]
end
function ServerPlum:_markHasReceived(client)
	self._hasReceivedPlum[client] = true
end

function ServerPlum.new(plumClassName, plumData)
	currentServerPlumId += 1

	local self = setmetatable({}, ServerPlum)

	local maid = Maid.new()

	self.ClassName = plumClassName
	
	self.Data = plumData
	self.Clients = {}
	self.Id = currentServerPlumId

	self.OnBroadcast = maid:Add(Signal.new())
	self.OnRaw = maid:Add(Signal.new())
	self.ClientAdded = maid:Add(Signal.new {
		OnObserve = function(handler)
			for _, client in self.Clients do
				task.spawn(handler, client, true)
			end
		end,
	})
	self.ClientRemoved = maid:Add(Signal.new())
	self.Destroyed = maid:Add(Signal.new())
	
	self._bubbleTo = {}
	self._hasReceivedPlum = {}
	self._hasBeenAddedOnce = {}
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

	forEachSubPlumShallowest(self.Data, function(subPlum)
		subPlum:_bubbleEventsTo(self)
	end)

	return self
end

------------
-- Public --
------------
function ServerPlum:SetValue(pathArray, newValue)
	-- Server modification
	local oldValue, subPaths = self:_setValueServerOnly(pathArray, newValue)
	
	-- Process new sub plums
	local newValue = self:_processNewSubPlums(newValue)

	-- Replication starting with topmost plum (self)
	local hitClients = {}
	for i, v in subPaths do
		local plum, pathString = v[1], v[2]

		for _, client in plum.Clients do
			if hitClients[client] then
				continue
			end
			hitClients[client] = true

			-- Client modification
			plum:_replicateTo(client, "SetValue", pathString, newValue)
		end
	end

	return oldValue
end

function ServerPlum:ArrayInsert(pathArray, newValue, index)
	-- Server modification
	local subPaths, index = self:_arrayInsertServerOnly(pathArray, newValue, index)

	-- Process new sub plums
	local newValue = self:_processNewSubPlums(newValue)

	-- Replication starting with topmost plum (self)
	local hitClients = {}
	for i, v in subPaths do
		local plum, pathString = v[1], v[2]
		
		for _, client in plum.Clients do
			if hitClients[client] then
				continue
			end
			hitClients[client] = true

			-- Client modification
			plum:_replicateTo(client, "ArrayInsert", pathString, index, newValue)
		end
	end
end

function ServerPlum:ArrayRemove(pathArray, index)
	-- Server modification
	local oldValue, subPaths = self:_arrayRemoveServerOnly(pathArray, index)
	
	-- Replication starting with topmost plum (self)
	local hitClients = {}
	for i, v in subPaths do
		local plum, pathString = v[1], v[2]

		for _, client in plum.Clients do
			if hitClients[client] then
				continue
			end
			hitClients[client] = true

			-- Client modification
			plum:_replicateTo(client, "ArrayRemove", pathString, index)
		end
	end
	
	return oldValue
end

function ServerPlum:IncValueServerOnly(pathArray, increment)
	local oldValue = PathUtil.get(self.Data, pathArray)
	self:_setValueServerOnly(pathArray, math.round((oldValue or 0) + (increment or 1)))
	return oldValue
end

function ServerPlum:DecValueServerOnly(pathArray, decrement)
	local oldValue = PathUtil.get(self.Data, pathArray)
	self:_setValueServerOnly(pathArray, math.round((oldValue or 0) - (decrement or 1)))
	return oldValue
end

function ServerPlum:MultiplyValueServerOnly(pathArray, multiplier)
	local oldValue = PathUtil.get(self.Data, pathArray)
	self:_setValueServerOnly(pathArray, (oldValue or 0) * (multiplier or 1))
	return oldValue
end

function ServerPlum:SetValueServerOnly(pathArray, newValue)
	local oldValue = self:_setValueServerOnly(pathArray, newValue)
	return oldValue
end

function ServerPlum:ArrayInsertServerOnly(pathArray, newValue, index)
	self:_arrayInsertServerOnly(pathArray, newValue, index)
end

function ServerPlum:ArrayRemoveServerOnly(pathArray, index)
	local oldValue = self:_arrayRemoveServerOnly(pathArray, index)
	return oldValue
end

function ServerPlum:IsClient(player)
	typeCheck.IsClient(player)
	return table.find(self.Clients, player) ~= nil
end

function ServerPlum:IncValue(pathArray, increment)
	typeCheck.IncValue(pathArray, increment)
	local oldValue = PathUtil.get(self.Data, pathArray)
	return self:SetValue(pathArray, math.round((oldValue or 0) + (increment or 1)))
end

function ServerPlum:DecValue(pathArray, decrement)
	return self:IncValue(pathArray, -1)
end

function ServerPlum:MultiplyValue(pathArray, multiplier)
	typeCheck.MultiplyValue(pathArray, multiplier)
	local oldValue = PathUtil.get(self.Data, pathArray)
	return self:SetValue(pathArray, (oldValue or 0) * (multiplier or 1))
end

function ServerPlum:AddClients(clients)
	typeCheck.AddClients(clients)
	
	if typeof(clients) == "Instance" then
		clients = {clients}	
	end
	
	-- First add to sub-plums
	forEachSubPlumDeepToShallow(self.Data, function(subPlum)
		subPlum:_addClients(clients)
	end)
	
	-- Then add to self
	self:_addClients(clients)
	
	return self
end

function ServerPlum:AddAllClients()
	self:AddClients(Players:GetPlayers())
	return self
end

function ServerPlum:RemoveClients(clients)
	typeCheck.RemoveClients(clients)
	
	if typeof(clients) == "Instance" then
		clients = {clients}
	end

	local beforeClients = table.clone(self.Clients)
	local removedClients = {}

	-- Remove the clients from the 'self.Clients' table
	for _, client in table.clone(clients) do
		local foundIndex = table.find(self.Clients, client)
		if not foundIndex then
			continue
		end

		table.remove(self.Clients, foundIndex)
		table.insert(removedClients, client)
		
		-- Fire server-only plumObject.Event
		self.ClientRemoved:Fire(client)

		self._maid:Remove(client.UserId .. "_LeavingConnection"):Disconnect()
	end
	
	if #removedClients == 0 then
		return
	end
	
	local savedRemovedClients = table.clone(removedClients)
	
	-- Go back through the clients and let them know of 'ClientRemoved' events in batches
	for i = #removedClients, 1, -1 do -- Replicate to each client the removed clients that come before it and itself removed
		local client = removedClients[i]
		self:_replicateTo(client, "RemoveClients", removedClients)
		local foundIdx = table.find(beforeClients, client)
		if foundIdx then
			table.remove(beforeClients, foundIdx) -- So we don't send it to them twice in the next loop
		end
		removedClients[i] = nil
	end
	
	-- All of the 'beforeClients' - 'removedClients' need to receive all of the 'removedClients'
	for _, client in beforeClients do
		self:_replicateTo(client, "RemoveClients", savedRemovedClients)
	end
end

function ServerPlum:EnableAutoAddClients()
	if self._autoAddClientsEnabled then
		return
	end

	self._autoAddClientsEnabled = true
	self._maid:Add(Players.PlayerAdded:Connect(function(player)
		self:AddClients(player)
	end), nil, "AutoAddClientsConnection")

	return self
end

function ServerPlum:DisableAutoAddClients()
	if not self._autoAddClientsEnabled then
		return
	end

	self._autoAddClientsEnabled = false
	self._maid:Remove("AutoAddClientsConnection"):Disconnect()
end

function ServerPlum:WaitFor(path)
	typeCheck.WaitFor(path)
	local val = PathUtil.get(self.Data, path)
	if not val then
		return self.ValueChanged(path):Wait()
	end
	return val
end

function ServerPlum:Broadcast(...)
	self:BroadcastTo(self.Clients, ...)
end

function ServerPlum:BroadcastTo(clients, ...)
	typeCheck.BroadcastTo(clients, ...)
	for _, client in clients do
		if self:IsClient(client) then
			self:_replicateTo(client, "Broadcast", ...)

			self.OnBroadcast:Fire(client, ...)
		end
	end
end

function ServerPlum:BindToInstance(instance)
	typeCheck.BindToInstance(instance)
	
	self:SetValue({"Instance"}, instance)
	
	instance.Destroying:Connect(function()
		self:Destroy()
	end)
	
	return self
end

function ServerPlum:Destroy()
	self:_replicate("Destroy") -- Tell receiving clients first
	self:_processRemovedSubPlums(self.Data, true)
	self:_destroyInternal()
end

return ServerPlum