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

		if type(v) == "table" and not v._isPlum then
			PathUtil.getPathsTo(v, needle, results, newPath, visited)
		end
	end

	return results
end

function PathUtil.getSubPaths(plum, pathArray)
	local oldValue = plum.Data
	local newValueParent = oldValue
	local subPaths = {{plum, nil, pathArray}}
	
	local n = #pathArray
	for i = 1, n do
		newValueParent = oldValue
		oldValue = oldValue[pathArray[i]]
		if i < n and oldValue._isPlum then
			table.insert(subPaths, {oldValue, i+1})
			oldValue = oldValue.Data
		end
	end

	for _, v in subPaths do
		if not v[3] then
			local start = v[2]
			local sub = table.create(n - start + 1)
			for i = start, n do
				sub[i - start + 1] = pathArray[i]
			end
			v[3] = sub
		end
		
		v[2] = table.concat(v[3], '.')
	end

	return subPaths, newValueParent, oldValue
end

function PathUtil.set(t, pathArray, newValue)
	for i = 1, #pathArray-1 do
		t = t[pathArray[i]]
		if t._isPlum then
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
		if t == nil then 
			return nil
		end
		if type(t) == "table" and t._isPlum and i ~= #pathArray then
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
		if n then 
			pathArray[i] = n
		end
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