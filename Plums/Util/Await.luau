-- v1.5.2

local Signal = require(script.Parent.Signal)

type EventWithSettingsType = {} -- {RBXScriptSignal, WinnerKey?, ...any?}
type TimeoutType = (number | RBXScriptSignal)?

local DEBUG_PRINTS = false
local WINNER_KEY_FLAG = "winner key"
local ALL_ARGUMENTS_CHECK_FLAG = "all arguments check"

local removed_from_game_signals = {}

local function isWinnerKey(t)
	if type(t) == "table" then
		return t[1] == WINNER_KEY_FLAG
	end
end

local function isAllArgumentsCheck(t)
	if type(t) == "table" then
		return t[1] == ALL_ARGUMENTS_CHECK_FLAG
	end
end

local function argsMatchParams(params, ...)
	local args = {...}
	
	for i, param in params do
		if isAllArgumentsCheck(param) then
			if not param[2](...) then
				return false
			end
		elseif type(param) == "function" then
			if not param(args[i]) then -- Typechecking
				return false
			end
		elseif param ~= args[i] then
			return false
		end
	end

	return true
end

local Await = {}

-- The typechecker is not required, but it adds more functionality
if script:FindFirstChild("t") then
	Await.t = require(script.t)
end

--[[

	(see Await.first() example)
	
]]
function Await.winnerKey(token)
	return {WINNER_KEY_FLAG, token}
end

function Await.allArgumentsCheck(fn)
	return {ALL_ARGUMENTS_CHECK_FLAG, fn}
end

--[[

	Fires when an object is parented to nil
	Fires immediately after '.Destroying'

]]
function Await.getRemovedFromGameSignal(obj): RBXScriptSignal
	if removed_from_game_signals[obj] then
		return removed_from_game_signals[obj]
	end

	local removedFromGameSignal = Signal.new()
	removed_from_game_signals[obj] = removedFromGameSignal

	local conns = {}
	local function fireRemoved()
		for _, v in conns do
			v:Disconnect()
		end

		removedFromGameSignal:Fire()
		removedFromGameSignal:DisconnectAll()

		removed_from_game_signals[obj] = nil
	end
	table.insert(conns, obj.AncestryChanged:Connect(function(child)
		if child == obj and not obj:IsDescendantOf(game) then
			fireRemoved()
		end
	end))
	table.insert(conns, obj.Destroying:Connect(function()
		task.defer(fireRemoved)
	end))

	return removedFromGameSignal
end

--[[
	
	local Players = game:GetService("Players")
	
	local timeoutDuration = nil -- The timeout duration is optional
	
	Await.args(timeoutDuration, Players.PlayerRemoving, function(player)
		return player.Name == "wrello"
	end)
	
	print("wrello left!")
	
]]
function Await.args(timeout: TimeoutType, event: RBXScriptSignal, ...: any): (boolean, ...any)
	local thread = coroutine.running()
	local params = {...}
	
	local conn, timeoutThread
	
	local function done(...)
		task.spawn(thread, ...)
		conn:Disconnect()
		if timeoutThread then
			pcall(task.cancel, timeoutThread) -- If we don't cancel this, it continues to hold a strong reference the connection, which contains a '_signal', which contains a '_connections'...
		end
	end
	
	conn = event:Connect(function(...)
		if argsMatchParams(params, ...) then
			done(false, ...)
		end
	end)

	if timeout then
		if type(timeout) == "number" then
			timeoutThread = task.delay(timeout, function()
				if conn.Connected then
					done(true)
				end
			end)
		else
			timeout:Once(function()
				if conn.Connected then
					done(true)
				end
			end)
		end
	end

	return coroutine.yield()
end

--[[
	
	local part = Instance.new("Part")
	part.Parent = workspace
	
	local timeoutDuration = 5 -- The timeout duration is optional
	
	local timedOut, hitPart = Await.event(timeoutDuration, part.Touched)
	
	if not timedOut then
		print("touched", hitPart)
	else
		print("did not touch anything after", timeoutDuration, "seconds")
	end
	
]]
function Await.event(timeout: TimeoutType, event: RBXScriptSignal): (boolean, ...any)
	local thread = coroutine.running()

	local conn, timeoutThread
	
	local function done(...)
		conn:Disconnect()
		task.spawn(thread, ...)
		if timeoutThread then
			pcall(task.cancel, timeoutThread) -- If we don't cancel this, it continues to hold a strong reference the connection, which contains a '_signal', which contains a '_connections'...
		end
	end
	
	conn = event:Connect(function(...)
		done(false, ...)
	end)

	if timeout then
		if type(timeout) == "number" then
			timeoutThread = task.delay(timeout, function()
				if conn.Connected then
					done(true)
				end
			end)
		else
			timeout:Once(function()
				if conn.Connected then
					done(true)
				end
			end)
		end
	end

	return coroutine.yield()
end

--[[
	
	local part = Instance.new("Part")
	part.Parent = workspace

	local eventRaceArgs = {
	
		{part.Destroying, Await.winnerKey("part destroyed")},
		
		{part.Touched, Await.winnerKey("touched by hrp"), function(hitPart)
			return hitPart.Name == "HumanoidRootPart"
		end},
		
		part:GetPropertyChangedSignal("Name") -- The winner key would default to 2 in this case (that's this event's position in the 'eventRaceArgs' table)
	
	}

	local timeoutDuration = nil -- The timeout duration is optional

	-- Wait for the first one to fire
	local timedOut, winnerKey, winnerArgs = Await.first(timeoutDuration, unpack(eventRaceArgs))
	
	
	-- Use this if you set the timeoutDuration to not nil
	
	--if not timedOut then
	--	print(winnerKey, "was the first event to fire! Passed args:", winnerArgs)
	--else
	--  print("no events fired after", timeoutDuration, "seconds")
	--end
	
	
	print(winnerKey, "was the first event to fire! Passed args:", ...)
	
]]
function Await.first(timeout: TimeoutType, ...: RBXScriptSignal | EventWithSettingsType): (boolean, number?, {any}?)
	local thread = coroutine.running()
	
	local conns, timeoutThread = {}, nil
	
	local t = os.clock()-10000

	local function done(...)
		if DEBUG_PRINTS then
			print(t, "[Await] race done with args:", ...)
		end

		for _, conn in conns do
			conn:Disconnect()
		end
		
		task.spawn(thread, ...)

		if timeoutThread then
			pcall(task.cancel, timeoutThread) -- MAYBE (might not be the case with 'conns[1]'): If we don't cancel this, it continues to hold a strong reference the connection, which contains a '_signal', which contains a '_connections'...
		end
	end
	
	for i, event in {...} do
		local conn
		
		if event.Connect then
			conn = event:Connect(function(...)
				done(false, i, {...})
			end)
		else
			local winnerKey = nil
			
			local params = {} do
				local len = #event
				for i = 2, len do
					if isWinnerKey(event[i]) then
						winnerKey = event[i][2]
					else
						table.insert(params, event[i])
					end
				end
			end
			
			if DEBUG_PRINTS then
				print(t, "[Await] connecting to event with required args:", event)
			end
			conn = event[1]:Connect(function(...)
				if DEBUG_PRINTS then
					print(t, "[Await] event fired sent args:", {...})
				end
				
				if argsMatchParams(params, ...) then
					if DEBUG_PRINTS then
						print(t, "[Await] args match params!")
					end
					
					done(false, winnerKey or i, {...})
				else
					if DEBUG_PRINTS then
						print(t, "[Await] args don't match params!")
					end
				end
			end)
			if DEBUG_PRINTS then
				print(t, "[Await] connected to event with required args:", event)
			end
		end

		table.insert(conns, conn)
	end

	if timeout then
		if type(timeout) == "number" then
			timeoutThread = task.delay(timeout, function()
				if conns[1].Connected then
					done(true)
				end
			end)
		else
			timeout:Once(function()
				if conns[1].Connected then
					done(true)
				end
			end)
		end
	end

	return coroutine.yield()
end

return Await