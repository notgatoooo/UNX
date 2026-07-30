setfpscap(999)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

if getgenv().isloading then
	return
end

getgenv().isloading = true

if not isfolder("unxhub") then
	makefolder("unxhub")
end

if not isfolder("unxhub/cache") then
	makefolder("unxhub/cache")
end

if not isfolder("unxhub/themes") then
	makefolder("unxhub/themes")
end

if not isfile("unxhub/themes/default.txt") then
	writefile("unxhub/themes/default.txt", "UNXIshM")
end

if not isfile("unxhub/themes/UNXIshM.json") then
	writefile(
		"unxhub/themes/UNXIshM.json",
		'{"MainColor":"21221d","FontFace":"Fantasy","AccentColor":"b9c29d","OutlineColor":"34362d","BackgroundColor":"121310","FontColor":"e6e6e6"}'
	)
end

if getgenv().unxshared and getgenv().unxshared.isloaded then
	getgenv().isloading = false
	return
end

pcall(function()
	loadstring(game:HttpGet("https://api.getunx.cc/Modules/v2/API.lua", true))()
end)

getgenv().unxshared = {
	version = "2.9.3b",
	gamename = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
	issupported = false,
	playername = game.Players.LocalPlayer.Name,
	playerid = game.Players.LocalPlayer.UserId,
	isloaded = false,
	devnote = "Made with 💖 by Gato",
	ver = 2
}

local folder = "unxhub/cache"
local cacheTime = folder .. "/.t"

local files = {
	{"Library.lua", "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"},
	{"ThemeManager.lua", "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"},
	{"SaveManager.lua", "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"},
	{"Bind.lua", "https://api.getunx.cc/Modules/v2/Bind.lua"}
}

local refresh = true

if isfile(cacheTime) then
	local t = tonumber(readfile(cacheTime))
	if t and os.time() - t < 86400 then
		refresh = false
	end
end

if refresh then
	for i = 1, #files do
		local data

		for _ = 1, 3 do
			local s, r = pcall(function()
				return game:HttpGet(files[i][2])
			end)

			if s and #r > 50 then
				data = r
				break
			end

			task.wait(1)
		end

		if data then
			writefile(folder .. "/" .. files[i][1], data)
		end
	end

	writefile(cacheTime, tostring(os.time()))
end

local pid = game.PlaceId

local games = {
	[12240122896] = "https://api.getunx.cc/Games/FigureL.lua",
	[136801880565837] = "https://api.getunx.cc/Games/Flick.lua",
	[893973440] = "https://api.getunx.cc/Games/Flee.lua",
	[132745842491660] = "https://api.getunx.cc/Games/Flee.lua",
	[106344247300586] = "https://api.getunx.cc/Games/Flee.lua",
	[125624013879756] = "https://api.getunx.cc/Games/Flee.lua",
	[107279422643029] = "https://api.getunx.cc/Modules/v2/Other/FleeEvent.lua",
	[105241313130846] = "https://api.getunx.cc/Games/OneShot.lua"
}

local success, err

if games[pid] then
	getgenv().unxshared.issupported = true

	success, err = pcall(function()
		loadstring(game:HttpGet(games[pid]))()
	end)
else
	success, err = pcall(function()
		loadstring(game:HttpGet("https://api.getunx.cc/Games/Universal.lua"))()
	end)
end

getgenv().unxshared.isloaded = success
getgenv().isloading = false

if not success then
	game.Players.LocalPlayer:Kick("UNXHub: An Error Occured: " .. tostring(err))
end
