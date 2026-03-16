--[[
comdoc "Plums Client" 1 LastUpdated

	[ Methods ]
	
		:Init()
	
			Initializes the library. Must do once on client + server before anything else.
	
		
		:AwaitInitialized()
		
			Yields until the library has been initialized (waits for an ':Init()' call).
			
		
		:WaitForPlum(plumId : number, debugTag : string?) -> Plum?
		
			Yields until the specified plum exists on the client. Provide a 'debugTag' for helpful debug prints if this plum is not being found.
		
	
	[ Events ]
	
		.AnyPlumReceived
		
			:Observe() -- Collects all prior plums and listens for new ones
			:Connect() -- Listens for new plums
			
			
		.PlumReceived(className : string)
		
			:Observe() -- Collects all prior plums of 'className' and listens for new ones
			:Connect() -- Listens for new plums of 'className'
			
			```lua
			Plums.PlumReceived("Player"):Observe(function(playerPlum)
				print("Received plum! ClassName:", playerPlum.ClassName, "Data:", playerPlum.Data)
			end)
			```

]]

script.Parent.PlumsServer:Destroy()

local Players = game:GetService("Players")

local PlumValueChangedUtil = require(script.Parent.Util.PlumValueChangedUtil)
local Signal = require(script.Parent.Util.Signal)
local Types = require(script.Parent.Util.Types)
local PlumsCache = require(script.Parent.Util.PlumsCache)
local Squash = require(script.Parent.Util.Squash)
local PathUtil = require(script.Parent.Util.PathUtil)
local Await = require(script.Parent.Util.Await)
local t = require(script.Parent.Util.t)
local SquashCodec = require(script.Parent.Util.SquashCodec)
local ClientReady = require(script.Parent.Util.ClientReady)
local IsPlum = require(script.Parent.Util.IsPlum)

local player = Players.LocalPlayer

local SQ_FROM_BUFF = Squash.frombuffer
local SQ_STR_DES = Squash.string().des
local SQ_U32_DES = Squash.uint(4).des

local initializedSignal = Signal.new()
local plumClass_to_receivedSignal = {}
local initialized = false

local function assertInitialized()
	assert(initialized, "must call PlumsClient:Init() before anything else")
end

local function getPlumIdFromBuf(buf)
	local ok, id = pcall(function()
		local cur = SQ_FROM_BUFF(buf)
		local str = SQ_STR_DES(cur)
		
		if str then
			local id = str:match("P(%d+)")
			if id then
				return tonumber(id)
			end
		end
	end)
	
	return ok and id
end

local PlumsClient = {}

-- Replaces all sub-plum id buffers with their plum objects and calls 'subPlum:_bubbleEventsTo(parentPlum)'
local function processNewSubPlums(parentPlum, t)
	for k, v in t do
		if type(v) == "table" then
			processNewSubPlums(parentPlum, v)
		elseif typeof(v) == "buffer" then
			local id = getPlumIdFromBuf(v)
			if id then
				t[k] = PlumsClient:WaitForPlum(id)
				t[k]:_bubbleEventsTo(parentPlum)
			end
		end
	end
end

local function processRemovedSubPlums(parentPlum, t, isDestroying)
	for k, v in t do
		if IsPlum(v) then
			if isDestroying then
				v:_stopBubbleEventsTo(parentPlum)
			else
				v:_updateBubbleEventsTo(parentPlum)
			end
		elseif typeof(v) == "table" then
			processRemovedSubPlums(parentPlum, v, isDestroying)
		end
	end
end

------------
-- Events --
------------
PlumsClient.AnyPlumReceived = PlumsCache.PlumAddedSignal

PlumsClient.PlumReceived = function(plumClassName)
	assertInitialized()
	
	t.strict(t.tuple(t.string))(plumClassName)

	local plumReceivedSignal = plumClass_to_receivedSignal[plumClassName]

	if not plumReceivedSignal then
		local classNameCache = PlumsCache.getClassNameCache(plumClassName)

		plumReceivedSignal = Signal.new({
			OnObserve = function(handler)
				for _, plum in classNameCache do
					task.spawn(handler, plum, true)
				end
			end,
		})

		plumClass_to_receivedSignal[plumClassName] = plumReceivedSignal
	end

	return plumReceivedSignal
end

-------------
-- Methods --
-------------
function PlumsClient:Init()
	if initialized then
		return
	end
	
	script.Parent:WaitForChild("InvokeFromClientRF") -- Move the dependency yield outside of the require
	local Plum = require(script.ClientPlum)
	
	local function onPlumMethodCall(buf, ...)
		local cursor = SQ_FROM_BUFF(buf)
		local methodName = SQ_STR_DES(cursor)
		local plumId = SQ_U32_DES(cursor)

		local plum = PlumsCache.getPlum(plumId)
		if not plum then -- It's possible that the plum doesn't exist in at least this case: The server just created the plum and it's a race between the method call "AddClients" and `Plum.PlumReceived` (i.e. the "AddClients" is received first before the plum gets created)
			return
		end

		if methodName == "Broadcast" then
			plum.OnBroadcast:Fire(...)
		elseif methodName == "Destroy" then
			processRemovedSubPlums(plum, plum.Data, true)
			plum:_destroyInternal()
		elseif methodName == "RemoveClients" then
			local removedClients = ...
			for _, v in removedClients do
				local foundIdx = table.find(plum.Clients, v)
				if foundIdx then
					table.remove(plum.Clients, foundIdx)
					plum.ClientRemoved:Fire(v)
					if v == player then
						plum.LocalClientRemoved:Fire()
					end
				end
			end
		elseif methodName == "AddClients" then
			local addedClients = ...
			for _, v in addedClients do
				if v.Parent == Players and not table.find(plum.Clients, v) then
					table.insert(plum.Clients, v)
					plum.ClientAdded:Fire(v)
					if v == player then
						plum.LocalClientAdded:Fire()
					end
				end
			end
		elseif methodName == "SetValue" or methodName == "ArrayInsert" or methodName == "ArrayRemove" then
			local newValue = ...
			local pathString, index = SquashCodec[methodName].Deserialize(cursor)
			local pathArray = PathUtil.toArray(pathString) -- Convert pathString to pathArray for performance

			if newValue then
				local subPlumId = getPlumIdFromBuf(newValue)
				if subPlumId then
					newValue = self:WaitForPlum(subPlumId)
					newValue:_bubbleEventsTo(plum)
				elseif type(newValue) == "table" then
					processNewSubPlums(plum, newValue)
				end
			end

			local oldValue

			if methodName == "SetValue" then
				oldValue = plum:_setValueInternal(pathArray, newValue)
			elseif methodName == "ArrayInsert" then
				plum:_arrayInsertInternal(pathArray, newValue, index)
			elseif methodName == "ArrayRemove" then
				oldValue = plum:_arrayRemoveInternal(pathArray, index)
			end
			
			if oldValue then
				if IsPlum(oldValue) then
					oldValue:_updateBubbleEventsTo(plum)
				elseif type(oldValue) == "table" then
					processRemovedSubPlums(plum, oldValue)
				end
			end
		end
	end

	local function onPlumReceived(buf, plumClients, plumData)
		local cursor = SQ_FROM_BUFF(buf)
		local plumClassName = SQ_STR_DES(cursor)
		local plumId = SQ_U32_DES(cursor)

		print("plum received", plumId, plumClassName, plumClients, plumData)

		local plum = Plum.new(plumId, plumClassName, plumData, plumClients)

		processNewSubPlums(plum, plumData)

		PlumsCache.addPlum(plum)
		PlumsClient.PlumReceived(plumClassName):Fire(plum)
	end
	
	script.Parent:WaitForChild("PlumReceivedRE").OnClientEvent:Connect(onPlumReceived)
	script.Parent:WaitForChild("PlumMethodCallRE").OnClientEvent:Connect(onPlumMethodCall)

	ClientReady.fireReady("Plums")
	
	initialized = true
	initializedSignal:Fire()
end

function PlumsClient:AwaitInitialized()
	if not initialized then
		initializedSignal:Wait()
	end
end

function PlumsClient:WaitForPlum(plumId, debugTag)
	assertInitialized()
	
	t.strict(t.tuple(t.integer))(plumId)
	
	local plum = PlumsCache.getPlum(plumId, debugTag)

	if not plum then
		task.delay(5, function()
			if not plum then
				if debugTag then
					warn("Infinite yield possible waiting for plum (", plumId, ")", debugTag)
				else
					warn("Infinite yield possible waiting for plum id", plumId)
				end
			end
		end)
	
		if debugTag then
			print("[WaitForPlum] didn't find plum (", plumId, ")", debugTag, "in cache", PlumsCache.idToPlum)
		end
	
		local _
		_, plum = Await.args(nil, PlumsCache.PlumAddedSignal, Await.allArgumentsCheck(function(plum)
			return plum.Id == plumId
		end))
	end

	return plum
end

return PlumsClient :: Types.PlumsClientType