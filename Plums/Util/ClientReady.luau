-- v3.0.0

local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)
local Await = require(script.Parent.Await)

local remoteEvent
if RunService:IsClient() then
	remoteEvent = script:WaitForChild("RemoteEvent")
else
	remoteEvent = Instance.new("RemoteEvent", script)
end

local DEFAULT_TIMEOUT = 30
local DEBUG_MODE = false
local EMPTY_TABLE = table.freeze({})

local ClientReady = {}

local client_to_readyServices = {}
local client_to_initializedServices = {} -- The server has awknowledged the client's readiness and finished incorporating in the client for that service

------------
-- SERVER --
------------

local getClientReadyServices, getClientInitializedServices, onClientReadied, onClientInitialized do
	function getClientReadyServices(client)
		if not client:IsDescendantOf(game) then
			return EMPTY_TABLE
		end
		if not client_to_readyServices[client] then
			client_to_readyServices[client] = {}
			Await.getRemovedFromGameSignal(client):Connect(function()
				client_to_readyServices[client] = nil
			end)
		end

		return client_to_readyServices[client]
	end
	function getClientInitializedServices(client)
		if not client:IsDescendantOf(game) then
			return EMPTY_TABLE
		end
		if not client_to_initializedServices[client] then
			client_to_initializedServices[client] = {}
			Await.getRemovedFromGameSignal(client):Connect(function()
				client_to_initializedServices[client] = nil
			end)
		end

		return client_to_initializedServices[client]
	end
	function onClientReadied(client, serviceName)
		local readyServices = getClientReadyServices(client)
		if not readyServices[serviceName] then
			readyServices[serviceName] = true
			if DEBUG_MODE then
				warn("client readied", client, serviceName)
			end
		end
	end
	function onClientInitialized(client, serviceName)
		local initializedServices = getClientInitializedServices(client)
		if not initializedServices[serviceName] then
			initializedServices[serviceName] = true
			if DEBUG_MODE then
				warn("service initialized client", client, serviceName)
			end
		end
	end
	if RunService:IsServer() then
		remoteEvent.OnServerEvent:Connect(onClientReadied)
		script:SetAttribute("ServerLoaded", true)
	end
end
local function awaitClientReady(client, serviceName, timeout)
	assert(serviceName, "missing service name")

	timeout = timeout or DEFAULT_TIMEOUT

	local readyServices = getClientReadyServices(client)

	if not readyServices[serviceName] then
		local s = os.clock()

		while os.clock() - s < timeout do
			if readyServices[serviceName]  -- The client readied up
				or not client:IsDescendantOf(game) -- The client left
			then
				return false
			end

			task.wait()
		end

		return true
	else
		return false
	end
end
local function awaitServiceInitializedClient(client, serviceName, timeout)
	assert(serviceName, "missing service name")

	timeout = timeout or DEFAULT_TIMEOUT

	local timedOut = awaitClientReady(client, serviceName, timeout)
	if not timedOut then
		local initializedServices = getClientInitializedServices(client)

		if not initializedServices[serviceName] then
		local s = os.clock()

		while os.clock() - s < timeout do
			if initializedServices[serviceName]  -- The service initialized the client
				or not client:IsDescendantOf(game) -- The client left
			then
				return false
			end

			task.wait()
		end
			return true
		else
			return false
		end
	else
		return true
	end
end

--[[
  ClientReady.awaitClientReady(client, serviceName):andThen(function()
  
  end, warn)
]]
function ClientReady.awaitClientReady(client: Player, serviceName: string, timeout: number?)
	local traceback = debug.traceback()
	return Promise.new(function(resolve, reject)
		if not client:IsDescendantOf(game) then
			-- reject(`client [{client.Name}] is not in the game`)
			return
		end

		local timedOut = awaitClientReady(client, serviceName, timeout)
		if not timedOut then
			if client:IsDescendantOf(game) then
				resolve()
			else
				-- reject(`client [{client.Name}] left the game before readying service [{serviceName}]. Traceback:\n`, traceback)
			end
		else
			-- reject(`[{client.Name}] did not ready themselves for service [{serviceName}] after {timeout or DEFAULT_TIMEOUT} seconds. Traceback:\n`, traceback)
		end
	end)
end
function ClientReady.isClientReady(client: Player, serviceName: string)
	if not client:IsDescendantOf(game) then
		return false
	end
	local readyServices = getClientReadyServices(client)
	return readyServices[serviceName]
end

--[[
  ClientReady.awaitServiceInitializedClient(client, serviceName):andThen(function()
  
  end, warn)
]]
function ClientReady.awaitServiceInitializedClient(client: Player, serviceName: string, timeout: number?)
	local traceback = debug.traceback()
	return Promise.new(function(resolve, reject)
		if not client:IsDescendantOf(game) then
			-- reject(`client [{client.Name}] is not in the game`)
			return
		end

		local timedOut = awaitServiceInitializedClient(client, serviceName, timeout)
		if not timedOut then
			if client:IsDescendantOf(game) then
				resolve()
			else
				-- reject(`client [{client.Name}] left the game before service [{serviceName}] could initialize them. Traceback:\n`, traceback)
			end
		else
			-- reject(`service [{serviceName}] did not initialize client [{client.Name}] after {timeout or DEFAULT_TIMEOUT} seconds. Traceback:\n`, traceback)
		end
	end)
end
function ClientReady.setServiceInitializedClient(client: Player, serviceName: string)
	if not client:IsDescendantOf(game) then
		return
	end
  	onClientInitialized(client, serviceName)
end
function ClientReady.didServiceInitializeClient(client: Player, serviceName: string): boolean
	local initializedServices = getClientInitializedServices(client)
	return initializedServices[serviceName] == true
end

------------
-- CLIENT --
------------

-- Yields until the server has loaded (should rarely yield)
function ClientReady.fireReady(serviceName: string)
	if not script:GetAttribute("ServerLoaded") then
		script:GetAttributeChangedSignal("ServerLoaded"):Wait()
	end
	if DEBUG_MODE then
		print("firing server ready:", serviceName)
	end
	remoteEvent:FireServer(serviceName)
end

return ClientReady