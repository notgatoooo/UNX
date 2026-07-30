local Maid = {}
Maid.ClassName = "Maid"
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {},
		_destroyed = false,
	}, Maid)
end

local function cleanupTask(task)
	if not task then
		return
	end

	local t = typeof(task)

	if t == "RBXScriptConnection" then
		task:Disconnect()
	elseif t == "Instance" then
		task:Destroy()
	elseif type(task) == "function" then
		task()
	elseif type(task) == "table" and type(task.Destroy) == "function" then
		task:Destroy()
	end
end

function Maid:Give(key, task)
	if self._destroyed then
		cleanupTask(task)
		return
	end

	if self._tasks[key] then
		cleanupTask(self._tasks[key])
	end

	self._tasks[key] = task
	return task
end

function Maid:GiveTask(task)
	if self._destroyed then
		cleanupTask(task)
		return
	end

	table.insert(self._tasks, task)
	return task
end

function Maid:DoCleaning()
	if self._destroyed then
		return
	end

	self._destroyed = true

	for key, task in pairs(self._tasks) do
		cleanupTask(task)
		self._tasks[key] = nil
	end
end

function Maid:Destroy()
	self:DoCleaning()
end

return Maid
