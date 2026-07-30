local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Config = {
    TweenSpeed = 250,
    SafeDistance = 35, 
    CampTime = 10,
    HideDepth = 60,
    RestTime = 15,
    DoorTime = 12.7,
    TargetColor = Color3.fromRGB(40, 127, 71),
    OccupiedCheckDist = 4,
    
    BeastHighlightColor = Color3.fromRGB(255, 0, 0),
    PCHighlightColor = Color3.fromRGB(0, 255, 0)
}

local State = {
    IsRunning = true,
    CurrentTween = nil,
    IsHiding = false,
    IsResting = false,
    OriginalY = nil,
    Escaped = false,
    CurrentTargetPC = nil,
    Blacklist = {},
    LastBeast = nil,
    Highlights = {PC = nil, Beast = nil},
    Status = "Idle",
    PCsDone = 0
}

local function Notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            ["Title"] = "UNXHub",
            ["Text"] = text,
            ["Duration"] = 5,
            ["Icon"] = "rbxassetid://72316072514229"
        })
    end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "igui"
if pcall(function() ScreenGui.Parent = CoreGui end) then
else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local InfoFrame = Instance.new("Frame")
InfoFrame.Name = "InfoFrame"
InfoFrame.Parent = ScreenGui
InfoFrame.BackgroundTransparency = 1
InfoFrame.BorderSizePixel = 0
InfoFrame.Position = UDim2.new(0.01, 0, 0.05, 0) 
InfoFrame.Size = UDim2.new(0.25, 0, 0.25, 0) 

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = InfoFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left 

local function CreateLabel(order, defaultText)
    local lab = Instance.new("TextLabel")
    lab.Parent = InfoFrame
    lab.BackgroundTransparency = 1
    lab.Size = UDim2.new(1, 0, 0.2, 0) 
    lab.Font = Enum.Font.GothamBold 
    lab.TextColor3 = Color3.fromRGB(255, 255, 255)
    lab.TextScaled = true 
    lab.TextXAlignment = Enum.TextXAlignment.Left 
    lab.Text = defaultText
    lab.LayoutOrder = order
    lab.TextStrokeTransparency = 0.5 
    lab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    return lab
end

local StatusLabel = CreateLabel(1, "Status: Idle")
local PCLabel = CreateLabel(2, "PCs Done: 0")
local SpeedLabel = CreateLabel(3, "Tween Speed: " .. Config.TweenSpeed)
local BeastLabel = CreateLabel(4, "Beast: None")

local function UpdateOverlay()
    StatusLabel.Text = "Status: " .. State.Status
    PCLabel.Text = "PCs Done: " .. State.PCsDone
    SpeedLabel.Text = "Tween Speed: " .. Config.TweenSpeed
    
    local beast = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and (p.Character:FindFirstChild("Hammer") or p.Character:FindFirstChild("BeastPowers")) then
            beast = p.Name
            break
        end
    end
    BeastLabel.Text = "Beast: " .. (beast or "None")
end

local function EnableAntiError()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if method == "FireServer" and args[1] == "SetPlayerMinigameResult" then
            args[2] = true
            return oldNamecall(self, unpack(args))
        end
        return oldNamecall(self, ...)
    end)
end
EnableAntiError()

RunService.Stepped:Connect(function()
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    UpdateOverlay()
end)

local function ClearHighlight(key)
    if State.Highlights[key] then
        if State.Highlights[key].Parent then State.Highlights[key]:Destroy() end
        State.Highlights[key] = nil
    end
end

local function CreateHighlight(target, color, key)
    if not target then return end
    if State.Highlights[key] and State.Highlights[key].Parent ~= target then
        ClearHighlight(key)
    end
    if not State.Highlights[key] then
        local hl = Instance.new("Highlight")
        hl.Name = "UNXHighlight_" .. key
        hl.FillColor = color
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Adornee = target
        hl.Parent = target
        State.Highlights[key] = hl
    end
end

local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function IsPlayerBeast(player)
    if not player or not player.Character then return false end
    return player.Character:FindFirstChild("Hammer") ~= nil or player.Character:FindFirstChild("BeastPowers") ~= nil
end

local function IsPCCompleted(model)
    if not model then return false end
    local success, result = pcall(function()
        local screen = model:FindFirstChild("Screen")
        if screen and screen:IsA("BasePart") then
            local c = screen.Color
            local t = Config.TargetColor
            if math.abs((c.R * 255) - (t.R * 255)) < 8 and
               math.abs((c.G * 255) - (t.G * 255)) < 8 and
               math.abs((c.B * 255) - (t.B * 255)) < 8 then
                return true
            end
        end
        return false
    end)
    return success and result
end

local function GetBeastPlayer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsPlayerBeast(p) then return p end
    end
    return nil
end

local function GetBeastLocation()
    local beast = GetBeastPlayer()
    if beast and beast.Character then
        if State.LastBeast ~= beast then
            ClearHighlight("Beast")
            State.LastBeast = beast
        end
        CreateHighlight(beast.Character, Config.BeastHighlightColor, "Beast")
        return beast.Character:GetPivot().Position
    else
        ClearHighlight("Beast")
    end
    return nil
end

local function IsPositionOccupied(targetPos)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = player.Character.HumanoidRootPart.Position
            if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude < Config.OccupiedCheckDist then
                return true
            end
        end
    end
    return false
end

local function GetAvailableTrigger(model)
    if not model then return nil end
    local triggers = {}
    if model:FindFirstChild("ComputerTrigger1") then table.insert(triggers, model.ComputerTrigger1) end
    if model:FindFirstChild("ComputerTrigger2") then table.insert(triggers, model.ComputerTrigger2) end
    if model:FindFirstChild("ComputerTrigger3") then table.insert(triggers, model.ComputerTrigger3) end

    for i = #triggers, 2, -1 do
        local j = math.random(i)
        triggers[i], triggers[j] = triggers[j], triggers[i]
    end

    for _, trigger in ipairs(triggers) do
        -- Removed the Occupied check that was causing errors
        if not IsPositionOccupied(trigger.Position) then
            return trigger.Position
        end
    end
    return nil 
end

local function GetNearestIncompletePC()
    local root = GetRoot()
    if not root then return nil end
    local nearest, minDst = nil, math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "ComputerTable" and obj:IsA("Model") then
            local isBlacklisted = false
            for _, bPC in ipairs(State.Blacklist) do
                if bPC == obj then isBlacklisted = true break end
            end
            
            if not isBlacklisted and not IsPCCompleted(obj) then
                if GetAvailableTrigger(obj) ~= nil then
                    local dist = (obj:GetPivot().Position - root.Position).Magnitude
                    if dist < minDst then minDst = dist nearest = obj end
                end
            end
        end
    end
    return nearest
end

local function GetExitDoor()
    local root = GetRoot()
    if not root then return nil end
    local nearest, minDst = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "ExitDoor" and obj:IsA("Model") then
            local dist = (obj:GetPivot().Position - root.Position).Magnitude
            if dist < minDst then minDst = dist nearest = obj end
        end
    end
    return nearest
end

local function CancelAction()
    if State.CurrentTween then
        State.CurrentTween:Cancel()
        State.CurrentTween = nil
    end
end

local function PerformTween(targetPos)
    local root = GetRoot()
    if not root then return end
    CancelAction()
    
    local dist = (root.Position - targetPos).Magnitude
    local time = dist / Config.TweenSpeed
    local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)
    
    State.CurrentTween = TweenService:Create(root, ti, {CFrame = CFrame.new(targetPos)})
    State.CurrentTween:Play()

    local completed = false
    local conn
    conn = State.CurrentTween.Completed:Connect(function()
        completed = true
        conn:Disconnect()
    end)
    return function() return completed end
end

local function TweenHide(root)
    if State.IsHiding then return end
    if not State.OriginalY then State.OriginalY = root.Position.Y end
    State.IsHiding = true
    CancelAction()
    
    local hidePos = Vector3.new(root.Position.X, State.OriginalY - Config.HideDepth, root.Position.Z)
    local checkDone = PerformTween(hidePos)
    while not checkDone() do task.wait() end
    root.Anchored = true
end

local function TweenUnhide(root)
    if not State.IsHiding then return end
    root.Anchored = false
    local targetY = State.OriginalY or (root.Position.Y + Config.HideDepth)
    local surfacePos = Vector3.new(root.Position.X, targetY, root.Position.Z)
    local checkDone = PerformTween(surfacePos)
    while not checkDone() do task.wait() end
    State.OriginalY = nil
    State.IsHiding = false
end

local function IsUnsafe()
    local root = GetRoot()
    if not root then return false end
    local bPos = GetBeastLocation()
    if bPos then
        local flatDist = (Vector3.new(bPos.X, 0, bPos.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
        if flatDist < Config.SafeDistance then return true end
    end
    return false
end

local function SafeTravelTo(targetPos)
    local root = GetRoot()
    if not root then return "CANCELLED" end
    State.Status = "Traveling"
    
    local checkDone = PerformTween(targetPos)
    while not checkDone() and State.CurrentTween do
        if IsUnsafe() then
            CancelAction()
            return "UNSAFE"
        end
        task.wait()
    end
    if not State.CurrentTween then return "CANCELLED" end
    return "ARRIVED"
end

local function PressE()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

task.spawn(function()
    while State.IsRunning do
        task.wait(0.1)
        local root = GetRoot()
        if not root then continue end

        if IsPlayerBeast(LocalPlayer) then
            State.Status = "Beast Mode - Resetting"
            Notify("Beast detected. Resetting...")
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.Health = 0
            end
            task.wait(5)
            continue
        end

        if IsUnsafe() then
            State.Status = "Hiding (Beast Near)"
            CancelAction()
            TweenHide(root)
            
            local campStart = tick()
            local beastLeft = false
            
            while true do
                task.wait(0.2)
                local bPos = GetBeastLocation()
                
                if not bPos then 
                    beastLeft = true 
                    break 
                end
                
                local flatDist = (Vector3.new(bPos.X, 0, bPos.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
                if flatDist > (Config.SafeDistance + 10) then
                    beastLeft = true
                    break
                end
                
                if (tick() - campStart) > Config.CampTime then
                    State.Status = "Beast Camping - Switching"
                    Notify("Beast Camping. Switching PC...")
                    
                    if State.CurrentTargetPC then
                        table.insert(State.Blacklist, State.CurrentTargetPC)
                        ClearHighlight("PC")
                        State.CurrentTargetPC = nil
                    end
                    
                    local newPC = GetNearestIncompletePC()
                    if newPC then
                        State.CurrentTargetPC = newPC
                        CreateHighlight(newPC, Config.PCHighlightColor, "PC")
                        local newDest = GetAvailableTrigger(newPC)
                        
                        if newDest then
                            State.Status = "Escaping Camp (Hidden)"
                            local undergroundPos = Vector3.new(newDest.X, root.Position.Y, newDest.Z)
                            local checkDone = PerformTween(undergroundPos)
                            while not checkDone() do task.wait() end
                            beastLeft = true 
                            break 
                        end
                    else
                         State.Status = "Camping - No PCs"
                         Notify("No PCs left. Going to Door.")
                         
                         local exitDoor = GetExitDoor()
                         if exitDoor then
                             local trigger = exitDoor:FindFirstChild("ExitDoorTrigger") or exitDoor:FindFirstChild("DoorTrigger")
                             if trigger then
                                 local undergroundPos = Vector3.new(trigger.Position.X, root.Position.Y, trigger.Position.Z)
                                 local checkDone = PerformTween(undergroundPos)
                                 while not checkDone() do task.wait() end
                                 beastLeft = true
                                 break
                             end
                         end
                         
                         -- Fallback if no door found immediately (rare)
                         beastLeft = true
                         break 
                    end
                end
            end
            
            if beastLeft then task.wait(0.5) end
            continue 
        end

        if State.IsHiding then
            TweenUnhide(root)
        end

        if State.IsResting then
            State.Status = "Waiting (Anti-Cheat)"
            continue
        end

        local targetPC = State.CurrentTargetPC or GetNearestIncompletePC()
        if targetPC ~= State.CurrentTargetPC then
            ClearHighlight("PC")
            State.CurrentTargetPC = targetPC
        end
        
        if targetPC then
            CreateHighlight(targetPC, Config.PCHighlightColor, "PC")
            State.CurrentTargetPC = targetPC
            State.Escaped = false
            
            local dest = GetAvailableTrigger(targetPC)
            if not dest then
                State.CurrentTargetPC = nil 
                ClearHighlight("PC")
                continue
            end

            local result = SafeTravelTo(dest)
            if result == "UNSAFE" then
                continue 
            elseif result == "ARRIVED" then
                if IsPositionOccupied(dest) then
                    State.CurrentTargetPC = nil 
                    continue
                end

                local hacking = true
                local hackStartTime = tick()

                while hacking do
                    State.Status = "Doing PC"
                    if IsUnsafe() then
                        hacking = false
                        break 
                    end

                    PressE()

                    if IsPCCompleted(targetPC) then
                        hacking = false
                        State.IsResting = true
                        
                        State.PCsDone = State.PCsDone + 1
                        
                        ClearHighlight("PC")
                        State.CurrentTargetPC = nil
                        
                        Notify("Computer Done.")
                        State.Status = "PC Done - Hiding"
                        TweenHide(root)
                        State.Status = "Waiting (Anti-Cheat)"
                        Notify("Waiting AntiCheat...")
                        task.wait(Config.RestTime)
                        State.IsResting = false
                        TweenUnhide(root)
                    end

                    if not targetPC.Parent then hacking = false end
                    
                    if tick() - hackStartTime > 15 and not IsPCCompleted(targetPC) and not State.IsResting then
                        root.CFrame = CFrame.new(dest)
                        hackStartTime = tick()
                    end
                    task.wait(0.1)
                end
            end
        elseif not State.Escaped then
            State.CurrentTargetPC = nil
            ClearHighlight("PC")
            State.Status = "Finding Door"
            
            local exitDoor = GetExitDoor()
            if exitDoor then
                local trigger = exitDoor:FindFirstChild("ExitDoorTrigger") or exitDoor:FindFirstChild("DoorTrigger")
                local exitArea = exitDoor:FindFirstChild("ExitArea")
                
                if trigger then
                    local res = SafeTravelTo(trigger.Position)
                    if res == "UNSAFE" then continue end
                    
                    if res == "ARRIVED" then
                        Notify("Opening Door...")
                        State.Status = "Opening Door"
                        local openStartTime = tick()
                        
                        while tick() - openStartTime < Config.DoorTime do
                            if IsUnsafe() then break end
                            PressE()
                            task.wait(0.1)
                        end
                        
                        if not IsUnsafe() and exitArea then
                            State.Status = "Exiting"
                            SafeTravelTo(exitArea.Position)
                            State.Escaped = true
                            Notify("Escaped!")
                        end
                    end
                end
            else
                task.wait(1)
            end
        else
            State.Status = "Escaped / Idle"
            task.wait(1)
        end
    end
end)

Notify("Script Fixed & Loaded")
