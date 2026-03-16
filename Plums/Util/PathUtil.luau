local IsPlum = require(script.Parent.IsPlum)

local PathUtil = {}

function PathUtil.getPathsTo(parent, needle, results, currentPath, visited)
	results = results or {}
	visited = visited or {}

	if visited[parent] then
		return results
	end
	visited[parent] = true

	for k, v in parent do
		local newPath = (currentPath and currentPath .. '.' or "") .. k

		if v == needle then
			table.insert(results, newPath)
		end

		if type(v) == "table" and not IsPlum(v) then
			PathUtil.getPathsTo(v, needle, results, newPath, visited)
		end
	end

	return results
end

function PathUtil.doesContain(t, needle, visited)
	visited = visited or {}

	if visited[t] then
		return false
	end
	visited[t] = true

	for _, v in t do
		local doesContain = v == needle
			or IsPlum(v) and PathUtil.doesContain(v.Data, needle, visited)
			or type(v) == "table" and PathUtil.doesContain(v, needle, visited)

		if doesContain then
			return true
		end
	end

	return false
end

function PathUtil.getSubPaths(plum, pathArray)
	local t = plum.Data
	local subPaths = {{plum, 1}}

	for i = 1, #pathArray do
		t = t[pathArray[i]]
		if IsPlum(t) then
			if i < #pathArray then
				table.insert(subPaths, {t, i+1})
			end
			t = t.Data
		end
	end

	local n = #pathArray
	for _, v in subPaths do
		v[2] = table.concat(pathArray, ".", v[2], n)
	end

	return subPaths
end

function PathUtil.set(t, pathArray, newValue)
	for i = 1, #pathArray-1 do
		t = t[pathArray[i]]
		if IsPlum(t) then
			t = t.Data
		end
	end
	
	t[pathArray[#pathArray]] = newValue
end

function PathUtil.ensure(t, pathArray, newValue)
	for i = 1, #pathArray - 1 do
		local key = pathArray[i]
		if t[key] == nil then
			t[key] = {}
		end
		t = t[key]
	end
	t[pathArray[#pathArray]] = newValue
end

function PathUtil.get(t, pathArray)
	for i, token in pathArray do
		t = t[token]
		if t == nil then return nil end
		if IsPlum(t) and i ~= #pathArray then
			t = t.Data
		end
	end

	return t
end

local toArrayCache = {}
function PathUtil.toArray(pathString)
	local cached = toArrayCache[pathString]
	if cached then 
		return cached 
	end
	
	local pathArray = string.split(pathString, ".")
	for i, v in pathArray do
		local n = tonumber(v)
		if n then pathArray[i] = n end
	end
	
	toArrayCache[pathString] = pathArray
	
	return pathArray
end

function PathUtil.toString(pathArray)
	return table.concat(pathArray, ".")
end

function PathUtil.remove(t, pathArray, index)
	local arr = PathUtil.get(t, pathArray)
	table.remove(arr, index)
end

function PathUtil.insert(t, pathArray, index, newValue)
	local arr = PathUtil.get(t, pathArray)
	table.insert(arr, index, newValue)
end

return PathUtil