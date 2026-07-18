local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {},
	}, Maid)
end

function Maid:Give(taskObject: any)
	table.insert(self._tasks, taskObject)
	return taskObject
end

function Maid:Clean()
	for _, taskObject in ipairs(self._tasks) do
		if typeof(taskObject) == "RBXScriptConnection" then
			taskObject:Disconnect()
		elseif typeof(taskObject) == "Instance" then
			taskObject:Destroy()
		elseif type(taskObject) == "function" then
			taskObject()
		elseif type(taskObject) == "table" and taskObject.Disconnect then
			taskObject:Disconnect()
		elseif type(taskObject) == "table" and taskObject.Destroy then
			taskObject:Destroy()
		end
	end

	table.clear(self._tasks)
end

return Maid
