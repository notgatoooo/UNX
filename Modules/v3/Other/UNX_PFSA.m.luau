local Library, Tabs, MainMaid = ...

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPlayers = Players.GetPlayers
local FindFirstChild = game.FindFirstChild
local IsDescendantOf = game.IsDescendantOf
local Raycast = Workspace.Raycast

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
	PredictionColor = Color3.fromRGB(160, 100, 255)
}

local function SafeParent()
	local success, parent = pcall(function()
		return (gethui and gethui()) or CoreGui
	end)
	if not success or not parent then
		parent = LocalPlayer:WaitForChild("PlayerGui")
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

local function GetPlayerNames()
	local names = {}
	for _, p in ipairs(GetPlayers(Players)) do
		if p ~= LocalPlayer then
			table.insert(names, p.Name)
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

MainMaid:GiveTask(Players.PlayerAdded:Connect(RefreshDropdowns))
MainMaid:GiveTask(Players.PlayerRemoving:Connect(RefreshDropdowns))

SilentAimTab:AddToggle("SA_SilentAim", {
	Text = "Enable Silent Aim",
	Default = true,
	Callback = function(v) Settings.Silent = v end
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

local function GetClosestTarget()
	local BestTarget = nil
	local BestDist = Settings.FOV
	local Center

	if Settings.FOVPlacement == "Mouse" then
		Center = UserInputService.GetMouseLocation(UserInputService)
	else
		Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	end

	local TargetTeams = Options.SA_TargetTeams.Value
	local Ignore = Options.SA_Ignore.Value
	local Priority = Options.SA_Prioritize.Value
	local Force = Options.SA_Force.Value

	for _, Plr in ipairs(GetPlayers(Players)) do
		if Plr == LocalPlayer then continue end
		if Ignore[Plr.Name] then continue end

		local IsForced = Force[Plr.Name]
		local IsPriority = Priority[Plr.Name]
		local PassedTeam = true

		if Settings.TeamCheck and Plr.Team == LocalPlayer.Team then
			PassedTeam = false
		end

		local T = Plr.Team
		if T then
			local n = T.Name:lower()
			if n:find("guard") and not TargetTeams["Guards"] then PassedTeam = false end
			if n:find("inmate") and not TargetTeams["Inmates"] then PassedTeam = false end
			if n:find("crim") and not TargetTeams["Criminals"] then PassedTeam = false end
		end

		if not PassedTeam and not IsForced then continue end

		local Char = Plr.Character
		if Char then
			local Part = FindFirstChild(Char, Settings.HitPart)
			local Hum = FindFirstChild(Char, "Humanoid")
			if Part and Hum and Hum.Health > 0 then
				local ScreenPos, OnScreen = WorldToViewportPoint(Camera, Part.Position)
				if OnScreen then
					local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - Center).Magnitude
					local CalcDist = Dist

					if IsPriority then CalcDist = Dist - 10000 end

					if CalcDist < BestDist then
						if Settings.WallCheck then
							local Origin = Camera.CFrame.Position
							local Dir = Part.Position - Origin
							local Params = RaycastParams.new()
							Params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
							Params.FilterType = Enum.RaycastFilterType.Exclude
							local Hit = Raycast(Workspace, Origin, Dir.Unit * Dir.Magnitude, Params)
							if Hit and Hit.Instance and not IsDescendantOf(Hit.Instance, Char) then continue end
						end
						BestDist = CalcDist
						BestTarget = Part
					end
				end
			end
		end
	end
	return BestTarget
end

MainMaid:GiveTask(RunService.RenderStepped:Connect(function()
	if Settings.ShowFOV then
		local Pos
		if Settings.FOVPlacement == "Mouse" then
			Pos = UserInputService.GetMouseLocation(UserInputService)
		else
			Pos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		end
		FOVCircle.Position = UDim2.new(0, Pos.X, 0, Pos.Y)
		FOVCircle.Size = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2)
		FOVCircle.Visible = true
	else
		FOVCircle.Visible = false
	end

	if Settings.Prediction then
		local Target = GetClosestTarget()
		if Target then
			local ScreenPos, OnScreen = WorldToViewportPoint(Camera, Target.Position)
			if OnScreen then
				local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
				local TargetPoint = Vector2.new(ScreenPos.X + (Settings.OffsetX * 15), ScreenPos.Y + (Settings.OffsetY * 15))
				Tracer.Visible = true
				Tracer.From = Center
				Tracer.To = TargetPoint
			else Tracer.Visible = false end
		else Tracer.Visible = false end
	else Tracer.Visible = false end
end))

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
	local method = getnamecallmethod()
	local args = {...}

	if method == "Raycast" and self == Workspace and Settings.Silent then
		local Target = GetClosestTarget()
		if Target then
			local FinalPos = Target.Position + Vector3.new(Settings.OffsetX, Settings.OffsetY, 0)
			return {
				Instance = Target,
				Position = FinalPos,
				Material = Enum.Material.Plastic,
				Normal = Vector3.new(0, 1, 0),
				Distance = (args[1] - FinalPos).Magnitude
			}
		end
	end

	return oldNamecall(self, unpack(args))
end)

setreadonly(mt, true)
