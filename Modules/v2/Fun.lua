-- for fun stuff

if isfile("unxignorefun1.unx") then
    if readfile("unxignorefun1.unx") == "True" then
        return
    end
end

local job_id = "6cc0966b-2bc3-431d-b381-f5513e0a78e4"

local a = game:GetService("Players")
local b = game:GetService("CoreGui")
local c = game:GetService("TweenService")
local d = game:GetService("RunService")
local e = game:GetService("TeleportService")
local f = a.LocalPlayer

local g = {
    Bg = Color3.fromRGB(26,26,26),
    BgL = Color3.fromRGB(35,35,35),
    BgD = Color3.fromRGB(20,20,20),
    Txt = Color3.fromRGB(255,255,255),
    TxtD = Color3.fromRGB(180,180,180),
    Bdr = Color3.fromRGB(50,50,50),
    Red = Color3.fromRGB(255,95,87),
    Yel = Color3.fromRGB(255,189,46),
    Grn = Color3.fromRGB(40,201,64),
    Azr = Color3.fromRGB(0, 127, 255),
    Err = Color3.fromRGB(255, 80, 80)
}

local h = Instance.new("ScreenGui")
h.Name = "UNXInviteWindow"
h.ResetOnSpawn = false
h.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if d:IsStudio() then
    h.Parent = f:WaitForChild("PlayerGui")
else
    h.Parent = b
end

local i = Instance.new("Frame")
i.Size = UDim2.new(0, 400, 0, 240)
i.Position = UDim2.new(0.5, -200, 0.5, -120)
i.BackgroundColor3 = g.Bg
i.Active = true
i.Draggable = true
i.BorderSizePixel = 0
i.ClipsDescendants = true
i.ZIndex = 2
i.Parent = h

local j = Instance.new("UICorner", i)
j.CornerRadius = UDim.new(0, 12)

local k = Instance.new("UIStroke", i)
k.Color = g.Bdr
k.Thickness = 1
k.Transparency = 0.3
k.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local l = Instance.new("Frame")
l.Size = UDim2.new(1, 0, 0, 40)
l.BackgroundColor3 = g.BgL
l.BorderSizePixel = 0
l.ZIndex = 3
l.Parent = i

local m = Instance.new("UICorner", l)
m.CornerRadius = UDim.new(0, 12)

local n = Instance.new("Frame")
n.Size = UDim2.new(1, 0, 0, 12)
n.Position = UDim2.new(0, 0, 1, -12)
n.BackgroundColor3 = g.BgL
n.BorderSizePixel = 0
n.ZIndex = 3
n.Parent = l

local o = Instance.new("Frame")
o.Size = UDim2.new(1, 0, 0, 1)
o.Position = UDim2.new(0, 0, 1, 0)
o.BackgroundColor3 = g.Bdr
o.BorderSizePixel = 0
o.ZIndex = 4
o.Parent = l

local p = Instance.new("Frame")
p.Size = UDim2.new(0, 60, 0, 14)
p.Position = UDim2.new(0, 12, 0.5, 0)
p.AnchorPoint = Vector2.new(0, 0.5)
p.BackgroundTransparency = 1
p.ZIndex = 4
p.Parent = l

local q = Instance.new("UIListLayout")
q.FillDirection = Enum.FillDirection.Horizontal
q.HorizontalAlignment = Enum.HorizontalAlignment.Left
q.VerticalAlignment = Enum.VerticalAlignment.Center
q.Padding = UDim.new(0, 6)
q.SortOrder = Enum.SortOrder.LayoutOrder
q.Parent = p

local function r(s, t)
    local u = Instance.new("TextButton")
    u.Name = t
    u.Size = UDim2.new(0, 12, 0, 12)
    u.BackgroundColor3 = s
    u.BorderSizePixel = 0
    u.Text = ""
    u.AutoButtonColor = false
    u.ZIndex = 5
    u.Parent = p
    local v = Instance.new("UICorner")
    v.CornerRadius = UDim.new(1, 0)
    v.Parent = u
    
    u.MouseEnter:Connect(function()
        c:Create(u, TweenInfo.new(0.1), {Size = UDim2.new(0, 13, 0, 13)}):Play()
    end)
    u.MouseLeave:Connect(function()
        c:Create(u, TweenInfo.new(0.1), {Size = UDim2.new(0, 12, 0, 12)}):Play()
    end)
    return u
end

local w = r(g.Red, "Close")
local x = r(g.Yel, "Min")
local y = r(g.Grn, "Max")

local z = Instance.new("TextLabel")
z.Size = UDim2.new(0, 200, 1, 0)
z.Position = UDim2.new(0.5, 0, 0, 0)
z.AnchorPoint = Vector2.new(0.5, 0)
z.BackgroundTransparency = 1
z.Text = "Server Invite"
z.TextColor3 = g.Txt
z.Font = Enum.Font.Gotham
z.TextSize = 14
z.ZIndex = 4
z.Parent = l

local A = Instance.new("Frame")
A.Name = "Content"
A.Parent = i
A.Size = UDim2.new(1, -24, 1, -62)
A.Position = UDim2.new(0, 12, 0, 50)
A.BackgroundColor3 = g.BgD
A.BorderSizePixel = 0
A.ZIndex = 3

local B = Instance.new("UICorner", A)
B.CornerRadius = UDim.new(0, 8)

local C = Instance.new("UIStroke", A)
C.Color = g.Bdr
C.Thickness = 1
C.Transparency = 0.5
C.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local D = Instance.new("TextLabel")
D.Parent = A
D.Size = UDim2.new(1, -20, 0, 25)
D.Position = UDim2.new(0, 10, 0, 15)
D.BackgroundTransparency = 1
D.Text = "You have been invited to join a server"
D.Font = Enum.Font.GothamBold
D.TextColor3 = g.Txt
D.TextSize = 18
D.TextWrapped = true
D.TextXAlignment = Enum.TextXAlignment.Center
D.ZIndex = 4

local E = Instance.new("TextLabel")
E.Parent = A
E.Size = UDim2.new(1, -20, 0, 60)
E.Position = UDim2.new(0, 10, 0, 45)
E.BackgroundTransparency = 1
E.Text = 'Clicking "Yes" will teleport you to the server, click "No" will close this window and never ask again, your executor may block the Teleport.'
E.Font = Enum.Font.Gotham
E.TextColor3 = g.TxtD
E.TextSize = 12
E.TextWrapped = true
E.TextXAlignment = Enum.TextXAlignment.Center
E.TextYAlignment = Enum.TextYAlignment.Top
E.ZIndex = 4

local F = Instance.new("Frame")
F.Parent = A
F.Size = UDim2.new(1, -40, 0, 30)
F.Position = UDim2.new(0, 20, 0, 105)
F.BackgroundTransparency = 1
F.ZIndex = 4

local G = Instance.new("UIListLayout")
G.Parent = F
G.FillDirection = Enum.FillDirection.Horizontal
G.HorizontalAlignment = Enum.HorizontalAlignment.Center
G.Padding = UDim.new(0, 15)

local function H(I)
    local J = Instance.new("TextButton")
    J.Parent = F
    J.Size = UDim2.new(0.45, 0, 1, 0)
    J.BackgroundColor3 = g.BgL
    J.Text = I
    J.Font = Enum.Font.GothamBold
    J.TextColor3 = g.Txt
    J.TextSize = 14
    J.AutoButtonColor = true
    J.ZIndex = 5
    
    local K = Instance.new("UICorner")
    K.CornerRadius = UDim.new(0, 6)
    K.Parent = J
    
    local L = Instance.new("UIStroke")
    L.Parent = J
    L.Color = g.Bdr
    L.Thickness = 1
    L.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    return J
end

local M = H("Yes")
local N = H("No")

local O = Instance.new("Frame")
O.Parent = A
O.Size = UDim2.new(1, -40, 0, 4)
O.Position = UDim2.new(0, 20, 0, 145)
O.BackgroundColor3 = g.BgL
O.BorderSizePixel = 0
O.Visible = false
O.ZIndex = 4

local P = Instance.new("UICorner")
P.CornerRadius = UDim.new(1, 0)
P.Parent = O

local Q = Instance.new("Frame")
Q.Parent = O
Q.Size = UDim2.new(0, 0, 1, 0)
Q.BackgroundColor3 = g.Azr
Q.BorderSizePixel = 0
Q.ZIndex = 5

local R = Instance.new("UICorner")
R.CornerRadius = UDim.new(1, 0)
R.Parent = Q

local function S()
    local T = c:Create(i, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
    T:Play()
    T.Completed:Wait()
    h:Destroy()
end

w.MouseButton1Click:Connect(S)

local U = false

x.MouseButton1Click:Connect(function()
    if not U then
        A.Visible = false
        c:Create(i, TweenInfo.new(0.3), {Size = UDim2.new(0, 400, 0, 40)}):Play()
        U = true
    end
end)

y.MouseButton1Click:Connect(function()
    if U then
        local V = c:Create(i, TweenInfo.new(0.3), {Size = UDim2.new(0, 400, 0, 240)})
        V:Play()
        V.Completed:Wait()
        A.Visible = true
        U = false
    else
        local V = c:Create(i, TweenInfo.new(0.1), {Size = UDim2.new(0, 410, 0, 250)})
        V:Play()
        V.Completed:Wait()
        c:Create(i, TweenInfo.new(0.1), {Size = UDim2.new(0, 400, 0, 240)}):Play()
    end
end)

N.MouseButton1Click:Connect(function()
    writefile("unxignorefun1.unx", "True")
    S()
end)

M.MouseButton1Click:Connect(function()
    M.Active = false
    N.Active = false
    O.Visible = true
    
    local W = c:Create(Q, TweenInfo.new(10, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
    W:Play()
    
    e:TeleportToPlaceInstance(game.PlaceId, job_id, f)
    
    task.delay(10, function()
        W:Cancel()
        Q.Size = UDim2.new(1, 0, 1, 0)
        Q.BackgroundColor3 = g.Err
        E.Text = E.Text .. "\nStatus: Failed To Teleport"
        task.wait(5)
        S()
    end)
end)
