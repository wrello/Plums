-- v2.2.1

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, handler, isOnce)
	return setmetatable({ 
		_signal = signal, 
		_isOnce = isOnce,
		Handler = handler, 
		Connected = true, 
	}, Connection)
end

function Connection:Disconnect()
	self.Connected = false
	local foundIdx = table.find(self._signal._connections, self)
	if foundIdx then
		table.remove(self._signal._connections, foundIdx)
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new(config: { OnObserve: (handler: (...any) -> ()) -> ()? }? )
	return setmetatable({ _connections = {}, _waitingThreads = {}, _config = config }, Signal)
end

function Signal:Wait(timeout: number?)
	local running = coroutine.running()
	table.insert(self._waitingThreads, running)
	if timeout then
		task.delay(timeout, function()
			local foundIndex = table.find(self._waitingThreads, running)
			if foundIndex then
				pcall(task.spawn, running, "timeout")
				table.remove(self._waitingThreads, foundIndex)
			end
		end)
	end
	return coroutine.yield()
end

function Signal:Connect(handler)
	local conn = Connection.new(self, handler)
	table.insert(self._connections, conn)
	return conn
end

-- Returns a connection object that can be immediately disconnected, but won't
-- actually be fireable until the next script resumption cycle
function Signal:ConnectDeferred(handler)
	local conn = Connection.new(self, handler)
	task.defer(function()
		if conn.Connected then
			table.insert(self._connections, conn)
		end
	end)
	return conn
end

function Signal:DisconnectAll()
	for _, conn in self._connections do
		conn.Connected = false
	end
	table.clear(self._connections)
end

-- Initial observer call and connection are both deferred in order to preserve
-- the intended execution order of observer before connection
function Signal:Observe(handler)
	task.defer(function() -- Allow the connection variable to be returned before the observer is called and potentially disconnects the connection
		if self._config and self._config.OnObserve then
			self._config.OnObserve(handler)
		else
			handler()
		end
	end)
	return self:ConnectDeferred(handler) -- Allows the handler to run first
end

function Signal:Once(handler)
	local conn = Connection.new(self, handler, true)
	table.insert(self._connections, conn)
	return conn
end

function Signal:Fire(...)
	-- Clone beforehand so things modifying them mid-loop don't cause side-effects
	local clonedWaitingThreads
	if #self._waitingThreads > 0 then
		clonedWaitingThreads = table.clone(self._waitingThreads)
		table.clear(self._waitingThreads)
	end
	local clonedConnections
	if #self._connections > 0 then
		clonedConnections = table.clone(self._connections)
	end
	
	if clonedWaitingThreads then
		for _, v in clonedWaitingThreads do
			task.spawn(v, ...)
		end
	end

	if clonedConnections then
		for _, v in clonedConnections do
			if v._isOnce then
				v:Disconnect()
			end
			task.spawn(v.Handler, ...)
		end
	end
end

function Signal:BindToInstance(instance)
	instance.Destroying:Connect(function()
		task.defer(function()
			self:DisconnectAll()
		end)
	end)
	return self
end

function Signal:Destroy()
	self:DisconnectAll()
	table.clear(self._waitingThreads)
end

return Signal