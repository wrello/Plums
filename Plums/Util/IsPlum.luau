local function IsPlum(t)
	if type(t) == "table" then
		return getmetatable(t) == require(script.Parent.PlumBase)
	else
		return false
	end
end

return IsPlum