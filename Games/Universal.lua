-- telling ya they onto me

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

--[[
ah = ...

if ah then
	print(ah)
end
]]

local Maid = loadstring([[
local Maid = {}
Maid.ClassName = "Maid"
Maid.__index = Maid

local typeof = typeof
local type = type
local pcall = pcall

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
		pcall(task.Disconnect, task)
	elseif t == "Instance" then
		pcall(task.Destroy, task)
	elseif t == "function" then
		pcall(task)
	elseif t == "table" then
		if type(task.Remove) == "function" then
			pcall(task.Remove, task)
		elseif type(task.Destroy) == "function" then
			pcall(task.Destroy, task)
		elseif type(task.DoCleaning) == "function" then
			pcall(task.DoCleaning, task)
		end
	end
end

Maid.CleanupTask = cleanupTask

function Maid:Give(key, task)
	if self._destroyed then
		cleanupTask(task)
		return task
	end

	local existing = self._tasks[key]
	if existing ~= nil and existing ~= task then
		cleanupTask(existing)
	end

	self._tasks[key] = task
	return task
end

function Maid:GiveTask(task)
	if self._destroyed then
		cleanupTask(task)
		return task
	end

	self._tasks[#self._tasks + 1] = task
	return task
end

function Maid:Remove(key)
	local existing = self._tasks[key]
	if existing ~= nil then
		self._tasks[key] = nil
		cleanupTask(existing)
	end
end

function Maid:IsDestroyed()
	return self._destroyed
end

function Maid:DoCleaning()
	if self._destroyed then
		return
	end

	self._destroyed = true

	local tasks = self._tasks
	for key, task in pairs(tasks) do
		tasks[key] = nil
		cleanupTask(task)
	end
end

function Maid:Destroy()
	self:DoCleaning()
end

return Maid
]])()

local function fetch(url)
	local body
	for attempt = 1, 3 do
		local ok, res = pcall(game.HttpGet, game, url)
		if ok and type(res) == "string" and #res > 0 then
			body = res
			break
		end
		if attempt < 3 then
			task.wait(0.35 * attempt)
		end
	end
	if not body then
		error("[UNX]: Failed to download " .. url, 0)
	end
	local chunk, err = loadstring(body)
	if not chunk then
		error("[UNX]: Failed to compile " .. url .. " -> " .. tostring(err), 0)
	end
	return chunk()
end

local Library = fetch(repo .. "Library.lua")
local ThemeManager = fetch(repo .. "addons/ThemeManager.lua")
local SaveManager = fetch(repo .. "addons/SaveManager.lua")
local BindButton = fetch("https://apigetunx.vercel.app/Modules/v2/Bind.lua")

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
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VirtualUser = nil
pcall(function()
	VirtualUser = game:GetService("VirtualUser")
end)

local Instance_new = Instance.new
local Vector2_new = Vector2.new
local Vector3_new = Vector3.new
local Vector3_zero = Vector3.zero
local Vector2_zero = Vector2.zero
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local CFrame_fromOrientation = CFrame.fromOrientation
local Color3_new = Color3.new
local Color3_fromRGB = Color3.fromRGB
local Color3_fromHSV = Color3.fromHSV
local Color3_fromHex = Color3.fromHex
local UDim2_new = UDim2.new
local UDim_new = UDim.new

local clock = os.clock
local floor = math.floor
local abs = math.abs
local min = math.min
local max = math.max
local clamp = math.clamp
local rad = math.rad
local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local exp = math.exp
local huge = math.huge

local tclear = table.clear
local tsort = table.sort
local sformat = string.format
local ipairs = ipairs
local pairs = pairs
local type = type
local pcall = pcall
local typeof = typeof
local tostring = tostring
local tonumber = tonumber

local BLACK = Color3_fromRGB(0, 0, 0)
local WHITE = Color3_fromRGB(255, 255, 255)
local PITCH_LIMIT = rad(87)
local BTN_IDLE = Color3_fromHex("0b0b0d")
local BTN_HELD = Color3_fromHex("262434")
local BTN_STROKE = Color3_fromHex("262434")

local function resolveFont(name)
	if type(name) ~= "string" or name == "" or name == "Unknown" then
		return nil
	end

	local okEnum, enumItem = pcall(function()
		return Enum.Font[name]
	end)
	if not okEnum or typeof(enumItem) ~= "EnumItem" then
		return nil
	end

	local okFace, face = pcall(function()
		return Font.fromEnum(enumItem)
	end)
	if okFace and typeof(face) == "Font" then
		return face
	end

	return enumItem
end

local function applyFont(textObject, font)
	if font == nil then
		return
	end
	if typeof(font) == "Font" then
		textObject.FontFace = font
	else
		textObject.Font = font
	end
end

local FONT_NAMES = {}
local FONT_VALUES = {}
do
	local candidates = { "BuilderSans", "SourceSans", "SourceSansBold", "Roboto", "Arcade", "Gotham", "GothamBold", "Oswald", "Code", "SciFi", "Bodoni", "AmaticSC" }
	for i = 1, #candidates do
		local name = candidates[i]
		local font = resolveFont(name)
		if font ~= nil then
			FONT_NAMES[#FONT_NAMES + 1] = name
			FONT_VALUES[name] = font
		end
	end
end

local DEFAULT_FONT = FONT_VALUES[FONT_NAMES[1]]
local BUTTON_FONT = resolveFont("GothamBold") or resolveFont("SourceSansBold") or DEFAULT_FONT

local HasDrawing = false
pcall(function()
	HasDrawing = type(Drawing) == "table" and type(Drawing.new) == "function"
end)

local SetFpsCap = nil
pcall(function()
	SetFpsCap = setfpscap
end)

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

local IsTouch = UserInputService.TouchEnabled
local IsMouse = UserInputService.MouseEnabled
local IsMobile = IsTouch and not IsMouse

local defaultWalkSpeed = 16
local defaultJumpPower = 50
local defaultMaxZoom = player.CameraMaxZoomDistance
local defaultMinZoom = player.CameraMinZoomDistance
local defaultGravity = Workspace.Gravity
local defaultFieldOfView = camera.FieldOfView
local defaultCameraMode = player.CameraMode
local defaultOcclusionMode = player.DevCameraOcclusionMode
local xrayTransparency = 0.8

local character, humanoid, rootpart

local viewportSize = camera.ViewportSize
MainMaid:GiveTask(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	viewportSize = camera.ViewportSize
end))

MainMaid:GiveTask(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local cam = Workspace.CurrentCamera
	if cam then
		camera = cam
		viewportSize = cam.ViewportSize
	end
end))

local Hub = {}
local Init = {}
local Refreshers = {}

local function anySelected(set)
	if type(set) ~= "table" then
		return false
	end
	for _, v in pairs(set) do
		if v then
			return true
		end
	end
	return false
end

local function safeCall(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[UNX]: " .. tostring(err))
	end
	return ok
end

local function toggleValue(name)
	local t = Toggles[name]
	return t ~= nil and t.Value == true
end

local function optionValue(name, fallback)
	local o = Options[name]
	if o == nil then
		return fallback
	end
	local v = o.Value
	if v == nil then
		return fallback
	end
	return v
end

local Scheduler = {}
do
	local signals = {
		RenderStepped = RunService.RenderStepped,
		Stepped = RunService.Stepped,
		Heartbeat = RunService.Heartbeat,
	}
	local groups = {}

	for name, signal in pairs(signals) do
		groups[name] = {
			signal = signal,
			map = {},
			list = {},
			count = 0,
			conn = nil,
		}
	end

	local function sortEntries(a, b)
		if a.priority == b.priority then
			return a.key < b.key
		end
		return a.priority < b.priority
	end

	local function rebuild(group)
		local list = {}
		local n = 0
		for _, entry in pairs(group.map) do
			n += 1
			list[n] = entry
		end
		tsort(list, sortEntries)
		group.list = list
		group.count = n

		if n > 0 and not group.conn then
			group.conn = group.signal:Connect(function(a, b)
				local items = group.list
				for i = 1, #items do
					local entry = items[i]
					local ok, err = pcall(entry.fn, a, b)
					if not ok then
						warn("[UNX]: loop '" .. entry.key .. "' errored -> " .. tostring(err))
					end
				end
			end)
		elseif n == 0 and group.conn then
			group.conn:Disconnect()
			group.conn = nil
		end
	end

	function Scheduler.Bind(event, key, fn, priority)
		local group = groups[event]
		if not group then
			return
		end
		group.map[key] = { key = key, fn = fn, priority = priority or 50 }
		rebuild(group)
	end

	function Scheduler.Unbind(event, key)
		local group = groups[event]
		if not group or group.map[key] == nil then
			return
		end
		group.map[key] = nil
		rebuild(group)
	end

	function Scheduler.IsBound(event, key)
		local group = groups[event]
		return group ~= nil and group.map[key] ~= nil
	end

	function Scheduler.Destroy()
		for _, group in pairs(groups) do
			tclear(group.map)
			group.list = {}
			group.count = 0
			if group.conn then
				group.conn:Disconnect()
				group.conn = nil
			end
		end
	end
end

MainMaid:GiveTask(Scheduler.Destroy)

local CharacterParts = {}
local CharacterPartCount = 0
local CharacterMaid = Maid.new()
MainMaid:Give("CharacterMaid", CharacterMaid)

local CharacterChangedCallbacks = {}
local function onCharacterReady(fn)
	CharacterChangedCallbacks[#CharacterChangedCallbacks + 1] = fn
end

local function rebuildCharacterParts()
	tclear(CharacterParts)
	CharacterPartCount = 0
	if not character then
		return
	end
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			CharacterPartCount += 1
			CharacterParts[CharacterPartCount] = obj
		end
	end
end

local function bindCharacter(c)
	if not c or not c.Parent then
		return
	end

	CharacterMaid:DoCleaning()
	CharacterMaid = Maid.new()
	MainMaid:Give("CharacterMaid", CharacterMaid)

	character = c
	humanoid = c:FindFirstChildOfClass("Humanoid") or c:WaitForChild("Humanoid", 10)
	rootpart = c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart", 10)

	AimcastParams.FilterDescendantsInstances = { c }

	if humanoid then
		pcall(function()
			humanoid.UseJumpPower = true
		end)
		defaultWalkSpeed = humanoid.WalkSpeed
		defaultJumpPower = humanoid.JumpPower
	end

	rebuildCharacterParts()

	CharacterMaid:GiveTask(c.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then
			CharacterPartCount += 1
			CharacterParts[CharacterPartCount] = obj
		end
	end))

	CharacterMaid:GiveTask(c.DescendantRemoving:Connect(function(obj)
		if obj:IsA("BasePart") then
			for i = 1, CharacterPartCount do
				if CharacterParts[i] == obj then
					CharacterParts[i] = CharacterParts[CharacterPartCount]
					CharacterParts[CharacterPartCount] = nil
					CharacterPartCount -= 1
					break
				end
			end
		end
	end))

	for i = 1, #CharacterChangedCallbacks do
		safeCall(CharacterChangedCallbacks[i], c)
	end
end

if player.Character then
	bindCharacter(player.Character)
end
MainMaid:GiveTask(player.CharacterAdded:Connect(bindCharacter))
MainMaid:GiveTask(player.CharacterRemoving:Connect(function()
	tclear(CharacterParts)
	CharacterPartCount = 0
	character, humanoid, rootpart = nil, nil, nil
end))

if not character then
	task.spawn(function()
		local c = player.CharacterAdded:Wait()
		if not character then
			bindCharacter(c)
		end
	end)
end

local function inSet(set, instance, name)
	if type(set) ~= "table" then
		return false
	end
	if set[instance] == true then
		return true
	end
	return name ~= nil and set[name] == true
end

local function resolvePlayerValue(value)
	if value == nil then
		return nil
	end
	if typeof(value) == "Instance" then
		return value:IsA("Player") and value or nil
	end
	local name = tostring(value)
	if name == "" then
		return nil
	end
	local found = Players:FindFirstChild(name)
	if found and found:IsA("Player") then
		return found
	end
	return nil
end

local Tracked = {}
local TrackedCount = 0
local TrackedByPlayer = {}
local TrackedMaid = Maid.new()
MainMaid:GiveTask(TrackedMaid)

local TrackedReleaseCallbacks = {}

local function releaseEntryVisuals(entry, full)
	for i = 1, #TrackedReleaseCallbacks do
		safeCall(TrackedReleaseCallbacks[i], entry, full)
	end
end

local function bindTrackedCharacter(entry, char)
	releaseEntryVisuals(entry)
	entry.character = char
	entry.head = nil
	entry.hrp = nil
	entry.humanoid = nil
	entry.alive = false
	entry.onScreen = false

	if not char then
		return
	end

	task.spawn(function()
		local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 10)
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 10)
		local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
		if entry.character == char then
			entry.head = head
			entry.hrp = hrp
			entry.humanoid = hum
		end
	end)
end

local function addTracked(plr)
	if plr == player or TrackedByPlayer[plr] then
		return
	end

	local entry = {
		player = plr,
		name = plr.Name,
		character = nil,
		head = nil,
		hrp = nil,
		humanoid = nil,
		alive = false,
		onScreen = false,
		screenX = 0,
		screenY = 0,
		dist = 0,
		distSq = 0,
	}

	TrackedCount += 1
	Tracked[TrackedCount] = entry
	TrackedByPlayer[plr] = entry

	local id = tostring(plr.UserId)
	TrackedMaid:Give("CA_" .. id, plr.CharacterAdded:Connect(function(c)
		bindTrackedCharacter(entry, c)
	end))
	TrackedMaid:Give("CR_" .. id, plr.CharacterRemoving:Connect(function()
		bindTrackedCharacter(entry, nil)
	end))

	if plr.Character then
		bindTrackedCharacter(entry, plr.Character)
	end
end

local function removeTracked(plr)
	local entry = TrackedByPlayer[plr]
	if not entry then
		return
	end

	releaseEntryVisuals(entry, true)
	TrackedByPlayer[plr] = nil

	for i = 1, TrackedCount do
		if Tracked[i] == entry then
			Tracked[i] = Tracked[TrackedCount]
			Tracked[TrackedCount] = nil
			TrackedCount -= 1
			break
		end
	end

	local id = tostring(plr.UserId)
	TrackedMaid:Remove("CA_" .. id)
	TrackedMaid:Remove("CR_" .. id)
end

for _, p in ipairs(Players:GetPlayers()) do
	addTracked(p)
end

MainMaid:GiveTask(Players.PlayerAdded:Connect(addTracked))
MainMaid:GiveTask(Players.PlayerRemoving:Connect(removeTracked))

local projectionKeys = {}

local function updateProjections()
	local cam = camera
	local origin = (rootpart and rootpart.Parent and rootpart.Position) or cam.CFrame.Position

	for i = 1, TrackedCount do
		local entry = Tracked[i]
		local char = entry.character
		local hrp = entry.hrp
		local hum = entry.humanoid

		if char and char.Parent and hrp and hrp.Parent and hum and hum.Health > 0 then
			local head = entry.head
			if not head or not head.Parent then
				head = hrp
			end
			entry.aimPart = head

			local headPos = head.Position
			local screenPos, onScreen = cam:WorldToViewportPoint(headPos)
			entry.screenX = screenPos.X
			entry.screenY = screenPos.Y
			entry.onScreen = onScreen

			local dx = hrp.Position.X - origin.X
			local dy = hrp.Position.Y - origin.Y
			local dz = hrp.Position.Z - origin.Z
			local distSq = dx * dx + dy * dy + dz * dz
			entry.distSq = distSq
			entry.dist = math.sqrt(distSq)
			entry.alive = true
		else
			entry.alive = false
			entry.onScreen = false
			entry.aimPart = nil
		end
	end
end

local function setProjectionUser(key, enabled)
	if enabled then
		projectionKeys[key] = true
	else
		projectionKeys[key] = nil
	end

	if next(projectionKeys) then
		if not Scheduler.IsBound("RenderStepped", "Projection") then
			Scheduler.Bind("RenderStepped", "Projection", updateProjections, 30)
		end
	else
		Scheduler.Unbind("RenderStepped", "Projection")
	end
end

local PlayerModule, Controls, ControlModule

local function resolveControls()
	if Controls and ControlModule then
		return true
	end
	local ok = pcall(function()
		local scripts = player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts", 10)
		if not scripts then
			return
		end
		local moduleScript = scripts:FindFirstChild("PlayerModule") or scripts:WaitForChild("PlayerModule", 10)
		if not moduleScript then
			return
		end
		PlayerModule = require(moduleScript)
		Controls = PlayerModule:GetControls()
		local controlScript = moduleScript:FindFirstChild("ControlModule") or moduleScript:WaitForChild("ControlModule", 10)
		if controlScript then
			ControlModule = require(controlScript)
		end
	end)
	return ok and Controls ~= nil
end

task.spawn(resolveControls)

local function getMoveVector()
	if not Controls then
		if not resolveControls() then
			return Vector3_zero
		end
	end
	local ok, mv = pcall(Controls.GetMoveVector, Controls)
	if not ok or typeof(mv) ~= "Vector3" then
		return Vector3_zero
	end
	local mag = mv.Magnitude
	if mag ~= mag or mag < 0.05 then
		return Vector3_zero
	end
	if mag > 1 then
		return mv / mag
	end
	return mv
end

local function makeFlightMovers(part, maid, rigid)
	if not part or not part:IsA("BasePart") then
		return nil, nil
	end

	local attachment = Instance_new("Attachment")
	attachment.Name = "UNX_FlightAttachment"
	attachment.Parent = part
	maid:GiveTask(attachment)

	local linear = Instance_new("LinearVelocity")
	linear.Name = "UNX_LinearVelocity"
	linear.Attachment0 = attachment
	linear.RelativeTo = Enum.ActuatorRelativeTo.World
	linear.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linear.VectorVelocity = Vector3_zero
	pcall(function()
		linear.MaxAxesForce = Vector3_new(huge, huge, huge)
	end)
	pcall(function()
		linear.MaxForce = huge
	end)
	linear.Parent = part
	maid:GiveTask(linear)

	local align = Instance_new("AlignOrientation")
	align.Name = "UNX_AlignOrientation"
	align.Attachment0 = attachment
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.RigidityEnabled = rigid ~= false
	align.CFrame = part.CFrame
	align.Parent = part
	maid:GiveTask(align)

	maid:GiveTask(function()
		if part and part.Parent then
			part.AssemblyLinearVelocity = Vector3_zero
			part.AssemblyAngularVelocity = Vector3_zero
		end
	end)

	return linear, align
end

do
local FlyGroupBox = Tabs.Main:AddRightGroupbox("Fly", "plane")
local FlyMaid = nil
local flySpeed = 5

local function stopFlying()
	Scheduler.Unbind("Heartbeat", "Fly")
	if FlyMaid then
		FlyMaid:DoCleaning()
		FlyMaid = nil
	end
end

local function startFlying()
	stopFlying()

	if not humanoid or not rootpart or not rootpart.Parent then
		return
	end

	FlyMaid = Maid.new()
	local maid = FlyMaid

	local hum = humanoid
	hum.PlatformStand = true
	maid:GiveTask(function()
		if hum and hum.Parent then
			hum.PlatformStand = false
		end
	end)

	local linear, align = makeFlightMovers(rootpart, maid, true)
	if not linear then
		stopFlying()
		return
	end

	resolveControls()

	local lastVelocity = Vector3_zero

	Scheduler.Bind("Heartbeat", "Fly", function()
		if not linear.Parent or not align.Parent or not rootpart or not rootpart.Parent then
			if Toggles.Fly then
				Toggles.Fly:SetValue(false)
			end
			return
		end

		local camCF = camera.CFrame
		align.CFrame = camCF

		local mv = getMoveVector()
		local velocity
		if mv == Vector3_zero then
			velocity = Vector3_zero
		else
			velocity = camCF:VectorToWorldSpace(mv) * (flySpeed * 10)
		end

		if velocity ~= lastVelocity then
			lastVelocity = velocity
			linear.VectorVelocity = velocity
		end
	end, 20)
end

FlyGroupBox:AddToggle("Fly", {Text="Fly", Default=false, Callback=function(v)
	if v then
		startFlying()
	else
		stopFlying()
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

FlyGroupBox:AddSlider("FlySpeed", {Text="Fly Speed", Default=5, Min=1, Max=75, Rounding=0, Callback=function(v)
	flySpeed = tonumber(v) or 5
end})

local VFlyGroupBox = Tabs.Main:AddRightGroupbox("VFly", "plane")
local VFlyMaid = nil

local vflySpeed = 100
local vflyMode = "Joystick"
local vflyMoveState = 0

local function createVFlyButtons(maid)
	local vflyUI = Instance_new("ScreenGui")
	vflyUI.Name = "UNX_VFly_Buttons"
	vflyUI.ResetOnSpawn = false
	vflyUI.IgnoreGuiInset = true
	vflyUI.DisplayOrder = 999999998
	vflyUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local okParent = pcall(function()
		vflyUI.Parent = CoreGui
	end)
	if not okParent then
		vflyUI.Parent = player:WaitForChild("PlayerGui")
	end
	maid:GiveTask(vflyUI)

	local frame = Instance_new("Frame")
	frame.Name = "Container"
	frame.Size = UDim2_new(0, 150, 0, 120)
	frame.Position = UDim2_new(0.85, 0, 0.6, 0)
	frame.BackgroundTransparency = 1
	frame.Active = false
	frame.Parent = vflyUI

	local function makeBtn(text, pos, state)
		local btn = Instance_new("TextButton")
		btn.Name = "VFly_" .. text
		btn.Text = text
		btn.Size = UDim2_new(0, 60, 0, 50)
		btn.Position = pos
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = BTN_IDLE
		btn.TextColor3 = WHITE
		applyFont(btn, BUTTON_FONT)
		btn.TextSize = 18
		btn.Parent = frame

		local corner = Instance_new("UICorner")
		corner.CornerRadius = UDim_new(0, 8)
		corner.Parent = btn

		local stroke = Instance_new("UIStroke")
		stroke.Color = BTN_STROKE
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn

		local activeInput = nil

		local function press(input)
			activeInput = input
			btn.BackgroundColor3 = BTN_HELD
			vflyMoveState = state
		end

		local function release()
			activeInput = nil
			btn.BackgroundColor3 = BTN_IDLE
			if vflyMoveState == state then
				vflyMoveState = 0
			end
		end

		maid:GiveTask(btn.InputBegan:Connect(function(input)
			local t = input.UserInputType
			if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
				press(input)
			end
		end))

		maid:GiveTask(btn.InputEnded:Connect(function(input)
			if input == activeInput or activeInput == nil then
				release()
			end
		end))

		maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
			if activeInput and input == activeInput then
				release()
			end
		end))

		maid:GiveTask(release)
	end

	makeBtn("^", UDim2_new(0.3, 0, 0, 0), 1)
	makeBtn("v", UDim2_new(0.3, 0, 0.5, 0), -1)
end

local function stopVFly()
	Scheduler.Unbind("RenderStepped", "VFly")
	vflyMoveState = 0
	if VFlyMaid then
		VFlyMaid:DoCleaning()
		VFlyMaid = nil
	end
end

local function startVFly()
	stopVFly()

	local char = player.Character
	if not char then
		return
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local target = (hum and hum.SeatPart) or root
	if not target or not target:IsA("BasePart") then
		return
	end

	VFlyMaid = Maid.new()
	local maid = VFlyMaid

	local linear, align = makeFlightMovers(target, maid, true)
	if not linear then
		stopVFly()
		return
	end

	if vflyMode == "Buttons" then
		createVFlyButtons(maid)
	end

	resolveControls()

	local lastVelocity = Vector3_zero

	Scheduler.Bind("RenderStepped", "VFly", function()
		if not target.Parent or not linear.Parent or not align.Parent then
			if Toggles.VFly then
				Toggles.VFly:SetValue(false)
			end
			return
		end

		local camCF = camera.CFrame
		align.CFrame = camCF

		local speed = vflySpeed
		local velocity = Vector3_zero

		if vflyMode == "Joystick" then
			local mv = getMoveVector()
			if mv ~= Vector3_zero then
				local dir = (camCF.LookVector * -mv.Z) + (camCF.RightVector * mv.X)
				local mag = dir.Magnitude
				if mag > 1e-4 then
					velocity = (dir / mag) * speed
				end
			end
		elseif vflyMoveState ~= 0 then
			velocity = camCF.LookVector * (speed * vflyMoveState)
		end

		if velocity ~= lastVelocity then
			lastVelocity = velocity
			linear.VectorVelocity = velocity
		end
	end, 20)
end

VFlyGroupBox:AddToggle("VFly", {Text="VFly", Default=false, Callback=function(v)
	if v then
		startVFly()
	else
		stopVFly()
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
	vflySpeed = clamp(tonumber(v) or 100, 0, 100000)
end})

VFlyGroupBox:AddDropdown("VFlyMode", {Text="VFly Mode", Values={"Joystick", "Buttons"}, Default="Joystick", Callback=function(v)
	if vflyMode == v then
		return
	end
	vflyMode = v
	if toggleValue("VFly") then
		startVFly()
	end
end})

MainMaid:GiveTask(function()
	stopFlying()
end)
MainMaid:GiveTask(function()
	stopVFly()
end)

onCharacterReady(function()
	if toggleValue("Fly") then
		task.defer(startFlying)
	end
	if toggleValue("VFly") then
		task.defer(startVFly)
	end
end)

end

do
local LeftMain = Tabs.Main:AddLeftGroupbox("Character", "user")

local LockMaid = Maid.new()
MainMaid:Give("LockMaid", LockMaid)
local applyingLock = false

local function rebuildLocks()
	LockMaid:DoCleaning()
	LockMaid = Maid.new()
	MainMaid:Give("LockMaid", LockMaid)

	if toggleValue("LockWalkspeed") and humanoid then
		local hum = humanoid
		local function apply()
			if applyingLock or not hum.Parent then
				return
			end
			local target = optionValue("Walkspeed", defaultWalkSpeed)
			if hum.WalkSpeed ~= target then
				applyingLock = true
				hum.WalkSpeed = target
				applyingLock = false
			end
		end
		apply()
		LockMaid:GiveTask(hum:GetPropertyChangedSignal("WalkSpeed"):Connect(apply))
	end

	if toggleValue("LockJumppower") and humanoid then
		local hum = humanoid
		local function apply()
			if applyingLock or not hum.Parent then
				return
			end
			local target = optionValue("Jumppower", defaultJumpPower)
			if hum.JumpPower ~= target then
				applyingLock = true
				pcall(function()
					hum.UseJumpPower = true
				end)
				hum.JumpPower = target
				applyingLock = false
			end
		end
		apply()
		LockMaid:GiveTask(hum:GetPropertyChangedSignal("JumpPower"):Connect(apply))
	end

	if toggleValue("LockGravity") then
		local function apply()
			if applyingLock then
				return
			end
			local target = optionValue("Gravity", defaultGravity)
			if Workspace.Gravity ~= target then
				applyingLock = true
				Workspace.Gravity = target
				applyingLock = false
			end
		end
		apply()
		LockMaid:GiveTask(Workspace:GetPropertyChangedSignal("Gravity"):Connect(apply))
	end
end

LeftMain:AddToggle("LockWalkspeed", {Text="Lock Walkspeed", Default=true, Callback=function()
	rebuildLocks()
end})
LeftMain:AddToggle("LockWalkspeedBindButton", {Text="Lock Walkspeed BindButton", Default=false, Callback=function(v)
	if v then
		BindButton:AddToggleBB("Lock WS", function() Toggles.LockWalkspeed:SetValue(true) end, function() Toggles.LockWalkspeed:SetValue(false) end)
	else
		BindButton:DelBindB("Lock WS")
	end
end})
LeftMain:AddSlider("Walkspeed", {Text="Walkspeed", Default=defaultWalkSpeed, Min=1, Max=500, Rounding=0, Callback=function(v)
	if humanoid and humanoid.Parent then
		applyingLock = true
		humanoid.WalkSpeed = v
		applyingLock = false
	end
end})

LeftMain:AddToggle("LockJumppower", {Text="Lock Jumppower", Default=true, Callback=function()
	rebuildLocks()
end})
LeftMain:AddToggle("LockJumppowerBindButton", {Text="Lock Jumppower BindButton", Default=false, Callback=function(v)
	if v then
		BindButton:AddToggleBB("Lock JP", function() Toggles.LockJumppower:SetValue(true) end, function() Toggles.LockJumppower:SetValue(false) end)
	else
		BindButton:DelBindB("Lock JP")
	end
end})
LeftMain:AddSlider("Jumppower", {Text="Jumppower", Default=defaultJumpPower, Min=1, Max=1000, Rounding=0, Callback=function(v)
	if humanoid and humanoid.Parent then
		applyingLock = true
		pcall(function()
			humanoid.UseJumpPower = true
		end)
		humanoid.JumpPower = v
		applyingLock = false
	end
end})

LeftMain:AddToggle("LockGravity", {Text="Lock Gravity", Default=true, Callback=function()
	rebuildLocks()
end})
LeftMain:AddToggle("LockGravityBindButton", {Text="Lock Gravity BindButton", Default=false, Callback=function(v)
	if v then
		BindButton:AddToggleBB("Lock Gravity", function() Toggles.LockGravity:SetValue(true) end, function() Toggles.LockGravity:SetValue(false) end)
	else
		BindButton:DelBindB("Lock Gravity")
	end
end})
LeftMain:AddSlider("Gravity", {Text="Gravity", Default=defaultGravity, Min=0, Max=500, Rounding=1, Callback=function(v)
	applyingLock = true
	Workspace.Gravity = v
	applyingLock = false
end})

onCharacterReady(function()
	rebuildLocks()
end)

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

local noclipDuringTween = false
local noclipTouched = {}

local function applyNoclip()
	for i = 1, CharacterPartCount do
		local part = CharacterParts[i]
		if part and part.CanCollide then
			noclipTouched[part] = true
			part.CanCollide = false
		end
	end
end

local function restoreNoclip()
	for part in pairs(noclipTouched) do
		if part and part.Parent then
			part.CanCollide = true
		end
		noclipTouched[part] = nil
	end
end

local function updateNoclipLoop()
	if toggleValue("Noclip") or noclipDuringTween then
		if not Scheduler.IsBound("Stepped", "Noclip") then
			Scheduler.Bind("Stepped", "Noclip", applyNoclip, 10)
		end
	else
		Scheduler.Unbind("Stepped", "Noclip")
		restoreNoclip()
	end
end

LeftMain:AddToggle("Noclip", {Text="Noclip", Default=false, Callback=updateNoclipLoop})
Toggles.Noclip:AddKeyPicker("NoclipKeybind", {Default="N", Mode="Toggle", Text="Noclip", SyncToggleState=true})
LeftMain:AddToggle("NoclipBindButton", {Text="Noclip BindButton", Default=false, Callback=function(v)
	if v then
		BindButton:AddToggleBB("Noclip", function() Toggles.Noclip:SetValue(true) end, function() Toggles.Noclip:SetValue(false) end)
	else
		BindButton:DelBindB("Noclip")
	end
end})

onCharacterReady(function()
	tclear(noclipTouched)
	updateNoclipLoop()
end)

local ThirdPersonMaid = Maid.new()
MainMaid:Give("ThirdPersonMaid", ThirdPersonMaid)

local function applyThirdPerson()
	if player.CameraMode ~= Enum.CameraMode.Classic then
		player.CameraMode = Enum.CameraMode.Classic
	end
	if player.CameraMinZoomDistance ~= 0.5 then
		player.CameraMinZoomDistance = 0.5
	end
end

local function updateThirdPerson(v)
	ThirdPersonMaid:DoCleaning()
	ThirdPersonMaid = Maid.new()
	MainMaid:Give("ThirdPersonMaid", ThirdPersonMaid)

	if v then
		applyThirdPerson()
		ThirdPersonMaid:GiveTask(player:GetPropertyChangedSignal("CameraMode"):Connect(applyThirdPerson))
		ThirdPersonMaid:GiveTask(player:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(applyThirdPerson))
		ThirdPersonMaid:GiveTask(function()
			player.CameraMinZoomDistance = defaultMinZoom
			player.CameraMode = defaultCameraMode
		end)
	end
end

LeftMain:AddToggle("ForceThirdPerson", {Text="Force Third Person", Default=false, Callback=updateThirdPerson})
LeftMain:AddToggle("ForceThirdPersonBindButton", {Text="Force Third Person BindButton", Default=false, Callback=function(v)
	if v then
		BindButton:AddToggleBB("3rd Person", function() Toggles.ForceThirdPerson:SetValue(true) end, function() Toggles.ForceThirdPerson:SetValue(false) end)
	else
		BindButton:DelBindB("3rd Person")
	end
end})

Hub.setTweenNoclip = function(state)
	noclipDuringTween = state
	updateNoclipLoop()
end

Init[#Init + 1] = rebuildLocks
Init[#Init + 1] = updateNoclipLoop
Init[#Init + 1] = function()
	updateThirdPerson(toggleValue("ForceThirdPerson"))
end

LeftMain:AddDivider()

local counterParts = {}
local counterChars = {}
local counterAccum = 0
local counterScan = 0

local function counterFlingScan(force)
	for i = 1, TrackedCount do
		local char = Tracked[i].character
		if char and char.Parent and (force or not counterChars[char]) then
			counterChars[char] = true
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and counterParts[part] == nil then
					counterParts[part] = part.CanCollide
				end
			end
		end
	end
end

local function counterFlingRestore()
	for part, original in pairs(counterParts) do
		if part.Parent and original then
			part.CanCollide = true
		end
		counterParts[part] = nil
	end
	tclear(counterChars)
end

local function counterFlingStep(dt)
	counterAccum += dt
	if counterAccum < 0.1 then
		return
	end
	counterAccum = 0

	counterScan += 0.1
	local force = false
	if counterScan >= 2 then
		counterScan = 0
		force = true
		for char in pairs(counterChars) do
			if not char.Parent then
				counterChars[char] = nil
			end
		end
	end
	counterFlingScan(force)

	for part in pairs(counterParts) do
		if not part.Parent then
			counterParts[part] = nil
		elseif part.CanCollide then
			part.CanCollide = false
		end
	end
end

LeftMain:AddToggle("CounterFling", {Text="Counter Fling", Default=false, Callback=function(v)
	if v then
		counterAccum = 0
		counterScan = 0
		counterFlingScan(true)
		Scheduler.Bind("Heartbeat", "CounterFling", counterFlingStep, 30)
	else
		Scheduler.Unbind("Heartbeat", "CounterFling")
		counterFlingRestore()
	end
end})

MainMaid:GiveTask(counterFlingRestore)

LeftMain:AddToggle("CounterVoid", {Text="Counter Void", Default=false, Callback=function(v)
	if not v then
		Scheduler.Unbind("Heartbeat", "CounterVoid")
		return
	end

	Scheduler.Bind("Heartbeat", "CounterVoid", function()
		local root = rootpart
		if not root or not root.Parent then
			return
		end
		local threshold = Workspace.FallenPartsDestroyHeight
		if threshold ~= threshold then
			threshold = -500
		end
		if root.Position.Y < threshold + 10 then
			local vel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3_new(vel.X, 100, vel.Z)
		end
	end, 15)
end})

local AFKMaid = nil

LeftMain:AddToggle("NoAFKKick", {Text="No AFK Kick", Default=false, Callback=function(v)
	if AFKMaid then
		AFKMaid:DoCleaning()
		AFKMaid = nil
	end

	if not v then
		return
	end

	AFKMaid = Maid.new()
	local maid = AFKMaid

	local function nudge()
		if not VirtualUser then
			return
		end
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2_zero)
		end)
	end

	maid:GiveTask(player.Idled:Connect(nudge))

	local alive = true
	maid:GiveTask(function()
		alive = false
	end)

	task.spawn(function()
		while alive do
			task.wait(60)
			if not alive then
				break
			end
			nudge()
		end
	end)
end})

LeftMain:AddDivider()

local XRayMaid = nil

local function startXRay()
	if XRayMaid then
		XRayMaid:DoCleaning()
	end
	XRayMaid = Maid.new()
	local maid = XRayMaid

	local originals = {}
	local alive = true
	maid:GiveTask(function()
		alive = false
		for obj, original in pairs(originals) do
			if obj.Parent then
				obj.Transparency = original
			end
			originals[obj] = nil
		end
	end)

	local function apply(obj)
		if not alive or originals[obj] ~= nil then
			return
		end
		if not obj:IsA("BasePart") or obj:IsA("Terrain") then
			return
		end
		if obj.Transparency >= 1 then
			return
		end
		if character and obj:IsDescendantOf(character) then
			return
		end
		originals[obj] = obj.Transparency
		obj.Transparency = xrayTransparency
	end

	task.spawn(function()
		local descendants = Workspace:GetDescendants()
		local total = #descendants
		local i = 1
		while alive and i <= total do
			local stop = min(i + 399, total)
			for j = i, stop do
				apply(descendants[j])
			end
			i = stop + 1
			if i <= total then
				RunService.Heartbeat:Wait()
			end
		end
	end)

	maid:GiveTask(Workspace.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then
			apply(obj)
		end
	end))

	maid:GiveTask(Workspace.DescendantRemoving:Connect(function(obj)
		local original = originals[obj]
		if original ~= nil then
			originals[obj] = nil
			obj.Transparency = original
		end
	end))
end

LeftMain:AddToggle("XRay", {Text="X-Ray", Default=false, Callback=function(v)
	if v then
		startXRay()
	elseif XRayMaid then
		XRayMaid:DoCleaning()
		XRayMaid = nil
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
	xrayTransparency = clamp(v / 100, 0, 1)
	if toggleValue("XRay") then
		startXRay()
	end
end})

local RightMain = Tabs.Main:AddRightGroupbox("Misc", "box")

RightMain:AddButton({Text="Reset Character", Func=function()
	if humanoid and humanoid.Parent then
		humanoid.Health = 0
	elseif character then
		pcall(function()
			character:BreakJoints()
		end)
	end
end})

RightMain:AddDivider()

RightMain:AddButton({Text="Reset Walk Speed", Func=function() Options.Walkspeed:SetValue(defaultWalkSpeed) end})
RightMain:AddButton({Text="Reset Jump Power", Func=function() Options.Jumppower:SetValue(defaultJumpPower) end})
RightMain:AddButton({Text="Reset Gravity", Func=function() Options.Gravity:SetValue(defaultGravity) end})

end

do
local ESPTabBox = Tabs.Visuals:AddLeftTabbox()
local ESPTab = ESPTabBox:AddTab("ESP")
local ESPConfigTab = ESPTabBox:AddTab("Config")
local GameVisuals = Tabs.Visuals:AddRightGroupbox("Game", "camera")

local espColor = Color3_new(1, 1, 1)
local outlineColor = Color3_new(1, 1, 1)
local tracersColor = Color3_new(1, 1, 1)
local outlineFillTransparency = 1
local outlineTransparency = 0
local espSize = 16
local espFont = DEFAULT_FONT
local showDistance = true
local showPlayerName = true
local rainbowSpeed = 5
local tracerOrigin = "Down"

local MAX_HIGHLIGHTS = 31

local espMaid = Maid.new()
MainMaid:GiveTask(espMaid)

local mousePos = Vector2_zero
local mouseTracked = false

local function setMouseTracking(enabled)
	if enabled == mouseTracked then
		return
	end
	mouseTracked = enabled
	if enabled then
		espMaid:Give("MouseTrack", UserInputService.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement then
				local pos = i.Position
				mousePos = Vector2_new(pos.X, pos.Y)
			end
		end))
	else
		espMaid:Remove("MouseTrack")
	end
end

local espFolder = nil

local function getEspFolder()
	if espFolder and espFolder.Parent then
		return espFolder
	end
	espFolder = Instance_new("Folder")
	espFolder.Name = "UNX_ESP"
	if not pcall(function()
		espFolder.Parent = CoreGui
	end) then
		espFolder.Parent = player:WaitForChild("PlayerGui")
	end
	return espFolder
end

local highlightPool = {}
local highlightPoolSize = 0

local function releaseHighlights()
	for i = 1, highlightPoolSize do
		local hl = highlightPool[i]
		if hl then
			hl:Destroy()
		end
		highlightPool[i] = nil
	end
	highlightPoolSize = 0
end

local function acquireHighlight(index)
	local hl = highlightPool[index]
	if hl and hl.Parent then
		return hl
	end
	hl = Instance_new("Highlight")
	hl.Name = "HL_" .. index
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Enabled = false
	hl.Parent = getEspFolder()
	highlightPool[index] = hl
	if index > highlightPoolSize then
		highlightPoolSize = index
	end
	return hl
end

local function destroyBillboard(entry)
	if entry.billboard then
		entry.billboard:Destroy()
		entry.billboard = nil
		entry.label = nil
		entry.stroke = nil
		entry.lastText = nil
		entry.lastDist = nil
		entry.lastSize = nil
		entry.lastFont = nil
		entry.lastColor = nil
		entry.lastStrokeColor = nil
	end
end

local function destroyTracer(entry)
	if entry.tracer then
		pcall(function()
			entry.tracer:Remove()
		end)
		entry.tracer = nil
	end
end

TrackedReleaseCallbacks[#TrackedReleaseCallbacks + 1] = function(entry, full)
	destroyBillboard(entry)
	if full then
		destroyTracer(entry)
	elseif entry.tracer and entry.tracer.Visible then
		entry.tracer.Visible = false
	end
end

local function ensureBillboard(entry, adornee)
	local billboard = entry.billboard
	if billboard then
		if billboard.Adornee ~= adornee then
			billboard.Adornee = adornee
		end
		return billboard
	end

	billboard = Instance_new("BillboardGui")
	billboard.Name = "Tag"
	billboard.Adornee = adornee
	billboard.Size = UDim2_new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3_new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.ResetOnSpawn = false
	billboard.Enabled = false
	billboard.Parent = getEspFolder()

	local label = Instance_new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2_new(1, 0, 1, 0)
	label.TextColor3 = espColor
	label.TextSize = espSize
	applyFont(label, espFont)
	label.Text = ""
	label.Parent = billboard

	local stroke = Instance_new("UIStroke")
	stroke.Thickness = 1.2
	stroke.Color = BLACK
	stroke.Transparency = 0
	stroke.Parent = label

	entry.billboard = billboard
	entry.label = label
	entry.stroke = stroke
	entry.lastText = nil
	entry.lastDist = nil
	entry.lastSize = nil
	entry.lastFont = nil
	entry.lastColor = nil
	entry.lastStrokeColor = nil
	return billboard
end

local function ensureTracer(entry)
	if entry.tracer then
		return entry.tracer
	end
	if not HasDrawing then
		return nil
	end
	local ok, line = pcall(Drawing.new, "Line")
	if not ok or not line then
		HasDrawing = false
		return nil
	end
	line.Visible = false
	line.Color = tracersColor
	line.Thickness = 1
	line.Transparency = 1
	entry.tracer = line
	return line
end

ESPTab:AddToggle("ESP", {Text="ESP", Default=false}):AddColorPicker("ESPColor", {Default=Color3_new(1,1,1), Title="ESP Color", Callback=function(v) espColor = v end})
ESPTab:AddToggle("Outline", {Text="Outline", Default=false}):AddColorPicker("OutlineColor", {Default=Color3_new(1,1,1), Title="Outline Color", Callback=function(v) outlineColor = v end})
ESPTab:AddToggle("Tracers", {Text="Tracers", Default=false}):AddColorPicker("TracersColor", {Default=Color3_new(1,1,1), Title="Tracers Color", Callback=function(v) tracersColor = v end})

ESPTab:AddDivider()

ESPTab:AddDropdown("ESPTeamOnly", { SpecialType = "Team", Multi = true, Text = "ESP Team Only", Searchable = true })
ESPTab:AddDropdown("OutlineTeamOnly", { SpecialType = "Team", Multi = true, Text = "Outline Team Only", Searchable = true })
ESPTab:AddDropdown("TracersTeamOnly", { SpecialType = "Team", Multi = true, Text = "Tracers Team Only", Searchable = true })

ESPTab:AddDivider()

ESPTab:AddDropdown("ESPPlayersOnly", { SpecialType = "Player", ExcludeLocalPlayer = true, Multi = true, Text = "ESP Players Only", Searchable = true })
ESPTab:AddDropdown("OutlinePlayersOnly", { SpecialType = "Player", ExcludeLocalPlayer = true, Multi = true, Text = "Outline Players Only", Searchable = true })
ESPTab:AddDropdown("TracersPlayersOnly", { SpecialType = "Player", ExcludeLocalPlayer = true, Multi = true, Text = "Tracers Players Only", Searchable = true })

local function makeFilter(teamKey, playerKey)
	local state = { teamSet = nil, playerSet = nil, teamHas = false, playerHas = false }

	function state.Refresh()
		local teamOption = Options[teamKey]
		local playerOption = Options[playerKey]
		state.teamSet = teamOption and teamOption.Value or nil
		state.playerSet = playerOption and playerOption.Value or nil
		state.teamHas = anySelected(state.teamSet)
		state.playerHas = anySelected(state.playerSet)
	end

	state.Refresh()

	pcall(function()
		Options[teamKey]:OnChanged(state.Refresh)
	end)
	pcall(function()
		Options[playerKey]:OnChanged(state.Refresh)
	end)

	return state
end

local function passesFilter(state, entry)
	if not state.teamHas and not state.playerHas then
		return true
	end
	if state.playerHas and inSet(state.playerSet, entry.player, entry.name) then
		return true
	end
	if state.teamHas then
		local team = entry.player.Team
		if team and inSet(state.teamSet, team, team.Name) then
			return true
		end
	end
	return false
end

local ESPFilter = makeFilter("ESPTeamOnly", "ESPPlayersOnly")
local OutlineFilter = makeFilter("OutlineTeamOnly", "OutlinePlayersOnly")
local TracersFilter = makeFilter("TracersTeamOnly", "TracersPlayersOnly")

local candidatePool = {}
local candidateList = {}
local candidateListSize = 0

local function sortByDistance(a, b)
	return a.dist < b.dist
end

local function espRender()
	local espOn = toggleValue("ESP")
	local outlineOn = toggleValue("Outline")
	local tracersOn = toggleValue("Tracers")

	local rainbowESP = toggleValue("RainbowESP")
	local rainbowOutline = toggleValue("RainbowOutline")
	local rainbowTracers = toggleValue("RainbowTracers")
	local teamESP = toggleValue("ESPColorFromTeam")
	local teamOutline = toggleValue("OutlineColorFromTeam")
	local teamTracers = toggleValue("TracersColorFromTeam")

	local rainbowColor, rainbowStroke
	if rainbowESP or rainbowOutline or rainbowTracers then
		local hue = (clock() * rainbowSpeed * 0.02) % 1
		rainbowColor = Color3_fromHSV(hue, 1, 1)
		rainbowStroke = Color3_fromHSV(hue, 1, 0.5)
	end

	local tracerFrom
	if tracersOn then
		if tracerOrigin == "Mouse" then
			tracerFrom = mousePos
		elseif tracerOrigin == "Upper" then
			tracerFrom = Vector2_new(viewportSize.X * 0.5, 0)
		elseif tracerOrigin == "Middle" then
			tracerFrom = Vector2_new(viewportSize.X * 0.5, viewportSize.Y * 0.5)
		else
			tracerFrom = Vector2_new(viewportSize.X * 0.5, viewportSize.Y)
		end
	end

	local candidateCount = 0

	for i = 1, TrackedCount do
		local entry = Tracked[i]

		if not entry.alive then
			if entry.billboard and entry.billboard.Enabled then
				entry.billboard.Enabled = false
			end
			if entry.tracer and entry.tracer.Visible then
				entry.tracer.Visible = false
			end
			continue
		end

		local onScreen = entry.onScreen
		local wantESP = espOn and onScreen and passesFilter(ESPFilter, entry)
		local wantOutline = outlineOn and onScreen and passesFilter(OutlineFilter, entry)
		local wantTracer = tracersOn and onScreen and passesFilter(TracersFilter, entry)

		if wantESP then
			local billboard = ensureBillboard(entry, entry.aimPart)
			local label = entry.label
			if billboard and label then
				if not billboard.Enabled then
					billboard.Enabled = true
				end

				local c = espColor
				if teamESP then
					local team = entry.player.Team
					if team then
						c = team.TeamColor.Color
					end
				end
				if rainbowESP then
					c = rainbowColor
				end
				if entry.lastColor ~= c then
					entry.lastColor = c
					label.TextColor3 = c
				end

				if entry.lastSize ~= espSize then
					entry.lastSize = espSize
					label.TextSize = espSize
				end
				if entry.lastFont ~= espFont then
					entry.lastFont = espFont
					applyFont(label, espFont)
				end

				local stroke = entry.stroke
				if stroke then
					local sc = rainbowESP and rainbowStroke or BLACK
					if entry.lastStrokeColor ~= sc then
						entry.lastStrokeColor = sc
						stroke.Color = sc
					end
				end

				local distInt = showDistance and floor(entry.dist) or -1
				if entry.lastDist ~= distInt or entry.lastText == nil then
					entry.lastDist = distInt
					local textStr
					if showPlayerName then
						if showDistance then
							textStr = entry.name .. " " .. sformat("[%d]", distInt)
						else
							textStr = entry.name
						end
					elseif showDistance then
						textStr = sformat("[%d]", distInt)
					else
						textStr = ""
					end
					if entry.lastText ~= textStr then
						entry.lastText = textStr
						label.Text = textStr
					end
				end
			end
		elseif entry.billboard and entry.billboard.Enabled then
			entry.billboard.Enabled = false
		end

		if wantOutline then
			candidateCount += 1
			local candidate = candidatePool[candidateCount]
			if not candidate then
				candidate = {}
				candidatePool[candidateCount] = candidate
			end
			candidate.char = entry.character
			candidate.dist = entry.dist
			local oc = outlineColor
			if teamOutline then
				local team = entry.player.Team
				if team then
					oc = team.TeamColor.Color
				end
			end
			if rainbowOutline then
				oc = rainbowColor
			end
			candidate.color = oc
			candidateList[candidateCount] = candidate
		end

		if wantTracer then
			local tracer = ensureTracer(entry)
			if tracer then
				local c = tracersColor
				if teamTracers then
					local team = entry.player.Team
					if team then
						c = team.TeamColor.Color
					end
				end
				if rainbowTracers then
					c = rainbowColor
				end
				tracer.Color = c
				tracer.From = tracerFrom
				tracer.To = Vector2_new(entry.screenX, entry.screenY)
				if not tracer.Visible then
					tracer.Visible = true
				end
			end
		elseif entry.tracer and entry.tracer.Visible then
			entry.tracer.Visible = false
		end
	end

	for i = candidateCount + 1, candidateListSize do
		candidateList[i] = nil
	end
	candidateListSize = candidateCount

	if candidateCount > 0 then
		if candidateCount > MAX_HIGHLIGHTS then
			tsort(candidateList, sortByDistance)
			candidateCount = MAX_HIGHLIGHTS
		end
		for i = 1, candidateCount do
			local candidate = candidateList[i]
			local hl = acquireHighlight(i)
			if hl.Adornee ~= candidate.char then
				hl.Adornee = candidate.char
			end
			if hl.OutlineColor ~= candidate.color then
				hl.OutlineColor = candidate.color
				hl.FillColor = candidate.color
			end
			if hl.OutlineTransparency ~= outlineTransparency then
				hl.OutlineTransparency = outlineTransparency
			end
			if hl.FillTransparency ~= outlineFillTransparency then
				hl.FillTransparency = outlineFillTransparency
			end
			if not hl.Enabled then
				hl.Enabled = true
			end
		end
	end

	for i = candidateCount + 1, highlightPoolSize do
		local hl = highlightPool[i]
		if hl and hl.Enabled then
			hl.Enabled = false
			hl.Adornee = nil
		end
	end
end

local function updateESPLoop()
	local espOn = toggleValue("ESP")
	local outlineOn = toggleValue("Outline")
	local tracersOn = toggleValue("Tracers")
	local anyOn = espOn or outlineOn or tracersOn

	setMouseTracking(tracersOn and tracerOrigin == "Mouse" and IsMouse)
	setProjectionUser("ESP", anyOn)

	if anyOn then
		if not Scheduler.IsBound("RenderStepped", "ESP") then
			Scheduler.Bind("RenderStepped", "ESP", espRender, 40)
		end
	else
		Scheduler.Unbind("RenderStepped", "ESP")
	end

	if not espOn then
		for i = 1, TrackedCount do
			destroyBillboard(Tracked[i])
		end
	end
	if not tracersOn then
		for i = 1, TrackedCount do
			destroyTracer(Tracked[i])
		end
	end
	if not outlineOn then
		releaseHighlights()
	end
	if not anyOn and espFolder then
		espFolder:Destroy()
		espFolder = nil
	end
end

Init[#Init + 1] = updateESPLoop

pcall(function() Toggles.ESP:OnChanged(updateESPLoop) end)
pcall(function() Toggles.Outline:OnChanged(updateESPLoop) end)
pcall(function() Toggles.Tracers:OnChanged(updateESPLoop) end)

espMaid:GiveTask(releaseHighlights)
espMaid:GiveTask(function()
	for i = 1, TrackedCount do
		local entry = Tracked[i]
		destroyBillboard(entry)
		destroyTracer(entry)
	end
	if espFolder then
		espFolder:Destroy()
		espFolder = nil
	end
end)

ESPConfigTab:AddToggle("RainbowESP", {Text="Rainbow ESP", Default=false})
ESPConfigTab:AddToggle("RainbowOutline", {Text="Rainbow Outline", Default=false})
ESPConfigTab:AddToggle("RainbowTracers", {Text="Rainbow Tracers", Default=false})
ESPConfigTab:AddSlider("RainbowSpeed", {Text="Rainbow Speed", Min=0, Max=10, Default=5, Rounding=1, Callback=function(v) rainbowSpeed = v end})
ESPConfigTab:AddSlider("ESPSize", {Text="ESP Size", Min=10, Max=30, Default=16, Rounding=0, Callback=function(v) espSize = v end})
ESPConfigTab:AddDropdown("ESPFont", {
	Text="ESP Font",
	Values = FONT_NAMES,
	Default = 1,
	Callback = function(v)
		espFont = FONT_VALUES[v] or DEFAULT_FONT
	end
})
ESPConfigTab:AddToggle("ShowDistance", {Text="Show Distance", Default=true, Callback=function(v)
	showDistance = v
	for i = 1, TrackedCount do
		Tracked[i].lastDist = nil
	end
end})
ESPConfigTab:AddToggle("ShowPlayerName", {Text="Show Player Name", Default=true, Callback=function(v)
	showPlayerName = v
	for i = 1, TrackedCount do
		Tracked[i].lastDist = nil
	end
end})
ESPConfigTab:AddSlider("OutlineFillTransparency", {Text="Outline Fill Transparency (%)", Min=0, Max=100, Default=100, Suffix="%", Rounding=0, Callback=function(v) outlineFillTransparency = v / 100 end})
ESPConfigTab:AddSlider("OutlineTransparency", {Text="Outline Transparency (%)", Min=0, Max=100, Default=0, Suffix="%", Rounding=0, Callback=function(v) outlineTransparency = v / 100 end})
ESPConfigTab:AddDropdown("TracersPosition", {Text="Tracers Position", Values={"Mouse","Upper","Middle","Down"}, Default="Down", Callback=function(v)
	tracerOrigin = v
	updateESPLoop()
end})
ESPConfigTab:AddToggle("ESPColorFromTeam", {Text="ESP Color From Team", Default=false})
ESPConfigTab:AddToggle("OutlineColorFromTeam", {Text="Outline Color From Team", Default=false})
ESPConfigTab:AddToggle("TracersColorFromTeam", {Text="Tracers Color From Team", Default=false})

local VisualsMaid = nil

GameVisuals:AddToggle("FullBright", {Text="Full Bright", Default=false, Callback=function(v)
	if VisualsMaid then
		VisualsMaid:DoCleaning()
		VisualsMaid = nil
	end
	if not v then
		return
	end

	VisualsMaid = Maid.new()

	local original = {
		Brightness = Lighting.Brightness,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ClockTime = Lighting.ClockTime,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
		FogColor = Lighting.FogColor,
		GlobalShadows = Lighting.GlobalShadows,
	}
	VisualsMaid:GiveTask(function()
		for k, val in pairs(original) do
			pcall(function()
				Lighting[k] = val
			end)
		end
	end)

	Lighting.Brightness = 2
	Lighting.Ambient = WHITE
	Lighting.OutdoorAmbient = WHITE
	Lighting.ClockTime = 12
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0
	Lighting.FogColor = WHITE
	Lighting.GlobalShadows = false
end})

local NoFogMaid = nil

GameVisuals:AddToggle("NoFog", {Text="No Fog", Default=false, Callback=function(v)
	if NoFogMaid then
		NoFogMaid:DoCleaning()
		NoFogMaid = nil
	end
	if not v then
		return
	end

	NoFogMaid = Maid.new()
	local maid = NoFogMaid

	local oldFogEnd = Lighting.FogEnd
	local oldFogStart = Lighting.FogStart
	maid:GiveTask(function()
		Lighting.FogEnd = oldFogEnd
		Lighting.FogStart = oldFogStart
	end)

	local atmospheres = {}
	local alive = true
	maid:GiveTask(function()
		alive = false
		for obj, density in pairs(atmospheres) do
			if obj.Parent then
				obj.Density = density
			end
			atmospheres[obj] = nil
		end
	end)

	local function apply(obj)
		if not alive or atmospheres[obj] ~= nil or not obj:IsA("Atmosphere") then
			return
		end
		atmospheres[obj] = obj.Density
		obj.Density = 0
	end

	for _, obj in ipairs(Lighting:GetChildren()) do
		apply(obj)
	end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		apply(obj)
	end

	maid:GiveTask(Lighting.ChildAdded:Connect(apply))

	Lighting.FogStart = 0
	Lighting.FogEnd = 100000000
end})

end

if game.PlaceId == 155615604 then
	local success, err = pcall(function()
		loadstring(game:HttpGet("https://api.getunx.cc/Modules/v3/Other/UNX_PFSA.m.luau"))(Library, Tabs, MainMaid)
	end)
	if not success then
		warn("[UNX]: Failed to load Silent Aim module.\nError Stack: " .. tostring(err))
	end
end

do
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
	Default = Color3_fromRGB(255, 255, 255),
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

AimlockConfigTab:AddDropdown("IgnoreTeam", { SpecialType = "Team", Multi = true, Text = "Ignore Team" })
AimlockConfigTab:AddDropdown("PrioritizeTeam", { SpecialType = "Team", Multi = true, Text = "Prioritize Team" })

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

end

do
local CameraGroupBox = Tabs.Features:AddLeftGroupbox("Camera", "camera")

local FovLockMaid = Maid.new()
MainMaid:GiveTask(FovLockMaid)
local applyingCamera = false

local function enforceFieldOfView()
	if applyingCamera then
		return
	end
	local target = optionValue("FOV", defaultFieldOfView)
	if camera.FieldOfView ~= target then
		applyingCamera = true
		camera.FieldOfView = target
		applyingCamera = false
	end
end

local zoomOverride = nil

local function enforceMaxZoom()
	if applyingCamera then
		return
	end
	local target = zoomOverride or optionValue("MaxZoom", defaultMaxZoom)
	if player.CameraMaxZoomDistance ~= target then
		applyingCamera = true
		player.CameraMaxZoomDistance = target
		applyingCamera = false
	end
end

CameraGroupBox:AddSlider("FOV", {Text = "Field Of View", Default = defaultFieldOfView, Min = 20, Max = 180, Rounding = 0, Callback = function()
	enforceFieldOfView()
end})

CameraGroupBox:AddSlider("MaxZoom", {Text = "Max Zoom", Default = defaultMaxZoom, Min = 0, Max = 9999, Rounding = 0, Callback = function()
	enforceMaxZoom()
end})

FovLockMaid:GiveTask(camera:GetPropertyChangedSignal("FieldOfView"):Connect(enforceFieldOfView))
FovLockMaid:GiveTask(player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(enforceMaxZoom))

Hub.setMaxZoomOverride = function(value)
	zoomOverride = value
	enforceMaxZoom()
end

Init[#Init + 1] = enforceFieldOfView
Init[#Init + 1] = enforceMaxZoom

CameraGroupBox:AddToggle("NoclipCamera", {Text = "Noclip Camera", Default = false, Callback = function(v)
	pcall(function()
		player.DevCameraOcclusionMode = v and Enum.DevCameraOcclusionMode.Invisicam or defaultOcclusionMode
	end)
end})
CameraGroupBox:AddToggle("NoclipCameraBindButton", {Text="Noclip Camera BindButton", Default=false, Callback=function(v)
	if v then
		BindButton:AddToggleBB("Noclip Cam", function() Toggles.NoclipCamera:SetValue(true) end, function() Toggles.NoclipCamera:SetValue(false) end)
	else
		BindButton:DelBindB("Noclip Cam")
	end
end})

end

do
local OrbitGroupBox = Tabs.Features:AddLeftGroupbox("Orbit", "circle")

local orbitTargets = {}
local orbitTargetCount = 0
local orbitStartTime = 0
local orbitCurrentIndex = 1

local function rebuildOrbitTargets()
	tclear(orbitTargets)
	orbitTargetCount = 0
	local selected = optionValue("OrbitPlayers", nil)
	if type(selected) ~= "table" then
		return
	end
	for value, isSelected in pairs(selected) do
		if isSelected then
			local p = resolvePlayerValue(value)
			if p and p ~= player then
				orbitTargetCount += 1
				orbitTargets[orbitTargetCount] = p
			end
		end
	end
	if orbitCurrentIndex > orbitTargetCount then
		orbitCurrentIndex = 1
	end
end

local function orbitStep()
	local root = rootpart
	if not root or not root.Parent or orbitTargetCount == 0 then
		return
	end

	local now = clock()
	local orbitTime = optionValue("OrbitTime", 5)

	if orbitTargetCount > 1 and orbitTime > 0 then
		if now - orbitStartTime > orbitTime then
			orbitStartTime = now
			orbitCurrentIndex += 1
			if orbitCurrentIndex > orbitTargetCount then
				orbitCurrentIndex = 1
			end
		end
	else
		orbitCurrentIndex = 1
	end

	local targetPlayer = orbitTargets[orbitCurrentIndex]
	local targetChar = targetPlayer and targetPlayer.Character
	local targetPart = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	if not targetPart then
		return
	end

	local radius = optionValue("OrbitOffset", 10)
	local rot = now * (optionValue("OrbitSpeed", 10) / 10)
	local targetPos = targetPart.Position
	local newPos = targetPos + Vector3_new(cos(rot) * radius, 0, sin(rot) * radius)

	root.CFrame = CFrame_new(newPos, targetPos)
	root.AssemblyLinearVelocity = Vector3_zero
	root.AssemblyAngularVelocity = Vector3_zero
end

local function updateOrbitLoop()
	if toggleValue("EnableOrbit") then
		rebuildOrbitTargets()
		orbitStartTime = clock()
		if not Scheduler.IsBound("RenderStepped", "Orbit") then
			Scheduler.Bind("RenderStepped", "Orbit", orbitStep, 60)
		end
	else
		Scheduler.Unbind("RenderStepped", "Orbit")
	end
end

OrbitGroupBox:AddToggle("EnableOrbit", {Text = "Enable Orbit", Default = false, Callback = updateOrbitLoop})
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
	Text = "Orbit Player Target",
	Callback = rebuildOrbitTargets
})
OrbitGroupBox:AddSlider("OrbitTime", {Text = "Orbit Time Per Player", Default = 5, Min = 0, Max = 30, Rounding = 1})
OrbitGroupBox:AddSlider("OrbitSpeed", {Text = "Orbit Speed", Default = 10, Min = 1, Max = 1000, Rounding = 0})
OrbitGroupBox:AddSlider("OrbitOffset", {Text = "Orbit Offset From Target", Default = 10, Min = 1, Max = 1000, Rounding = 0})

Init[#Init + 1] = updateOrbitLoop
Refreshers[#Refreshers + 1] = rebuildOrbitTargets

MainMaid:GiveTask(Players.PlayerRemoving:Connect(rebuildOrbitTargets))

end

do
local FreeCamGroupBox = Tabs.Features:AddLeftGroupbox("Free Camera", "camera")
local FreeCamMaid = nil

local freecamYaw = 0
local freecamPitch = 0
local freecamPos = Vector3_zero
local freecamVelocity = Vector3_zero
local freecamLookDelta = Vector2_zero
local freecamVertical = 0
local boostTimer = 0
local isBoosting = false

local function stopFreecam()
	Scheduler.Unbind("RenderStepped", "Freecam")
	if FreeCamMaid then
		FreeCamMaid:DoCleaning()
		FreeCamMaid = nil
	end
	freecamLookDelta = Vector2_zero
	freecamVelocity = Vector3_zero
	freecamVertical = 0
	boostTimer = 0
	isBoosting = false
end

local function createFreecamTouchPad(maid)
	local gui = Instance_new("ScreenGui")
	gui.Name = "UNX_Freecam_Touch"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999999997
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local okParent = pcall(function()
		gui.Parent = CoreGui
	end)
	if not okParent then
		gui.Parent = player:WaitForChild("PlayerGui")
	end
	maid:GiveTask(gui)

	local holder = Instance_new("Frame")
	holder.Name = "Vertical"
	holder.Size = UDim2_new(0, 70, 0, 150)
	holder.Position = UDim2_new(1, -90, 0.5, -75)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	local function makeBtn(text, pos, dir)
		local btn = Instance_new("TextButton")
		btn.Name = "Freecam_" .. text
		btn.Text = text
		btn.Size = UDim2_new(0, 70, 0, 65)
		btn.Position = pos
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = BTN_IDLE
		btn.BackgroundTransparency = 0.25
		btn.TextColor3 = WHITE
		applyFont(btn, BUTTON_FONT)
		btn.TextSize = 22
		btn.Parent = holder

		local corner = Instance_new("UICorner")
		corner.CornerRadius = UDim_new(0, 10)
		corner.Parent = btn

		local stroke = Instance_new("UIStroke")
		stroke.Color = BTN_STROKE
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn

		local activeInput = nil

		local function press(input)
			activeInput = input
			btn.BackgroundColor3 = BTN_HELD
			freecamVertical = dir
		end

		local function release()
			activeInput = nil
			btn.BackgroundColor3 = BTN_IDLE
			if freecamVertical == dir then
				freecamVertical = 0
			end
		end

		maid:GiveTask(btn.InputBegan:Connect(function(input)
			local t = input.UserInputType
			if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
				press(input)
			end
		end))
		maid:GiveTask(btn.InputEnded:Connect(function(input)
			if input == activeInput or activeInput == nil then
				release()
			end
		end))
		maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
			if activeInput and input == activeInput then
				release()
			end
		end))
		maid:GiveTask(release)
	end

	makeBtn("+", UDim2_new(0, 0, 0, 0), 1)
	makeBtn("-", UDim2_new(0, 0, 0, 85), -1)
end

local function startFreecam()
	stopFreecam()

	FreeCamMaid = Maid.new()
	local maid = FreeCamMaid

	local char = player.Character
	local rp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	local startCF = camera.CFrame
	freecamPos = startCF.Position
	local look = startCF.LookVector
	freecamYaw = atan2(-look.X, -look.Z)
	freecamPitch = clamp(math.asin(clamp(look.Y, -1, 1)), -PITCH_LIMIT, PITCH_LIMIT)
	freecamVelocity = Vector3_zero
	freecamLookDelta = Vector2_zero
	freecamVertical = 0
	boostTimer = 0
	isBoosting = false

	local prevCameraType = camera.CameraType
	local prevSubject = camera.CameraSubject
	camera.CameraType = Enum.CameraType.Scriptable

	if rp then
		rp.Anchored = true
	end
	if hum then
		hum.PlatformStand = true
	end

	maid:GiveTask(function()
		camera.CameraType = prevCameraType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or prevCameraType
		if prevSubject then
			camera.CameraSubject = prevSubject
		end
		if rp and rp.Parent then
			rp.Anchored = false
		end
		if hum and hum.Parent then
			hum.PlatformStand = false
		end
	end)

	if IsTouch then
		createFreecamTouchPad(maid)
	end

	if not IsMobile then
		local prevBehavior = UserInputService.MouseBehavior
		maid:GiveTask(function()
			UserInputService.MouseBehavior = prevBehavior
		end)
	end

	resolveControls()

	maid:GiveTask(UserInputService.InputChanged:Connect(function(input, gameProcessed)
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch then
			if gameProcessed then
				return
			end
			local delta = input.Delta
			freecamLookDelta = Vector2_new(freecamLookDelta.X + delta.X * 0.55, freecamLookDelta.Y + delta.Y * 0.55)
		elseif t == Enum.UserInputType.MouseMovement then
			if IsMobile then
				return
			end
			local delta = input.Delta
			freecamLookDelta = Vector2_new(freecamLookDelta.X + delta.X, freecamLookDelta.Y + delta.Y)
		end
	end))

	maid:GiveTask(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Space then
			freecamVertical = 1
		elseif key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.LeftShift then
			freecamVertical = -1
		end
	end))

	maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		local key = input.KeyCode
		if key == Enum.KeyCode.Space and freecamVertical == 1 then
			freecamVertical = 0
		elseif (key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.LeftShift) and freecamVertical == -1 then
			freecamVertical = 0
		end
	end))

	Scheduler.Bind("RenderStepped", "Freecam", function(dt)
		if dt > 0.25 then
			dt = 0.25
		end

		if not IsMobile then
			local wantLock = Library.Toggled ~= true
			local desired = wantLock and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
			if UserInputService.MouseBehavior ~= desired then
				UserInputService.MouseBehavior = desired
			end
			if not wantLock then
				freecamLookDelta = Vector2_zero
			end
		end

		local sens = optionValue("FreecamSens", 1) * 0.003
		local delta = freecamLookDelta
		if delta ~= Vector2_zero then
			freecamLookDelta = Vector2_zero
			freecamYaw -= delta.X * sens
			freecamPitch = clamp(freecamPitch - delta.Y * sens, -PITCH_LIMIT, PITCH_LIMIT)
		end

		local rotationCFrame = CFrame_fromOrientation(0, freecamYaw, 0) * CFrame_fromOrientation(freecamPitch, 0, 0)

		local moveVector = getMoveVector()
		local isMoving = moveVector ~= Vector3_zero

		if toggleValue("EnableFreeCamBoost") and isMoving then
			if not isBoosting then
				if moveVector.Z < -0.8 and abs(moveVector.X) < 0.4 then
					boostTimer += dt
					if boostTimer >= optionValue("FreecamBoostTime", 5) then
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

		local baseSpeed = optionValue("FreecamSpeed", 30)
		local currentSpeed = isBoosting and (baseSpeed * optionValue("FreecamBoostMult", 3)) or baseSpeed

		local targetVelocity = Vector3_zero
		if isMoving then
			targetVelocity = rotationCFrame:VectorToWorldSpace(moveVector) * currentSpeed
		end
		if freecamVertical ~= 0 then
			targetVelocity += Vector3_new(0, freecamVertical * currentSpeed, 0)
		end

		local alpha = 1 - exp(-16 * dt)
		freecamVelocity = freecamVelocity:Lerp(targetVelocity, alpha)
		if freecamVelocity.Magnitude < 0.01 then
			freecamVelocity = Vector3_zero
		end

		freecamPos += freecamVelocity * dt

		camera.CFrame = CFrame_new(freecamPos) * rotationCFrame
	end, 5)
end

FreeCamGroupBox:AddToggle("EnableFreeCam", {Text="Enable Free Camera", Default=false, Callback=function(v)
	if v then
		startFreecam()
	else
		stopFreecam()
	end
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

MainMaid:GiveTask(function()
	stopFreecam()
end)

onCharacterReady(function()
	if toggleValue("EnableFreeCam") then
		task.defer(startFreecam)
	end
end)

end

do
local FlingGroupBox = Tabs.Features:AddLeftGroupbox("Fling", "wind")

local flingTime = 5
local flingForce = 50000
local flingBusy = false
local flingCancel = false
local flingRestorePos = nil

FlingGroupBox:AddDropdown("FlingPlayer", {
	Text = "Select Players",
	SpecialType = "Player",
	ExcludeLocalPlayer = true,
	Multi = true,
	Searchable = true,
})

local function zeroCharacterVelocity(char)
	for _, x in ipairs(char:GetChildren()) do
		if x:IsA("BasePart") then
			x.AssemblyLinearVelocity = Vector3_zero
			x.AssemblyAngularVelocity = Vector3_zero
		end
	end
end

local function fling(targetPlayer, duration)
	if flingBusy or not targetPlayer then
		return
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = hum and hum.RootPart
	local targetChar = targetPlayer.Character
	if not char or not hum or not root or not targetChar then
		return
	end

	local tHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
	local tRoot = tHumanoid and tHumanoid.RootPart
	local tHead = targetChar:FindFirstChild("Head")
	local accessory = targetChar:FindFirstChildOfClass("Accessory")
	local handle = accessory and accessory:FindFirstChild("Handle")

	local basePart = nil
	if tRoot and tHead then
		basePart = ((tRoot.Position - tHead.Position).Magnitude > 5) and tHead or tRoot
	else
		basePart = tRoot or tHead or handle
	end
	if not basePart then
		return
	end

	flingBusy = true
	flingCancel = false

	if root.AssemblyLinearVelocity.Magnitude < 50 then
		flingRestorePos = root.CFrame
	end
	flingRestorePos = flingRestorePos or root.CFrame

	local prevSubject = camera.CameraSubject
	local prevDestroyHeight = Workspace.FallenPartsDestroyHeight
	local prevSeatEnabled = true

	camera.CameraSubject = tHead or handle or tHumanoid or prevSubject

	local ok = pcall(function()
		Workspace.FallenPartsDestroyHeight = 0 / 0
	end)

	local attachment = Instance_new("Attachment")
	attachment.Name = "UNX_FlingAttachment"
	attachment.Parent = root

	local mover = Instance_new("LinearVelocity")
	mover.Name = "UNX_FlingVelocity"
	mover.Attachment0 = attachment
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	mover.VectorVelocity = Vector3_new(flingForce, flingForce, flingForce)
	pcall(function()
		mover.MaxAxesForce = Vector3_new(huge, huge, huge)
	end)
	pcall(function()
		mover.MaxForce = huge
	end)
	mover.Parent = root

	pcall(function()
		prevSeatEnabled = hum:GetStateEnabled(Enum.HumanoidStateType.Seated)
		hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	end)

	local function setPose(part, posOffset, angles)
		if not root.Parent or not part.Parent then
			return false
		end
		local pivot = CFrame_new(part.Position) * posOffset * angles
		char:PivotTo(pivot)
		root.AssemblyLinearVelocity = Vector3_new(flingForce, flingForce * 10, flingForce)
		root.AssemblyAngularVelocity = Vector3_new(flingForce * 20, flingForce * 20, flingForce * 20)
		return true
	end

	local deadline = clock() + (duration or 2)
	local angle = 0

	while not flingCancel and clock() < deadline do
		if not root.Parent or not basePart.Parent or basePart.Parent ~= targetPlayer.Character then
			break
		end
		if targetPlayer.Parent ~= Players then
			break
		end
		if tHumanoid and tHumanoid.Sit then
			break
		end
		if basePart.AssemblyLinearVelocity.Magnitude > 500 then
			break
		end

		local moveDir = tHumanoid and tHumanoid.MoveDirection or Vector3_zero
		local partSpeed = basePart.AssemblyLinearVelocity.Magnitude

		if partSpeed < 50 then
			angle += 100
			local ang = CFrame_Angles(rad(angle), 0, 0)
			local push = moveDir * (partSpeed / 1.25)
			if not setPose(basePart, CFrame_new(0, 1.5, 0) + push, ang) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, -1.5, 0) + push, ang) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(2.25, 1.5, -2.25) + push, ang) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(-2.25, -1.5, 2.25) + push, ang) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, 1.5, 0) + moveDir, ang) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, -1.5, 0) + moveDir, ang) then break end
			task.wait()
		else
			local walkSpeed = tHumanoid and tHumanoid.WalkSpeed or 16
			local rootSpeed = tRoot and tRoot.AssemblyLinearVelocity.Magnitude / 1.25 or 0
			local up = CFrame_Angles(rad(90), 0, 0)
			local flat = CFrame_Angles(0, 0, 0)
			local down = CFrame_Angles(rad(-90), 0, 0)
			if not setPose(basePart, CFrame_new(0, 1.5, walkSpeed), up) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, -1.5, -walkSpeed), flat) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, 1.5, walkSpeed), up) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, 1.5, rootSpeed), up) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, -1.5, -rootSpeed), flat) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, 1.5, rootSpeed), up) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, -1.5, 0), up) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, -1.5, 0), flat) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, -1.5, 0), down) then break end
			task.wait()
			if not setPose(basePart, CFrame_new(0, -1.5, 0), flat) then break end
			task.wait()
		end
	end

	mover:Destroy()
	attachment:Destroy()

	pcall(function()
		hum:SetStateEnabled(Enum.HumanoidStateType.Seated, prevSeatEnabled)
	end)
	camera.CameraSubject = hum

	local restoreDeadline = clock() + 5
	while flingRestorePos and root.Parent and clock() < restoreDeadline do
		local goal = flingRestorePos * CFrame_new(0, 0.5, 0)
		char:PivotTo(goal)
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
		zeroCharacterVelocity(char)
		if (root.Position - flingRestorePos.Position).Magnitude < 25 then
			break
		end
		task.wait()
	end

	if ok then
		Workspace.FallenPartsDestroyHeight = prevDestroyHeight
	end
	flingRestorePos = nil
	flingBusy = false
end

local function flingQueue(list)
	if flingBusy then
		return
	end
	task.spawn(function()
		for i = 1, #list do
			if flingCancel then
				break
			end
			local targetPlayer = list[i]
			if targetPlayer and targetPlayer.Parent == Players and targetPlayer.Character then
				fling(targetPlayer, flingTime)
				task.wait(0.5)
			end
		end
	end)
end

FlingGroupBox:AddButton({Text="Fling Selected", Func=function()
	local selected = optionValue("FlingPlayer", nil)
	if type(selected) ~= "table" then
		return
	end
	local list = {}
	for value, isSelected in pairs(selected) do
		if isSelected then
			local targetPlayer = resolvePlayerValue(value)
			if targetPlayer and targetPlayer ~= player then
				list[#list + 1] = targetPlayer
			end
		end
	end
	flingQueue(list)
end})

FlingGroupBox:AddButton({Text="Fling All", Func=function()
	local list = {}
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player and targetPlayer.Character then
			list[#list + 1] = targetPlayer
		end
	end
	flingQueue(list)
end})

FlingGroupBox:AddButton({Text="Stop Fling", Func=function()
	flingCancel = true
end})

FlingGroupBox:AddDivider()

FlingGroupBox:AddSlider("FlingTime", {Text="Fling Time", Default=5, Min=1, Max=25, Rounding=1, Callback=function(v) flingTime = v end})
FlingGroupBox:AddSlider("FlingForce", {Text="Fling Force", Default=50000, Min=1, Max=9999999, Rounding=0, Callback=function(v) flingForce = v end})

MainMaid:GiveTask(function()
	flingCancel = true
end)

end

do
local TeleportGroupBox = Tabs.Features:AddLeftGroupbox("Teleport", "map-pin")
local SpectateGroupBox = Tabs.Features:AddLeftGroupbox("Spectate", "eye")

local teleportPlayer = nil
local teleportType = "Instant (TP)"
local teleportBusy = false

TeleportGroupBox:AddDropdown("TeleportPlayer", {
	Text = "Select Player",
	SpecialType = "Player",
	ExcludeLocalPlayer = true,
	Searchable = true,
	Callback = function(v)
		teleportPlayer = resolvePlayerValue(v)
	end
})

TeleportGroupBox:AddButton({Text="Teleport To Player", Func=function()
	if teleportBusy then
		return
	end

	local targetChar = teleportPlayer and teleportPlayer.Character
	local target = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	local root = rootpart
	if not target or not root or not root.Parent then
		return
	end

	if teleportType == "Instant (TP)" then
		root.CFrame = target.CFrame
		return
	end

	teleportBusy = true
	task.spawn(function()
		local tweenNoclip = false
		if toggleValue("NoclipOnTween") and not toggleValue("Noclip") then
			tweenNoclip = true
			Hub.setTweenNoclip(true)
		end

		local dist = (root.Position - target.Position).Magnitude
		local duration = clamp(dist / 500, 0.05, 30)
		local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = target.CFrame })
		tween:Play()

		local finished = false
		local conn
		conn = tween.Completed:Connect(function()
			finished = true
		end)

		local deadline = clock() + duration + 2
		while not finished and clock() < deadline do
			if not root.Parent then
				tween:Cancel()
				break
			end
			task.wait(0.05)
		end
		if conn then
			conn:Disconnect()
		end

		if tweenNoclip then
			Hub.setTweenNoclip(false)
		end
		teleportBusy = false
	end)
end})

TeleportGroupBox:AddDropdown("TeleportType", {Text="Teleport Type", Values={"Instant (TP)","Tween (Fast)"}, Default="Instant (TP)", Callback=function(v) teleportType = v end})
TeleportGroupBox:AddToggle("NoclipOnTween", {Text="Noclip During Tween", Default=false})

local spectatePlayer = nil
local spectateType = "Third Person"
local SpectateMaid = Maid.new()
MainMaid:Give("SpectateMaid", SpectateMaid)

local function restoreCamera()
	player.CameraMode = defaultCameraMode
	Hub.setMaxZoomOverride(nil)
	if humanoid and humanoid.Parent then
		camera.CameraSubject = humanoid
	end
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function applySpectate()
	local targetChar = spectatePlayer and spectatePlayer.Character
	local targetHumanoid = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid then
		return false
	end

	if spectateType == "First Person" then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		Hub.setMaxZoomOverride(0.5)
		camera.CameraSubject = targetHumanoid
		camera.CameraType = Enum.CameraType.Custom
	else
		player.CameraMode = Enum.CameraMode.Classic
		Hub.setMaxZoomOverride(nil)
		camera.CameraSubject = targetHumanoid
		camera.CameraType = Enum.CameraType.Follow
	end
	return true
end

local function updateSpectate()
	SpectateMaid:DoCleaning()
	SpectateMaid = Maid.new()
	MainMaid:Give("SpectateMaid", SpectateMaid)

	if not toggleValue("SpectatePlayer") or not spectatePlayer or spectatePlayer.Parent ~= Players then
		restoreCamera()
		return
	end

	if toggleValue("EnableFreeCam") then
		return
	end

	applySpectate()

	SpectateMaid:GiveTask(spectatePlayer.CharacterAdded:Connect(function()
		task.wait(0.35)
		if toggleValue("SpectatePlayer") then
			applySpectate()
		end
	end))

	SpectateMaid:GiveTask(restoreCamera)
end

SpectateGroupBox:AddToggle("SpectatePlayer", {Text="Spectate Player", Default=false, Callback=updateSpectate})

SpectateGroupBox:AddDropdown("PlayerToSpectate", {
	Text = "Player To Spectate",
	SpecialType = "Player",
	ExcludeLocalPlayer = true,
	Searchable = true,
	Callback = function(v)
		spectatePlayer = resolvePlayerValue(v)
		if toggleValue("SpectatePlayer") then
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
		if toggleValue("SpectatePlayer") then
			updateSpectate()
		end
	end
})

MainMaid:GiveTask(Players.PlayerRemoving:Connect(function(p)
	if p == spectatePlayer then
		spectatePlayer = nil
		if toggleValue("SpectatePlayer") then
			Toggles.SpectatePlayer:SetValue(false)
		end
	end
	if p == teleportPlayer then
		teleportPlayer = nil
	end
end))

onCharacterReady(function()
	if toggleValue("SpectatePlayer") then
		task.defer(updateSpectate)
	end
end)

end

do
local FPSGroupBox = Tabs.Features:AddRightGroupbox("FPS", "activity")

local fpsValue = 60
FPSGroupBox:AddSlider("FPSMeter", {Text="FPS Cap", Default=60, Min=1, Max=1024, Rounding=0, Callback=function(v) fpsValue = v end})
FPSGroupBox:AddButton({Text="Apply FPS Cap", Func=function()
	if type(SetFpsCap) ~= "function" then
		Library:Notify("FPS cap is not supported by this executor.", 4)
		return
	end
	local okCap = pcall(SetFpsCap, fpsValue)
	if not okCap then
		Library:Notify("Failed to apply FPS cap.", 4)
	end
end})

end

do
local ServerGroupBox = Tabs.Features:AddRightGroupbox("Server", "server")

local function safeSetClipboard(text)
	local fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if type(fn) ~= "function" then
		Library:Notify("Clipboard is not supported by this executor.", 4)
		return
	end
	local okClip = pcall(fn, text)
	if not okClip then
		Library:Notify("Failed to copy to clipboard.", 4)
	end
end

local function rejoinServer()
	if game.JobId == "" then
		Library:Notify("No JobId available in this place.", 4)
		return
	end
	local okTp, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)
	if not okTp then
		Library:Notify("Rejoin failed: " .. tostring(err), 5)
	end
end

ServerGroupBox:AddButton({Text = "Copy Server JobID", Func = function()
	safeSetClipboard(game.JobId)
end})

ServerGroupBox:AddButton({Text = "Copy Server Join Link", Func = function()
	safeSetClipboard(sformat("roblox://placeId=%d&gameInstanceId=%s", game.PlaceId, game.JobId))
end})

ServerGroupBox:AddDivider()

local targetJobId = ""
ServerGroupBox:AddInput("TargetJobId", {
	Text = "Target Server JobID",
	Placeholder = "Enter JobId...",
	Callback = function(v)
		targetJobId = tostring(v or ""):gsub("%s+", "")
	end
})

ServerGroupBox:AddButton({Text = "Join Server", Func = function()
	if targetJobId == "" or not targetJobId:match("^%w+%-") then
		Library:Notify("Invalid JobId.", 4)
		return
	end
	local okTp, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, player)
	end)
	if not okTp then
		Library:Notify("Join failed: " .. tostring(err), 5)
	end
end})

ServerGroupBox:AddDivider()

ServerGroupBox:AddButton({Text = "Rejoin Server", Func = rejoinServer})
ServerGroupBox:AddToggle("RejoinBindButton", {Text="Rejoin BindButton", Default=false, Callback=function(v)
	if v then
		BindButton:BindB("Rejoin", rejoinServer)
	else
		BindButton:DelBindB("Rejoin")
	end
end})

ServerGroupBox:AddLabel("Rejoin Keybind"):AddKeyPicker("RejoinKeybind", {Default="R", Mode="Press", Text="Rejoin Server", Callback=rejoinServer})

ServerGroupBox:AddButton({Text = "Quit Game", Func = function()
	pcall(function()
		game:Shutdown()
	end)
end, Risky=true})

end

do
local AutoChatGroupBox = Tabs.Features:AddRightGroupbox("Auto-Chat", "message-square")
local ChatMaid = nil

local autoChatDelay = 1
local autoChatMessage = "hi!"
local autoChatType = "Infinite"
local autoChatLimit = 10

local legacyChatEvent = nil
local textChannel = nil

local function resolveChat()
	if textChannel and textChannel.Parent then
		return "modern"
	end
	if legacyChatEvent and legacyChatEvent.Parent then
		return "legacy"
	end

	local channels = TextChatService:FindFirstChild("TextChannels")
	if channels then
		local general = channels:FindFirstChild("RBXGeneral")
		if general then
			textChannel = general
			return "modern"
		end
	end

	local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
	local sayEvent = events and events:FindFirstChild("SayMessageRequest")
	if sayEvent then
		legacyChatEvent = sayEvent
		return "legacy"
	end

	return nil
end

local function sendChat(message)
	local mode = resolveChat()
	if mode == "modern" then
		return pcall(function()
			textChannel:SendAsync(message)
		end)
	elseif mode == "legacy" then
		return pcall(function()
			legacyChatEvent:FireServer(message, "All")
		end)
	end
	return false
end

AutoChatGroupBox:AddToggle("AutoChat", {Text="Auto Chat", Default=false, Callback=function(v)
	if ChatMaid then
		ChatMaid:DoCleaning()
		ChatMaid = nil
	end
	if not v then
		return
	end

	ChatMaid = Maid.new()
	local alive = true
	ChatMaid:GiveTask(function()
		alive = false
	end)

	task.spawn(function()
		local sent = 0
		local startedAt = clock()
		local failures = 0

		while alive do
			task.wait(max(autoChatDelay, 0.35))
			if not alive then
				break
			end

			local message = autoChatMessage
			if message == "" then
				continue
			end

			if autoChatType == "Times" then
				if sent >= autoChatLimit then
					Toggles.AutoChat:SetValue(false)
					break
				end
			elseif autoChatType == "Seconds" then
				if clock() - startedAt >= autoChatLimit then
					Toggles.AutoChat:SetValue(false)
					break
				end
			end

			if sendChat(message) then
				sent += 1
				failures = 0
			else
				failures += 1
				if failures >= 5 then
					Library:Notify("Auto Chat stopped: unable to send messages.", 5)
					Toggles.AutoChat:SetValue(false)
					break
				end
			end
		end
	end)
end})

AutoChatGroupBox:AddToggle("AutoChatBindButton", {Text="Auto Chat BindButton", Default=false, Callback=function(v)
	if v then
		BindButton:AddToggleBB("AutoChat", function() Toggles.AutoChat:SetValue(true) end, function() Toggles.AutoChat:SetValue(false) end)
	else
		BindButton:DelBindB("AutoChat")
	end
end})
AutoChatGroupBox:AddSlider("AutoChatDelay", {Text="Auto Chat Delay", Default=1, Min=0, Max=5, Rounding=2, Callback=function(v) autoChatDelay = v end})
AutoChatGroupBox:AddInput("AutoChatMessage", {Text="Auto Chat Message", Default="hi!", Callback=function(v) autoChatMessage = tostring(v or "") end})
AutoChatGroupBox:AddDropdown("AutoChatType", {Text="Auto Chat Type", Values={"Infinite", "Times", "Seconds"}, Default="Infinite", Callback=function(v) autoChatType = v end})
AutoChatGroupBox:AddInput("AutoChatLimit", {Text="Times / Seconds", Default="10", Callback=function(v) autoChatLimit = max(tonumber(v) or 10, 1) end})

end

do
local FOVGui = Instance_new("ScreenGui")
FOVGui.Name = "UNX_FOV_Circle"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.DisplayOrder = 999999999
FOVGui.Enabled = false
FOVGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if not pcall(function() FOVGui.Parent = CoreGui end) then
	FOVGui.Parent = player:WaitForChild("PlayerGui")
end
MainMaid:GiveTask(FOVGui)

local FOVFrame = Instance_new("Frame")
FOVFrame.Name = "Circle"
FOVFrame.AnchorPoint = Vector2_new(0.5, 0.5)
FOVFrame.BackgroundTransparency = 1
FOVFrame.BorderSizePixel = 0
FOVFrame.Size = UDim2_new(0, 200, 0, 200)
FOVFrame.Position = UDim2_new(0.5, 0, 0.5, 0)
FOVFrame.Parent = FOVGui

local FOVCorner = Instance_new("UICorner")
FOVCorner.CornerRadius = UDim_new(1, 0)
FOVCorner.Parent = FOVFrame

local FOVStroke = Instance_new("UIStroke")
FOVStroke.Thickness = 2.5
FOVStroke.Color = WHITE
FOVStroke.Transparency = 1
FOVStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
FOVStroke.Parent = FOVFrame

local lastFovRadius = -1
local lastFovThickness = -1
local lastFovTransparency = -1
local lastFovColor = nil
local lastFovPosition = nil

local function updateFOVCircle()
	if not toggleValue("ShowFOV") then
		if FOVGui.Enabled then
			FOVGui.Enabled = false
		end
		return
	end

	if not FOVGui.Enabled then
		FOVGui.Enabled = true
	end

	local radius = optionValue("FOVSize", 150)
	if radius ~= lastFovRadius then
		lastFovRadius = radius
		FOVFrame.Size = UDim2_new(0, radius * 2, 0, radius * 2)
	end

	local colorOption = Options.FOVColor
	local transparency = colorOption and colorOption.Transparency or 0
	if transparency ~= lastFovTransparency then
		lastFovTransparency = transparency
		FOVStroke.Transparency = transparency
	end

	local thickness = optionValue("FOVStrokeThickness", 2.5)
	if thickness ~= lastFovThickness then
		lastFovThickness = thickness
		FOVStroke.Thickness = thickness
	end

	local color
	if toggleValue("RainbowFOV") then
		local t = clock() * optionValue("RainbowFOVSpeed", 2) * 0.5
		color = Color3_new(sin(t) * 0.5 + 0.5, sin(t + 2) * 0.5 + 0.5, sin(t + 4) * 0.5 + 0.5)
	else
		color = colorOption and colorOption.Value or WHITE
	end
	if color ~= lastFovColor then
		lastFovColor = color
		FOVStroke.Color = color
	end

	local position
	if optionValue("FOVType", "Centered") == "Centered" then
		position = UDim2_new(0.5, 0, 0.5, 0)
	else
		local mouse = UserInputService:GetMouseLocation()
		position = UDim2_new(0, mouse.X, 0, mouse.Y)
	end
	if position ~= lastFovPosition then
		lastFovPosition = position
		FOVFrame.Position = position
	end
end

local OptFOVSize = nil
local OptFOVType = nil
local OptAimlockType = nil
local OptMouseMaxDist = nil
local OptAimlockMaxDist = nil
local OptCertainPlayer = nil
local OptOffsetX = nil
local OptOffsetY = nil
local OptSmoothness = nil

local function cacheAimOptions()
	OptFOVSize = Options.FOVSize
	OptFOVType = Options.FOVType
	OptAimlockType = Options.AimlockType
	OptMouseMaxDist = Options.MouseMaxDist
	OptAimlockMaxDist = Options.AimlockMaxDist
	OptCertainPlayer = Options.AimlockCertainPlayer
	OptOffsetX = Options.AimlockOffsetX
	OptOffsetY = Options.AimlockOffsetY
	OptSmoothness = Options.AimbotSmoothness
end

cacheAimOptions()

local aimWhitelistSet = nil
local aimWhitelistHas = false
local aimPrioritizePlayersSet = nil
local aimPrioritizePlayersHas = false
local aimPrioritizeTeamSet = nil
local aimPrioritizeTeamHas = false
local aimIgnoreTeamSet = nil
local aimIgnoreTeamHas = false
local aimExcludeSet = nil

local function refreshAimSets()
	local whitelist = optionValue("WhitelistPlayers", nil)
	aimWhitelistSet = type(whitelist) == "table" and whitelist or nil
	aimWhitelistHas = anySelected(aimWhitelistSet)

	local prioPlayers = optionValue("PrioritizePlayers", nil)
	aimPrioritizePlayersSet = type(prioPlayers) == "table" and prioPlayers or nil
	aimPrioritizePlayersHas = anySelected(aimPrioritizePlayersSet)

	local prioTeam = optionValue("PrioritizeTeam", nil)
	aimPrioritizeTeamSet = type(prioTeam) == "table" and prioTeam or nil
	aimPrioritizeTeamHas = anySelected(aimPrioritizeTeamSet)

	local ignoreTeam = optionValue("IgnoreTeam", nil)
	aimIgnoreTeamSet = type(ignoreTeam) == "table" and ignoreTeam or nil
	aimIgnoreTeamHas = anySelected(aimIgnoreTeamSet)

	local exclude = optionValue("ExcludeFromTeamExclusion", nil)
	aimExcludeSet = type(exclude) == "table" and exclude or nil
end

refreshAimSets()
for _, key in ipairs({ "WhitelistPlayers", "PrioritizePlayers", "PrioritizeTeam", "IgnoreTeam", "ExcludeFromTeamExclusion" }) do
	pcall(function()
		Options[key]:OnChanged(refreshAimSets)
	end)
end

local ignoreForceField = false
local teamCheck = true
local wallCheck = true
local localTeam = nil

local function isValidTarget(entry)
	if not entry.alive then
		return false
	end

	local plr = entry.player
	local team = plr.Team

	if teamCheck and team == localTeam then
		return false
	end
	if aimWhitelistHas and inSet(aimWhitelistSet, plr, entry.name) then
		return false
	end
	if ignoreForceField and entry.character:FindFirstChildOfClass("ForceField") then
		return false
	end
	if aimIgnoreTeamHas and team and inSet(aimIgnoreTeamSet, team, team.Name) then
		if not inSet(aimExcludeSet, plr, entry.name) then
			return false
		end
	end

	return true
end

local function hasLineOfSight(targetPart, originPos)
	if not wallCheck then
		return true
	end
	local direction = targetPart.Position - originPos
	if direction.Magnitude < 1e-3 then
		return true
	end
	local result = Workspace:Raycast(originPos, direction, AimcastParams)
	if not result then
		return true
	end
	local hit = result.Instance
	return hit ~= nil and hit:IsDescendantOf(targetPart.Parent)
end

local function getClosestTarget(mouseX, mouseY, centerX, centerY)
	local originPos = camera.CFrame.Position
	local nearestMouse = (OptAimlockType and OptAimlockType.Value or "Nearest Character") == "Nearest Mouse"
	local maxDist = nearestMouse and (OptMouseMaxDist and OptMouseMaxDist.Value or 5000) or (OptAimlockMaxDist and OptAimlockMaxDist.Value or 5000)
	local maxDistSq = maxDist * maxDist

	local certain = OptCertainPlayer and OptCertainPlayer.Value or nil
	if certain ~= nil and certain ~= "" then
		local certainPlayer = resolvePlayerValue(certain)
		local entry = certainPlayer and TrackedByPlayer[certainPlayer] or nil
		if entry and isValidTarget(entry) and entry.distSq <= maxDistSq and hasLineOfSight(entry.aimPart, originPos) then
			return entry
		end
		return nil
	end

	local checkX = nearestMouse and mouseX or centerX
	local checkY = nearestMouse and mouseY or centerY

	local fovEnabled = toggleValue("EnableFOV")
	local fovSize = fovEnabled and (OptFOVSize and OptFOVSize.Value or 150) or 0
	local fovSizeSq = fovSize * fovSize
	local fovCenterX, fovCenterY = centerX, centerY
	if fovEnabled and (OptFOVType and OptFOVType.Value or "Centered") ~= "Centered" then
		fovCenterX, fovCenterY = mouseX, mouseY
	end

	local best = nil
	local shortest = huge

	for i = 1, TrackedCount do
		local entry = Tracked[i]
		if entry.onScreen and entry.distSq <= maxDistSq and isValidTarget(entry) then
			local sx, sy = entry.screenX, entry.screenY

			local distMult = 1
			if aimPrioritizePlayersHas and inSet(aimPrioritizePlayersSet, entry.player, entry.name) then
				distMult = 0.5
			elseif aimPrioritizeTeamHas then
				local team = entry.player.Team
				if team and inSet(aimPrioritizeTeamSet, team, team.Name) then
					distMult = 0.5
				end
			end

			local ddx = sx - checkX
			local ddy = sy - checkY
			local distance = math.sqrt(ddx * ddx + ddy * ddy) * distMult

			if distance < shortest then
				local insideFov = true
				if fovEnabled then
					local fx = sx - fovCenterX
					local fy = sy - fovCenterY
					insideFov = (fx * fx + fy * fy) <= fovSizeSq
				end
				if insideFov and hasLineOfSight(entry.aimPart, originPos) then
					shortest = distance
					best = entry
				end
			end
		end
	end

	return best
end

local function aimlockStep()
	updateFOVCircle()

	if not toggleValue("EnableAimlock") then
		return
	end

	ignoreForceField = toggleValue("IgnoreForceFielded")
	teamCheck = toggleValue("TeamCheck")
	wallCheck = toggleValue("WallCheck")
	localTeam = player.Team

	local mouse = UserInputService:GetMouseLocation()
	local centerX = viewportSize.X * 0.5
	local centerY = viewportSize.Y * 0.5

	local entry = getClosestTarget(mouse.X, mouse.Y + 36, centerX, centerY)
	if not entry then
		return
	end

	local aimPart = entry.aimPart
	if not aimPart or not aimPart.Parent then
		return
	end

	local offsetX = (OptOffsetX and OptOffsetX.Value or 0) * 10
	local offsetY = (OptOffsetY and OptOffsetY.Value or 0) * 10
	local targetPos = aimPart.Position + Vector3_new(offsetX, offsetY, 0)

	local camCF = camera.CFrame
	local goal = CFrame_new(camCF.Position, targetPos)

	if toggleValue("SmoothAimlock") then
		camera.CFrame = camCF:Lerp(goal, clamp((OptSmoothness and OptSmoothness.Value or 25) / 100, 0.01, 1))
	else
		camera.CFrame = goal
	end
end

local function updateAimlockLoop()
	local aimOn = toggleValue("EnableAimlock")
	setProjectionUser("Aimlock", aimOn)

	if aimOn or toggleValue("ShowFOV") then
		if not Scheduler.IsBound("RenderStepped", "Aimlock") then
			Scheduler.Bind("RenderStepped", "Aimlock", aimlockStep, 70)
		end
	else
		Scheduler.Unbind("RenderStepped", "Aimlock")
		if FOVGui.Enabled then
			FOVGui.Enabled = false
		end
	end
end

Init[#Init + 1] = updateAimlockLoop
Init[#Init + 1] = refreshAimSets

pcall(function() Toggles.EnableAimlock:OnChanged(updateAimlockLoop) end)
pcall(function() Toggles.ShowFOV:OnChanged(updateAimlockLoop) end)

end

MainMaid:GiveTask(UserInputService.JumpRequest:Connect(function()
	if toggleValue("InfiniteJump") and humanoid and humanoid.Parent and not toggleValue("EnableFreeCam") then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))

do
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", {Default=Library.KeybindFrame.Visible, Text="Open Keybind Menu", Callback=function(v) Library.KeybindFrame.Visible = v end})
MenuGroup:AddToggle("ShowCustomCursor", {Text="Custom Cursor", Default=true, Callback=function(v) Library.ShowCustomCursor = v end})
MenuGroup:AddDropdown("NotificationSide", {Values={"Left","Right"}, Default="Right", Text="Notification Side", Callback=function(v) Library:SetNotifySide(v) end})
MenuGroup:AddDropdown("DPIDropdown", {Values={"50%","75%","100%","125%","150%","175%","200%"}, Default="100%", Text="DPI Scale", Callback=function(v) Library:SetDPIScale((tonumber((v:gsub("%%", ""))) or 100) / 100) end})
MenuGroup:AddDivider()
MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)
MenuGroup:AddLabel("<font color='rgb(255,0,0)'><u>DISCLAIMER</u></font>: We Use This To See How Many Users We Get, <u>We Do Not Share This Information With Any Third Partys</u>.", true)
MenuGroup:AddCheckbox("OptOutLog", {
	Text = "Opt-Out Log",
	Default = isfile and isfile("optout.unx") or false,
	Callback = function(Value)
		pcall(function()
			if Value then
				writefile("optout.unx", "")
			elseif isfile("optout.unx") then
				delfile("optout.unx")
			end
		end)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default="U", NoUI=true, Text="Menu keybind"})
Library.ToggleKeybind = Options.MenuKeybind

local BindButtonGroup = Tabs["UI Settings"]:AddRightGroupbox("Bind Button")
BindButtonGroup:AddSlider("BindButtonSize", {Text="Size Scale", Default=1, Min=0.5, Max=2, Rounding=1, Callback=function(v) BindButton:SetSizeB(v) end})
BindButtonGroup:AddDropdown("BindButtonShape", {Values={"Round", "Square", "Slight Round"}, Default=1, Text="Shape", Callback=function(v)
	if v == "Round" then
		BindButton:MakeAllShape(0)
	elseif v == "Square" then
		BindButton:MakeAllShape(1)
	elseif v == "Slight Round" then
		BindButton:MakeAllShape(2)
	end
end})
BindButtonGroup:AddButton("Reset Positions", function() BindButton:ResetPos() end)

end

Library:OnUnload(function()
	Scheduler.Destroy()
	MainMaid:Destroy()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)
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

MainMaid:GiveTask(Players.PlayerAdded:Connect(function()
	for i = 1, #Refreshers do
		safeCall(Refreshers[i])
	end
end))
MainMaid:GiveTask(Players.PlayerRemoving:Connect(function()
	for i = 1, #Refreshers do
		safeCall(Refreshers[i])
	end
end))

for i = 1, #Init do
	safeCall(Init[i])
end
