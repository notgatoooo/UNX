local Library,Tabs,MainMaid=...

local players=game:GetService("Players")
local runservice=game:GetService("RunService")
local uis=game:GetService("UserInputService")
local workspace=game:GetService("Workspace")
local coregui=game:GetService("CoreGui")
local replicatedstorage=game:GetService("ReplicatedStorage")

local localplayer=players.LocalPlayer
local camera=workspace.CurrentCamera
local findfirstchild=game.FindFirstChild
local findfirstchildofclass=game.FindFirstChildOfClass
local isdescendantof=game.IsDescendantOf
local clock=os.clock
local random=math.random
local char=string.char
local create=Instance.new

local gun_remotes=replicatedstorage:FindFirstChild("Gun Remotes") or replicatedstorage:FindFirstChild("GunRemotes")
local shoot_event=gun_remotes and gun_remotes:FindFirstChild("ShootEvent")
local func_reload=gun_remotes and gun_remotes:FindFirstChild("FuncReload")

local shared_modules=replicatedstorage:FindFirstChild("SharedModules")
local tracers_module=shared_modules and shared_modules:FindFirstChild("GunTracers")
local gun_tracers=tracers_module and require(tracers_module)

local settings={
	silent=true,
	fov=150,
	show_fov=false,
	fov_placement="Mouse",
	team_check=true,
	wall_check=true,
	hit_part="Head",
	prediction=false,
	offset_x=0,
	offset_y=0,
	spread=0,
	hit_chance=100,
	normalize_aim=false,
	auto_shoot=false,
	auto_reload=false
}

local function random_name()
	return char(
		random(0,127),
		random(0,127),
		random(0,127),
		random(0,127),
		random(0,127),
		random(0,127),
		random(0,127),
		random(0,127)
	)
end

local function new_instance(class,parent)
	local object=create(class)
	object.Name=random_name()
	object.Parent=parent
	return object
end

local gui_parent=gethui and gethui() or coregui

local screen_gui=new_instance("ScreenGui",gui_parent)
screen_gui.ResetOnSpawn=false
screen_gui.DisplayOrder=10
screen_gui.IgnoreGuiInset=true
MainMaid:GiveTask(screen_gui)

local fov_circle=new_instance("Frame",screen_gui)
fov_circle.BackgroundTransparency=1
fov_circle.AnchorPoint=Vector2.new(.5,.5)
fov_circle.Visible=false

local fov_stroke=new_instance("UIStroke",fov_circle)
fov_stroke.Color=Color3.fromRGB(255,255,255)
fov_stroke.Thickness=1.5
fov_stroke.Transparency=.5

new_instance("UICorner",fov_circle).CornerRadius=UDim.new(1,0)

local tracer=Drawing.new("Line")
tracer.Thickness=1.5
tracer.Transparency=1
tracer.Visible=false
tracer.Color=Color3.fromRGB(160,100,255)

MainMaid:GiveTask(function()
	tracer:Remove()
end)

local options=Library.Options
local tabbox=Tabs.Features:AddLeftTabbox()
local silent_tab=tabbox:AddTab("Silent Aim")
local config_tab=tabbox:AddTab("Configurations")

local player_list=players:GetPlayers()
local player_cache={}
local player_connections={}

local function cache_character(player,character)
	if not character then
		player_cache[player]=nil
		return
	end

	player_cache[player]={
		character=character,
		humanoid=findfirstchildofclass(character,"Humanoid"),
		head=findfirstchild(character,"Head"),
		torso=findfirstchild(character,"Torso"),
		upper_torso=findfirstchild(character,"UpperTorso"),
		root=findfirstchild(character,"HumanoidRootPart"),
		forcefield=findfirstchildofclass(character,"ForceField")
	}
end

local function bind_player(player)
	local old=player_connections[player]

	if old then
		old[1]:Disconnect()
		old[2]:Disconnect()
	end

	local connections={}
	player_connections[player]=connections

	cache_character(player,player.Character)

	connections[1]=player.CharacterAdded:Connect(function(character)
		cache_character(player,character)
	end)

	connections[2]=player.CharacterRemoving:Connect(function()
		player_cache[player]=nil
	end)
end

for i=1,#player_list do
	local player=player_list[i]

	if player~=localplayer then
		bind_player(player)
	end
end

local function get_player_names()
	local names=table.create(#player_list)
	local count=0

	for i=1,#player_list do
		local player=player_list[i]

		if player~=localplayer then
			count+=1
			names[count]=player.Name
		end
	end

	return names
end

local function refresh_dropdowns()
	local names=get_player_names()
	options.SA_Ignore:SetValues(names)
	options.SA_Prioritize:SetValues(names)
	options.SA_Force:SetValues(names)
end

MainMaid:GiveTask(players.PlayerAdded:Connect(function(player)
	player_list[#player_list+1]=player
	bind_player(player)
	refresh_dropdowns()
end))

MainMaid:GiveTask(players.PlayerRemoving:Connect(function(player)
	local index=table.find(player_list,player)

	if index then
		table.remove(player_list,index)
	end

	player_cache[player]=nil

	local connections=player_connections[player]

	if connections then
		connections[1]:Disconnect()
		connections[2]:Disconnect()
		player_connections[player]=nil
	end

	refresh_dropdowns()
end))

silent_tab:AddToggle("SA_SilentAim",{
	Text="Enable Silent Aim",
	Default=true,
	Callback=function(value)
		settings.silent=value
	end
})

silent_tab:AddToggle("SA_ShowFOV",{
	Text="Show FOV",
	Default=false,
	Callback=function(value)
		settings.show_fov=value
	end
}):AddColorPicker("SA_FOVColor",{
	Default=Color3.fromRGB(255,255,255),
	Callback=function(value)
		fov_stroke.Color=value
	end
})

silent_tab:AddSlider("SA_FOVRadius",{
	Text="FOV Radius",
	Default=150,
	Min=10,
	Max=600,
	Rounding=0,
	Callback=function(value)
		settings.fov=value
	end
})

silent_tab:AddDropdown("SA_FOVPlacement",{
	Values={"Mouse","Center Of Screen"},
	Default=1,
	Text="FOV Placement",
	Callback=function(value)
		settings.fov_placement=value
	end
})

silent_tab:AddDropdown("SA_TargetTeams",{
	Values={"Guards","Inmates","Criminals"},
	Default={"Guards","Inmates","Criminals"},
	Multi=true,
	Text="Target Selection"
})

config_tab:AddDropdown("SA_Ignore",{
	Values=get_player_names(),
	Default={},
	Multi=true,
	Text="Ignore Player"
})

config_tab:AddDropdown("SA_Prioritize",{
	Values=get_player_names(),
	Default={},
	Multi=true,
	Text="Prioritize Player"
})

config_tab:AddDropdown("SA_Force",{
	Values=get_player_names(),
	Default={},
	Multi=true,
	Text="Ignore Player From Team Ignore"
})

config_tab:AddDivider()

config_tab:AddToggle("SA_WallCheck",{
	Text="Wall Check",
	Default=true,
	Callback=function(value)
		settings.wall_check=value
	end
})

config_tab:AddToggle("SA_TeamCheck",{
	Text="Team Check",
	Default=true,
	Callback=function(value)
		settings.team_check=value
	end
})

config_tab:AddDropdown("SA_HitPart",{
	Values={"Head","Torso","HumanoidRootPart"},
	Default=1,
	Text="Target Hit Part",
	Callback=function(value)
		settings.hit_part=value
	end
})

config_tab:AddToggle("SA_Prediction",{
	Text="Show Prediction Tracer",
	Default=false,
	Callback=function(value)
		settings.prediction=value
	end
}):AddColorPicker("SA_PredColor",{
	Default=Color3.fromRGB(160,100,255),
	Callback=function(value)
		tracer.Color=value
	end
})

config_tab:AddSlider("SA_OffsetX",{
	Text="Offset X",
	Default=0,
	Min=-5,
	Max=5,
	Rounding=1,
	Callback=function(value)
		settings.offset_x=value
	end
})

config_tab:AddSlider("SA_OffsetY",{
	Text="Offset Y",
	Default=0,
	Min=-5,
	Max=5,
	Rounding=1,
	Callback=function(value)
		settings.offset_y=value
	end
})

silent_tab:AddDivider()

silent_tab:AddSlider("SA_Spread",{
	Text="Spread (Studs)",
	Default=0,
	Min=0,
	Max=15,
	Rounding=1,
	Callback=function(value)
		settings.spread=value
	end
})

silent_tab:AddSlider("SA_HitChance",{
	Text="Hit Chance (%)",
	Default=100,
	Min=0,
	Max=100,
	Rounding=0,
	Callback=function(value)
		settings.hit_chance=value
	end
})

silent_tab:AddToggle("SA_NormalizeAim",{
	Text="Normalize Aim",
	Default=false,
	Callback=function(value)
		settings.normalize_aim=value
	end
})

silent_tab:AddDivider()

silent_tab:AddToggle("SA_AutoShoot",{
	Text="Auto Shoot",
	Default=false,
	Callback=function(value)
		settings.auto_shoot=value
	end
})

silent_tab:AddToggle("SA_AutoReload",{
	Text="Auto Reload",
	Default=false,
	Callback=function(value)
		settings.auto_reload=value
	end
})

local raycast_params=RaycastParams.new()
raycast_params.FilterType=Enum.RaycastFilterType.Exclude
raycast_params.IgnoreWater=true

local function update_filter()
	local character=localplayer.Character
	raycast_params.FilterDescendantsInstances=character and {character,camera} or {camera}
end

update_filter()

MainMaid:GiveTask(localplayer.CharacterAdded:Connect(function()
	task.defer(function()
		camera=workspace.CurrentCamera
		update_filter()
	end)
end))

MainMaid:GiveTask(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera=workspace.CurrentCamera
	update_filter()
end))

local cached_target
local cached_target_time=0
local target_interval=.03
local tau=math.pi*2
local miss_distance=3

local function get_hit_part(cache)
	if settings.hit_part=="Head" then
		return cache.head or cache.root
	elseif settings.hit_part=="Torso" then
		return cache.torso or cache.upper_torso or cache.root or cache.head
	end

	return cache.root or cache.head
end

local function visible_from(origin,part,character)
	local direction=part.Position-origin

	if direction.Magnitude<.1 then
		return true
	end

	local result=workspace:Raycast(origin,direction,raycast_params)

	if not result then
		return true
	end

	return result.Instance==part or isdescendantof(result.Instance,character)
end

local function make_aim_position(origin,target_position)
	local direction=target_position-origin
	local distance=direction.Magnitude

	if distance<.001 then
		return target_position
	end

	direction/=distance

	local radius=settings.spread

	if settings.hit_chance<100 and random()*100>settings.hit_chance then
		radius=math.max(radius,miss_distance)
	end

	if radius<=0 then
		return target_position
	end

	local right=direction:Cross(Vector3.yAxis)

	if right.Magnitude<.0001 then
		right=direction:Cross(Vector3.xAxis)
	end

	right=right.Unit

	local up=right:Cross(direction).Unit
	local radial=math.sqrt(random())*radius
	local angle=random()*tau

	local aim_position=
		target_position+
		right*math.cos(angle)*radial+
		up*math.sin(angle)*radial

	if settings.normalize_aim then
		local aim_direction=aim_position-origin
		local aim_distance=aim_direction.Magnitude

		if aim_distance>.001 then
			aim_position=origin+aim_direction.Unit*distance
		end
	end

	return aim_position
end

local function get_target(center_x,center_y)
	local now=clock()

	if cached_target and cached_target.Parent and now-cached_target_time<target_interval then
		return cached_target
	end

	local teams=options.SA_TargetTeams.Value
	local ignored=options.SA_Ignore.Value
	local prioritized=options.SA_Prioritize.Value
	local forced=options.SA_Force.Value

	local allow_guards=teams.Guards
	local allow_inmates=teams.Inmates
	local allow_criminals=teams.Criminals

	local local_team=localplayer.Team
	local camera_position=camera.CFrame.Position
	local max_distance=settings.fov*settings.fov

	local best_target
	local best_score=max_distance

	for i=1,#player_list do
		local player=player_list[i]

		if player==localplayer then
			continue
		end

		local name=player.Name

		if ignored[name] then
			continue
		end

		local force=forced[name]
		local priority=prioritized[name]
		local allowed=true
		local team=player.Team

		if settings.team_check and team==local_team then
			allowed=false
		end

		if team then
			local team_name=team.Name:lower()

			if team_name:find("guard",1,true) then
				allowed=allow_guards
			elseif team_name:find("inmate",1,true) then
				allowed=allow_inmates
			elseif team_name:find("crim",1,true) then
				allowed=allow_criminals
			end
		end

		if not allowed and not force then
			continue
		end

		local cache=player_cache[player]

		if not cache then
			continue
		end

		local humanoid=cache.humanoid

		if not humanoid or humanoid.Health<=0 or cache.forcefield then
			continue
		end

		local part=get_hit_part(cache)

		if not part then
			continue
		end

		local position,on_screen=camera:WorldToViewportPoint(part.Position)

		if not on_screen then
			continue
		end

		local dx=position.X-center_x
		local dy=position.Y-center_y
		local distance=dx*dx+dy*dy

		if distance>max_distance then
			continue
		end

		local score=priority and distance-100000000 or distance

		if score>=best_score then
			continue
		end

		if settings.wall_check and not visible_from(camera_position,part,cache.character) then
			continue
		end

		best_score=score
		best_target=part
	end

	cached_target=best_target
	cached_target_time=now

	return best_target
end

MainMaid:GiveTask(runservice.RenderStepped:Connect(function()
	local center_x
	local center_y

	if settings.fov_placement=="Mouse" then
		local mouse=uis:GetMouseLocation()
		center_x=mouse.X
		center_y=mouse.Y
	else
		local viewport=camera.ViewportSize
		center_x=viewport.X*.5
		center_y=viewport.Y*.5
	end

	local target

	if settings.silent or settings.auto_shoot or settings.prediction then
		target=get_target(center_x,center_y)
	else
		cached_target=nil
	end

	if settings.show_fov then
		local diameter=settings.fov*2
		fov_circle.Position=UDim2.fromOffset(center_x,center_y)
		fov_circle.Size=UDim2.fromOffset(diameter,diameter)
		fov_circle.Visible=true
	else
		fov_circle.Visible=false
	end

	if settings.prediction and target then
		local position,on_screen=camera:WorldToViewportPoint(target.Position)

		if on_screen then
			local viewport=camera.ViewportSize

			tracer.From=Vector2.new(viewport.X*.5,viewport.Y*.5)
			tracer.To=Vector2.new(
				position.X+settings.offset_x*15,
				position.Y+settings.offset_y*15
			)
			tracer.Visible=true
		else
			tracer.Visible=false
		end
	else
		tracer.Visible=false
	end
end))

local current_gun

local function update_gun(character)
	current_gun=nil

	if not character then
		return
	end

	local children=character:GetChildren()

	for i=1,#children do
		local child=children[i]

		if child:IsA("Tool") and child:GetAttribute("ToolType")=="Gun" then
			current_gun=child
			return
		end
	end
end

local function bind_character(character)
	update_gun(character)

	MainMaid:GiveTask(character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("ToolType")=="Gun" then
			current_gun=child
		end
	end))

	MainMaid:GiveTask(character.ChildRemoved:Connect(function(child)
		if child==current_gun then
			current_gun=nil
		end
	end))
end

if localplayer.Character then
	bind_character(localplayer.Character)
end

MainMaid:GiveTask(localplayer.CharacterAdded:Connect(bind_character))

local last_shot=0
local last_reload=0

MainMaid:GiveTask(runservice.Heartbeat:Connect(function()
	if not settings.auto_shoot and not settings.auto_reload then
		return
	end

	local gun=current_gun

	if not gun or not gun.Parent then
		return
	end

	local ammo=gun:GetAttribute("Local_CurrentAmmo") or 0

	if settings.auto_reload and ammo<=0 then
		local now=clock()

		if now-last_reload>1 then
			last_reload=now

			gun:SetAttribute("Local_ReloadSession",now)

			if func_reload then
				func_reload:InvokeServer()
			end

			task.delay(gun:GetAttribute("ReloadTime") or 2,function()
				if gun.Parent and gun:GetAttribute("Local_ReloadSession")==now then
					gun:SetAttribute("Local_CurrentAmmo",gun:GetAttribute("MaxAmmo") or 0)
					gun:SetAttribute("Local_ReloadSession",0)
				end
			end)
		end

		return
	end

	if not settings.auto_shoot or not settings.silent then
		return
	end

	local target=cached_target

	if not target or not target.Parent or ammo<=0 then
		return
	end

	local now=clock()
	local fire_rate=gun:GetAttribute("FireRate") or .2

	if now-last_shot<fire_rate+.05 then
		return
	end

	local character=localplayer.Character

	if not character then
		return
	end

	local head=findfirstchild(character,"Head")
	local root=findfirstchild(character,"HumanoidRootPart")
	local origin=head and head.Position or root and root.Position

	if not origin then
		return
	end

	local muzzle=findfirstchild(gun,"Muzzle")
	local muzzle_position=muzzle and muzzle.Position or origin
	local count=gun:GetAttribute("ProjectileCount") or 1
	local shots=table.create(count)

	for i=1,count do
		local aim_position=make_aim_position(origin,target.Position)
		shots[i]={origin,aim_position,target}
	end

	last_shot=now

	if shoot_event then
		shoot_event:FireServer(shots)
	end

	if gun_tracers and shots[1] then
		local position=shots[1][2]
		local behavior=gun:GetAttribute("Behavior")

		if behavior=="Sniper" and gun_tracers.createSniper then
			gun_tracers.createSniper(muzzle_position,position)
		elseif behavior=="Taser" and gun_tracers.createTaser then
			gun_tracers.createTaser(muzzle_position,position)
		elseif gun_tracers.createBullet then
			gun_tracers.createBullet(muzzle_position,position)
		end
	end

	gun:SetAttribute("Local_CurrentAmmo",math.max(0,ammo-1))
end))

local metatable=getrawmetatable(game)
local old_namecall=metatable.__namecall

setreadonly(metatable,false)

metatable.__namecall=newcclosure(function(self,...)
	local method=getnamecallmethod()

	if method=="Raycast" and self==workspace and settings.silent then
		local target=cached_target

		if target and target.Parent then
			local args=table.pack(...)
			local origin=args[1]
			local direction=args[2]

			if typeof(origin)=="Vector3" and typeof(direction)=="Vector3" then
				local target_position=target.Position+Vector3.new(
					settings.offset_x,
					settings.offset_y,
					0
				)

				local final_position=make_aim_position(origin,target_position)

				return {
					Instance=target,
					Position=final_position,
					Material=Enum.Material.Plastic,
					Normal=Vector3.yAxis,
					Distance=(origin-final_position).Magnitude
				}
			end
		end
	elseif method=="FireServer" and self==shoot_event and settings.silent then
		local target=cached_target

		if target and target.Parent then
			local args=table.pack(...)
			local shots=args[1]

			if type(shots)=="table" and #shots>0 then
				local center=Vector3.zero
				local valid=0

				for i=1,#shots do
					local shot=shots[i]
					local position=shot and shot[2]

					if typeof(position)=="Vector3" then
						center+=position
						valid+=1
					end
				end

				if valid>0 then
					center/=valid

					local target_position=target.Position+Vector3.new(
						settings.offset_x,
						settings.offset_y,
						0
					)

					local new_shots=table.create(#shots)

					for i=1,#shots do
						local shot=shots[i]

						if type(shot)~="table" then
							new_shots[i]=shot
							continue
						end

						local origin=shot[1]
						local position=shot[2]

						if typeof(origin)~="Vector3" or typeof(position)~="Vector3" then
							new_shots[i]=shot
							continue
						end

						local aim_position=make_aim_position(origin,target_position)

						new_shots[i]={
							origin,
							aim_position+(position-center),
							target
						}
					end

					return old_namecall(self,new_shots)
				end
			end
		end
	end

	return old_namecall(self,...)
end)

setreadonly(metatable,true)
