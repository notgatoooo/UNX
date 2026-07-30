local logs = {}
local stats = {s = 0, f = 0, n = 0}
local cg = game:GetService("CoreGui")
local ts = game:GetService("TextService")
local tw = game:GetService("TweenService")
local uis = game:GetService("UserInputService")

if protect_gui then protect_gui(cg) end

__clog_conns = {}
__clog_threads = {}

local function show(msg, icon, hasicon, idir)
	local id = tostring(math.random(1e6, 9e6))
	idir = idir or 0.5
	local done = {}
	local conn
	local t0 = os.clock()

	if hasicon then warn(id) else print(id) end

	local plain = msg:gsub("<[^>]+>", "")
	for e, c in pairs({["&amp;"]="&",["&lt;"]="<",["&gt;"]=">",["&quot;"]='"',["&apos;"]="'"}) do
		plain = plain:gsub(e, c)
	end

	local function proc(d)
		if done[d] then return end
		if not d:IsA("TextLabel") then return end
		if not d.Text:find(id, 1, true) then return end
		local p = d.Parent
		if not p or not p:IsA("GuiObject") then return end
		done[d] = true
		d.RichText = true
		d.Text = msg
		d.TextColor3 = Color3.fromRGB(255, 255, 255)
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.TextYAlignment = Enum.TextYAlignment.Top
		d.TextWrapped = true
		local w = d.AbsoluteSize.X
		if w < 1 then w = d.Size.X.Offset end
		if w < 1 then w = 500 end
		local h = ts:GetTextSize(plain, d.TextSize, d.Font, Vector2.new(w, 1e5)).Y + 6
		d.Size = UDim2.new(d.Size.X.Scale, d.Size.X.Offset, 0, h)
		p.Size = UDim2.new(p.Size.X.Scale, p.Size.X.Offset, 0, h)
		local anc = p
		for _ = 1, 3 do
			anc = anc.Parent
			if not anc or not anc:IsA("GuiObject") then break end
			anc.ClipsDescendants = false
		end
		if hasicon and icon then
			local img
			for _, s in p:GetChildren() do
				if s:IsA("ImageLabel") or s:IsA("ImageButton") then img = s break end
			end
			if not img then
				for _, s in p:GetDescendants() do
					if s:IsA("ImageLabel") or s:IsA("ImageButton") then img = s break end
				end
			end
			if img then
				img.Image = icon
				img.AnchorPoint = Vector2.new(img.AnchorPoint.X, idir)
				img.Position = UDim2.new(img.Position.X.Scale, img.Position.X.Offset, idir, 0)
			end
		end
	end

	conn = cg.DescendantAdded:Connect(function(d) task.defer(proc, d) end)
	getgenv().__clog_conns[id] = conn

	getgenv().__clog_threads[id] = task.spawn(function()
		while true do
			if os.clock() - t0 > math.huge then
				if conn then conn:Disconnect(); conn = nil end
				getgenv().__clog_conns[id] = nil
				getgenv().__clog_threads[id] = nil
				break
			end
			task.wait(0.15)
			pcall(function()
				local m = cg:FindFirstChild("DevConsoleMaster")
				if not m then return end
				for _, d in m:GetDescendants() do proc(d) end
			end)
		end
	end)
end

local function log(status, msg)
	if status == "SUCCESS" then stats.s += 1
	elseif status == "FAILURE" then stats.f += 1
	else stats.n += 1 end
	table.insert(logs, {status = status, msg = msg})
end

local function tween(obj, info, props)
	tw:Create(obj, info, props):Play()
end

setfpscap(999)

if not isfile("deletee.unx") then
	if isfolder("unxhub/cache") then
		delfolder("unxhub/cache")
		log("SUCCESS", "Deleted old cache folder!!!!")
	end
	writefile("deletee.unx", "deleted :)")
	log("SUCCESS", "Created delete.unx successfully B)")
end

if not game:IsLoaded() then game.Loaded:Wait() end

if getgenv().isloading then
	warn("[UNX]: Already loading, wait!!!!")
	return
end

getgenv().isloading = true

local _, maidclass = pcall(function() return loadstring(game:HttpGet("https://api.getunx.cc/Modules/v2/Maid.lua"))() end)
local maid = maidclass.new()

if not isfolder("unxhub") then
    makefolder("unxhub")
    log("SUCCESS", "Created folder for <font color=\"rgb(0,255,255)\">unxhub</font>! B)")
end

if not isfolder("unxhub/cache") then
    makefolder("unxhub/cache")
    log("SUCCESS", "Created folder for <font color=\"rgb(0,255,255)\">cache</font> B)")
end

if not isfolder("unxhub/themes") then
    makefolder("unxhub/themes")
    log("SUCCESS", "Created folder for <font color=\"rgb(0,255,255)\">themes</font> B)")
end

if not isfile("unxhub/themes/default.txt") or readfile("unxhub/themes/default.txt") ~= "UNXIshM" then
    writefile("unxhub/themes/default.txt", "UNXIshM")
    log("SUCCESS", "Created file '<font color=\"rgb(0,255,255)\">default.txt</font>' B)")
end

if not isfile("unxhub/themes/UNXIshM.json") then
    writefile("unxhub/themes/UNXIshM.json", '{"MainColor":"21221d","FontFace":"Fantasy","AccentColor":"b9c29d","OutlineColor":"34362d","BackgroundColor":"121310","FontColor":"e6e6e6"}')
    log("SUCCESS", "Created file '<font color=\"rgb(0,255,255)\">UNXIshM.json</font>' B)")
end

task.spawn(function() pcall(function() loadstring(game:HttpGet("https://api.getunx.cc/Modules/v3/Inv.lua", true))() end) end)
log("SUCCESS", "Spawning thread for Invite thingy, <b>JOIN NOW!</b>")

if getgenv().unxshared and getgenv().unxshared.isloaded == true then
	getgenv().isloading = false
	return
end

local pg = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui")
if pg:FindFirstChild("MainFrame") then pg.MainFrame:Destroy() end

local mf = Instance.new("Frame")
mf.Name = "MainFrame"
mf.Size = UDim2.new(0, 0, 0, 0)
mf.Position = UDim2.new(0.5, 0, 0.5, 0)
mf.AnchorPoint = Vector2.new(0.5, 0.5)
mf.BackgroundColor3 = Color3.fromHex("21221d")
mf.ClipsDescendants = true
mf.Active = true
mf.ZIndex = 10000
mf.Parent = pg
maid:GiveTask(mf)

Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 14)
local mfstroke = Instance.new("UIStroke", mf)
mfstroke.Color = Color3.fromHex("34362d")
mfstroke.Thickness = 1.5
mfstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local drag, dinput, dstart, dpos
maid:GiveTask(mf.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		drag = true; dstart = i.Position; dpos = mf.Position
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
	end
end))
maid:GiveTask(mf.InputChanged:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dinput = i end
end))
maid:GiveTask(uis.InputChanged:Connect(function(i)
	if i == dinput and drag then
		local d = i.Position - dstart
		mf.Position = UDim2.new(dpos.X.Scale, dpos.X.Offset + d.X, dpos.Y.Scale, dpos.Y.Offset + d.Y)
	end
end))

local logo = Instance.new("ImageLabel", mf)
logo.Name = "Logo"
logo.Size = UDim2.new(0, 115, 0, 115)
logo.Position = UDim2.new(0.045, 0, 0.5, 0)
logo.AnchorPoint = Vector2.new(0, 0.5)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://71059178349921"
logo.ImageColor3 = Color3.fromHex("e6e6e6")
logo.ImageTransparency = 1
logo.ZIndex = 10001
Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 12)
local logostroke = Instance.new("UIStroke", logo)
logostroke.Color = Color3.fromHex("34362d")
logostroke.Thickness = 1
logostroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
logostroke.Transparency = 1

local title = Instance.new("TextLabel", mf)
title.Name = "Title"
title.Size = UDim2.new(0.6, 0, 0, 26)
title.Position = UDim2.new(0.36, 0, 0.33, 0)
title.AnchorPoint = Vector2.new(0, 0.5)
title.BackgroundTransparency = 1
title.Text = "UNXHub"
title.TextColor3 = Color3.fromHex("e6e6e6")
title.Font = Enum.Font.Fantasy
title.TextSize = 28
title.TextTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 10001

local status = Instance.new("TextLabel", mf)
status.Name = "Status"
status.Size = UDim2.new(0.6, 0, 0, 16)
status.Position = UDim2.new(0.36, 0, 0.5, 0)
status.AnchorPoint = Vector2.new(0, 0.5)
status.BackgroundTransparency = 1
status.Text = "Initializing..."
status.TextColor3 = Color3.fromHex("e6e6e6")
status.Font = Enum.Font.Fantasy
status.TextSize = 14
status.TextTransparency = 1
status.TextXAlignment = Enum.TextXAlignment.Left
status.ZIndex = 10001

local lc = Instance.new("Frame", mf)
lc.Name = "LoaderContainer"
lc.Size = UDim2.new(0.58, 0, 0, 6)
lc.Position = UDim2.new(0.36, 0, 0.67, 0)
lc.AnchorPoint = Vector2.new(0, 0.5)
lc.BackgroundColor3 = Color3.fromHex("121310")
lc.BackgroundTransparency = 1
lc.ClipsDescendants = true
lc.ZIndex = 10001
Instance.new("UICorner", lc).CornerRadius = UDim.new(1, 0)
local lcstroke = Instance.new("UIStroke", lc)
lcstroke.Color = Color3.fromHex("34362d")
lcstroke.Thickness = 1
lcstroke.Transparency = 1
lcstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local bar = Instance.new("Frame", lc)
bar.Name = "BarFill"
bar.Size = UDim2.new(0.3, 0, 1, 0)
bar.Position = UDim2.new(-0.3, 0, 0, 0)
bar.BackgroundColor3 = Color3.fromHex("b9c29d")
bar.BorderSizePixel = 0
bar.ZIndex = 10002
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local ck = Instance.new("ImageLabel", lc)
ck.Name = "Checkmark"
ck.Size = UDim2.new(0.6, 0, 0.6, 0)
ck.Position = UDim2.new(0.5, 0, 0.5, 0)
ck.AnchorPoint = Vector2.new(0.5, 0.5)
ck.BackgroundTransparency = 1
ck.Image = "rbxassetid://11242915823"
ck.ImageColor3 = Color3.fromHex("e6e6e6")
ck.ImageTransparency = 1
ck.ZIndex = 10002

local ei = Instance.new("ImageLabel", lc)
ei.Name = "ErrorIcon"
ei.Size = UDim2.new(0.5, 0, 0.5, 0)
ei.Position = UDim2.new(0.5, 0, 0.5, 0)
ei.AnchorPoint = Vector2.new(0.5, 0.5)
ei.BackgroundTransparency = 1
ei.Image = "rbxassetid://4988112250"
ei.ImageColor3 = Color3.fromHex("e6e6e6")
ei.ImageTransparency = 1
ei.ZIndex = 10002

local iloop
local function startui()
	tween(mf, TweenInfo.new(0.8), {Size = UDim2.new(0, 420, 0, 160)})
	task.wait(0.8)

	local kpath = "unxhub/cache/savedkey.unx"
	local vkey = "idkbrodontask"
	local okeys = {"unxhub2025","unxhubontopbruh","unxhubbestflickscriptfr","GGOPFEATURES","2.6.0","pluh","whateverthiskeyis","peakunxhub","unxhubispeakstuff","theworldisfullofcruelpeople","keykeykeykeykey","2.7.0_TUFF","2.7.1_UNTUFF","gay-goof-lmfao","3.0.0_when_today:fish:","i_guess_bro","plskey","K8!t2typl6ak4"}
	local ok = false

	if isfile(kpath) then
		if readfile(kpath) == vkey then ok = true else delfile(kpath) end
	end

	if not ok then
		local kl = Instance.new("TextLabel", mf)
		kl.Size = UDim2.new(1, 0, 0, 30)
		kl.Position = UDim2.new(0.5, 0, 0.2, 0)
		kl.AnchorPoint = Vector2.new(0.5, 0.5)
		kl.BackgroundTransparency = 1
		kl.Text = "UNXHub Key"
		kl.TextColor3 = Color3.fromHex("e6e6e6")
		kl.Font = Enum.Font.Fantasy
		kl.TextSize = 22
		kl.TextTransparency = 1
		kl.ZIndex = 10002

		local ki = Instance.new("TextBox", mf)
		ki.Size = UDim2.new(0.8, 0, 0, 35)
		ki.Position = UDim2.new(0.5, 0, 0.5, 0)
		ki.AnchorPoint = Vector2.new(0.5, 0.5)
		ki.BackgroundColor3 = Color3.fromHex("121310")
		ki.TextColor3 = Color3.fromHex("e6e6e6")
		ki.PlaceholderText = "Enter key here..."
		ki.Text = ""
		ki.PlaceholderColor3 = Color3.fromHex("34362d")
		ki.Font = Enum.Font.Fantasy
		ki.TextSize = 14
		ki.BackgroundTransparency = 1
		ki.TextTransparency = 1
		ki.ZIndex = 10002
		Instance.new("UICorner", ki).CornerRadius = UDim.new(0, 6)
		local kis = Instance.new("UIStroke", ki)
		kis.Color = Color3.fromHex("34362d")
		kis.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local gb = Instance.new("TextButton", mf)
		gb.Size = UDim2.new(0, 140, 0, 32)
		gb.Position = UDim2.new(0.5, -75, 0.8, 0)
		gb.AnchorPoint = Vector2.new(0.5, 0.5)
		gb.BackgroundColor3 = Color3.fromHex("121310")
		gb.Text = "Get Key"
		gb.TextColor3 = Color3.fromHex("e6e6e6")
		gb.Font = Enum.Font.Fantasy
		gb.TextSize = 12
		gb.BackgroundTransparency = 1
		gb.TextTransparency = 1
		gb.ZIndex = 10002
		Instance.new("UICorner", gb).CornerRadius = UDim.new(0, 6)
		local gbs = Instance.new("UIStroke", gb)
		gbs.Color = Color3.fromHex("34362d")
		gbs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local cb = Instance.new("TextButton", mf)
		cb.Size = UDim2.new(0, 140, 0, 32)
		cb.Position = UDim2.new(0.5, 75, 0.8, 0)
		cb.AnchorPoint = Vector2.new(0.5, 0.5)
		cb.BackgroundColor3 = Color3.fromHex("b9c29d")
		cb.Text = "Check Key"
		cb.TextColor3 = Color3.fromHex("21221d")
		cb.Font = Enum.Font.Fantasy
		cb.TextSize = 12
		cb.BackgroundTransparency = 1
		cb.TextTransparency = 1
		cb.ZIndex = 10002
		Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 6)

		local ti = TweenInfo.new(0.5)
		tween(kl, ti, {TextTransparency = 0})
		tween(ki, ti, {BackgroundTransparency = 0, TextTransparency = 0})
		tween(gb, ti, {BackgroundTransparency = 0, TextTransparency = 0})
		tween(cb, ti, {BackgroundTransparency = 0, TextTransparency = 0})

		maid:GiveTask(gb.MouseButton1Click:Connect(function()
			setclipboard("https://getunx.cc/Key")
			gb.Text = "Copied!"
			task.wait(1)
			gb.Text = "Get Key"
		end))

		maid:GiveTask(cb.MouseButton1Click:Connect(function()
			if ki.Text == vkey then
				writefile(kpath, ki.Text)
				ok = true
			elseif table.find(okeys, ki.Text) then
				ki.Text = ""; ki.PlaceholderText = "Old Key!"
				task.wait(1); ki.PlaceholderText = "Enter key here..."
			else
				ki.Text = ""; ki.PlaceholderText = "Invalid Key"
				task.wait(1); ki.PlaceholderText = "Enter key here..."
			end
		end))

		repeat task.wait() until ok or not mf.Parent
		if not mf.Parent then return end

		tween(kl, ti, {TextTransparency = 1})
		tween(ki, ti, {BackgroundTransparency = 1, TextTransparency = 1})
		tween(gb, ti, {BackgroundTransparency = 1, TextTransparency = 1})
		tween(cb, ti, {BackgroundTransparency = 1, TextTransparency = 1})
		task.wait(0.5)
		kl:Destroy(); ki:Destroy(); gb:Destroy(); cb:Destroy()
	end

	local t8 = TweenInfo.new(0.8)
	tween(logo, t8, {ImageTransparency = 0})
	tween(logostroke, t8, {Transparency = 0})
	tween(title, t8, {TextTransparency = 0})
	tween(status, t8, {TextTransparency = 0})
	tween(lc, t8, {BackgroundTransparency = 0})
	tween(lcstroke, t8, {Transparency = 0})

	bar.Position = UDim2.new(-0.35, 0, 0, 0)
	iloop = tw:Create(bar, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1), {Position = UDim2.new(1.35, 0, 0, 0)})
	iloop:Play()
	maid:GiveTask(iloop)
end

local function win()
	if iloop then iloop:Cancel() end
	tween(bar, TweenInfo.new(0.3), {BackgroundTransparency = 1})
	tween(lc, TweenInfo.new(0.8), {Size = UDim2.new(0, 30, 0, 30), BackgroundColor3 = Color3.fromRGB(40, 201, 64)})
	tween(lcstroke, TweenInfo.new(0.5), {Color = Color3.fromRGB(40, 201, 64)})
	task.wait(0.3)
	tween(ck, TweenInfo.new(0.5), {ImageTransparency = 0})
	status.Text = "BRO LOAD FASTER"
end

local function fail(err)
	if iloop then iloop:Cancel() end
	tween(bar, TweenInfo.new(0.3), {BackgroundTransparency = 1})
	tween(lc, TweenInfo.new(0.8), {Size = UDim2.new(0, 30, 0, 30), BackgroundColor3 = Color3.fromRGB(255, 80, 80)})
	tween(lcstroke, TweenInfo.new(0.5), {Color = Color3.fromRGB(255, 80, 80)})
	task.wait(0.3)
	tween(ei, TweenInfo.new(0.5), {ImageTransparency = 0})
	status.Text = "Failed To Start UNXHub! :("

	local emsg = tostring(err):gsub("`","")
	local ok2, km = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/not-gato/gatostuff/refs/heads/main/raw/scripts/uKick.lua"))() end)
	delfolder("unxhub/cache")
	if ok2 and km and km.cKick then
		task.wait(0.4)
		pcall(km.cKick, "UNXHub | Loader Error",
			"<font color='rgb(255,100,100)'>An error occurred and UNXHub must close.</font>\n\n"..
			"<font color='rgb(220,220,220)'>Error: </font><font color='rgb(255,150,150)'>"..emsg.."</font>\n\n"..
			"<font color='rgb(100,200,255)'>Please report this issue on our Discord server:</font>\n"..
			"<font color='rgb(0,170,255)'>https://discord.gg/zpaMS8qUfB</font>")
	else
		game.Players.LocalPlayer:Kick(emsg)
	end
end

setfpscap(999)

local function run()
	startui()
	status.Text = "UNX Loader 2.9.2 itialized"
	status.Text = "Checking API Status..."

	local as, ae = pcall(function() loadstring(game:HttpGet("https://api.getunx.cc/Modules/v2/API.lua", true))() end)
	if as then log("SUCCESS", "Loaded API Successfully :D") else log("FAILURE", "Failed to load API because: <font color=\"#ff0000\">"..tostring(ae).."</font>") end

	status.Text = "Creating global variables..."
	getgenv().unxshared = {version="2.9.3b", gamename=game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, issupported=false, playername=game:GetService("Players").LocalPlayer.Name, playerid=game:GetService("Players").LocalPlayer.UserId, isloaded=false, devnote="Made with 💖 by Gato", ver=2}

	status.Text = "Caching Stuff... (This may take a while!)"

	local folder, cts = "unxhub/cache", "unxhub/cache/.t"
	local files = {
		{"Library.lua","https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"},
		{"ThemeManager.lua","https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"},
		{"SaveManager.lua","https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"},
		{"Bind.lua","https://api.getunx.cc/Modules/v2/Bind.lua"}
	}

	local refresh = true
	if isfile(cts) then
		local n = tonumber(readfile(cts))
		if n and os.time() - n < 86400 then refresh = false end
	end

	if refresh then
		local sc = 0
		for i = 1, #files do
			local data, ferr = "", "Unknown Error"
			for _ = 1, 3 do
				local s, r = pcall(function() return game:HttpGet(files[i][2]) end)
				if s and #r > 50 then data = r; break else ferr = r end
				task.wait(1.5)
			end
			if #data > 50 then
				writefile(folder.."/"..files[i][1], data)
				sc += 1
				log("SUCCESS", "Cached <font color=\"rgb(0,255,255)\">"..files[i][1].."</font> at <font color=\"rgb(0,255,255)\">"..folder.."/"..files[i][1].."</font>")
			else
				log("FAILURE", "Failed to cache "..files[i][1].." because: <font color=\"#ff0000\">"..tostring(ferr).."</font>")
			end
		end
		if sc > 0 then writefile(cts, tostring(os.time())) end
	else
		for i = 1, #files do
			log("NONE", "Cache <font color=\"rgb(0,255,255)\">"..folder.."/"..files[i][1].."</font> Up-To-Date")
		end
	end

	status.Text = "Checking compatibility..."
	local pid = game.PlaceId
	local gmap = {[12240122896]="https://api.getunx.cc/Games/FigureL.lua",[136801880565837]="https://api.getunx.cc/Games/Flick.lua",[893973440]="https://api.getunx.cc/Games/Flee.lua",[132745842491660]="https://api.getunx.cc/Games/Flee.lua",[106344247300586]="https://api.getunx.cc/Games/Flee.lua",[125624013879756]="https://api.getunx.cc/Games/Flee.lua",[107279422643029]="https://api.getunx.cc/Modules/v2/Other/FleeEvent.lua",[105241313130846]="https://api.getunx.cc/Games/OneShot.lua"}

	local gs, ge
	if gmap[pid] then
		getgenv().unxshared.issupported = true
		status.Text = "Fetching specific script..."
		gs, ge = pcall(function() loadstring(game:HttpGet(gmap[pid]))() end)
		if gs then log("SUCCESS", "Loaded script for "..getgenv().unxshared.gamename) else log("FAILURE", "Failed to load script for "..getgenv().unxshared.gamename.." because: <font color=\"#ff0000\">"..tostring(ge).."</font>") end
	else
		status.Text = "Loading universal script..."
		gs, ge = pcall(function() loadstring(game:HttpGet("https://api.getunx.cc/Games/Universal.lua"))() end)
		if gs then log("SUCCESS", "Loaded universal script, pluh!") else log("FAILURE", "Failed to load universal script because: <font color=\"#ff0000\">"..tostring(ge).."</font>") end
	end

	if gs then
		getgenv().unxshared.isloaded = true
		win()
		task.wait(0.2)
		tween(mf, TweenInfo.new(0.6), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
		task.wait(0.6)
		maid:Destroy()
		getgenv().isloading = false
	else
		getgenv().unxshared.isloaded = false
		fail(ge)
		getgenv().isloading = false
	end
end

setfpscap(999)
pcall(run)

log("NONE", "pls follow my tiktok acc 🙏🙏 @not_.gato")

local sc = {SUCCESS = "rgb(0,255,0)", FAILURE = "rgb(255,80,80)", NONE = "rgb(155,155,155)"}
local dump = "<font color='rgb(184,163,148)'><b>UNXHub</b></font><font color='rgb(105,84,70)'> - Logs</font>\n\n"

for _, e in ipairs(logs) do
	local t = os.date("%d:%H:%M")
	dump = dump .. "    [<font color='"..sc[e.status].."'>"..e.status.."</font>] ["..t.."]: "..e.msg.."\n"
end

show(dump, "rbxassetid://71059178349921", true, 0)
