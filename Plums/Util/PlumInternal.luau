local RunService = game:GetService("RunService")

local PathUtil = require(script.Parent.PathUtil)
local PlumValueChangedUtil = require(script.Parent.PlumValueChangedUtil)
local PlumsCache = require(script.Parent.PlumsCache)

local EMPTY_FN = function() end

local PlumInternal = {}
PlumInternal.__index = PlumInternal

function PlumInternal:_updateBubbleEventsTo(plum)
	local paths = PathUtil.getPathsTo(plum.Data, self)
	if #paths > 0 then
		self._bubbleTo[plum][2] = paths
	else
		self:_stopBubbleEventsTo(plum)
	end
end

function PlumInternal:_bubbleEventsTo(plum)
	if not self._bubbleTo[plum] then
		self._bubbleTo[plum] = {plum.Destroyed:Connect(function()
			self._bubbleTo[plum] = nil
		end), PathUtil.getPathsTo(plum.Data, self)}
	else -- Update paths to
		self._bubbleTo[plum][2] = PathUtil.getPathsTo(plum.Data, self)
	end
	return self
end

function PlumInternal:_stopBubbleEventsTo(plum)
	if self._bubbleTo[plum] then
		self._bubbleTo[plum][1]:Disconnect()
		self._bubbleTo[plum] = nil
	end
end

function PlumInternal:_setValueInternal(pathArray, newValue)
	-- Get old value and hit sub-plums in the path
	local subPaths, targetTable, oldValue = PathUtil.getSubPaths(self, pathArray)

	local eventQueue = {}

	local isQueued = {}
	local function queueEvents(plum, pathString, pathArray)
		local plumQueued = isQueued[plum]
		if not plumQueued then
			plumQueued = {}
			isQueued[plum] = plumQueued
		end

		if not plumQueued[pathString] then
			plumQueued[pathString] = true

			pathArray = pathArray or PathUtil.toArray(pathString)

			-- Fire all signals post-set
			table.insert(eventQueue, {
				plum, 
				pathArray, 
				PlumValueChangedUtil.getTriggeredValueChangedEvents(plum, pathArray, newValue)
			})
		end
	end

	-- Collect the 'plum.Event'(s) for all sub-plums, bottom-up
	for i = #subPaths, 1, -1 do
		local plum, pathString, pathArray = subPaths[i][1], subPaths[i][2], subPaths[i][3]

		queueEvents(plum, pathString, pathArray)

		-- Bubble events upward (breadth first)
		if next(self._bubbleTo) then
			local queue = {{plum, pathString}}
			local head = 1
			while head <= #queue do
				local plum, pathToVal = queue[head][1], queue[head][2]
				head += 1
				for bubblePlum, t in plum._bubbleTo do
					for _, pathToUs in t[2] do
						local prepended = pathToUs .. '.' .. pathToVal
						queueEvents(bubblePlum, prepended)
						table.insert(queue, {bubblePlum, prepended})
					end
				end
			end
		end
	end

	-- Set the 'newValue' once for all sub-plums
	targetTable[pathArray[#pathArray]] = newValue

	-- Fire events
	for _, v in eventQueue do
		PlumValueChangedUtil.fireValueChangedSignals(v[3])
		v[1].OnRaw:Fire("SetValue", v[2], newValue, oldValue)
	end
	
	return oldValue, subPaths
end

function PlumInternal:_arrayInsertInternal(pathArray, newValue, index)
	index = index or #PathUtil.get(self.Data, pathArray)+1

	-- Get old value and hit sub-plums in the path
	local subPaths, targetTable = PathUtil.getSubPaths(self, pathArray)
	targetTable = targetTable[pathArray[#pathArray]]

	local eventQueue = {}

	local isQueued = {}
	local function queueEvents(plum, pathString, pathArray)
		local plumQueued = isQueued[plum]
		if not plumQueued then
			plumQueued = {}
			isQueued[plum] = plumQueued
		end

		if not plumQueued[pathString] then
			plumQueued[pathString] = true

			pathArray = pathArray or PathUtil.toArray(pathString)
			table.insert(pathArray, index)

			-- Fire all signals post-set
			table.insert(eventQueue, {
				plum, 
				pathArray, 
				PlumValueChangedUtil.getTriggeredValueChangedEvents(plum, pathArray, newValue), 
				plum._path_to_signal["OnArrayInsert"][pathString]
			})
			
			pathArray[#pathArray] = nil
		end
	end

	-- Collect the 'plum.Event'(s) for all sub-plums, bottom-up
	for i = #subPaths, 1, -1 do
		local plum, pathString, pathArray = subPaths[i][1], subPaths[i][2], subPaths[i][3]

		queueEvents(plum, pathString, pathArray)

		-- Bubble events upward
		if next(self._bubbleTo) then
			local queue = {{plum, pathString}}
			local head = 1
			while head <= #queue do
				local plum, pathToVal = queue[head][1], queue[head][2]
				head += 1
				for bubblePlum, t in plum._bubbleTo do
					for _, pathToUs in t[2] do
						local prepended = pathToUs .. '.' .. pathToVal
						queueEvents(bubblePlum, prepended)
						table.insert(queue, {bubblePlum, prepended})
					end
				end
			end
		end
	end

	-- Insert the 'newValue' once for all sub-plums
	table.insert(targetTable, index, newValue)

	-- Fire events
	for _, v in eventQueue do
		if v[4] then
			v[4]:Fire(newValue, index)
		end

		PlumValueChangedUtil.fireValueChangedSignals(v[3])
		v[1].OnRaw:Fire("OnArrayInsert", v[2], newValue, index)
	end

	return subPaths, index
end

function PlumInternal:_arrayRemoveInternal(pathArray, index)
	local subPaths, targetTable, oldValue = PathUtil.getSubPaths(self, pathArray)
	targetTable = targetTable[pathArray[#pathArray]]
	oldValue = oldValue[index]

	local eventQueue = {}

	local isQueued = {}
	local function queueEvents(plum, pathString, pathArray)
		local plumQueued = isQueued[plum]
		if not plumQueued then
			plumQueued = {}
			isQueued[plum] = plumQueued
		end

		if not plumQueued[pathString] then
			plumQueued[pathString] = true

			pathArray = pathArray or PathUtil.toArray(pathString)
			table.insert(pathArray, index)

			-- Fire all signals post-set
			table.insert(eventQueue, {
				plum, 
				pathArray, 
				PlumValueChangedUtil.getTriggeredValueChangedEvents(plum, pathArray, nil), 
				plum._path_to_signal["OnArrayRemove"][pathString]
			})
			
			pathArray[#pathArray] = nil
		end
	end

	-- Collect the 'plum.Event'(s) for all sub-plums, bottom-up
	for i = #subPaths, 1, -1 do
		local plum, pathString, pathArray = subPaths[i][1], subPaths[i][2], subPaths[i][3]

		queueEvents(plum, pathString, pathArray)

		-- Bubble events upward
		if next(self._bubbleTo) then
			local queue = {{plum, pathString}}
			local head = 1
			while head <= #queue do
				local plum, pathToVal = queue[head][1], queue[head][2]
				head += 1
				for bubblePlum, t in plum._bubbleTo do
					for _, pathToUs in t[2] do
						local prepended = pathToUs .. '.' .. pathToVal
						queueEvents(bubblePlum, prepended)
						table.insert(queue, {bubblePlum, prepended})
					end
				end
			end
		end
	end

	-- Remove the the value at 'index' once for all sub-plums
	table.remove(targetTable, index)

	-- Fire events
	for _, v in eventQueue do
		if v[4] then
			v[4]:Fire(oldValue, index)
		end

		PlumValueChangedUtil.fireValueChangedSignals(v[3])
		v[1].OnRaw:Fire("OnArrayRemove", v[2], oldValue, index)
	end

	return oldValue, subPaths
end

function PlumInternal:_destroyInternal()
	self.IsDestroyed = true

	PlumsCache.removePlum(self)

	self.Destroyed:Fire()

	-- Add empty methods to prevent errors
	for k, v in self do
		if type(v) == "function" then
			self[k] = EMPTY_FN
		end
	end

	-- Disconnect all internal connections in this plum and external connections to this plum
	self._maid:Destroy()
end

return PlumInternal