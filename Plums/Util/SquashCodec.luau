local Squash = require(script.Parent.Squash)
local BufferEncoder = require(script.Parent.BufferEncoder)

-- Ser
local SQ_CURSOR = Squash.cursor
local SQ_TO_BUF = Squash.tobuffer
local SQ_STR_SER = Squash.string().ser
local SQ_STR_ARR_SER = Squash.array(Squash.string()).ser
local SQ_U32_SER = Squash.uint(4).ser

-- Des
local SQ_FROM_BUF = Squash.frombuffer
local SQ_STR_DES = Squash.string().des
local SQ_STR_ARR_DES = Squash.array(Squash.string()).des
local SQ_U32_DES = Squash.uint(4).des

local arrayMethods = {
	Serialize = function(methodName, plumId, args)
		local pathString, index = table.remove(args, 1), table.remove(args, 1)
		
		local cursor = SQ_CURSOR()
		SQ_U32_SER(cursor, index)
		SQ_STR_SER(cursor, pathString)
		SQ_U32_SER(cursor, plumId)
		SQ_STR_SER(cursor, methodName)
		return SQ_TO_BUF(cursor), unpack(args)
	end,
	Deserialize = function(cursor)
		local pathString = SQ_STR_DES(cursor)
		local index = SQ_U32_DES(cursor)
		
		return pathString, index
	end,
}

local methodNameAndPlumId = {
	Serialize = function(methodName, plumId, args)
		local cursor = SQ_CURSOR()
		SQ_U32_SER(cursor, plumId)
		SQ_STR_SER(cursor, methodName)
		return SQ_TO_BUF(cursor), unpack(args)
	end,
	-- Don't need a deserialize for this because the client does it manually in order to extract the method name to use in the first place
}

return {
	["ArrayInsert"] = arrayMethods,
	["ArrayRemove"] = arrayMethods,
	["SetValue"] = {
		Serialize = function(methodName, plumId, args)
			local pathString = table.remove(args, 1)
			
			local cursor = SQ_CURSOR()
			SQ_STR_SER(cursor, pathString)
			SQ_U32_SER(cursor, plumId)
			SQ_STR_SER(cursor, methodName)
			return SQ_TO_BUF(cursor), unpack(args)
		end,
		Deserialize = function(cursor)
			local pathString = SQ_STR_DES(cursor)
			
			return pathString
		end,
	},
	["AddClients"] = methodNameAndPlumId,
	["Broadcast"] = methodNameAndPlumId,
	["RemoveClients"] = methodNameAndPlumId,
	["Destroy"] = methodNameAndPlumId,
}
