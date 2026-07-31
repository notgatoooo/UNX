local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

ah = ...

if ah then
	print(ah)
end

local Maid = loadstring([[
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
]])()

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local BindButton = loadstring(game:HttpGet("https://apigetunx.vercel.app/Modules/v2/Bind.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")
local Teams = game:GetService("Teams")

Library.ForceCheckbox = true
Library.ShowToggleFrameInKeybinds = true

local MainMaid = Maid.new()

local AimcastParams = RaycastParams.new()
AimcastParams.FilterType = Enum.RaycastFilterType.Exclude
AimcastParams.IgnoreWater = true

local Window = Library:CreateWindow({
    Title = "UNXHub",
    Footer = "Version: " .. (getgenv().unxshared and getgenv().unxshared.version or "Unknown") .. ", Game: " .. (getgenv().unxshared and getgenv().unxshared.gamename or "Unknown") .. ", Player: " .. (getgenv().unxshared and getgenv().unxshared.playername or "Unknown"),
    Icon = 71059178349921,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("Main", "home"),
	Visuals = Window:AddTab("Visuals", "eye"),
	Features = Window:AddTab("Features", "zap"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local defaultWalkSpeed = 16
local defaultJumpPower = 50
local defaultMaxZoom = 400
local defaultGravity = 196.2
local xrayTransparency = 0.8
local defaultFieldOfView = camera.FieldOfView

local character, humanoid, rootpart

local function getCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid", 5)
	rootpart = character:WaitForChild("HumanoidRootPart", 5)
    
    if character then
        AimcastParams.FilterDescendantsInstances = {character}
    end

    if humanoid then
        humanoid.UseJumpPower = true 
        defaultWalkSpeed = humanoid.WalkSpeed
        defaultJumpPower = humanoid.JumpPower
    end

	defaultMaxZoom = player.CameraMaxZoomDistance
	defaultGravity = Workspace.Gravity
end

getCharacter()
MainMaid:GiveTask(player.CharacterAdded:Connect(getCharacter))

local function getTeamList()
    local t = {}
    for _, team in ipairs(Teams:GetTeams()) do
        table.insert(t, team.Name)
    end
    return t
end

local function getPlayerList()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then table.insert(list, p.Name) end
	end
	return list
end

local FlyGroupBox = Tabs.Main:AddRightGroupbox("Fly", "plane")
local FlyMaid = nil

local flySpeed = 5

local function startFlying()
    if FlyMaid then FlyMaid:DoCleaning() end
    FlyMaid = Maid.new()

	if not humanoid or not rootpart then return end
	
	humanoid.PlatformStand = true
	FlyMaid:GiveTask(function() 
		if humanoid then humanoid.PlatformStand = false end 
	end)

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e6,1e6,1e6)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = rootpart
	FlyMaid:GiveTask(bodyVelocity)

	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
	bodyGyro.P = 10000
	bodyGyro.D = 500
	bodyGyro.Parent = rootpart
	FlyMaid:GiveTask(bodyGyro)

	FlyMaid:GiveTask(RunService.Heartbeat:Connect(function()
		if not humanoid or not rootpart or not bodyVelocity.Parent or not bodyGyro.Parent then return end
		local cm = require(player.PlayerScripts:WaitForChild("PlayerModule",5):WaitForChild("ControlModule",5))
		if not cm then return end
		local mv = cm:GetMoveVector()
		local dir = camera.CFrame:VectorToWorldSpace(mv)
		bodyVelocity.Velocity = dir * (flySpeed*10)
		bodyGyro.CFrame = camera.CFrame
	end))
end

FlyGroupBox:AddToggle("Fly", {Text="Fly", Default=false, Callback=function(v)
	if v then 
        startFlying() 
    else 
        if FlyMaid then FlyMaid:DoCleaning() FlyMaid = nil end 
    end
end})

Toggles.Fly:AddKeyPicker("FlyKeybind", {Default="F", Mode="Toggle", Text="Fly", SyncToggleState=true})

FlyGroupBox:AddToggle("FlyBindButton", {Text="Fly BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Fly", function() Toggles.Fly:SetValue(true) end, function() Toggles.Fly:SetValue(false) end)
    else
        BindButton:DelBindB("Fly")
    end
end})

FlyGroupBox:AddSlider("FlySpeed", {Text="Fly Speed", Default=5, Min=1, Max=75, Rounding=0, Callback=function(v) flySpeed = v end})

MainMaid:GiveTask(player.CharacterAdded:Connect(function(c)
	character = c
	humanoid = c:WaitForChild("Humanoid")
	rootpart = c:WaitForChild("HumanoidRootPart")
    if character then AimcastParams.FilterDescendantsInstances = {character} end
    if humanoid then humanoid.UseJumpPower = true end
	if Toggles.Fly.Value then startFlying() end
end))

local VFlyGroupBox = Tabs.Main:AddRightGroupbox("VFly", "plane")
local VFlyMaid = nil

local vflySpeed = 100
local vflyMode = "Joystick"
local vflyMoveState = 0 

local function createVFlyButtons()
    local vflyUI = Instance.new("ScreenGui")
    vflyUI.Name = "UNX_VFly_Buttons"
    vflyUI.Parent = game:GetService("CoreGui")
    VFlyMaid:GiveTask(vflyUI)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 0, 120)
    frame.Position = UDim2.new(0.85, 0, 0.6, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = vflyUI
    
    local function makeBtn(text, pos, callbackDown, callbackUp)
        local btn = Instance.new("TextButton")
        btn.Text = text
        btn.Size = UDim2.new(0, 60, 0, 50)
        btn.Position = pos
        btn.BackgroundColor3 = Color3.fromHex("0b0b0d")
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.Parent = frame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromHex("262434")
        stroke.Thickness = 2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = btn
        
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromHex("262434")}):Play()
            callbackDown()
        end)
        
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromHex("0b0b0d")}):Play()
            callbackUp()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromHex("0b0b0d")}):Play()
            callbackUp()
        end)
        
        btn.TouchTap:Connect(function()
             TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromHex("262434")}):Play()
             callbackDown()
             task.wait(0.1)
             TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromHex("0b0b0d")}):Play()
             callbackUp()
        end)
    end
    
    makeBtn("^", UDim2.new(0.3, 0, 0, 0), function() vflyMoveState = 1 end, function() vflyMoveState = 0 end)
    makeBtn("v", UDim2.new(0.3, 0, 0.5, 0), function() vflyMoveState = -1 end, function() vflyMoveState = 0 end)
end

local function startVFly()
    if VFlyMaid then VFlyMaid:DoCleaning() end
    VFlyMaid = Maid.new()
    
    local char = player.Character
    if not char then return end
    
    local hum = char:WaitForChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local target = root
    
    if hum.SeatPart then target = hum.SeatPart end
    if not target then return end
    
    local vflyBV = Instance.new("BodyVelocity")
    vflyBV.Name = "VFlyVelocity"
    vflyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    vflyBV.Velocity = Vector3.zero
    vflyBV.Parent = target
    VFlyMaid:GiveTask(vflyBV)
    
    local vflyBG = Instance.new("BodyGyro")
    vflyBG.Name = "VFlyGyro"
    vflyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    vflyBG.P = 3000
    vflyBG.D = 100
    vflyBG.CFrame = target.CFrame
    vflyBG.Parent = target
    VFlyMaid:GiveTask(vflyBG)
    
    if vflyMode == "Buttons" then
        createVFlyButtons()
    end
    
    local controlModule = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
    
    VFlyMaid:GiveTask(RunService.RenderStepped:Connect(function()
        if not target or not target.Parent or not vflyBV.Parent or not vflyBG.Parent then
            Toggles.VFly:SetValue(false)
            return
        end
        
        vflyBG.CFrame = camera.CFrame
        
        local speed = vflySpeed
        
        if vflyMode == "Joystick" then
            local moveVector = controlModule:GetMoveVector()
            if moveVector.Magnitude > 0.1 then
                local direction = (camera.CFrame.LookVector * -moveVector.Z) + (camera.CFrame.RightVector * moveVector.X)
                if vflyBV then vflyBV.Velocity = direction.Unit * speed end
            else
                if vflyBV then vflyBV.Velocity = Vector3.zero end
            end
        else
            if vflyMoveState == 1 then
                if vflyBV then vflyBV.Velocity = camera.CFrame.LookVector * speed end
            elseif vflyMoveState == -1 then
                if vflyBV then vflyBV.Velocity = camera.CFrame.LookVector * -speed end
            else
                if vflyBV then vflyBV.Velocity = Vector3.zero end
            end
        end
    end))
end

VFlyGroupBox:AddToggle("VFly", {Text="VFly", Default=false, Callback=function(v)
    if v then 
        startVFly() 
    else 
        if VFlyMaid then VFlyMaid:DoCleaning() VFlyMaid = nil end 
    end
end})

VFlyGroupBox:AddToggle("VFlyBindButton", {Text="VFly BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("VFly", function() Toggles.VFly:SetValue(true) end, function() Toggles.VFly:SetValue(false) end)
    else
        BindButton:DelBindB("VFly")
    end
end})

VFlyGroupBox:AddInput("VFlySpeed", {Text="VFly Speed", Default="100", Numeric=true, Callback=function(v)
    vflySpeed = tonumber(v) or 100
end})

VFlyGroupBox:AddDropdown("VFlyMode", {Text="VFly Mode", Values={"Joystick", "Buttons"}, Default="Joystick", Callback=function(v)
    vflyMode = v
    if Toggles.VFly.Value then startVFly() end
end})

local LeftMain = Tabs.Main:AddLeftGroupbox("Character", "user")

LeftMain:AddToggle("LockWalkspeed", {Text="Lock Walkspeed", Default=true})
LeftMain:AddToggle("LockWalkspeedBindButton", {Text="Lock Walkspeed BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Lock WS", function() Toggles.LockWalkspeed:SetValue(true) end, function() Toggles.LockWalkspeed:SetValue(false) end)
    else
        BindButton:DelBindB("Lock WS")
    end
end})
LeftMain:AddSlider("Walkspeed", {Text="Walkspeed", Default=defaultWalkSpeed, Min=1, Max=500, Rounding=0, Callback=function(v)
    if not Toggles.LockWalkspeed.Value and humanoid then
        humanoid.WalkSpeed = v
    end
end})

LeftMain:AddToggle("LockJumppower", {Text="Lock Jumppower", Default=true})
LeftMain:AddToggle("LockJumppowerBindButton", {Text="Lock Jumppower BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Lock JP", function() Toggles.LockJumppower:SetValue(true) end, function() Toggles.LockJumppower:SetValue(false) end)
    else
        BindButton:DelBindB("Lock JP")
    end
end})
LeftMain:AddSlider("Jumppower", {Text="Jumppower", Default=defaultJumpPower, Min=1, Max=1000, Rounding=0, Callback=function(v)
    if not Toggles.LockJumppower.Value and humanoid then
        humanoid.JumpPower = v
    end
end})

LeftMain:AddToggle("LockGravity", {Text="Lock Gravity", Default=true})
LeftMain:AddToggle("LockGravityBindButton", {Text="Lock Gravity BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Lock Gravity", function() Toggles.LockGravity:SetValue(true) end, function() Toggles.LockGravity:SetValue(false) end)
    else
        BindButton:DelBindB("Lock Gravity")
    end
end})
LeftMain:AddSlider("Gravity", {Text="Gravity", Default=defaultGravity, Min=0, Max=500, Rounding=1, Callback=function(v)
    if not Toggles.LockGravity.Value then
        Workspace.Gravity = v
    end
end})

LeftMain:AddDivider()

LeftMain:AddToggle("InfiniteJump", {Text="Infinite Jump", Default=false})
Toggles.InfiniteJump:AddKeyPicker("InfiniteJumpKeybind", {Default="I", Mode="Toggle", Text="Infinite Jump", SyncToggleState=true})
LeftMain:AddToggle("InfiniteJumpBindButton", {Text="Infinite Jump BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Inf Jump", function() Toggles.InfiniteJump:SetValue(true) end, function() Toggles.InfiniteJump:SetValue(false) end)
    else
        BindButton:DelBindB("Inf Jump")
    end
end})

LeftMain:AddToggle("Noclip", {Text="Noclip", Default=false})
Toggles.Noclip:AddKeyPicker("NoclipKeybind", {Default="N", Mode="Toggle", Text="Noclip", SyncToggleState=true})
LeftMain:AddToggle("NoclipBindButton", {Text="Noclip BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Noclip", function() Toggles.Noclip:SetValue(true) end, function() Toggles.Noclip:SetValue(false) end)
    else
        BindButton:DelBindB("Noclip")
    end
end})

LeftMain:AddToggle("ForceThirdPerson", {Text="Force Third Person", Default=false})
LeftMain:AddToggle("ForceThirdPersonBindButton", {Text="Force Third Person BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("3rd Person", function() Toggles.ForceThirdPerson:SetValue(true) end, function() Toggles.ForceThirdPerson:SetValue(false) end)
    else
        BindButton:DelBindB("3rd Person")
    end
end})

LeftMain:AddDivider()

local CounterFlingMaid = nil

LeftMain:AddToggle("CounterFling", {Text="Counter Fling", Default=false, Callback=function(v)
    if v then
        if CounterFlingMaid then CounterFlingMaid:DoCleaning() end
        CounterFlingMaid = Maid.new()

        CounterFlingMaid:GiveTask(RunService.Stepped:Connect(function()
            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                     for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                     end
                end
            end
        end))
    else
        if CounterFlingMaid then CounterFlingMaid:DoCleaning() CounterFlingMaid = nil end
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
    end
end})

local CounterVoidMaid = nil

LeftMain:AddToggle("CounterVoid", {Text="Counter Void", Default=false, Callback=function(v)
    if v then
        if CounterVoidMaid then CounterVoidMaid:DoCleaning() end
        CounterVoidMaid = Maid.new()

        CounterVoidMaid:GiveTask(RunService.Heartbeat:Connect(function()
            if character and rootpart then
                local voidThreshold = workspace.FallenPartsDestroyHeight or -500
                if rootpart.Position.Y < voidThreshold + 10 then
                    rootpart.Velocity = Vector3.new(rootpart.Velocity.X, 100, rootpart.Velocity.Z)
                end
            end
        end))
    else
        if CounterVoidMaid then CounterVoidMaid:DoCleaning() CounterVoidMaid = nil end
    end
end})

local AFKMaid = nil

LeftMain:AddToggle("NoAFKKick", {Text="No AFK Kick", Default=false, Callback=function(v)
    if v then
        if AFKMaid then AFKMaid:DoCleaning() end
        AFKMaid = Maid.new()

        AFKMaid:GiveTask(RunService.Heartbeat:Connect(function()
            if player then
                local VirtualInputManager = game:GetService("VirtualInputManager")
                VirtualInputManager:SendMouseMoveEvent(10, 10, game)
                task.wait(1)
                VirtualInputManager:SendMouseMoveEvent(20, 20, game)
            end
        end))
        
        if player then
            local playerScripts = player:FindFirstChild("PlayerScripts")
            if playerScripts then
                local playerModule = playerScripts:FindFirstChild("PlayerModule")
                if playerModule then
                    local controlModule = playerModule:FindFirstChild("ControlModule")
                    if controlModule then
                        local clone = controlModule:Clone()
                        AFKMaid:GiveTask(function()
                            if playerModule:FindFirstChild("ControlModule") then playerModule.ControlModule:Destroy() end
                            clone.Parent = playerModule
                        end)
                    end
                end
            end
        end
    else
        if AFKMaid then AFKMaid:DoCleaning() AFKMaid = nil end
    end
end})

LeftMain:AddDivider()

local xrayEnabled = false
local XRayMaid = nil

LeftMain:AddToggle("XRay", {Text="X-Ray", Default=false, Callback=function(v)
	xrayEnabled = v
	if v then
        if XRayMaid then XRayMaid:DoCleaning() end
        XRayMaid = Maid.new()

        local originalTransparencies = {}
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Parent ~= character then
				originalTransparencies[obj] = obj.Transparency
				obj.Transparency = xrayTransparency
			end
		end
        XRayMaid:GiveTask(function()
            for obj, originalTransparency in pairs(originalTransparencies) do
                if obj and obj:IsA("BasePart") then
                    obj.Transparency = originalTransparency
                end
            end
        end)
	else
		if XRayMaid then XRayMaid:DoCleaning() XRayMaid = nil end
	end
end})
LeftMain:AddToggle("XRayBindButton", {Text="X-Ray BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("X-Ray", function() Toggles.XRay:SetValue(true) end, function() Toggles.XRay:SetValue(false) end)
    else
        BindButton:DelBindB("X-Ray")
    end
end})

LeftMain:AddSlider("XRayTransparency", {Text="X-Ray Transparency (%)", Default=80, Min=0, Max=100, Rounding=0, Suffix="%", Callback=function(v)
	xrayTransparency = v/100
	if xrayEnabled then
        Toggles.XRay:SetValue(false)
        Toggles.XRay:SetValue(true)
	end
end})

local RightMain = Tabs.Main:AddRightGroupbox("Misc", "box")

RightMain:AddButton({Text="Reset Character", Func=function()
	if character then
		character:BreakJoints()
	end
end})

RightMain:AddDivider()

RightMain:AddButton({Text="Reset Walk Speed", Func=function() Options.Walkspeed:SetValue(defaultWalkSpeed) end})
RightMain:AddButton({Text="Reset Jump Power", Func=function() Options.Jumppower:SetValue(defaultJumpPower) end})
RightMain:AddButton({Text="Reset Gravity", Func=function() Options.Gravity:SetValue(defaultGravity) end})

local ESPTabBox = Tabs.Visuals:AddLeftTabbox()
local ESPTab = ESPTabBox:AddTab("ESP")
local ESPConfigTab = ESPTabBox:AddTab("Config")
local GameVisuals = Tabs.Visuals:AddRightGroupbox("Game", "camera")

local espColor = Color3.new(1,1,1)
local outlineColor = Color3.new(1,1,1)
local tracersColor = Color3.new(1,1,1)
local outlineFillTransparency = 1
local outlineTransparency = 0
local espSize = 16
local espFont = Enum.Font.BuilderSans
local showDistance = true
local showPlayerName = true
local rainbowSpeed = 5
local tracerOrigin = "Down"

local highlights = {}
local drawings = {}

local function addPlayer(plr)
	if plr == player then return end
	
	local function onChar(c)
		if drawings[plr] then
			if drawings[plr].tracer then drawings[plr].tracer:Remove() end
			if drawings[plr].billboard then drawings[plr].billboard:Destroy() end
			drawings[plr] = nil
		end
		if highlights[plr] then highlights[plr]:Destroy() highlights[plr] = nil end
		
		local hl = Instance.new("Highlight")
		hl.Adornee = c
		hl.Parent = c
		hl.Enabled = false
		highlights[plr] = hl
		
		local l = Drawing.new("Line")
		l.Visible = false 
		l.Color = tracersColor 
		l.Thickness = 1
		
		local head = c:WaitForChild("Head", 10)
		local billboard, textLabel, uiStroke
		
		if head then
			if head:FindFirstChild("unxcontainer") then head.unxcontainer:Destroy() end

			billboard = Instance.new("BillboardGui")
			billboard.Name = "unxcontainer"
			billboard.Adornee = head
			billboard.Size = UDim2.new(0, 200, 0, 50)
			billboard.StudsOffset = Vector3.new(0, 2, 0)
			billboard.AlwaysOnTop = true
			billboard.Enabled = false
			billboard.Parent = head

			textLabel = Instance.new("TextLabel")
			textLabel.Parent = billboard
			textLabel.BackgroundTransparency = 1
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.TextColor3 = espColor
			textLabel.TextSize = espSize
			textLabel.Font = espFont
			textLabel.Text = plr.Name .. " [...]"

			uiStroke = Instance.new("UIStroke")
			uiStroke.Parent = textLabel
			uiStroke.Thickness = 1.2
			uiStroke.Color = Color3.fromRGB(0, 0, 0)
			uiStroke.Transparency = 0
		end

		drawings[plr] = {tracer=l, billboard=billboard, label=textLabel, stroke=uiStroke}
	end

	if plr.Character then onChar(plr.Character) end
	plr.CharacterAdded:Connect(onChar)
end

for _,p in Players:GetPlayers() do addPlayer(p) end
MainMaid:GiveTask(Players.PlayerAdded:Connect(addPlayer))
MainMaid:GiveTask(Players.PlayerRemoving:Connect(function(plr)
	if highlights[plr] then highlights[plr]:Destroy() highlights[plr] = nil end
	if drawings[plr] then 
		if drawings[plr].tracer then drawings[plr].tracer:Remove() end
		if drawings[plr].billboard then drawings[plr].billboard:Destroy() end
		drawings[plr] = nil 
	end
end))

local mousePos = Vector2.new()
MainMaid:GiveTask(UserInputService.InputChanged:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseMovement then mousePos = Vector2.new(i.Position.X,i.Position.Y) end
end))

ESPTab:AddToggle("ESP", {Text="ESP", Default=false}):AddColorPicker("ESPColor", {Default=Color3.new(1,1,1), Title="ESP Color", Callback=function(v) espColor = v end})

ESPTab:AddToggle("Outline", {Text="Outline", Default=false}):AddColorPicker("OutlineColor", {Default=Color3.new(1,1,1), Title="Outline Color", Callback=function(v) outlineColor = v end})

ESPTab:AddToggle("Tracers", {Text="Tracers", Default=false}):AddColorPicker("TracersColor", {Default=Color3.new(1,1,1), Title="Tracers Color", Callback=function(v) tracersColor = v end})

ESPTab:AddDivider()

ESPTab:AddDropdown("ESPTeamOnly", {
    Values = getTeamList(),
    Multi = true,
    Text = "ESP Team Only",
    Searchable = true
})

ESPTab:AddDropdown("OutlineTeamOnly", {
    Values = getTeamList(),
    Multi = true,
    Text = "Outline Team Only",
    Searchable = true
})

ESPTab:AddDropdown("TracersTeamOnly", {
    Values = getTeamList(),
    Multi = true,
    Text = "Tracers Team Only",
    Searchable = true
})

ESPTab:AddDivider()

ESPTab:AddDropdown("ESPPlayersOnly", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Multi = true,
    Text = "ESP Players Only",
    Searchable = true
})

ESPTab:AddDropdown("OutlinePlayersOnly", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Multi = true,
    Text = "Outline Players Only",
    Searchable = true
})

ESPTab:AddDropdown("TracersPlayersOnly", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Multi = true,
    Text = "Tracers Players Only",
    Searchable = true
})

local function isPlayerAllowed(plr, teamOption, playerOption)
    local teamFilterHasSelections = false
    if teamOption.Value then
        for _, v in pairs(teamOption.Value) do
            if v then teamFilterHasSelections = true break end
        end
    end

    local playerFilterHasSelections = false
    if playerOption.Value then
        for _, v in pairs(playerOption.Value) do
            if v then playerFilterHasSelections = true break end
        end
    end

    if not teamFilterHasSelections and not playerFilterHasSelections then
        return true
    end

    if playerFilterHasSelections and playerOption.Value and playerOption.Value[plr.Name] then
        return true
    end

    if teamFilterHasSelections and teamOption.Value and plr.Team and teamOption.Value[plr.Team.Name] then
        return true
    end

    return false
end

MainMaid:GiveTask(RunService.RenderStepped:Connect(function()
	for plr, data in pairs(drawings) do
		local char = plr.Character
		local hl = highlights[plr]
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChild("Humanoid")
		
		if not char or not hrp or not hum or hum.Health <= 0 then
			if hl then hl.Enabled = false end
			if data.billboard then data.billboard.Enabled = false end
			if data.tracer then data.tracer.Visible = false end
			continue
		end
		
		local head = char:FindFirstChild("Head") or hrp
		local headPos = head.Position + Vector3.new(0,2,0)
		local pos3d, onScreen = camera:WorldToViewportPoint(headPos)
		local pos = Vector2.new(pos3d.X, pos3d.Y)

		if Toggles.ESP and Toggles.ESP.Value and data.billboard and data.label and onScreen and isPlayerAllowed(plr, Options.ESPTeamOnly, Options.ESPPlayersOnly) then
			data.billboard.Enabled = true
			
			local c = espColor
			if Toggles.ESPColorFromTeam and Toggles.ESPColorFromTeam.Value and plr.Team then c = plr.TeamColor.Color end
			if Toggles.RainbowESP and Toggles.RainbowESP.Value then c = Color3.fromHSV(tick()*(rainbowSpeed/50)%1,1,1) end
			
			data.label.TextColor3 = c
			data.label.TextSize = espSize
			data.label.Font = espFont
			if data.stroke then 
				if Toggles.RainbowESP and Toggles.RainbowESP.Value then
					data.stroke.Color = Color3.fromHSV(tick()*(rainbowSpeed/50)%1,1,0.5)
				else
					data.stroke.Color = Color3.fromRGB(0,0,0)
				end
			end
			
			local dist = 0
			if rootpart then
				dist = (rootpart.Position - hrp.Position).Magnitude
			elseif camera then
				dist = (camera.CFrame.Position - hrp.Position).Magnitude
			end
			
            local textStr = ""
            if showPlayerName then textStr = plr.Name .. " " end
            if showDistance then textStr = textStr .. string.format("[%d]", math.floor(dist)) end
            
            if data.label.Text ~= textStr then
			    data.label.Text = textStr
            end
		else
			if data.billboard then data.billboard.Enabled = false end
		end

		if hl then
			if onScreen and Toggles.Outline and Toggles.Outline.Value and isPlayerAllowed(plr, Options.OutlineTeamOnly, Options.OutlinePlayersOnly) then
				hl.Enabled = true
				local c = outlineColor
				if Toggles.OutlineColorFromTeam and Toggles.OutlineColorFromTeam.Value and plr.Team then c = plr.TeamColor.Color end
				if Toggles.RainbowOutline and Toggles.RainbowOutline.Value then c = Color3.fromHSV(tick()*(rainbowSpeed/50)%1,1,1) end
				hl.OutlineColor = c hl.FillColor = c hl.OutlineTransparency = outlineTransparency hl.FillTransparency = outlineFillTransparency
			else
				hl.Enabled = false
			end
		end
		
		if data.tracer then
			if onScreen and Toggles.Tracers and Toggles.Tracers.Value and isPlayerAllowed(plr, Options.TracersTeamOnly, Options.TracersPlayersOnly) then
				data.tracer.Visible = true
				local c = tracersColor
				if Toggles.TracersColorFromTeam and Toggles.TracersColorFromTeam.Value and plr.Team then c = plr.TeamColor.Color end
				if Toggles.RainbowTracers and Toggles.RainbowTracers.Value then c = Color3.fromHSV(tick()*(rainbowSpeed/50)%1,1,1) end
				data.tracer.Color = c
				if tracerOrigin == "Mouse" then data.tracer.From = mousePos
				elseif tracerOrigin == "Upper" then data.tracer.From = Vector2.new(camera.ViewportSize.X/2,0)
				elseif tracerOrigin == "Middle" then data.tracer.From = Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
				else data.tracer.From = Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y) end
				data.tracer.To = pos
			else
				data.tracer.Visible = false
			end
		end
	end
end))

ESPConfigTab:AddToggle("RainbowESP", {Text="Rainbow ESP", Default=false})
ESPConfigTab:AddToggle("RainbowOutline", {Text="Rainbow Outline", Default=false})
ESPConfigTab:AddToggle("RainbowTracers", {Text="Rainbow Tracers", Default=false})
ESPConfigTab:AddSlider("RainbowSpeed", {Text="Rainbow Speed", Min=0, Max=10, Default=5, Rounding=1, Callback=function(v) rainbowSpeed = v end})
ESPConfigTab:AddSlider("ESPSize", {Text="ESP Size", Min=10, Max=30, Default=16, Rounding=0, Callback=function(v) espSize = v end})
ESPConfigTab:AddDropdown("ESPFont", {
	Text="ESP Font", 
	Values={"BuilderSans","SourceSans","SourceSansBold","Roboto","Arcade","Gotham","GothamBold","Oswald","Code","SciFi","Bodoni","AmaticSC"}, 
	Default=1, 
	Callback=function(v) 
		espFont = Enum.Font[v] or Enum.Font.BuilderSans 
	end
})
ESPConfigTab:AddToggle("ShowDistance", {Text="Show Distance", Default=true, Callback=function(v) showDistance = v end})
ESPConfigTab:AddToggle("ShowPlayerName", {Text="Show Player Name", Default=true, Callback=function(v) showPlayerName = v end})
ESPConfigTab:AddSlider("OutlineFillTransparency", {Text="Outline Fill Transparency (%)", Min=0, Max=100, Default=100, Suffix="%", Rounding=0, Callback=function(v) outlineFillTransparency = v/100 end})
ESPConfigTab:AddSlider("OutlineTransparency", {Text="Outline Transparency (%)", Min=0, Max=100, Default=0, Suffix="%", Rounding=0, Callback=function(v) outlineTransparency = v/100 end})
ESPConfigTab:AddDropdown("TracersPosition", {Text="Tracers Position", Values={"Mouse","Upper","Middle","Down"}, Default="Down", Callback=function(v) tracerOrigin = v end})
ESPConfigTab:AddToggle("ESPColorFromTeam", {Text="ESP Color From Team", Default=false})
ESPConfigTab:AddToggle("OutlineColorFromTeam", {Text="Outline Color From Team", Default=false})
ESPConfigTab:AddToggle("TracersColorFromTeam", {Text="Tracers Color From Team", Default=false})

local VisualsMaid = nil

GameVisuals:AddToggle("FullBright", {Text="Full Bright", Default=false, Callback=function(v)
	if v then
        if VisualsMaid then VisualsMaid:DoCleaning() end
        VisualsMaid = Maid.new()

        local originalLighting = {
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            FogColor = Lighting.FogColor
        }
        VisualsMaid:GiveTask(function()
            for k, val in pairs(originalLighting) do Lighting[k] = val end
        end)
		
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(255,255,255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
		Lighting.ClockTime = 12
		Lighting.FogEnd = 100000
		Lighting.FogStart = 0
		Lighting.FogColor = Color3.fromRGB(255,255,255)
	else
		if VisualsMaid then VisualsMaid:DoCleaning() VisualsMaid = nil end
	end
end})

local NoFogMaid = nil

GameVisuals:AddToggle("NoFog", {Text="No Fog", Default=false, Callback=function(v)
	if v then
        if NoFogMaid then NoFogMaid:DoCleaning() end
        NoFogMaid = Maid.new()

        local oldFogEnd = Lighting.FogEnd
        NoFogMaid:GiveTask(function() Lighting.FogEnd = oldFogEnd end)
        
        local originalAtmospheres = {}
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("Atmosphere") then
				originalAtmospheres[obj] = obj.Density
				obj.Density = 0
			end
		end
        NoFogMaid:GiveTask(function()
            for obj, density in pairs(originalAtmospheres) do
                if obj then obj.Density = density end
            end
        end)
		Lighting.FogEnd = 100000000
	else
		if NoFogMaid then NoFogMaid:DoCleaning() NoFogMaid = nil end
	end
end})

if game.PlaceId == 155615604 then
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://api.getunx.cc/Modules/v3/Other/UNX_PFSA.m.luau"))(Library, Tabs, MainMaid)
    end)
    if not success then warn("[UNX]: Failed to load Silent Aim module wtf?!!\nError Stack: " .. err) end
end

local AimlockTabbox = Tabs.Features:AddLeftTabbox("Aimlock", "target")
local AimlockTab = AimlockTabbox:AddTab("Aimlock")
local AimlockConfigTab = AimlockTabbox:AddTab("Configuration")

AimlockTab:AddToggle("EnableAimlock", { Text = "Enable Aimlock", Default = false })
AimlockTab:AddToggle("AimlockBindButton", {Text="Aimlock BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Aimlock", function() Toggles.EnableAimlock:SetValue(true) end, function() Toggles.EnableAimlock:SetValue(false) end)
    else
        BindButton:DelBindB("Aimlock")
    end
end})
AimlockTab:AddDropdown("AimlockType", { Values = { "Nearest Character", "Nearest Mouse" }, Default = 1, Text = "Aimlock Type" })
AimlockTab:AddDivider()
AimlockTab:AddToggle("WallCheck", { Text = "Wall Check", Default = true })
AimlockTab:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
AimlockTab:AddDivider()
AimlockTab:AddDropdown("AimlockCertainPlayer", { 
    SpecialType = "Player", 
    ExcludeLocalPlayer = true, 
    Multi = false,
    Searchable = true,
    Text = "Aimlock Certain Player" 
})
AimlockTab:AddDivider()
AimlockTab:AddToggle("EnableFOV", { Text = "Enable FOV", Default = false })
AimlockTab:AddToggle("ShowFOV", { Text = "Show FOV", Default = false })
AimlockTab:AddLabel("FOV Color"):AddColorPicker("FOVColor", { 
    Default = Color3.fromRGB(255, 255, 255), 
    Title = "FOV Color", 
    Transparency = 1
})
AimlockTab:AddDropdown("FOVType", { Values = { "Centered", "Mouse" }, Default = 1, Text = "FOV Type" })

AimlockConfigTab:AddSlider("AimlockMaxDist", { Text = "Aimlock Max Dist", Default = 5000, Min = 1, Max = 10000, Rounding = 0 })
AimlockConfigTab:AddSlider("MouseMaxDist", { Text = "Mouse Max Dist", Default = 5000, Min = 1, Max = 10000, Rounding = 0 })
AimlockConfigTab:AddSlider("FOVMaxDist", { Text = "FOV Max Dist", Default = 5000, Min = 1, Max = 10000, Rounding = 0 })
AimlockConfigTab:AddDivider()
AimlockConfigTab:AddToggle("SmoothAimlock", { Text = "Smooth Aimlock", Default = false })
AimlockConfigTab:AddSlider("AimbotSmoothness", { Text = "Aimbot Smoothness", Default = 25, Min = 1, Max = 100, Rounding = 0 })
AimlockConfigTab:AddDivider()
AimlockConfigTab:AddSlider("FOVSize", { Text = "FOV Size", Default = 150, Min = 1, Max = 750, Rounding = 0 })
AimlockConfigTab:AddSlider("FOVStrokeThickness", { Text = "FOV Stroke Thickness", Default = 2.5, Min = 1, Max = 10, Rounding = 1 })
AimlockConfigTab:AddToggle("RainbowFOV", { Text = "Rainbow FOV", Default = false })
AimlockConfigTab:AddSlider("RainbowFOVSpeed", { Text = "Rainbow FOV Speed", Default = 2, Min = 1, Max = 10, Rounding = 0 })
AimlockConfigTab:AddDivider()
AimlockConfigTab:AddDropdown("WhitelistPlayers", { 
    SpecialType = "Player", 
    ExcludeLocalPlayer = true, 
    Multi = true,
    Searchable = true,
    Text = "Whitelist Players" 
})
AimlockConfigTab:AddDropdown("PrioritizePlayers", { 
    SpecialType = "Player", 
    ExcludeLocalPlayer = true, 
    Multi = true,
    Searchable = true,
    Text = "Prioritize Players" 
})

AimlockConfigTab:AddDivider()

AimlockConfigTab:AddDropdown("IgnoreTeam", {
    Values = getTeamList(),
    Multi = true,
    Text = "Ignore Team"
})

AimlockConfigTab:AddDropdown("PrioritizeTeam", {
    Values = getTeamList(),
    Multi = true,
    Text = "Prioritize Team"
})

AimlockConfigTab:AddDivider()
AimlockConfigTab:AddDropdown("ExcludeFromTeamExclusion", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Multi = true,
    Searchable = true,
    Text = "Exclude Player From Team Exclusion"
})
AimlockConfigTab:AddToggle("IgnoreForceFielded", { Text = "Ignore ForceFielded", Default = false })

AimlockConfigTab:AddDivider()
AimlockConfigTab:AddSlider("AimlockOffsetY", { Text = "Aimlock Offset (Y)", Default = 0, Min = -1, Max = 1, Rounding = 2 })
AimlockConfigTab:AddSlider("AimlockOffsetX", { Text = "Aimlock Offset (X)", Default = 0, Min = -1, Max = 1, Rounding = 2 })

local CameraGroupBox = Tabs.Features:AddLeftGroupbox("Camera", "camera")

CameraGroupBox:AddSlider("FOV", {Text = "Field Of View", Default = defaultFieldOfView, Min = 20, Max = 180, Rounding = 0, Callback = function(v)
    camera.FieldOfView = v
end})

CameraGroupBox:AddSlider("MaxZoom", {Text = "Max Zoom", Default = defaultMaxZoom, Min = 0, Max = 9999, Rounding = 0, Callback = function(v)
    player.CameraMaxZoomDistance = v
end})

CameraGroupBox:AddToggle("NoclipCamera", {Text = "Noclip Camera", Default = false, Callback = function(v)
    if v then
        player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
    else
        player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end
end})
CameraGroupBox:AddToggle("NoclipCameraBindButton", {Text="Noclip Camera BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Noclip Cam", function() Toggles.NoclipCamera:SetValue(true) end, function() Toggles.NoclipCamera:SetValue(false) end)
    else
        BindButton:DelBindB("Noclip Cam")
    end
end})

local OrbitGroupBox = Tabs.Features:AddLeftGroupbox("Orbit", "circle")

OrbitGroupBox:AddToggle("EnableOrbit", {Text = "Enable Orbit", Default = false})
OrbitGroupBox:AddToggle("EnableOrbitBindButton", {Text="Orbit BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Orbit", function() Toggles.EnableOrbit:SetValue(true) end, function() Toggles.EnableOrbit:SetValue(false) end)
    else
        BindButton:DelBindB("Orbit")
    end
end})
OrbitGroupBox:AddDivider()
OrbitGroupBox:AddDropdown("OrbitPlayers", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Multi = true,
    Searchable = true,
    Text = "Orbit Player Target"
})
OrbitGroupBox:AddSlider("OrbitTime", {Text = "Orbit Time Per Player", Default = 5, Min = 0, Max = 30, Rounding = 1})
OrbitGroupBox:AddSlider("OrbitSpeed", {Text = "Orbit Speed", Default = 10, Min = 1, Max = 1000, Rounding = 0})
OrbitGroupBox:AddSlider("OrbitOffset", {Text = "Orbit Offset From Target", Default = 10, Min = 1, Max = 1000, Rounding = 0})

local FreeCamGroupBox = Tabs.Features:AddLeftGroupbox("Free Camera", "camera")
local FreeCamMaid = nil

local freecamCFrame = CFrame.new()
local boostTimer = 0
local isBoosting = false
local PlayerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local function toggleFreecam(v)
    if FreeCamMaid then FreeCamMaid:DoCleaning() end
    FreeCamMaid = Maid.new()

    local char = player.Character
    local rp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if v then
        camera.CameraType = Enum.CameraType.Scriptable
        freecamCFrame = camera.CFrame
        if rp then rp.Anchored = true end
        if hum then hum.PlatformStand = true end
        
        FreeCamMaid:GiveTask(function()
            camera.CameraType = Enum.CameraType.Custom
            if rp then rp.Anchored = false end
            if hum then hum.PlatformStand = false end
            boostTimer = 0
            isBoosting = false
        end)
        
        FreeCamMaid:GiveTask(RunService.RenderStepped:Connect(function(dt)
            local moveVector = Controls:GetMoveVector()
            local isMoving = moveVector.Magnitude > 0.1
            
            if Toggles.EnableFreeCamBoost.Value and isMoving then
                if isBoosting then
                else
                    local isWalkingStraight = (moveVector.Z < -0.8) and (math.abs(moveVector.X) < 0.4)
                    if isWalkingStraight then
                        boostTimer = boostTimer + dt
                        if boostTimer >= Options.FreecamBoostTime.Value then
                            isBoosting = true
                        end
                    else
                        boostTimer = 0
                    end
                end
            else
                isBoosting = false
                boostTimer = 0
            end
            
            local baseSpeed = Options.FreecamSpeed.Value
            local boostMult = Options.FreecamBoostMult.Value
            local currentSpeed = isBoosting and (baseSpeed * boostMult) or baseSpeed
            
            local delta = UserInputService:GetMouseDelta()
            local sens = Options.FreecamSens.Value * 0.003
            local rotateInput = delta * sens
            
            local currentLook = freecamCFrame.LookVector
            local yaw = math.atan2(-currentLook.X, -currentLook.Z)
            local pitch = math.asin(currentLook.Y)
            
            local newYaw = yaw - rotateInput.X
            local newPitch = math.clamp(pitch - rotateInput.Y, -math.rad(89), math.rad(89))
            
            local rotationCFrame = CFrame.fromOrientation(0, newYaw, 0) * CFrame.fromOrientation(newPitch, 0, 0)
            local worldMoveDir = rotationCFrame:VectorToWorldSpace(moveVector)
            
            if moveVector.Magnitude > 0 then
                local appliedSpeed = currentSpeed * (isBoosting and 1 or moveVector.Magnitude)
                freecamCFrame = freecamCFrame + (worldMoveDir * appliedSpeed * dt)
            end
            
            freecamCFrame = CFrame.new(freecamCFrame.Position) * rotationCFrame.Rotation
            camera.CFrame = freecamCFrame
        end))
    else
        if FreeCamMaid then FreeCamMaid:DoCleaning() FreeCamMaid = nil end
    end
end

FreeCamGroupBox:AddToggle("EnableFreeCam", {Text="Enable Free Camera", Default=false, Callback=function(v)
    toggleFreecam(v)
end})
FreeCamGroupBox:AddToggle("EnableFreeCamBindButton", {Text="Free Camera BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("Freecam", function() Toggles.EnableFreeCam:SetValue(true) end, function() Toggles.EnableFreeCam:SetValue(false) end)
    else
        BindButton:DelBindB("Freecam")
    end
end})

FreeCamGroupBox:AddDivider()
FreeCamGroupBox:AddSlider("FreecamSpeed", {Text="Freecam Base Speed", Default=30, Min=1, Max=1000, Rounding=0})
FreeCamGroupBox:AddSlider("FreecamBoostMult", {Text="Freecam Boost Speed Multiplier", Default=3, Min=1, Max=50, Rounding=0})
FreeCamGroupBox:AddSlider("FreecamBoostTime", {Text="Freecam Boost Wait Time", Default=5, Min=0, Max=30, Rounding=1})
FreeCamGroupBox:AddSlider("FreecamSens", {Text="Sensibility", Default=1, Min=0.01, Max=10, Rounding=2})
FreeCamGroupBox:AddToggle("EnableFreeCamBoost", {Text="Enable Boost", Default=true})

local FlingGroupBox = Tabs.Features:AddLeftGroupbox("Fling", "wind")

local flingTime = 5
local flingForce = 50000

FlingGroupBox:AddDropdown("FlingPlayer", {
	Text = "Select Players",
	Values = getPlayerList(),
	Multi = true,
	Searchable = true,
	Callback = function(v) end
})

local function fling(TargetPlayer, duration)
	local startTime = tick()
	local Character = player.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Humanoid and Humanoid.RootPart

	local TCharacter = TargetPlayer.Character
	local THumanoid
	local TRootPart
	local THead
	local Accessory
	local Handle

	if TCharacter:FindFirstChildOfClass("Humanoid") then
		THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
	end
	if THumanoid and THumanoid.RootPart then
		TRootPart = THumanoid.RootPart
	end
	if TCharacter:FindFirstChild("Head") then
		THead = TCharacter.Head
	end
	if TCharacter:FindFirstChildOfClass("Accessory") then
		Accessory = TCharacter:FindFirstChildOfClass("Accessory")
	end
	if Accessory and Accessory:FindFirstChild("Handle") then
		Handle = Accessory.Handle
	end

	if Character and Humanoid and RootPart then
		if RootPart.Velocity.Magnitude < 50 then
			getgenv().OldPos = RootPart.CFrame
		end
		if THead then
			workspace.CurrentCamera.CameraSubject = THead
		elseif not THead and Handle then
			workspace.CurrentCamera.CameraSubject = Handle
		elseif THumanoid and TRootPart then
			workspace.CurrentCamera.CameraSubject = THumanoid
		end
		if not TCharacter:FindFirstChildWhichIsA("BasePart") then
			return
		end
		
		local FPos = function(BasePart, Pos, Ang)
			RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
			Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
			RootPart.Velocity = Vector3.new(flingForce, flingForce * 10, flingForce)
			RootPart.RotVelocity = Vector3.new(flingForce * 20, flingForce * 20, flingForce * 20)
		end
		
		local SFBasePart = function(BasePart)
			local TimeToWait = duration or 2
			local Time = tick()
			local Angle = 0

			repeat
				if RootPart and THumanoid then
					if BasePart.Velocity.Magnitude < 50 then
						Angle = Angle + 100

						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
					else
						FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						
						FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
						task.wait()

						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						task.wait()
					end
				else
					break
				end
			until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or tick() > Time + TimeToWait
		end
		
		local previousDestroyHeight = workspace.FallenPartsDestroyHeight
		workspace.FallenPartsDestroyHeight = 0/0
		
		local BV = Instance.new("BodyVelocity")
		BV.Name = "EpixVel"
		BV.Parent = RootPart
		BV.Velocity = Vector3.new(flingForce, flingForce, flingForce)
		BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
		
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		
		if TRootPart and THead then
			if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
				SFBasePart(THead)
			else
				SFBasePart(TRootPart)
			end
		elseif TRootPart and not THead then
			SFBasePart(TRootPart)
		elseif not TRootPart and THead then
			SFBasePart(THead)
		elseif not TRootPart and not THead and Accessory and Handle then
			SFBasePart(Handle)
		end
		
		BV:Destroy()
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		workspace.CurrentCamera.CameraSubject = Humanoid
		
		repeat
			if Character and Humanoid and RootPart and getgenv().OldPos then
				RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
				Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
				Humanoid:ChangeState("GettingUp")
				table.foreach(Character:GetChildren(), function(_, x)
					if x:IsA("BasePart") then
						x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
					end
				end)
			end
			task.wait()
		until RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
		workspace.FallenPartsDestroyHeight = previousDestroyHeight
	end
end

FlingGroupBox:AddButton({Text="Fling Selected", Func=function()
	if not Options.FlingPlayer.Value then return end
	
	for selectedPlayer, isSelected in pairs(Options.FlingPlayer.Value) do
		if isSelected then
			local targetPlayer = Players:FindFirstChild(tostring(selectedPlayer))
			if targetPlayer and targetPlayer.Character then
				fling(targetPlayer, flingTime)
				task.wait(flingTime + 0.5)
			end
		end
	end
end})

FlingGroupBox:AddButton({Text="Fling All", Func=function()
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player and targetPlayer.Character then
			fling(targetPlayer, flingTime)
			task.wait(flingTime + 0.5)
		end
	end
end})

FlingGroupBox:AddDivider()

FlingGroupBox:AddSlider("FlingTime", {Text="Fling Time", Default=5, Min=1, Max=25, Rounding=1, Callback=function(v) flingTime = v end})
FlingGroupBox:AddSlider("FlingForce", {Text="Fling Force", Default=50000, Min=1, Max=9999999, Rounding=0, Callback=function(v) flingForce = v end})

local TeleportGroupBox = Tabs.Features:AddLeftGroupbox("Teleport", "map-pin")
local SpectateGroupBox = Tabs.Features:AddLeftGroupbox("Spectate", "eye")

local teleportPlayer = nil
local teleportType = "Instant (TP)"

TeleportGroupBox:AddDropdown("TeleportPlayer", {
	Text = "Select Player",
	Values = getPlayerList(),
	Callback = function(v) teleportPlayer = Players:FindFirstChild(v) end
})

local noclipDuringTween = false
TeleportGroupBox:AddButton({Text="Teleport To Player", Func=function()
	if not teleportPlayer or not teleportPlayer.Character or not teleportPlayer.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	local target = teleportPlayer.Character.HumanoidRootPart
	local wasNoclip = Toggles.Noclip.Value
	if teleportType == "Tween (Fast)" and Toggles.NoclipOnTween.Value then
		Toggles.Noclip:SetValue(true)
		noclipDuringTween = true
	end
	if teleportType == "Instant (TP)" then
		if rootpart then rootpart.CFrame = target.CFrame end
	else
		if rootpart then
			local dist = (rootpart.Position - target.Position).Magnitude
			local tween = TweenService:Create(rootpart, TweenInfo.new(dist/500, Enum.EasingStyle.Linear), {CFrame = target.CFrame})
			tween:Play()
			tween.Completed:Wait()
			if Toggles.NoclipOnTween.Value and not wasNoclip then
				Toggles.Noclip:SetValue(false)
				noclipDuringTween = false
			end
		end
	end
end})

TeleportGroupBox:AddDropdown("TeleportType", {Text="Teleport Type", Values={"Instant (TP)","Tween (Fast)"}, Default="Instant (TP)", Callback=function(v) teleportType = v end})
TeleportGroupBox:AddToggle("NoclipOnTween", {Text="Noclip During Tween", Default=false})

local spectatePlayer = nil
local spectateType = "Third Person"

local function updateSpectate()
	if Toggles.SpectatePlayer.Value and spectatePlayer and spectatePlayer.Character then
		local humanoid = spectatePlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if spectateType == "First Person" then
				player.CameraMode = Enum.CameraMode.LockFirstPerson
				player.CameraMaxZoomDistance = 0
				camera.CameraSubject = humanoid
				camera.CameraType = Enum.CameraType.Custom
			else
				player.CameraMode = Enum.CameraMode.Classic
				player.CameraMaxZoomDistance = defaultMaxZoom
				camera.CameraSubject = humanoid
				camera.CameraType = Enum.CameraType.Follow
			end
		end
	else
		if character and humanoid then
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMaxZoomDistance = defaultMaxZoom
			camera.CameraSubject = humanoid
			camera.CameraType = Enum.CameraType.Custom
		end
	end
end

SpectateGroupBox:AddToggle("SpectatePlayer", {Text="Spectate Player", Default=false, Callback=function(v)
	updateSpectate()
end})

SpectateGroupBox:AddDropdown("PlayerToSpectate", {
	Text = "Player To Spectate",
	Values = getPlayerList(),
	Searchable = true,
	Callback = function(v) 
		spectatePlayer = Players:FindFirstChild(v)
		if Toggles.SpectatePlayer.Value then
			updateSpectate()
		end
	end
})

SpectateGroupBox:AddDropdown("SpectateType", {
	Text = "Type",
	Values = {"First Person", "Third Person"},
	Default = "Third Person",
	Callback = function(v) 
		spectateType = v
		if Toggles.SpectatePlayer.Value then
			updateSpectate()
		end
	end
})

local FPSGroupBox = Tabs.Features:AddRightGroupbox("FPS", "activity")

local fpsValue = 60
FPSGroupBox:AddSlider("FPSMeter", {Text="FPS Cap", Default=60, Min=1, Max=1024, Rounding=0, Callback=function(v) fpsValue = v end})
FPSGroupBox:AddButton({Text="Apply FPS Cap", Func=function() setfpscap(fpsValue) end})

local ServerGroupBox = Tabs.Features:AddRightGroupbox("Server", "server")

ServerGroupBox:AddButton({Text = "Copy Server JobID", Func = function()
	setclipboard(game.JobId)
end})

ServerGroupBox:AddButton({Text = "Copy Server Join Link", Func = function()
	local link = string.format("roblox://placeId=%d&gameInstanceId=%s", game.PlaceId, game.JobId)
	setclipboard(link)
end})

ServerGroupBox:AddDivider()

local targetJobId = ""
ServerGroupBox:AddInput("TargetJobId", {
	Text = "Target Server JobID",
	Placeholder = "Enter JobId...",
	Callback = function(v) targetJobId = v:gsub("%s+", "") end
})

ServerGroupBox:AddButton({Text = "Join Server", Func = function()
	if targetJobId == "" or not targetJobId:match("^%w+%-") then
		return
	end
	TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, player)
end})

ServerGroupBox:AddDivider()

ServerGroupBox:AddButton({Text = "Rejoin Server", Func = function()
	if game.JobId == "" then return end
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end})
ServerGroupBox:AddToggle("RejoinBindButton", {Text="Rejoin BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:BindB("Rejoin", function() if game.JobId == "" then return end TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
    else
        BindButton:DelBindB("Rejoin")
    end
end})

ServerGroupBox:AddLabel("Rejoin Keybind"):AddKeyPicker("RejoinKeybind", {Default="R", Mode="Press", Text="Rejoin Server", Callback=function()
	if game.JobId == "" then return end
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end})

ServerGroupBox:AddButton({Text = "Quit Game", Func = function() game:Shutdown() end, Risky=true})

local AutoChatGroupBox = Tabs.Features:AddRightGroupbox("Auto-Chat", "message-square")
local ChatMaid = nil

local autoChatDelay = 1
local autoChatMessage = "hi!"
local autoChatType = "Infinite"
local autoChatLimit = 10

AutoChatGroupBox:AddToggle("AutoChat", {Text="Auto Chat", Default=false, Callback=function(v) 
    if v then
        if ChatMaid then ChatMaid:DoCleaning() end
        ChatMaid = Maid.new()

        local active = true
        ChatMaid:GiveTask(function() active = false end)
        task.spawn(function()
            local chatChannel = TextChatService.TextChannels:WaitForChild("RBXGeneral")
            local count = 0
            while active and task.wait(autoChatDelay) do
                if autoChatMessage == "" then continue end
                if not active then break end
                
                if autoChatType == "Infinite" then
                    chatChannel:SendAsync(autoChatMessage)
                elseif autoChatType == "Times" then
                    if count < autoChatLimit then
                        chatChannel:SendAsync(autoChatMessage)
                        count = count + 1
                    else
                        Toggles.AutoChat:SetValue(false)
                        active = false
                    end
                elseif autoChatType == "Seconds" then
                    local start = tick()
                    if tick() - start < autoChatLimit then
                         chatChannel:SendAsync(autoChatMessage)
                    else
                        Toggles.AutoChat:SetValue(false)
                        active = false
                    end
                end
            end
        end)
    else
        if ChatMaid then ChatMaid:DoCleaning() ChatMaid = nil end
    end
end})

AutoChatGroupBox:AddToggle("AutoChatBindButton", {Text="Auto Chat BindButton", Default=false, Callback=function(v)
    if v then
        BindButton:AddToggleBB("AutoChat", function() Toggles.AutoChat:SetValue(true) end, function() Toggles.AutoChat:SetValue(false) end)
    else
        BindButton:DelBindB("AutoChat")
    end
end})
AutoChatGroupBox:AddSlider("AutoChatDelay", {Text="Auto Chat Delay", Default=1, Min=0, Max=5, Rounding=2, Callback=function(v) autoChatDelay = v end})
AutoChatGroupBox:AddInput("AutoChatMessage", {Text="Auto Chat Message", Default="hi!", Callback=function(v) autoChatMessage = v end})
AutoChatGroupBox:AddDropdown("AutoChatType", {Text="Auto Chat Type", Values={"Infinite", "Times", "Seconds"}, Default="Infinite", Callback=function(v) autoChatType = v end})
AutoChatGroupBox:AddInput("AutoChatLimit", {Text="Times / Seconds", Default="10", Callback=function(v) autoChatLimit = tonumber(v) or 10 end})

local CoreGui = game:GetService("CoreGui")

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "UNX_FOV_Circle"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.DisplayOrder = 999999999
FOVGui.Parent = CoreGui
MainMaid:GiveTask(FOVGui)

local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "Circle"
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.BackgroundTransparency = 1
FOVFrame.BorderSizePixel = 0
FOVFrame.Size = UDim2.new(0, 200, 0, 200)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Parent = FOVGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FOVFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2.5
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Transparency = 1
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = FOVFrame

local rainbowClock = 0
local function UpdateRainbowFOV()
    if Toggles.RainbowFOV.Value then
        rainbowClock = rainbowClock + (Options.RainbowFOVSpeed.Value / 100)
        local r = math.sin(rainbowClock) * 0.5 + 0.5
        local g = math.sin(rainbowClock + 2) * 0.5 + 0.5
        local b = math.sin(rainbowClock + 4) * 0.5 + 0.5
        UIStroke.Color = Color3.new(r, g, b)
    else
        UIStroke.Color = Options.FOVColor.Value
    end
end

local function UpdateFOV()
    if Toggles.ShowFOV.Value then
        local radius = Options.FOVSize.Value
        FOVFrame.Size = UDim2.new(0, radius * 2, 0, radius * 2)
        UIStroke.Transparency = Options.FOVColor.Transparency
        UIStroke.Thickness = Options.FOVStrokeThickness.Value

        if Options.FOVType.Value == "Centered" then
            FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        else
            local mousePos = UserInputService:GetMouseLocation()
            FOVFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
        end

        UpdateRainbowFOV()
        FOVGui.Enabled = true
    else
        FOVGui.Enabled = false
    end
end

local function IsValidTarget(plr)
    if not plr or plr == player then return false end
    if not plr.Character or not plr.Character:FindFirstChild("Head") or not plr.Character:FindFirstChild("Humanoid") then return false end
    if plr.Character.Humanoid.Health <= 0 then return false end
    if Toggles.IgnoreForceFielded and Toggles.IgnoreForceFielded.Value then
        if plr.Character:FindFirstChildOfClass("ForceField") then return false end
    end
    if Toggles.TeamCheck.Value and plr.Team == player.Team then return false end
    
    if Options.WhitelistPlayers.Value then
        for whitelistedPlayer, isWhitelisted in pairs(Options.WhitelistPlayers.Value) do
            if isWhitelisted and plr.Name == tostring(whitelistedPlayer) then
                return false
            end
        end
    end

    if Options.IgnoreTeam.Value then
        for teamName, ignored in pairs(Options.IgnoreTeam.Value) do
             if ignored and plr.Team and plr.Team.Name == teamName then
                local isExcludedFromExclusion = false
                if Options.ExcludeFromTeamExclusion.Value and Options.ExcludeFromTeamExclusion.Value[plr.Name] then
                    isExcludedFromExclusion = true
                end

                if not isExcludedFromExclusion then
                    return false
                end
             end
        end
    end
    
    return true
end

local function HasLineOfSight(targetHead)
    if not Toggles.WallCheck.Value then return true end
    local result = Workspace:Raycast(camera.CFrame.Position, (targetHead.Position - camera.CFrame.Position).Unit * 500, AimcastParams)
    return not result or result.Instance:IsDescendantOf(targetHead.Parent)
end

local function GetClosestPlayer()
    if Options.AimlockCertainPlayer.Value and Options.AimlockCertainPlayer.Value ~= "" then
        local certainPlayerValue = tostring(Options.AimlockCertainPlayer.Value)
        local certainPlayer = Players:FindFirstChild(certainPlayerValue)
        if certainPlayer and IsValidTarget(certainPlayer) then
            local head = certainPlayer.Character:FindFirstChild("Head")
            if head and HasLineOfSight(head) then
                local worldDist = (head.Position - camera.CFrame.Position).Magnitude
                local maxDist = Options.AimlockType.Value == "Nearest Mouse" and Options.MouseMaxDist.Value or Options.AimlockMaxDist.Value
                if worldDist <= maxDist then
                    return certainPlayer
                end
            end
        end
        return nil
    end

    local closest = nil
    local shortestDistance = math.huge
    local mousePos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y + 36)
    local centerPos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    local checkPos = Options.AimlockType.Value == "Nearest Mouse" and mousePos or centerPos

    for _, plr in Players:GetPlayers() do
        if IsValidTarget(plr) then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local distMult = 1
                if Options.PrioritizePlayers.Value then
                    for prioritizedPlayer, isPrio in pairs(Options.PrioritizePlayers.Value) do
                        if isPrio and plr.Name == tostring(prioritizedPlayer) then
                            distMult = 0.5
                            break
                        end
                    end
                end
                
                if distMult == 1 and Options.PrioritizeTeam.Value then
                    for teamName, prioritized in pairs(Options.PrioritizeTeam.Value) do
                        if prioritized and plr.Team and plr.Team.Name == teamName then
                            distMult = 0.5
                            break
                        end
                    end
                end

                local worldDist = (head.Position - camera.CFrame.Position).Magnitude
                local maxDist = Options.AimlockType.Value == "Nearest Mouse" and Options.MouseMaxDist.Value or Options.AimlockMaxDist.Value

                if worldDist <= maxDist then
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - checkPos).Magnitude * distMult
                        if distance < shortestDistance then
                             if Toggles.EnableFOV.Value then
                                local fovCenter = Options.FOVType.Value == "Centered" and centerPos or mousePos
                                if (Vector2.new(screenPos.X, screenPos.Y) - fovCenter).Magnitude <= Options.FOVSize.Value then
                                    if HasLineOfSight(head) then
                                        shortestDistance = distance
                                        closest = plr
                                    end
                                end
                            else
                                if HasLineOfSight(head) then
                                    shortestDistance = distance
                                    closest = plr
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return closest
end

MainMaid:GiveTask(RunService.RenderStepped:Connect(function()
    UpdateFOV()

    if Toggles.EnableAimlock.Value then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local offset = Vector3.new(Options.AimlockOffsetX.Value * 10, Options.AimlockOffsetY.Value * 10, 0)
            local targetPos = head.Position + offset

            if Toggles.SmoothAimlock.Value then
                local smoothness = Options.AimbotSmoothness.Value / 100
                camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, targetPos), smoothness)
            else
                camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
            end
        end
    end
end))

local orbitStartTime = 0
local orbitCurrentIndex = 1

MainMaid:GiveTask(RunService.RenderStepped:Connect(function()
    if Toggles.EnableOrbit.Value and character and rootpart then
        local targets = {}
        if Options.OrbitPlayers.Value then
            for name, selected in pairs(Options.OrbitPlayers.Value) do
                if selected then
                    local p = Players:FindFirstChild(name)
                    if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        table.insert(targets, p.Character.HumanoidRootPart)
                    end
                end
            end
        end

        if #targets > 0 then
            if #targets > 1 and Options.OrbitTime.Value > 0 then
                if tick() - orbitStartTime > Options.OrbitTime.Value then
                    orbitStartTime = tick()
                    orbitCurrentIndex = orbitCurrentIndex + 1
                    if orbitCurrentIndex > #targets then orbitCurrentIndex = 1 end
                end
            elseif #targets == 1 then
                orbitCurrentIndex = 1
            end

            local targetPart = targets[orbitCurrentIndex]
            if targetPart then
                local speed = Options.OrbitSpeed.Value
                local radius = Options.OrbitOffset.Value
                local rot = tick() * (speed / 10)
                local x = math.cos(rot) * radius
                local z = math.sin(rot) * radius
                rootpart.CFrame = CFrame.new(targetPart.Position) * CFrame.new(x, 0, z)
                rootpart.CFrame = CFrame.new(rootpart.Position, targetPart.Position)
                rootpart.Velocity = Vector3.zero
            end
        end
    end
end))

MainMaid:GiveTask(RunService.Stepped:Connect(function()
	if not character or not humanoid or not rootpart then return end

	if Toggles.Noclip.Value or noclipDuringTween then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
    
    if Toggles.NoclipCamera and Toggles.NoclipCamera.Value then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = character or player.CharacterAdded:Wait()
    end

	if Toggles.ForceThirdPerson and Toggles.ForceThirdPerson.Value then
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = Options.MaxZoom.Value
	end

    if Toggles.LockWalkspeed.Value then
        humanoid.WalkSpeed = Options.Walkspeed.Value
    end
    
    if Toggles.LockJumppower.Value then
        humanoid.JumpPower = Options.Jumppower.Value
    end

	player.CameraMaxZoomDistance = Options.MaxZoom.Value

    if Toggles.LockGravity.Value then
        Workspace.Gravity = Options.Gravity.Value
    end

	camera.FieldOfView = Options.FOV.Value
end))

Toggles.Noclip:OnChanged(function()
	if not Toggles.Noclip.Value and not noclipDuringTween and character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
end)

MainMaid:GiveTask(UserInputService.JumpRequest:Connect(function()
	if Toggles.InfiniteJump and Toggles.InfiniteJump.Value and humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", {Default=Library.KeybindFrame.Visible, Text="Open Keybind Menu", Callback=function(v) Library.KeybindFrame.Visible = v end})
MenuGroup:AddToggle("ShowCustomCursor", {Text="Custom Cursor", Default=true, Callback=function(v) Library.ShowCustomCursor = v end})
MenuGroup:AddDropdown("NotificationSide", {Values={"Left","Right"}, Default="Right", Text="Notification Side", Callback=function(v) Library:SetNotifySide(v) end})
MenuGroup:AddDropdown("DPIDropdown", {Values={"50%","75%","100%","125%","150%","175%","200%"}, Default="100%", Text="DPI Scale", Callback=function(v) Library:SetDPIScale(tonumber(v:gsub("%%",""))/100) end})
MenuGroup:AddDivider()
MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)
MenuGroup:AddLabel("<font color='rgb(255,0,0)'><u>DISCLAIMER</u></font>: We Use This To See How Many Users We Get, <u>We Do Not Share This Information With Any Third Partys</u>.", true)
MenuGroup:AddCheckbox("OptOutLog", {
	Text = "Opt-Out Log",
	Default = isfile("optout.unx"),
	Callback = function(Value)
		if Value then
			writefile("optout.unx", "")
		else
			if isfile("optout.unx") then
				delfile("optout.unx")
			end
		end
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default="U", NoUI=true, Text="Menu keybind"})
Library.ToggleKeybind = Options.MenuKeybind

local BindButtonGroup = Tabs["UI Settings"]:AddRightGroupbox("Bind Button")
BindButtonGroup:AddSlider("BindButtonSize", {Text="Size Scale", Default=1, Min=0.5, Max=2, Rounding=1, Callback=function(v) BindButton:SetSizeB(v) end})
BindButtonGroup:AddDropdown("BindButtonShape", {Values={"Round", "Square", "Slight Round"}, Default=1, Text="Shape", Callback=function(v) 
    if v == "Round" then BindButton:MakeAllShape(0)
    elseif v == "Square" then BindButton:MakeAllShape(1)
    elseif v == "Slight Round" then BindButton:MakeAllShape(2) end
end})
BindButtonGroup:AddButton("Reset Positions", function() BindButton:ResetPos() end)

Library:OnUnload(function()
    MainMaid:Destroy()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("unxhub")
SaveManager:SetFolder("unxhub")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

local function refreshPlayers()
	task.wait(1)
	if Options.TeleportPlayer then Options.TeleportPlayer:SetValues(getPlayerList()) end
	if Options.PlayerToSpectate then Options.PlayerToSpectate:SetValues(getPlayerList()) end
	if Options.FlingPlayer then Options.FlingPlayer:SetValues(getPlayerList()) end
    if Options.ESPTeamOnly then Options.ESPTeamOnly:SetValues(getTeamList()) end
    if Options.OutlineTeamOnly then Options.OutlineTeamOnly:SetValues(getTeamList()) end
    if Options.TracersTeamOnly then Options.TracersTeamOnly:SetValues(getTeamList()) end
    if Options.IgnoreTeam then Options.IgnoreTeam:SetValues(getTeamList()) end
    if Options.PrioritizeTeam then Options.PrioritizeTeam:SetValues(getTeamList()) end
    if Options.ESPPlayersOnly then Options.ESPPlayersOnly:SetValues(getPlayerList()) end
    if Options.OutlinePlayersOnly then Options.OutlinePlayersOnly:SetValues(getPlayerList()) end
    if Options.TracersPlayersOnly then Options.TracersPlayersOnly:SetValues(getPlayerList()) end
    if Options.OrbitPlayers then Options.OrbitPlayers:SetValues(getPlayerList()) end
    if Options.ExcludeFromTeamExclusion then Options.ExcludeFromTeamExclusion:SetValues(getPlayerList()) end
end

MainMaid:GiveTask(Players.PlayerAdded:Connect(refreshPlayers))
MainMaid:GiveTask(Players.PlayerRemoving:Connect(refreshPlayers))
refreshPlayers()
