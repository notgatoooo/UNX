return newcclosure(function()
    local Maid = {}
    Maid.ClassName = "Maid"
    Maid.__index = Maid

    Maid.new = newcclosure(function()
        return setmetatable({
            _tasks = {},
            _destroyed = false,
        }, Maid)
    end)

    local cleanupTask = newcclosure(function(task)
        if not task then return end
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
    end)

    Maid.Give = newcclosure(function(self, key, task)
        if self._destroyed then
            cleanupTask(task)
            return
        end
        if self._tasks[key] then
            cleanupTask(self._tasks[key])
        end
        self._tasks[key] = task
        return task
    end)

    Maid.GiveTask = newcclosure(function(self, task)
        if self._destroyed then
            cleanupTask(task)
            return
        end
        table.insert(self._tasks, task)
        return task
    end)

    Maid.DoCleaning = newcclosure(function(self)
        if self._destroyed then return end
        self._destroyed = true
        for key, task in pairs(self._tasks) do
            cleanupTask(task)
            self._tasks[key] = nil
        end
        self._destroyed = false
    end)

    Maid.Destroy = newcclosure(function(self)
        self._destroyed = true
        for key, task in pairs(self._tasks) do
            cleanupTask(task)
            self._tasks[key] = nil
        end
    end)

    return Maid
end)
