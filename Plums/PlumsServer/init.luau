--[[
comdoc "Plums Server" 2 LastUpdated

	[ Constructor ]
	
		.new(plumClassName : string, plumData : {}?) -> Plum
		
			Creates a new plum of 'plumClassName' with plum.Data set to 'plumData'.
	
			```lua
			local playerPlum = Plums.new("Player", {
				Money = 100
			}):AddClients(player) -- This method chaining approach is optional
			```
	
	
	[ Methods ]
	
		:Init(initSettings : {
			AutoSerializeEnabled : boolean (true by default) -- Will serialize all tables being sent to the client if it reduces packet size (including initial 'plum.Data' table)
		}?)
	
			Initializes the library. Must do once on client + server before anything else.
	
		
		:AwaitInitialized()
		
			Yields until the library has been initialized (waits for an ':Init()' call).
			
		
		:WaitForPlum(plumId : number, debugTag : string?) -> Plum
		
			Yields until the specified plum exists on the server. Provide a 'debugTag' for helpful debug prints if this plum is not being found.
		
	
	[ Events ]
	
		.AnyPlumCreated
		
			:Observe() -- Collects all prior plums and listens for new ones
			:Connect() -- Listens for new plums
			
			
		.PlumCreated(className : string)
		
			:Observe() -- Collects all prior plums of 'className' and listens for new ones
			:Connect() -- Listens for new plums of 'className'
			
			```lua
			Plums.PlumCreated("Player"):Observe(function(playerPlum)
				print("Plum created! ClassName:", playerPlum.ClassName, "Data:", playerPlum.Data)
			end)
			```

]]

local Signal = require(script.Parent.Util.Signal)
local Types = require(script.Parent.Util.Types)
local PlumsCache = require(script.Parent.Util.PlumsCache)
local Await = require(script.Parent.Util.Await)
local t = require(script.Parent.Util.t)
local Squash = require(script.Parent.Util.Squash)
local Plum = require(script.ServerPlum)
local PlumInternal = require(script.Parent.Util.PlumInternal)

local initializedSignal = Signal.new()
local plumClass_to_createdSignal = {}
local initialized = false

local function assertInitialized()
	assert(initialized, "must call PlumsServer:Init() before anything else")
end

local PlumsServer = {}

------------
-- Events --
------------
PlumsServer.AnyPlumCreated = PlumsCache.PlumAddedSignal

PlumsServer.PlumCreated = function(plumClassName)
	t.strict(t.tuple(t.string))(plumClassName)
	
	local plumCreatedSignal = plumClass_to_createdSignal[plumClassName]

	if not plumCreatedSignal then
		local classNameCache = PlumsCache.getClassNameCache(plumClassName)

		plumCreatedSignal = Signal.new({
			OnObserve = function(handler)
				for _, plum in classNameCache do
					task.spawn(handler, plum, true)
				end
			end,
		})

		plumClass_to_createdSignal[plumClassName] = plumCreatedSignal
	end

	return plumCreatedSignal
end

-------------
-- Methods --
-------------
function PlumsServer:Init(initSettings)
	if initSettings and initSettings.AutoSerializeEnabled == false then
		PlumInternal.AutoSerializeEnabled = false
	end
	
	if initialized then
		return
	end
	
	local invokeFromClientRF = Instance.new("RemoteFunction")
	invokeFromClientRF.Name = "InvokeFromClientRF"
	invokeFromClientRF.Parent = script.Parent
	invokeFromClientRF.OnServerInvoke = function(client, plumId, ...)
		local plum = PlumsCache.getPlum(plumId)
		if plum.OnServerInvoke and plum:IsClient(client) then
			return plum.OnServerInvoke(client, ...)
		end
	end
	
	initialized = true
	initializedSignal:Fire()
end

function PlumsServer.new(plumClassName, plumData)
	assertInitialized()

	t.strict(t.tuple(t.string, t.optional(t.table), t.optional(t.table), t.optional(t.table)))(plumClassName, plumData)

	local plum = Plum.new(plumClassName, plumData or {})

	PlumsCache.addPlum(plum)
	PlumsServer.PlumCreated(plumClassName):Fire(plum)

	return plum
end

function PlumsServer:AwaitInitialized()
	if not initialized then
		initializedSignal:Wait()
	end
end

function PlumsServer:WaitForPlum(plumId, debugTag)
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

		local _; _, plum = Await.args(nil, PlumsCache.PlumAddedSignal, Await.allArgumentsCheck(function(plum)
			return plum.Id == plumId
		end))
	end

	return plum
end

return PlumsServer :: Types.PlumsServerType