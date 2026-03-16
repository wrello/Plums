local PathUtil = require(script.Parent.PathUtil)

local PlumValueChangedUtil = {}

local function collectEvents(t, path, out, newValue, oldValue)
	local signal = t._signal
	if signal then
		if newValue ~= oldValue then
			table.insert(out, {signal, newValue, oldValue})
		end
	end

	for k, v in t do
		if k == "_signal" then
			continue
		end
		
		table.insert(path, k)

		--[[
		
			-- Old
			Data = {T = {A = {B = {}}}}
			
			-- Listening
			.ValueChanged({"T", "A", "B"})
		
			-- New
			:Set({"T", "A"}, nil)


			[ Recursion Diagram ]
			
			newValue : New[depth + 1]
			oldValue : Old[depth + 1]
			
			Depth 0

			newValue = T
			oldValue = T

			Listening		New			Old
			
				T <-		 T			 T
				|			 |			 |
				A			 A = nil	 A
				|			 			 |
				B			 			 B
		
			Depth 1

			newValue = nil
			oldValue = A
		
			Listening		New			Old
			
				T   		 T			 T
				|			 |			 |
				A <-		 A = nil	 A
				|			 			 |
				B			 			 B
				
			Depth 2

			newValue = nil
			oldValue = B
		
			Listening		New			Old
			
				T   		 T			 T
				|			 |			 |
				A 			 A = nil	 A
				|			 			 |
				B <-			 		 B
		
		]]

		collectEvents(v, path, out,
			if type(newValue) == "table" then
				if newValue._isPlum then
					newValue.Data[k]
				else
					newValue[k]
			else
				nil,
			if type(oldValue) == "table" then
				if oldValue._isPlum then
					oldValue.Data[k]
				else
					oldValue[k]
			else
				nil
		)
		
		path[#path] = nil
	end
end

-- Returns all the value changed signals that are triggered by setting 'plum[pathArray] = newValue' recursively
function PlumValueChangedUtil.getTriggeredValueChangedEvents(plum, pathArray, newValue)
	local listening = plum._valueChangedSignalTrie
	local oldValue = plum.Data
	for _, v in pathArray do
		listening = listening[v]
		if not listening then -- Changing path goes deeper than listening path
			return {}
		end
		oldValue = oldValue[v]
		if type(oldValue) == "table" and oldValue._isPlum then
			oldValue = oldValue.Data
		end
	end
	
	local events = {}
	collectEvents(listening, pathArray, events, newValue, oldValue)
	return events
end

function PlumValueChangedUtil.fireValueChangedSignals(signals)
	for _, v in signals do
        v[1]:Fire(v[2], v[3])
    end
end

return PlumValueChangedUtil