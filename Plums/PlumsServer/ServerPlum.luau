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
	
				:IncValue(path : {string | number}, increment : number?) -> number
				
					Increments the old value at 'path' by 'increment' (1 by default) and returns the old value.
					
					':IncValueServerOnly()' doesn't replicate to clients.
				
				
				:DecValue(path : {string | number}, decrement : number?) -> number
				
					Decrements the old value at 'path' by 'increment' (1 by default) and returns the old value.
					
					':DecValueServerOnly()' doesn't replicate to clients.
				
	
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
			
			
		:EnableAutoAddClient() -> self
		
			Starts adding clients to the 'plum.Clients' array whenever the 'Players.PlayerAdded' event fires.
		
		
		:DisableAutoAddClient()
		
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

--[[
	Sub-plums are added when found...
	
		...in the 'data' table passed into 'Plums.new()'
		...as the 'newValue' or inside of the 'newValue' table through ':SetValue()'/':ArrayInsert()'
	
	Note: Not going to account for sub-plums added with assignment (Plums.Data = {sub-plum}) because it increases complexity/overhead for each replicated method call.
	If the dev wants server + client events for sub-plums, they must add them through cases a. or b.

	On sub-plum added:
	
		Server-side:
			
			Call sub-plum:AddClients(self.Clients)
		
		Server & client:
		
			Call sub-plum:_bubbleEventsTo(self)
		
		
	Sub-plums are removed when found...
	
		...as the 'oldValue' or in the 'oldValue' table through ':SetValue()'/':ArrayRemove()'
			(find all sub-plums in 'oldValue' and check to see if they are in the 'newValue'. if not, remove them as sub-plums)

	On sub-plum removed:
		
		Server & client:

			Call sub-plum:_stopBubbleEventsTo(self)
			
			
	Also stop bubbling up events...
	
		...when our plum is destroyed -> stop bubbling all 1st level sub-plum events to it
	
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
local PlumInternal = require(script.Parent.Parent.Util.PlumInternal)
local BufferEncoder = require(script.Parent.Parent.Util.BufferEncoder)
local PacketSizeCounter = require(script.Parent.Parent.Util.PacketSizeCounter)

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
			if v._isPlum then
				if callback then
					callback(v)
				end

				-- Replace sub-plum with its id for replication to client
				result[k] = plumToIdBuf(v)
			else
				result[k] = compressSubPlumsShallowest(v, callback, visited)
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
		if type(v) == "table" then
			if v._isPlum then
				-- First go as deep as possible
				forEachSubPlumDeepToShallow(v.Data, callback, visited)
				callback(v)
			else
				forEachSubPlumDeepToShallow(v, callback, visited)
			end
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
		if type(v) == "table" then
			if v._isPlum then
				callback(v)
			else
				forEachSubPlumShallowest(v, callback, visited)
			end
		end
	end
end

-- Compresses t with BufferEncoder only if it reduces t's size
local function bufferEncode(t)
	local buf, refs = BufferEncoder.write(t, nil, {
		allowreferences = true,
		allowdeduplication = true
	})

	local compressedSize = PacketSizeCounter.GetPacketSize({RunContext = "Server", RemoteType = "RemoteEvent", PacketData = {buf, refs}})
	local rawSize = PacketSizeCounter.GetPacketSize({RunContext = "Server", RemoteType = "RemoteEvent", PacketData = {t}})

	if rawSize < compressedSize then
		return t
	else
		return buf, refs
	end
end

local ServerPlum = PlumInternal

-------------
-- Private --
-------------
function ServerPlum:_processNewSubPlums(newValue)
	if type(newValue) == "table" then
		if newValue._isPlum then
			newValue:AddClients(self.Clients)
			newValue:_bubbleEventsTo(self)
			newValue = plumToIdBuf(newValue)
		else
			newValue = compressSubPlumsShallowest(newValue, function(subPlum)
				subPlum:AddClients(self.Clients)
				subPlum:_bubbleEventsTo(self)
			end)
		end
	end
	return newValue
end

function ServerPlum:_processRemovedSubPlums(oldValue, isDestroying)
	if type(oldValue) == "table" then
		if oldValue._isPlum then
			oldValue:_updateBubbleEventsTo(self)
		else
			forEachSubPlumShallowest(oldValue, function(subPlum)
				if isDestroying then
					subPlum:_stopBubbleEventsTo(self)
				else
					subPlum:_updateBubbleEventsTo(self)
				end
			end)
		end
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
					
					if self.AutoSerializeEnabled then
						plumReceivedRE:FireClient(client, SQ_TO_BUFF(cursor), self.Clients, bufferEncode(compressSubPlumsShallowest(self.Data)))
					else
						plumReceivedRE:FireClient(client, SQ_TO_BUFF(cursor), self.Clients, compressSubPlumsShallowest(self.Data))
					end
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
	local args = {...}
	
	if self.AutoSerializeEnabled
		and methodName == "SetValue" or methodName == "ArrayInsert"
	then
		local newValue = args[2]
		if type(newValue) == "table" then
			args[2], args[3] = bufferEncode(newValue)
		end
	end
	
	plumMethodCallRE:FireClient(client, SquashCodec[methodName:gsub("Bubble", "")].Serialize(methodName, self.Id, args))
end

function ServerPlum:_replicate(methodName, ...)
	for _, client in self.Clients do
		self:_replicateTo(client, methodName, ...)
	end
end

function ServerPlum:_setValueServerOnly(pathArray, newValue)
	if IS_STUDIO then
		t.strict(t.tuple(t.array(t.union(t.string, t.number)), t.optional(t.any)))(pathArray, newValue)
	end
	local oldValue, subPaths = self:_setValueInternal(pathArray, newValue)
	self:_processRemovedSubPlums(oldValue)
	return oldValue, subPaths
end
function ServerPlum:_arrayInsertServerOnly(pathArray, newValue, index)
	if IS_STUDIO then
		t.strict(t.tuple(t.array(t.union(t.string, t.number)), t.optional(t.any), t.optional(t.integer)))(pathArray, newValue, index)
	end
	return self:_arrayInsertInternal(pathArray, newValue, index)
end
function ServerPlum:_arrayRemoveServerOnly(pathArray, index)
	if IS_STUDIO then
		t.strict(t.tuple(t.array(t.union(t.string, t.number)), t.integer))(pathArray, index)
	end
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
	
	self._isPlum = true
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
	
	if #self.Clients == 0 then
		return
	end
	
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

	if #self.Clients == 0 then
		return
	end

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
	
	if #self.Clients == 0 then
		return
	end
	
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
	if IS_STUDIO then
		t.strict(t.tuple(t.instanceOf("Player")))(player)
	end
	return table.find(self.Clients, player) ~= nil
end

function ServerPlum:IncValue(pathArray, increment)
	if IS_STUDIO then
		t.strict(t.tuple(t.array(t.union(t.string, t.number)), t.optional(t.number)))(pathArray, increment)
	end
	local oldValue = PathUtil.get(self.Data, pathArray)
	return self:SetValue(pathArray, math.round((oldValue or 0) + (increment or 1)))
end

function ServerPlum:DecValue(pathArray, decrement)
	return self:IncValue(pathArray, -(decrement or 1))
end

function ServerPlum:AddClients(clients)
	if IS_STUDIO then
		t.strict(t.tuple(t.union(t.instanceOf("Player"), t.array(t.instanceOf("Player")))))(clients)
	end
	
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
	if IS_STUDIO then
		t.strict(t.tuple(t.union(t.instanceOf("Player"), t.array(t.instanceOf("Player")))))(clients)
	end
	
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

		local conn = self._maid:Remove(client.UserId .. "_LeavingConnection")
		if conn then
			conn:Disconnect()
		end
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

function ServerPlum:EnableAutoAddClient()
	if self._autoAddClientEnabled then
		return
	end

	self._autoAddClientEnabled = true
	self._maid:Add(Players.PlayerAdded:Connect(function(player)
		self:AddClients(player)
	end), nil, "AutoAddClientConnection")

	return self
end

function ServerPlum:DisableAutoAddClient()
	if not self._autoAddClientEnabled then
		return
	end

	self._autoAddClientEnabled = false
	self._maid:Remove("AutoAddClientConnection"):Disconnect()
end

function ServerPlum:WaitFor(path)
	if IS_STUDIO then
		t.strict(t.tuple(t.array(t.union(t.string, t.number))))(path)
	end
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
	if IS_STUDIO then
		t.strict(t.tuple(t.union(t.array(t.instanceIsA("Player")), t.instanceIsA("Player"))))(clients, ...)
	end
	for _, client in clients do
		if self:IsClient(client) then
			self:_replicateTo(client, "Broadcast", ...)

			self.OnBroadcast:Fire(client, ...)
		end
	end
end

function ServerPlum:BindToInstance(instance)
	if IS_STUDIO then
		t.strict(t.tuple(t.Instance))(instance)
	end

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