local Library, Tabs, MainMaid = ...

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local WorldToViewportPoint = Camera.WorldToViewportPoint
local FindFirstChild = game.FindFirstChild
local FindFirstChildOfClass = game.FindFirstChildOfClass
local IsDescendantOf = game.IsDescendantOf
local Raycast = Workspace.Raycast

local ShootEvent, FuncReload, GT
pcall(function()
	local remotes = ReplicatedStorage:FindFirstChild("GunRemotes")
	if remotes then
		ShootEvent = remotes:FindFirstChild("ShootEvent")
		FuncReload = remotes:FindFirstChild("FuncReload")
	end
	local sharedMods = ReplicatedStorage:FindFirstChild("SharedModules")
	if sharedMods then
		GT = require(sharedMods:WaitForChild("GunTracers"))
	end
end)

local Settings = {
	Silent = true,
	FOV = 150,
	EnableFOV = true,
	ShowFOV = false,
	FOVPlacement = "Mouse",
	TeamCheck = true,
	WallCheck = true,
	HitPart = "Head",
	Prediction = false,
	OffsetX = 0,
	OffsetY = 0,
	FOVColor = Color3.fromRGB(255, 255, 255),
	PredictionColor = Color3.fromRGB(160, 100, 255),
	AutoShoot = false,
	AutoReload = false,
}

local function SafeParent()
	local parent
	pcall(function()
		if gethui then
			parent = gethui()
		end
	end)
	if not parent then
		pcall(function()
			parent = CoreGui
		end)
	end
	if not parent then
		parent = FindFirstChildOfClass(LocalPlayer, "PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
	end
	return parent
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "!!UNX_PFFOV_SA"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = SafeParent()
MainMaid:GiveTask(ScreenGui)

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.Parent = ScreenGui
FOVCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOVCircle.BackgroundTransparency = 1
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Visible = false

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Parent = FOVCircle
FOVStroke.Color = Settings.FOVColor
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.5

local FOVCorner = Instance.new("UICorner")
FOVCorner.Parent = FOVCircle
FOVCorner.CornerRadius = UDim.new(1, 0)

local Tracer = Drawing.new("Line")
Tracer.Thickness = 1.5
Tracer.Color = Settings.PredictionColor
Tracer.Transparency = 1
Tracer.Visible = false
MainMaid:GiveTask(function() Tracer:Remove() end)

local Options = Library.Options
local Toggles = Library.Toggles

local SATabbox = Tabs.Features:AddLeftTabbox()
local SilentAimTab = SATabbox:AddTab("Silent Aim")
local ConfigTab = SATabbox:AddTab("Configurations")

local PlayerList = Players:GetPlayers()

local function GetPlayerNames()
	local names = table.create(#PlayerList)
	local count = 0
	for i = 1, #PlayerList do
		local p = PlayerList[i]
		if p ~= LocalPlayer then
			count = count + 1
			names[count] = p.Name
		end
	end
	return names
end

local function RefreshDropdowns()
	local names = GetPlayerNames()
	if Options.SA_Ignore then Options.SA_Ignore:SetValues(names) end
	if Options.SA_Prioritize then Options.SA_Prioritize:SetValues(names) end
	if Options.SA_Force then Options.SA_Force:SetValues(names) end
end

MainMaid:GiveTask(Players.PlayerAdded:Connect(function(p)
	table.insert(PlayerList, p)
	RefreshDropdowns()
end))

MainMaid:GiveTask(Players.PlayerRemoving:Connect(function(p)
	local idx = table.find(PlayerList, p)
	if idx then
		table.remove(PlayerList, idx)
	end
	RefreshDropdowns()
end))

SilentAimTab:AddToggle("SA_SilentAim", {
	Text = "Enable Silent Aim",
	Default = true,
	Callback = function(v) Settings.Silent = v end
})

SilentAimTab:AddToggle("SA_AutoShoot", {
	Text = "Auto Shoot",
	Default = false,
	Callback = function(v) Settings.AutoShoot = v end
})

SilentAimTab:AddToggle("SA_AutoReload", {
	Text = "Auto Reload",
	Default = false,
	Callback = function(v) Settings.AutoReload = v end
})

SilentAimTab:AddDivider()

SilentAimTab:AddToggle("SA_ShowFOV", {
	Text = "Show FOV",
	Default = false,
	Callback = function(v) Settings.ShowFOV = v end
}):AddColorPicker("SA_FOVColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(v) Settings.FOVColor = v FOVStroke.Color = v end
})

SilentAimTab:AddSlider("SA_FOVRadius", {
	Text = "FOV Radius",
	Default = 150,
	Min = 10,
	Max = 600,
	Rounding = 0,
	Callback = function(v) Settings.FOV = v end
})

SilentAimTab:AddDropdown("SA_FOVPlacement", {
	Values = { "Mouse", "Center Of Screen" },
	Default = 1,
	Text = "FOV Placement",
	Callback = function(v) Settings.FOVPlacement = v end
})

SilentAimTab:AddDropdown("SA_TargetTeams", {
	Values = { "Guards", "Inmates", "Criminals" },
	Default = { "Guards", "Inmates", "Criminals" },
	Multi = true,
	Text = "Target Selection"
})

ConfigTab:AddDropdown("SA_Ignore", {
	Values = GetPlayerNames(),
	Default = {},
	Multi = true,
	Text = "Ignore Player"
})

ConfigTab:AddDropdown("SA_Prioritize", {
	Values = GetPlayerNames(),
	Default = {},
	Multi = true,
	Text = "Prioritize Player"
})

ConfigTab:AddDropdown("SA_Force", {
	Values = GetPlayerNames(),
	Default = {},
	Multi = true,
	Text = "Ignore Player From Team Ignore"
})

ConfigTab:AddDivider()

ConfigTab:AddToggle("SA_WallCheck", {
	Text = "Wall Check",
	Default = true,
	Callback = function(v) Settings.WallCheck = v end
})

ConfigTab:AddToggle("SA_TeamCheck", {
	Text = "Team Check",
	Default = true,
	Callback = function(v) Settings.TeamCheck = v end
})

ConfigTab:AddDropdown("SA_HitPart", {
	Values = { "Head", "Torso", "HumanoidRootPart" },
	Default = 1,
	Text = "Target Hit Part",
	Callback = function(v) Settings.HitPart = v end
})

ConfigTab:AddToggle("SA_Prediction", {
	Text = "Show Prediction Tracer",
	Default = false,
	Callback = function(v) Settings.Prediction = v end
}):AddColorPicker("SA_PredColor", {
	Default = Color3.fromRGB(160, 100, 255),
	Callback = function(v) Settings.PredictionColor = v Tracer.Color = v end
})

ConfigTab:AddSlider("SA_OffsetX", {
	Text = "Offset X",
	Default = 0,
	Min = -5,
	Max = 5,
	Rounding = 1,
	Callback = function(v) Settings.OffsetX = v end
})

ConfigTab:AddSlider("SA_OffsetY", {
	Text = "Offset Y",
	Default = 0,
	Min = -5,
	Max = 5,
	Rounding = 1,
	Callback = function(v) Settings.OffsetY = v end
})

local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
wallParams.IgnoreWater = true

local function UpdateFilter()
	local char = LocalPlayer.Character
	if char then
		wallParams.FilterDescendantsInstances = { char, Camera }
	else
		wallParams.FilterDescendantsInstances = { Camera }
	end
end

UpdateFilter()
MainMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(UpdateFilter))
MainMaid:GiveTask(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
	UpdateFilter()
end))

local function VisibleFrom(camPos, part, char)
	local dir = part.Position - camPos
	if dir.Magnitude < 0.1 then return true end
	local hit = Raycast(Workspace, camPos, dir, wallParams)
	if not hit then return true end
	local hitInst = hit.Instance
	return hitInst == part or IsDescendantOf(hitInst, char)
end

local CachedTarget = nil

local function GetClosestTarget(CenterX, CenterY)
	local TargetTeams = Options.SA_TargetTeams.Value
	local hasGuards = TargetTeams["Guards"]
	local hasInmates = TargetTeams["Inmates"]
	local hasCriminals = TargetTeams["Criminals"]

	local Ignore = Options.SA_Ignore.Value
	local Priority = Options.SA_Prioritize.Value
	local Force = Options.SA_Force.Value

	local camPos = Camera.CFrame.Position
	local checkWall = Settings.WallCheck
	local teamCheck = Settings.TeamCheck
	local myTeam = LocalPlayer.Team
	local hitPartName = Settings.HitPart

	local maxRadius = Settings.FOV
	local maxDistSq = maxRadius * maxRadius
	local bestScore = maxDistSq
	local bestTarget = nil

	for i = 1, #PlayerList do
		local Plr = PlayerList[i]
		if Plr == LocalPlayer then continue end

		local pName = Plr.Name
		if Ignore[pName] then continue end

		local isForced = Force[pName]
		local isPriority = Priority[pName]
		local passedTeam = true

		if teamCheck and Plr.Team == myTeam then
			passedTeam = false
		end

		local T = Plr.Team
		if T then
			local n = T.Name:lower()
			if string.find(n, "guard") and not hasGuards then passedTeam = false
			elseif string.find(n, "inmate") and not hasInmates then passedTeam = false
			elseif string.find(n, "crim") and not hasCriminals then passedTeam = false
			end
		end

		if not passedTeam and not isForced then continue end

		local Char = Plr.Character
		if Char then
			local Hum = FindFirstChildOfClass(Char, "Humanoid")
			if Hum and Hum.Health > 0 and not FindFirstChildOfClass(Char, "ForceField") then
				local Part = FindFirstChild(Char, hitPartName) or FindFirstChild(Char, "Head") or FindFirstChild(Char, "HumanoidRootPart")
				if Part then
					local ScreenPos, OnScreen = WorldToViewportPoint(Camera, Part.Position)
					if OnScreen then
						local dx = ScreenPos.X - CenterX
						local dy = ScreenPos.Y - CenterY
						local distSq = dx * dx + dy * dy

						if distSq <= maxDistSq then
							local score = isPriority and (distSq - 100000000) or distSq
							if score < bestScore then
								if not checkWall or VisibleFrom(camPos, Part, Char) then
									bestScore = score
									bestTarget = Part
								end
							end
						end
					end
				end
			end
		end
	end

	CachedTarget = bestTarget
	return bestTarget
end

MainMaid:GiveTask(RunService.RenderStepped:Connect(function()
	local CenterX, CenterY
	if Settings.FOVPlacement == "Mouse" then
		local mouseLoc = UserInputService:GetMouseLocation()
		CenterX, CenterY = mouseLoc.X, mouseLoc.Y
	else
		local vp = Camera.ViewportSize
		CenterX, CenterY = vp.X * 0.5, vp.Y * 0.5
	end

	local Target
	if Settings.Silent or Settings.AutoShoot or Settings.Prediction then
		Target = GetClosestTarget(CenterX, CenterY)
	else
		CachedTarget = nil
	end

	if Settings.ShowFOV then
		local diam = Settings.FOV * 2
		FOVCircle.Position = UDim2.new(0, CenterX, 0, CenterY)
		FOVCircle.Size = UDim2.new(0, diam, 0, diam)
		if not FOVCircle.Visible then
			FOVCircle.Visible = true
		end
	else
		if FOVCircle.Visible then
			FOVCircle.Visible = false
		end
	end

	if Settings.Prediction and Target then
		local ScreenPos, OnScreen = WorldToViewportPoint(Camera, Target.Position)
		if OnScreen then
			local vp = Camera.ViewportSize
			Tracer.From = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
			Tracer.To = Vector2.new(ScreenPos.X + (Settings.OffsetX * 15), ScreenPos.Y + (Settings.OffsetY * 15))
			if not Tracer.Visible then
				Tracer.Visible = true
			end
		else
			if Tracer.Visible then
				Tracer.Visible = false
			end
		end
	else
		if Tracer.Visible then
			Tracer.Visible = false
		end
	end
end))

local CurrentGun = nil

local function UpdateEquippedGun(char)
	CurrentGun = nil
	if not char then return end
	local children = char:GetChildren()
	for i = 1, #children do
		local t = children[i]
		if t:IsA("Tool") and t:GetAttribute("ToolType") == "Gun" then
			CurrentGun = t
			break
		end
	end
end

local function BindCharacter(char)
	UpdateEquippedGun(char)
	MainMaid:GiveTask(char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and c:GetAttribute("ToolType") == "Gun" then
			CurrentGun = c
		end
	end))
	MainMaid:GiveTask(char.ChildRemoved:Connect(function(c)
		if c == CurrentGun then
			CurrentGun = nil
		end
	end))
end

if LocalPlayer.Character then
	BindCharacter(LocalPlayer.Character)
end
MainMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(BindCharacter))

local lastShot, lastReload = 0, 0

MainMaid:GiveTask(RunService.Heartbeat:Connect(function()
	if not Settings.AutoShoot and not Settings.AutoReload then return end
	local gun = CurrentGun
	if not gun or not gun.Parent then return end
	if gun:GetAttribute("Local_IsShooting") then return end
	if (gun:GetAttribute("Local_ReloadSession") or 0) ~= 0 then return end
	local ammo = gun:GetAttribute("Local_CurrentAmmo") or 0

	if Settings.AutoReload and ammo <= 0 then
		local now = os.clock()
		if now - lastReload > 1 then
			lastReload = now
			task.spawn(function()
				local sess = os.clock()
				gun:SetAttribute("Local_ReloadSession", sess)
				pcall(function()
					LocalPlayer.PlayerGui.Home.hud.BottomRightFrame.GunFrame.BulletsLabel.Text = "..."
				end)
				if FuncReload then pcall(function() FuncReload:InvokeServer() end) end
				task.wait((gun.Parent and gun:GetAttribute("ReloadTime")) or 2)
				if gun.Parent and gun:GetAttribute("Local_ReloadSession") == sess then
					if gun:GetAttribute("Behavior") == "Sniper" then
						gun:SetAttribute("Local_CurrentAmmo", 1)
					else
						gun:SetAttribute("Local_CurrentAmmo", gun:GetAttribute("MaxAmmo") or 0)
					end
					gun:SetAttribute("Local_ReloadSession", 0)
				end
			end)
		end
		return
	end

	if Settings.AutoShoot and Settings.Silent then
		local Target = CachedTarget
		if not Target or not Target.Parent or ammo <= 0 then return end
		local rate = gun:GetAttribute("FireRate") or 0.2
		local now = os.clock()
		if now - lastShot < rate + 0.05 then return end
		local char = LocalPlayer.Character
		local myHRP = char and (FindFirstChild(char, "HumanoidRootPart") or FindFirstChild(char, "Head"))
		if myHRP and (Target.Position - myHRP.Position).Magnitude > (gun:GetAttribute("Range") or 1100) then return end
		lastShot = now

		local head = char and FindFirstChild(char, "Head")
		local origin = head and head.Position or char:GetPivot().Position
		local muzzle = FindFirstChild(gun, "Muzzle")
		local mpos = (muzzle and muzzle.Position) or origin
		local count = gun:GetAttribute("ProjectileCount") or 1
		local shots = table.create(count)
		local tPos = Target.Position
		for i = 1, count do
			shots[i] = { origin, tPos, Target }
		end
		if ShootEvent then ShootEvent:FireServer(shots) end
		if GT then
			local behavior = gun:GetAttribute("Behavior")
			if behavior == "Sniper" then
				GT.createSniper(mpos, tPos)
			elseif behavior == "Taser" then
				GT.createTaser(mpos, tPos)
			else
				GT.createBullet(mpos, tPos)
			end
		end
		gun:SetAttribute("Local_CurrentAmmo", math.max(0, ammo - 1))
	end
end))

pcall(function()
	if GT then
		local origB, origS, origT = GT.createBullet, GT.createSniper, GT.createTaser
		local function LockEnd(startPos, endPos)
			if not Settings.Silent then return endPos end
			local target = CachedTarget
			if not target or not target.Parent then return endPos end
			local char = LocalPlayer.Character
			if not char then return endPos end
			local hrp = FindFirstChild(char, "HumanoidRootPart") or FindFirstChild(char, "Head")
			if not hrp or (startPos - hrp.Position).Magnitude > 30 then return endPos end
			return target.Position
		end
		if origB then GT.createBullet = newcclosure(function(p1, p2) return origB(p1, LockEnd(p1, p2)) end) end
		if origS then GT.createSniper = newcclosure(function(p1, p2) return origS(p1, LockEnd(p1, p2)) end) end
		if origT then GT.createTaser = newcclosure(function(p1, p2) return origT(p1, LockEnd(p1, p2)) end) end
	end
end)

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
	local method = getnamecallmethod()

	if method == "Raycast" then
		if self == Workspace and Settings.Silent then
			local Target = CachedTarget
			if Target then
				local origin = ...
				local FinalPos = Target.Position + Vector3.new(Settings.OffsetX, Settings.OffsetY, 0)
				return {
					Instance = Target,
					Position = FinalPos,
					Material = Enum.Material.Plastic,
					Normal = Vector3.new(0, 1, 0),
					Distance = (origin - FinalPos).Magnitude
				}
			end
		end
	elseif method == "FireServer" then
		if self == ShootEvent and Settings.Silent then
			local checkExec = false
			pcall(function() checkExec = checkcaller() end)
			if not checkExec then
				local shotsArg = ...
				if type(shotsArg) == "table" and #shotsArg > 0 and type(shotsArg[1]) == "table" then
					local Target = CachedTarget
					if Target and Target.Parent then
						local tPos = Target.Position
						local newShots = table.create(#shotsArg)
						for i = 1, #shotsArg do
							local shot = shotsArg[i]
							if type(shot) == "table" then
								newShots[i] = { shot[1], tPos, Target }
							end
						end
						return oldNamecall(self, newShots)
					end
				end
			end
		end
	end

	return oldNamecall(self, ...)
end)

setreadonly(mt, true)
