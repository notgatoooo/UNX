local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local UI = (type(gethui) == "function" and gethui():FindFirstChild("UNX_BB"))
	or CoreGui:FindFirstChild("UNX_BB")
	or (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("UNX_BB"))

if not UI then
	UI = Instance.new("ScreenGui")
	UI.Name = "UNX_BB"
	UI.ResetOnSpawn = false

	local parent = (type(gethui) == "function" and gethui()) or CoreGui or (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui"))
	if parent then
		UI.Parent = parent
	end
end

local Container = UI:FindFirstChild("Container")
if not Container then
	Container = Instance.new("Frame")
	Container.Name = "Container"
	Container.Parent = UI
	Container.BackgroundColor3 = Color3.fromHex("121310")
	Container.BackgroundTransparency = 1
	Container.Position = UDim2.new(0, 10, 0, 10)
	Container.Size = UDim2.new(0, 300, 0, 300)
end

local SoundName = "SFX"
local ClickSound = Workspace:FindFirstChild(SoundName)
if not ClickSound then
	ClickSound = Instance.new("Sound")
	ClickSound.Name = SoundName
	ClickSound.SoundId = "rbxassetid://6895079853"
	ClickSound.Volume = 1
	ClickSound.Parent = Workspace
end

local Module = {
	Locked = false,
	_nextOrder = 0,
	_ripplePool = {},
}

local DragConnections = {}
local CurrentCorner = UDim.new(1, 0)
local CurrentSize = 45
local Padding = 5
local Columns = 6

local COLORS = {
	Button = Color3.fromHex("21221d"),
	ButtonStroke = Color3.fromHex("34362d"),
	ButtonActive = Color3.fromHex("b9c29d"),
	Text = Color3.fromHex("e6e6e6"),
}

local RIPPLE_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BUTTON_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SHAPE_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local RESET_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function DisconnectConns(conns)
	if not conns then
		return
	end

	for _, conn in pairs(conns) do
		if conn and conn.Disconnect then
			pcall(function()
				conn:Disconnect()
			end)
		end
	end
end

local function GetButtons()
	local buttons = {}

	for _, child in ipairs(Container:GetChildren()) do
		if child:IsA("TextButton") then
			buttons[#buttons + 1] = child
		end
	end

	table.sort(buttons, function(a, b)
		if a.LayoutOrder == b.LayoutOrder then
			return a.Name < b.Name
		end
		return a.LayoutOrder < b.LayoutOrder
	end)

	return buttons
end

local function GetNextPosition(index)
	local row = math.floor(index / Columns)
	local col = index % Columns
	return UDim2.new(0, col * (CurrentSize + Padding), 0, row * (CurrentSize + Padding))
end

local function GetRipple()
	local ripple = table.remove(Module._ripplePool)
	if ripple and ripple.Parent == nil then
		return ripple
	end

	ripple = Instance.new("Frame")
	ripple.Name = "Ripple"
	ripple.BackgroundColor3 = COLORS.ButtonActive
	ripple.BackgroundTransparency = 0.6
	ripple.BorderSizePixel = 0
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
	ripple.Size = UDim2.new(0, 0, 0, 0)
	ripple.ZIndex = 1

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ripple

	ripple.Destroying:Connect(function()
		for i = #Module._ripplePool, 1, -1 do
			if Module._ripplePool[i] == ripple then
				table.remove(Module._ripplePool, i)
				break
			end
		end
	end)

	return ripple
end

local function ReleaseRipple(ripple)
	if not ripple or ripple.Parent == nil then
		return
	end

	ripple.Visible = false
	ripple.BackgroundTransparency = 0.6
	ripple.Size = UDim2.new(0, 0, 0, 0)
	ripple.Parent = nil
	table.insert(Module._ripplePool, ripple)
end

local function CreateRipple(parent)
	local ripple = GetRipple()
	ripple.Parent = parent
	ripple.Visible = true
	ripple.ZIndex = parent.ZIndex + 1
	ripple.BackgroundColor3 = COLORS.ButtonActive
	ripple.BackgroundTransparency = 0.6
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
	ripple.Size = UDim2.new(0, 0, 0, 0)

	TweenService:Create(ripple, RIPPLE_INFO, {
		Size = UDim2.new(1.5, 0, 1.5, 0),
		BackgroundTransparency = 1,
	}):Play()

	task.delay(0.6, function()
		if ripple then
			ReleaseRipple(ripple)
		end
	end)
end

local function MakeDraggable(obj)
	if Module.Locked or DragConnections[obj] then
		return
	end

	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil

	local conns = {}

	conns[#conns + 1] = obj.InputBegan:Connect(function(input)
		if Module.Locked then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
			dragStart = input.Position
			startPos = obj.Position
			obj.ZIndex = 10
		end
	end)

	conns[#conns + 1] = obj.InputEnded:Connect(function(input)
		if input == dragInput then
			dragging = false
			dragInput = nil
			obj.ZIndex = 1
		end
	end)

	conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
		if not dragging or input ~= dragInput or not dragStart or not startPos then
			return
		end

		local delta = input.Position - dragStart
		obj.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end)

	DragConnections[obj] = conns
end

local function CreateButton(text)
	if type(text) ~= "string" then
		return nil
	end

	if Container:FindFirstChild(text) then
		return nil
	end

	local button = Instance.new("TextButton")
	button.Name = text
	button.Parent = Container
	button.BackgroundColor3 = COLORS.Button
	button.BackgroundTransparency = 0.2
	button.AutoButtonColor = false
	button.Font = Enum.Font.Fantasy
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.TextSize = 10
	button.TextWrapped = true
	button.ClipsDescendants = true
	button.Size = UDim2.new(0, CurrentSize, 0, CurrentSize)
	button.LayoutOrder = Module._nextOrder
	button.Position = GetNextPosition(Module._nextOrder)

	Module._nextOrder = Module._nextOrder + 1

	local corner = Instance.new("UICorner")
	corner.CornerRadius = CurrentCorner
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = COLORS.ButtonStroke
	stroke.Thickness = 2
	stroke.Parent = button

	MakeDraggable(button)

	return button, stroke, corner
end

function Module:Kill()
	for obj, conns in pairs(DragConnections) do
		DisconnectConns(conns)
		DragConnections[obj] = nil
	end

	for _, ripple in ipairs(self._ripplePool) do
		if ripple and ripple.Parent == nil then
			ripple:Destroy()
		end
	end
	self._ripplePool = {}

	if UI then
		UI:Destroy()
	end
end

function Module:SetSizeB(scale)
	CurrentSize = 45 * (tonumber(scale) or 1)

	for _, child in ipairs(GetButtons()) do
		child.Size = UDim2.new(0, CurrentSize, 0, CurrentSize)
	end
end

function Module:MakeAllShape(num)
	local rad = (num == 0 and UDim.new(1, 0))
		or (num == 1 and UDim.new(0, 0))
		or (num == 2 and UDim.new(0.25, 0))
		or CurrentCorner

	CurrentCorner = rad

	for _, child in ipairs(GetButtons()) do
		local uiCorner = child:FindFirstChildOfClass("UICorner")
		if uiCorner then
			TweenService:Create(uiCorner, SHAPE_INFO, { CornerRadius = rad }):Play()
		end
	end
end

function Module:ResetPos()
	for i, child in ipairs(GetButtons()) do
		TweenService:Create(child, RESET_INFO, { Position = GetNextPosition(i - 1) }):Play()
	end
end

function Module:DelBindB(text)
	local button = Container:FindFirstChild(text)
	if button then
		local conns = DragConnections[button]
		if conns then
			DisconnectConns(conns)
			DragConnections[button] = nil
		end
		button:Destroy()
	end
end

function Module:BindB(text, func)
	local button = CreateButton(text)
	if not button then
		return
	end

	button.Activated:Connect(function()
		ClickSound:Play()
		CreateRipple(button)

		task.spawn(function()
			pcall(func)
		end)
	end)
end

function Module:AddToggleBB(text, on, off)
	local button = CreateButton(text)
	if not button then
		return
	end

	local state = false
	local stroke = button:FindFirstChildOfClass("UIStroke")

	button.Activated:Connect(function()
		state = not state
		ClickSound.PlaybackSpeed = state and 1 or 0.75
		ClickSound:Play()
		CreateRipple(button)

		TweenService:Create(button, BUTTON_INFO, {
			BackgroundColor3 = state and COLORS.ButtonActive or COLORS.Button,
		}):Play()

		if stroke then
			TweenService:Create(stroke, BUTTON_INFO, {
				Color = state and COLORS.ButtonActive or COLORS.ButtonStroke,
			}):Play()
		end

		task.spawn(function()
			pcall(state and on or off)
		end)
	end)
end

function Module:Lock()
	Module.Locked = true

	for obj, conns in pairs(DragConnections) do
		DisconnectConns(conns)
		DragConnections[obj] = nil
	end
end

function Module:Unlock()
	Module.Locked = false

	for _, child in ipairs(GetButtons()) do
		if not DragConnections[child] then
			MakeDraggable(child)
		end
	end
end

do
	local highest = -1
	for _, child in ipairs(Container:GetChildren()) do
		if child:IsA("TextButton") and child.LayoutOrder > highest then
			highest = child.LayoutOrder
		end
	end
	Module._nextOrder = highest + 1
end

return Module
