local Signal = require(script.Parent.Signal)

local idToPlum = {}
local classNameToCache = {}

local function getClassNameCache(className)
	local classNameCache = classNameToCache[className]

	if not classNameCache then
		classNameCache = {}
		classNameToCache[className] = classNameCache
	end

	return classNameCache
end

local PlumsCache = {}

PlumsCache.PlumAddedSignal = Signal.new {
	OnObserve = function(handler)
		for k, v in PlumsCache.classNameToCache do
			for _, plum in v do
				task.spawn(handler, plum, true)
			end
		end
	end,
}

function PlumsCache.getPlum(plumId)
	return idToPlum[plumId]
end

function PlumsCache.addPlum(plum)
	idToPlum[plum.Id] = plum
	table.insert(getClassNameCache(plum.ClassName), plum)
	PlumsCache.PlumAddedSignal:Fire(plum)
end

function PlumsCache.removePlum(plum)
	if not idToPlum[plum.Id] then
		return
	end
	idToPlum[plum.Id] = nil
	local classNameCache = getClassNameCache(plum.ClassName)
	table.remove(classNameCache, table.find(classNameCache, plum))
end

function PlumsCache.getClassNameCache(className)
	return getClassNameCache(className)
end

PlumsCache.classNameToCache = classNameToCache
PlumsCache.idToPlum = idToPlum

return PlumsCache