-- near
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local CONSTANTS = {
	TARGET_TIME = os.time({year = 2026, month = 4, day = 1, hour = 0, min = 0, sec = 0}),
	SOUNDS = {
		MAIN = "rbxassetid://109355510805271",
		SEC = "rbxassetid://139726388352120"
	},
	COLORS = {
		SAFE = Color3.fromRGB(0, 255, 0),
		WARN = Color3.fromRGB(255, 140, 0),
		DANGER = Color3.fromRGB(255, 0, 0)
	}
}

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({Tasks = {}}, Maid)
end

function Maid:Add(item)
	table.insert(self.Tasks, item)
end

function Maid:Clean()
	for _, item in ipairs(self.Tasks) do
		if typeof(item) == "RBXScriptConnection" then
			item:Disconnect()
		elseif typeof(item) == "Instance" then
			item:Destroy()
		elseif type(item) == "function" then
			task.spawn(item)
		end
	end
	self.Tasks = {}
end

local App = {}
App.__index = App

function App.new()
	local self = setmetatable({}, App)
	self.Maid = Maid.new()
	
	local targetParent = (gethui and gethui()) or CoreGui
	
	self.Screen = Instance.new("ScreenGui")
	self.Screen.Name = HttpService:GenerateGUID(false)
	self.Screen.ResetOnSpawn = false
	self.Screen.Parent = targetParent
	self.Maid:Add(self.Screen)

	self.Label = Instance.new("TextLabel")
	self.Label.Size = UDim2.new(1, 0, 0, 120)
	self.Label.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Label.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Label.BackgroundTransparency = 1
	self.Label.TextScaled = true
	self.Label.Font = Enum.Font.Creepster
	self.Label.TextStrokeTransparency = 1
	self.Label.Parent = self.Screen
	
	self.Sound1 = Instance.new("Sound")
	self.Sound1.SoundId = CONSTANTS.SOUNDS.MAIN
	self.Sound1.Looped = true
	self.Sound1.Parent = self.Screen
	
	self.Sound2 = Instance.new("Sound")
	self.Sound2.SoundId = CONSTANTS.SOUNDS.SEC
	self.Sound2.Looped = true
	self.Sound2.Parent = self.Screen

	self.BasePos = self.Label.Position
	self.ShakeLevel = 0
	self.Flicker = false
	
	self.Maid:Add(RunService.RenderStepped:Connect(function()
		if self.ShakeLevel > 0 then
			local x = math.random(-self.ShakeLevel, self.ShakeLevel)
			local y = math.random(-self.ShakeLevel, self.ShakeLevel)
			self.Label.Position = self.BasePos + UDim2.new(0, x, 0, y)
		else
			self.Label.Position = self.BasePos
		end
		
		if self.Flicker then
			self.Label.TextColor3 = Color3.fromRGB(math.random(150, 255), 0, 0)
		end
	end))

	return self
end

function App:GetState()
	local diff = CONSTANTS.TARGET_TIME - os.time()
	local days = diff / 86400
	
	if diff <= 0 then return "BEGUN", 0 end
	if diff <= 3600 then return "DOOM", 0 end
	if diff <= 86400 then return "DAY", diff end
	if days < 7 then return "CRITICAL", days end
	if days < 15 then return "DANGER", days end
	if days < 31 then return "WARN", days end
	return "SAFE", days
end

function App:GetAudioDuration(sound)
	if not sound.IsLoaded then
		sound.Loaded:Wait()
	end
	if sound.TimeLength <= 0 then return 5 end
	return sound.TimeLength / sound.PlaybackSpeed
end

function App:ApplyEffects(state, val)
	self.Sound1:Stop()
	self.Sound2:Stop()
	
	if state == "BEGUN" then
		self.Label.Text = "It has begun."
		self.Label.TextColor3 = CONSTANTS.COLORS.DANGER
		return 10 -- The last one is 10s
	elseif state == "DOOM" then
		self.Label.Text = "Doom is soon."
		self.Label.TextColor3 = CONSTANTS.COLORS.DANGER
		self.ShakeLevel = 14
		self.Flicker = true
		self.Sound1.PlaybackSpeed = 1
		self.Sound2.PlaybackSpeed = 1
		self.Sound1:Play()
		self.Sound2:Play()
		self:StartChaos()
		return self:GetAudioDuration(self.Sound1)
	elseif state == "DAY" then
		self.Label.Text = string.format("Hours Left: %d", math.floor(val/3600))
		self.Label.TextColor3 = CONSTANTS.COLORS.DANGER
		self.ShakeLevel = 6
		self.Sound2.PlaybackSpeed = 0.3
		self.Sound2:Play()
		return self:GetAudioDuration(self.Sound2)
	elseif state == "CRITICAL" then
		self.Label.Text = string.format("Days Left: %d", math.floor(val))
		self.Label.TextColor3 = CONSTANTS.COLORS.DANGER
		self.ShakeLevel = 3
		self.Sound2.PlaybackSpeed = 0.5
		self.Sound2:Play()
		return self:GetAudioDuration(self.Sound2)
	elseif state == "DANGER" then
		self.Label.Text = string.format("Days Left: %d", math.floor(val))
		self.Label.TextColor3 = CONSTANTS.COLORS.DANGER
		self.Sound1.PlaybackSpeed = 0.4
		self.Sound1:Play()
		return self:GetAudioDuration(self.Sound1)
	elseif state == "WARN" then
		self.Label.Text = string.format("Days Left: %d", math.floor(val))
		self.Label.TextColor3 = CONSTANTS.COLORS.WARN
		self.Sound1.PlaybackSpeed = 0.6
		self.Sound1:Play()
		return self:GetAudioDuration(self.Sound1)
	else
		self.Label.Text = string.format("Days Left: %d", math.floor(val))
		self.Label.TextColor3 = CONSTANTS.COLORS.SAFE
		self.Sound1.PlaybackSpeed = 1
		self.Sound1:Play()
		return self:GetAudioDuration(self.Sound1)
	end
end

function App:StartChaos()
	local thread = task.spawn(function()
		while true do
			self.Sound1.Volume = math.random()
			self.Sound2.Volume = math.random()
			self.Sound1.PlaybackSpeed = math.random(10, 200) / 100
			self.Sound2.PlaybackSpeed = math.random(10, 200) / 100
			task.wait(0.2)
		end
	end)
	self.Maid:Add(function() task.cancel(thread) end)
end

function App:Run()
	local state, val = self:GetState()
	local fadeDuration = self:ApplyEffects(state, val)
	
	task.delay(0.1, function()
		local tween = TweenService:Create(self.Label, TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear), {TextTransparency = 1})
		tween.Completed:Connect(function()
			self.Maid:Clean()
		end)
		tween:Play()
	end)
end

App.new():Run()
