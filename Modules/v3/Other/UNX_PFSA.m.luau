local Library,Tabs,MainMaid=...
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local CoreGui=game:GetService("CoreGui")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local LocalPlayer=Players.LocalPlayer
local Camera=Workspace.CurrentCamera
local FindFirstChild=game.FindFirstChild
local FindFirstChildOfClass=game.FindFirstChildOfClass
local IsDescendantOf=game.IsDescendantOf
local Clock=os.clock
local Random=Random.new()
local InstanceNew=Instance.new
local StringChar=string.char

local function RandomName()
	return StringChar(
		Random:NextInteger(0,127),
		Random:NextInteger(0,127),
		Random:NextInteger(0,127),
		Random:NextInteger(0,127),
		Random:NextInteger(0,127),
		Random:NextInteger(0,127),
		Random:NextInteger(0,127),
		Random:NextInteger(0,127)
	)
end

local function NewInstance(Class,Parent)
	local Object=InstanceNew(Class)
	Object.Name=RandomName()
	Object.Parent=Parent
	return Object
end

local GunRemotes=ReplicatedStorage:FindFirstChild("GunRemotes")
local ShootEvent=GunRemotes and GunRemotes:FindFirstChild("ShootEvent")
local FuncReload=GunRemotes and GunRemotes:FindFirstChild("FuncReload")
local SharedModules=ReplicatedStorage:FindFirstChild("SharedModules")
local TracersModule=SharedModules and SharedModules:FindFirstChild("GunTracers")
local GunTracers=TracersModule and require(TracersModule)

local Settings={
	Silent=true,
	FOV=150,
	ShowFOV=false,
	FOVPlacement="Mouse",
	TeamCheck=true,
	WallCheck=true,
	HitPart="Head",
	Prediction=false,
	OffsetX=0,
	OffsetY=0,
	Spread=0,
	HitChance=100,
	NormalizeAim=false,
	AutoShoot=false,
	AutoReload=false
}

local GUIParent=gethui and gethui() or CoreGui

local ScreenGui=NewInstance("ScreenGui",GUIParent)
ScreenGui.ResetOnSpawn=false
ScreenGui.DisplayOrder=10
ScreenGui.IgnoreGuiInset=true
MainMaid:GiveTask(ScreenGui)

local FOVCircle=NewInstance("Frame",ScreenGui)
FOVCircle.BackgroundTransparency=1
FOVCircle.AnchorPoint=Vector2.new(.5,.5)
FOVCircle.Visible=false

local FOVStroke=NewInstance("UIStroke",FOVCircle)
FOVStroke.Color=Color3.fromRGB(255,255,255)
FOVStroke.Thickness=1.5
FOVStroke.Transparency=.5

local FOVCorner=NewInstance("UICorner",FOVCircle)
FOVCorner.CornerRadius=UDim.new(1,0)

local Tracer=Drawing.new("Line")
Tracer.Thickness=1.5
Tracer.Transparency=1
Tracer.Visible=false
Tracer.Color=Color3.fromRGB(160,100,255)

MainMaid:GiveTask(function()
	Tracer:Remove()
end)

local Options=Library.Options
local Tabbox=Tabs.Features:AddLeftTabbox()
local SilentAimTab=Tabbox:AddTab("Silent Aim")
local ConfigTab=Tabbox:AddTab("Configurations")

local PlayerList=Players:GetPlayers()
local PlayerCache={}
local PlayerConnections={}

local function CacheCharacter(Player,Character)
	if not Character then
		PlayerCache[Player]=nil
		return
	end

	PlayerCache[Player]={
		Character=Character,
		Humanoid=FindFirstChildOfClass(Character,"Humanoid"),
		Head=FindFirstChild(Character,"Head"),
		Torso=FindFirstChild(Character,"Torso"),
		UpperTorso=FindFirstChild(Character,"UpperTorso"),
		Root=FindFirstChild(Character,"HumanoidRootPart"),
		ForceField=FindFirstChildOfClass(Character,"ForceField")
	}
end

local function BindPlayer(Player)
	local Old=PlayerConnections[Player]

	if Old then
		Old[1]:Disconnect()
		Old[2]:Disconnect()
	end

	local Connections={}
	PlayerConnections[Player]=Connections

	CacheCharacter(Player,Player.Character)

	Connections[1]=Player.CharacterAdded:Connect(function(Character)
		CacheCharacter(Player,Character)
	end)

	Connections[2]=Player.CharacterRemoving:Connect(function()
		PlayerCache[Player]=nil
	end)
end

for I=1,#PlayerList do
	local Player=PlayerList[I]

	if Player~=LocalPlayer then
		BindPlayer(Player)
	end
end

local function GetPlayerNames()
	local Names=table.create(#PlayerList)
	local Count=0

	for I=1,#PlayerList do
		local Player=PlayerList[I]

		if Player~=LocalPlayer then
			Count+=1
			Names[Count]=Player.Name
		end
	end

	return Names
end

local function RefreshDropdowns()
	local Names=GetPlayerNames()
	Options.SA_Ignore:SetValues(Names)
	Options.SA_Prioritize:SetValues(Names)
	Options.SA_Force:SetValues(Names)
end

MainMaid:GiveTask(Players.PlayerAdded:Connect(function(Player)
	PlayerList[#PlayerList+1]=Player
	BindPlayer(Player)
	RefreshDropdowns()
end))

MainMaid:GiveTask(Players.PlayerRemoving:Connect(function(Player)
	local Index=table.find(PlayerList,Player)

	if Index then
		table.remove(PlayerList,Index)
	end

	PlayerCache[Player]=nil

	local Connections=PlayerConnections[Player]

	if Connections then
		Connections[1]:Disconnect()
		Connections[2]:Disconnect()
		PlayerConnections[Player]=nil
	end

	RefreshDropdowns()
end))

SilentAimTab:AddToggle("SA_SilentAim",{
	Text="Enable Silent Aim",
	Default=true,
	Callback=function(Value)
		Settings.Silent=Value
	end
})

SilentAimTab:AddToggle("SA_ShowFOV",{
	Text="Show FOV",
	Default=false,
	Callback=function(Value)
		Settings.ShowFOV=Value
	end
}):AddColorPicker("SA_FOVColor",{
	Default=Color3.fromRGB(255,255,255),
	Callback=function(Value)
		FOVStroke.Color=Value
	end
})

SilentAimTab:AddSlider("SA_FOVRadius",{
	Text="FOV Radius",
	Default=150,
	Min=10,
	Max=600,
	Rounding=0,
	Callback=function(Value)
		Settings.FOV=Value
	end
})

SilentAimTab:AddDropdown("SA_FOVPlacement",{
	Values={"Mouse","Center Of Screen"},
	Default=1,
	Text="FOV Placement",
	Callback=function(Value)
		Settings.FOVPlacement=Value
	end
})

SilentAimTab:AddDropdown("SA_TargetTeams",{
	Values={"Guards","Inmates","Criminals"},
	Default={"Guards","Inmates","Criminals"},
	Multi=true,
	Text="Target Selection"
})

ConfigTab:AddDropdown("SA_Ignore",{
	Values=GetPlayerNames(),
	Default={},
	Multi=true,
	Text="Ignore Player"
})

ConfigTab:AddDropdown("SA_Prioritize",{
	Values=GetPlayerNames(),
	Default={},
	Multi=true,
	Text="Prioritize Player"
})

ConfigTab:AddDropdown("SA_Force",{
	Values=GetPlayerNames(),
	Default={},
	Multi=true,
	Text="Ignore Player From Team Ignore"
})

ConfigTab:AddDivider()

ConfigTab:AddToggle("SA_WallCheck",{
	Text="Wall Check",
	Default=true,
	Callback=function(Value)
		Settings.WallCheck=Value
	end
})

ConfigTab:AddToggle("SA_TeamCheck",{
	Text="Team Check",
	Default=true,
	Callback=function(Value)
		Settings.TeamCheck=Value
	end
})

ConfigTab:AddDropdown("SA_HitPart",{
	Values={"Head","Torso","HumanoidRootPart"},
	Default=1,
	Text="Target Hit Part",
	Callback=function(Value)
		Settings.HitPart=Value
	end
})

ConfigTab:AddToggle("SA_Prediction",{
	Text="Show Prediction Tracer",
	Default=false,
	Callback=function(Value)
		Settings.Prediction=Value
	end
}):AddColorPicker("SA_PredColor",{
	Default=Color3.fromRGB(160,100,255),
	Callback=function(Value)
		Tracer.Color=Value
	end
})

ConfigTab:AddSlider("SA_OffsetX",{
	Text="Offset X",
	Default=0,
	Min=-5,
	Max=5,
	Rounding=1,
	Callback=function(Value)
		Settings.OffsetX=Value
	end
})

ConfigTab:AddSlider("SA_OffsetY",{
	Text="Offset Y",
	Default=0,
	Min=-5,
	Max=5,
	Rounding=1,
	Callback=function(Value)
		Settings.OffsetY=Value
	end
})

SilentAimTab:AddDivider()

SilentAimTab:AddSlider("SA_Spread",{
	Text="Spread (Studs)",
	Default=0,
	Min=0,
	Max=15,
	Rounding=1,
	Callback=function(Value)
		Settings.Spread=Value
	end
})

SilentAimTab:AddSlider("SA_HitChance",{
	Text="Hit Chance (%)",
	Default=100,
	Min=0,
	Max=100,
	Rounding=0,
	Callback=function(Value)
		Settings.HitChance=Value
	end
})

SilentAimTab:AddToggle("SA_NormalizeAim",{
	Text="Normalize Aim",
	Default=false,
	Callback=function(Value)
		Settings.NormalizeAim=Value
	end
})

SilentAimTab:AddDivider()

SilentAimTab:AddToggle("SA_AutoShoot",{
	Text="Auto Shoot",
	Default=false,
	Callback=function(Value)
		Settings.AutoShoot=Value
	end
})

SilentAimTab:AddToggle("SA_AutoReload",{
	Text="Auto Reload",
	Default=false,
	Callback=function(Value)
		Settings.AutoReload=Value
	end
})

local RaycastParams=RaycastParams.new()
RaycastParams.FilterType=Enum.RaycastFilterType.Exclude
RaycastParams.IgnoreWater=true

local function UpdateFilter()
	local Character=LocalPlayer.Character
	RaycastParams.FilterDescendantsInstances=Character and {Character,Camera} or {Camera}
end

UpdateFilter()

MainMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(UpdateFilter))

MainMaid:GiveTask(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera=Workspace.CurrentCamera
	UpdateFilter()
end))

local TAU=math.pi*2
local MissDistance=3
local CachedTarget
local CachedTargetTime=0
local TargetInterval=.03

local function GetHitPart(Cache)
	local Name=Settings.HitPart

	if Name=="Head" then
		return Cache.Head or Cache.Root
	end

	if Name=="Torso" then
		return Cache.Torso or Cache.UpperTorso or Cache.Root or Cache.Head
	end

	return Cache.Root or Cache.Head
end

local function VisibleFrom(Origin,Part,Character)
	local Direction=Part.Position-Origin

	if Direction.Magnitude<.1 then
		return true
	end

	local Result=Workspace:Raycast(Origin,Direction,RaycastParams)

	if not Result then
		return true
	end

	local Instance=Result.Instance

	return Instance==Part or IsDescendantOf(Instance,Character)
end

local function MakeAimPosition(Origin,TargetPosition)
	local Direction=TargetPosition-Origin
	local Distance=Direction.Magnitude

	if Distance<.001 then
		return TargetPosition
	end

	Direction/=Distance

	local Radius=Settings.Spread

	if Settings.HitChance<100 and Random:NextNumber(0,100)>Settings.HitChance then
		Radius=math.max(Radius,MissDistance)
	end

	if Radius<=0 then
		return TargetPosition
	end

	local Right=Direction:Cross(Vector3.yAxis)

	if Right.Magnitude<.0001 then
		Right=Direction:Cross(Vector3.xAxis)
	end

	Right=Right.Unit

	local Up=Right:Cross(Direction).Unit
	local Radial=math.sqrt(Random:NextNumber())*Radius
	local Angle=Random:NextNumber(0,TAU)

	local AimPosition=
		TargetPosition+
		Right*math.cos(Angle)*Radial+
		Up*math.sin(Angle)*Radial

	if Settings.NormalizeAim then
		local AimDirection=AimPosition-Origin
		local AimDistance=AimDirection.Magnitude

		if AimDistance>.001 then
			AimPosition=Origin+AimDirection.Unit*Distance
		end
	end

	return AimPosition
end

local function GetTarget(CenterX,CenterY)
	local Now=Clock()

	if CachedTarget and CachedTarget.Parent and Now-CachedTargetTime<TargetInterval then
		return CachedTarget
	end

	local Teams=Options.SA_TargetTeams.Value
	local Ignored=Options.SA_Ignore.Value
	local Prioritized=Options.SA_Prioritize.Value
	local Forced=Options.SA_Force.Value

	local AllowGuards=Teams.Guards
	local AllowInmates=Teams.Inmates
	local AllowCriminals=Teams.Criminals

	local CameraPosition=Camera.CFrame.Position
	local LocalTeam=LocalPlayer.Team
	local MaxDistance=Settings.FOV*Settings.FOV
	local BestScore=MaxDistance
	local BestTarget

	for I=1,#PlayerList do
		local Player=PlayerList[I]

		if Player==LocalPlayer then
			continue
		end

		local Name=Player.Name

		if Ignored[Name] then
			continue
		end

		local Force=Forced[Name]
		local Priority=Prioritized[Name]
		local Allowed=true
		local Team=Player.Team

		if Settings.TeamCheck and Team==LocalTeam then
			Allowed=false
		end

		if Team then
			local TeamName=Team.Name:lower()

			if TeamName:find("guard",1,true) then
				Allowed=AllowGuards
			elseif TeamName:find("inmate",1,true) then
				Allowed=AllowInmates
			elseif TeamName:find("crim",1,true) then
				Allowed=AllowCriminals
			end
		end

		if not Allowed and not Force then
			continue
		end

		local Cache=PlayerCache[Player]

		if not Cache then
			continue
		end

		local Humanoid=Cache.Humanoid

		if not Humanoid or Humanoid.Health<=0 or Cache.ForceField then
			continue
		end

		local Part=GetHitPart(Cache)

		if not Part then
			continue
		end

		local Position,OnScreen=Camera:WorldToViewportPoint(Part.Position)

		if not OnScreen then
			continue
		end

		local DX=Position.X-CenterX
		local DY=Position.Y-CenterY
		local Distance=DX*DX+DY*DY

		if Distance>MaxDistance then
			continue
		end

		local Score=Priority and Distance-100000000 or Distance

		if Score>=BestScore then
			continue
		end

		if Settings.WallCheck and not VisibleFrom(CameraPosition,Part,Cache.Character) then
			continue
		end

		BestScore=Score
		BestTarget=Part
	end

	CachedTarget=BestTarget
	CachedTargetTime=Now

	return BestTarget
end

MainMaid:GiveTask(RunService.RenderStepped:Connect(function()
	local CenterX,CenterY

	if Settings.FOVPlacement=="Mouse" then
		local Mouse=UserInputService:GetMouseLocation()
		CenterX,CenterY=Mouse.X,Mouse.Y
	else
		local Viewport=Camera.ViewportSize
		CenterX,CenterY=Viewport.X*.5,Viewport.Y*.5
	end

	local Target

	if Settings.Silent or Settings.AutoShoot or Settings.Prediction then
		Target=GetTarget(CenterX,CenterY)
	else
		CachedTarget=nil
	end

	if Settings.ShowFOV then
		local Diameter=Settings.FOV*2
		FOVCircle.Position=UDim2.fromOffset(CenterX,CenterY)
		FOVCircle.Size=UDim2.fromOffset(Diameter,Diameter)
		FOVCircle.Visible=true
	else
		FOVCircle.Visible=false
	end

	if Settings.Prediction and Target then
		local Position,OnScreen=Camera:WorldToViewportPoint(Target.Position)

		if OnScreen then
			local Viewport=Camera.ViewportSize
			Tracer.From=Vector2.new(Viewport.X*.5,Viewport.Y*.5)
			Tracer.To=Vector2.new(
				Position.X+Settings.OffsetX*15,
				Position.Y+Settings.OffsetY*15
			)
			Tracer.Visible=true
		else
			Tracer.Visible=false
		end
	else
		Tracer.Visible=false
	end
end))

local CurrentGun

local function UpdateGun(Character)
	CurrentGun=nil

	if not Character then
		return
	end

	local Children=Character:GetChildren()

	for I=1,#Children do
		local Child=Children[I]

		if Child:IsA("Tool") and Child:GetAttribute("ToolType")=="Gun" then
			CurrentGun=Child
			return
		end
	end
end

local function BindCharacter(Character)
	UpdateGun(Character)

	MainMaid:GiveTask(Character.ChildAdded:Connect(function(Child)
		if Child:IsA("Tool") and Child:GetAttribute("ToolType")=="Gun" then
			CurrentGun=Child
		end
	end))

	MainMaid:GiveTask(Character.ChildRemoved:Connect(function(Child)
		if Child==CurrentGun then
			CurrentGun=nil
		end
	end))
end

if LocalPlayer.Character then
	BindCharacter(LocalPlayer.Character)
end

MainMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(BindCharacter))

local LastShot=0
local LastReload=0

MainMaid:GiveTask(RunService.Heartbeat:Connect(function()
	if not Settings.AutoShoot and not Settings.AutoReload then
		return
	end

	local Gun=CurrentGun

	if not Gun or not Gun.Parent then
		return
	end

	if Gun:GetAttribute("Local_IsShooting") or (Gun:GetAttribute("Local_ReloadSession") or 0)~=0 then
		return
	end

	local Ammo=Gun:GetAttribute("Local_CurrentAmmo") or 0

	if Settings.AutoReload and Ammo<=0 then
		local Now=Clock()

		if Now-LastReload>1 then
			LastReload=Now

			task.spawn(function()
				local Session=Clock()

				Gun:SetAttribute("Local_ReloadSession",Session)

				if FuncReload then
					FuncReload:InvokeServer()
				end

				task.wait(Gun:GetAttribute("ReloadTime") or 2)

				if Gun.Parent and Gun:GetAttribute("Local_ReloadSession")==Session then
					Gun:SetAttribute(
						"Local_CurrentAmmo",
						Gun:GetAttribute("Behavior")=="Sniper" and 1 or Gun:GetAttribute("MaxAmmo") or 0
					)
					Gun:SetAttribute("Local_ReloadSession",0)
				end
			end)
		end

		return
	end

	if not Settings.AutoShoot or not Settings.Silent then
		return
	end

	local Target=CachedTarget

	if not Target or not Target.Parent or Ammo<=0 then
		return
	end

	local Now=Clock()
	local FireRate=Gun:GetAttribute("FireRate") or .2

	if Now-LastShot<FireRate+.05 then
		return
	end

	local Character=LocalPlayer.Character

	if not Character then
		return
	end

	local Head=FindFirstChild(Character,"Head")
	local Root=FindFirstChild(Character,"HumanoidRootPart")
	local Origin=Head and Head.Position or Root and Root.Position

	if not Origin then
		return
	end

	if Root and (Target.Position-Root.Position).Magnitude>(Gun:GetAttribute("Range") or 1100) then
		return
	end

	local Muzzle=FindFirstChild(Gun,"Muzzle")
	local MuzzlePosition=Muzzle and Muzzle.Position or Origin
	local Count=Gun:GetAttribute("ProjectileCount") or 1
	local Shots=table.create(Count)

	for I=1,Count do
		Shots[I]={
			Origin,
			MakeAimPosition(Origin,Target.Position),
			Target
		}
	end

	LastShot=Now

	if ShootEvent then
		ShootEvent:FireServer(Shots)
	end

	if GunTracers and Shots[1] then
		local Position=Shots[1][2]
		local Behavior=Gun:GetAttribute("Behavior")

		if Behavior=="Sniper" then
			GunTracers.createSniper(MuzzlePosition,Position)
		elseif Behavior=="Taser" then
			GunTracers.createTaser(MuzzlePosition,Position)
		else
			GunTracers.createBullet(MuzzlePosition,Position)
		end
	end

	Gun:SetAttribute("Local_CurrentAmmo",math.max(0,Ammo-1))
end))

if GunTracers then
	local CreateBullet=GunTracers.createBullet
	local CreateSniper=GunTracers.createSniper
	local CreateTaser=GunTracers.createTaser

	local function LockEnd(StartPosition,EndPosition)
		if not Settings.Silent then
			return EndPosition
		end

		local Target=CachedTarget

		if not Target or not Target.Parent then
			return EndPosition
		end

		local Character=LocalPlayer.Character

		if not Character then
			return EndPosition
		end

		local Root=FindFirstChild(Character,"HumanoidRootPart") or FindFirstChild(Character,"Head")

		if not Root or (StartPosition-Root.Position).Magnitude>30 then
			return EndPosition
		end

		return MakeAimPosition(StartPosition,Target.Position)
	end

	if CreateBullet then
		GunTracers.createBullet=newcclosure(function(A,B)
			return CreateBullet(A,LockEnd(A,B))
		end)
	end

	if CreateSniper then
		GunTracers.createSniper=newcclosure(function(A,B)
			return CreateSniper(A,LockEnd(A,B))
		end)
	end

	if CreateTaser then
		GunTracers.createTaser=newcclosure(function(A,B)
			return CreateTaser(A,LockEnd(A,B))
		end)
	end
end

local Metatable=getrawmetatable(game)
local OldNamecall=Metatable.__namecall

setreadonly(Metatable,false)

Metatable.__namecall=newcclosure(function(Self,...)
	local Method=getnamecallmethod()

	if Method=="Raycast" and Self==Workspace and Settings.Silent then
		local Target=CachedTarget

		if Target and Target.Parent then
			local Args=table.pack(...)
			local Origin=Args[1]
			local Direction=Args[2]

			if typeof(Origin)=="Vector3" and typeof(Direction)=="Vector3" then
				local TargetPosition=Target.Position+Vector3.new(
					Settings.OffsetX,
					Settings.OffsetY,
					0
				)

				local FinalPosition=MakeAimPosition(Origin,TargetPosition)

				return {
					Instance=Target,
					Position=FinalPosition,
					Material=Enum.Material.Plastic,
					Normal=Vector3.new(0,1,0),
					Distance=(Origin-FinalPosition).Magnitude
				}
			end
		end
	elseif Method=="FireServer" and Self==ShootEvent and Settings.Silent then
		local Caller=checkcaller and checkcaller() or false

		if not Caller then
			local Args=table.pack(...)
			local Shots=Args[1]
			local Target=CachedTarget

			if Target and Target.Parent and type(Shots)=="table" and #Shots>0 and type(Shots[1])=="table" then
				local Center=Vector3.zero
				local Valid=0

				for I=1,#Shots do
					local Shot=Shots[I]
					local Position=Shot and Shot[2]

					if typeof(Position)=="Vector3" then
						Center+=Position
						Valid+=1
					end
				end

				if Valid>0 then
					Center/=Valid

					local TargetPosition=Target.Position+Vector3.new(
						Settings.OffsetX,
						Settings.OffsetY,
						0
					)

					local NewShots=table.create(#Shots)

					for I=1,#Shots do
						local Shot=Shots[I]

						if type(Shot)~="table" then
							NewShots[I]=Shot
							continue
						end

						local Origin=Shot[1]
						local Position=Shot[2]

						if typeof(Origin)~="Vector3" or typeof(Position)~="Vector3" then
							NewShots[I]=Shot
							continue
						end

						local AimPosition=MakeAimPosition(Origin,TargetPosition)

						NewShots[I]={
							Origin,
							AimPosition+(Position-Center),
							Target
						}
					end

					return OldNamecall(Self,NewShots)
				end
			end
		end
	end

	return OldNamecall(Self,...)
end)

setreadonly(Metatable,true)
