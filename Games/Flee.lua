local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local BaseUrl = "https://api.getunx.cc/Games/FTF/"

local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

Library.ForceCheckbox = true

local function SafeCallback(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        return false, result
    end
    return true, result
end

local request = http_request or request or (http and http.request)

local TotalModules = 7
local LoadedModules = 0

local LoadNotif = Library:Notify({
    Title = "Loading UNXHub",
    Description = "Initializing...",
    Steps = TotalModules,
    Persist = true
})

local function unxgmfu(url, ...)
    local fileName = url:match("^.+/(.+)$") or url
    
    if LoadNotif then
        LoadNotif:ChangeDescription("Fetching " .. fileName)
    end

    local success, response = pcall(request, {Url = url, Method = "GET"})
    
    if not success or not response or not response.Body then
        if LoadNotif then LoadNotif:ChangeDescription("Failed to fetch " .. fileName) end
        return nil
    end

    local chunk, loadErr = loadstring(response.Body)
    if not chunk then
        if LoadNotif then LoadNotif:ChangeDescription("Syntax Error in " .. fileName) end
        return nil
    end

    local chunkSuccess, moduleFunc = SafeCallback(chunk)
    if not chunkSuccess then
        if LoadNotif then LoadNotif:ChangeDescription("Init Error in " .. fileName) end
        return nil
    end

    if type(moduleFunc) ~= "function" then
        if LoadNotif then LoadNotif:ChangeDescription(fileName .. " invalid return") end
        return nil
    end

    local runSuccess, runResult = SafeCallback(moduleFunc, ...)
    if not runSuccess then
        if LoadNotif then LoadNotif:ChangeDescription("Runtime Error in " .. fileName) end
        return nil
    else
        LoadedModules = LoadedModules + 1
        if LoadNotif then
            LoadNotif:ChangeStep(LoadedModules)
            LoadNotif:ChangeDescription("Loaded " .. fileName)
            
            if LoadedModules >= TotalModules then
                LoadNotif:ChangeTitle("Finished")
                LoadNotif:ChangeDescription("All modules loaded successfully!")
                task.delay(2, function()
                    if LoadNotif then LoadNotif:Destroy() end
                end)
            end
        end
        return runResult
    end
end

local MaidClass = unxgmfu(BaseUrl .. "maid.m.luau.txt")
if not MaidClass then return end

local Translator = unxgmfu(BaseUrl .. "translator.m.luau.txt")
if Translator then
    Translator.Init()
end

local Window = Library:CreateWindow({
    Title = "UNXHub | FTF",
    Footer = "Version: " .. (getgenv().unxshared and getgenv().unxshared.version or "Unknown") .. ", Game: " .. (getgenv().unxshared and getgenv().unxshared.gamename or "Unknown") .. ", Player: " .. (getgenv().unxshared and getgenv().unxshared.playername or "Unknown"),
    Icon = 71059178349921,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local T = Translator.T
local Tabs = {
    Main = Window:AddTab(T("Main"), "user"),
    Visuals = Window:AddTab(T("Visuals"), "eye"),
    Features = Window:AddTab(T("Features"), "bug"),
    ["UI Settings"] = Window:AddTab(T("UI Settings"), "settings"),
}

local RootMaid = MaidClass.new()
local RunService = game:GetService("RunService")

local CacheManager = {
    Computers = {},
    Pods = {},
    Exits = {}
}

CacheManager.Update = newcclosure(function(self)
    local pcs = {}
    local pods = {}
    local exits = {}

    local descendants = workspace:GetDescendants()
    for i = 1, #descendants do
        local obj = descendants[i]
        if obj:IsA("Model") then
            if obj.Name == "ComputerTable" then
                local screen = obj:FindFirstChild("Screen")
                if screen and screen:IsA("BasePart") then
                    table.insert(pcs, obj)
                end
            elseif obj.Name == "FreezePod" or obj.Name == "Freeze Pod" then
                table.insert(pods, obj)
            end
        elseif obj:IsA("BasePart") and obj.Name == "ExitDoorTrigger" then
            table.insert(exits, obj)
        end
    end

    self.Computers = pcs
    self.Pods = pods
    self.Exits = exits
end)

CacheManager:Update()

local Scheduler = unxgmfu(BaseUrl .. "scheduler.m.luau.txt", Library, Tabs, RootMaid, CacheManager, MaidClass)

if Scheduler then
    RootMaid:GiveTask(Scheduler.Interval(5, newcclosure(function()
        CacheManager:Update()
    end)))
end

unxgmfu(BaseUrl .. "main.t.luau.txt", Library, Tabs, RootMaid, CacheManager, MaidClass, Scheduler, Translator)
unxgmfu(BaseUrl .. "visuals.t.luau.txt", Library, Tabs, RootMaid, CacheManager, MaidClass, Scheduler, Translator)
unxgmfu(BaseUrl .. "features.t.luau.txt", Library, Tabs, RootMaid, CacheManager, MaidClass, Scheduler, Translator)
unxgmfu(BaseUrl .. "uisettings.t.luau.txt", Library, Tabs, RootMaid, SaveManager, ThemeManager, Translator, Scheduler)

Library:OnUnload(newcclosure(function()
    if getgenv().unxshared then getgenv().unxshared.isloaded = false end
    RootMaid:Destroy()
    Library.Unloaded = true
end))
