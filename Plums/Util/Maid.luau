-- v2.1.0

local function CustomAssert(check, ...)
	if not check then
		print("ERROR:", ...)
		error("read above message for information")
	end
end

-- Unsafe because it yields without a pcall
local function unsafeCleanThing(thing)
	local type = typeof(thing)

	if type == "Instance" then
		if thing:IsA("AnimationTrack") then
			if thing.IsPlaying then
				thing:Stop()
			end
		else
			thing:Destroy()
		end
	elseif type == "RBXScriptConnection" or (type == "table" and thing.Disconnect) then
		if thing.Connected then
			thing:Disconnect()
		end
	elseif type == "table" then
		if thing.Destroy then
			thing:Destroy()
		else
			thing:destroy()
		end
	elseif type == "function" then
		thing()
	elseif type == "thread" then
		pcall(task.cancel, thing)
	end
end

local function safeCleanThing(thing)
	task.spawn(function()
		pcall(unsafeCleanThing, thing)
	end)
end

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _dictionary = {}, _array = {}, _keys = {} }, Maid)
end

function Maid:BindToInstance(instance: Instance): Instance
	self:Add(instance.Destroying:Connect(function()
		self:Destroy()
	end))

	return self
end

--[[

	Warning: Memory leaks can still be created if we keep adding things and
	never remove them from the maid. The maid will automatically remove
	*instances* when they get '.Destroyed' to help with
	this problem.

]]
function Maid:Add(thing: any, canClean: ((thing: any) -> (boolean))?, key: any?)
	CustomAssert(thing, "Maid -", thing, "is not a valid object to add to maid")

	local foundValue = self._dictionary[thing]
	if not foundValue then
		local key = key or newproxy()

		local v = {thing, canClean, key}

		self._keys[key] = thing
		self._dictionary[thing] = v
		table.insert(self._array, v)

		if typeof(thing) == "Instance" then -- Auto remove once destroyed
			local _, connectionKey; connectionKey = self:Add(thing.Destroyed:Connect(function()
				self:Remove(key)
				self:Remove(connectionKey) -- Make sure to also remove the reference to the connection that we're holding in this maid
			end))
		end

		return thing, key
	end

	return thing, foundValue[3]
end

function Maid:Find(key: any): any?
	return self._keys[key]
end

function Maid:Remove(key: any): any
	local thing = self._keys[key]
	if thing == nil then
		return
	end
	self._keys[key] = nil
	self._dictionary[thing] = nil
	for i, v in self._array do
		if v[1] == thing then
			table.remove(self._array, i)
			break
		end
	end
	return thing
end

function Maid:Clean()
	if self._cleaning then -- Can happen if one of the added functions calls `maid:Clean()` triggering recursion
		return
	end
	self._cleaning = true

	for _, v in self._array do
		if type(v[2]) == "function" then
			local predicateCo = coroutine.create(v[2])

			local ok, result = coroutine.resume(predicateCo)
			if coroutine.status(predicateCo) == "suspended" then
				error("Maid 'canClean' predicate must not yield for thing", v)
			end

			if not ok then
				warn("Maid failed to run 'canClean' predicate for thing", v, ":", result, "Not cleaning.")
			end

			if ok and result then
				safeCleanThing(v[1])
			end
		else
			safeCleanThing(v[1])
		end
	end

	table.clear(self._dictionary)
	table.clear(self._array)
	table.clear(self._keys)

	self._cleaning = false
end

function Maid:Destroy()
	self:Clean()
end

Maid.IfNotDestroyed = function(v)
	return function()
		return v:IsDescendantOf(game)
	end
end

return Maid