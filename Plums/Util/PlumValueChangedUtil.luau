local PathUtil = require(script.Parent.PathUtil)
local IsPlum = require(script.Parent.IsPlum)

local PlumValueChangedUtil = {}

local function collectEvents(t, path, data, out, newValue)
	local signal = t._signal
	if signal then
		local oldValue = PathUtil.get(data, path)

		if newValue ~= oldValue then
			table.insert(out, {signal, newValue, oldValue})
		end
	end

	for k, v in t do
		if k == "_signal" then
			continue
		end
		
		table.insert(path, k)

		collectEvents(v, path, data, out,
			if IsPlum(newValue) then
				newValue.Data
			elseif type(newValue) == "table" then
				newValue[k]
			else
				nil
		)
		
		path[#path] = nil
	end
end

-- Returns all the value changed signals that are triggered by setting 'plum[pathArray] = newValue' recursively
function PlumValueChangedUtil.getTriggeredValueChangedEvents(plum, changingPathArray, newValue)
	local listening = plum._valueChangedSignalTrie
	for _, v in changingPathArray do
		listening = listening[v]
		if not listening then -- Changing path goes deeper than listening path
			return {}
		end
	end
	
	local events = {}
	collectEvents(listening, changingPathArray, plum.Data, events, newValue)
	return events
end

function PlumValueChangedUtil.fireValueChangedSignals(signals)
	for _, v in signals do
        v[1]:Fire(v[2], v[3])
    end
end

return PlumValueChangedUtil