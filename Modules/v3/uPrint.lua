-- PAHAHHAHAHAHAHAH

local uPrint = {}

local cg = game:GetService("CoreGui")
local ts = game:GetService("TextService")

function uPrint.log(msg, icon, hasicon, icondir, timeout)
	local id = tostring(math.random(1e6, 9e6))
	icondir = icondir or 0.5
	timeout = timeout or 30
	local done = false
	local conn = nil
	local start = os.clock()

	if hasicon then warn(id) else print(id) end

	local plain = string.gsub(msg, "<[^>]+>", "")
	for ent, ch in pairs({["&amp;"]="&",["&lt;"]="<",["&gt;"]=">",["&quot;"]='"',["&apos;"]="'"}) do
		plain = string.gsub(plain, ent, ch)
	end

	local function run(d)
		if done then return end
		if not d:IsA("TextLabel") then return end
		if not string.find(d.Text, id, 1, true) then return end

		local p = d.Parent
		if not p or not p:IsA("GuiObject") then return end

		done = true

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

		local ancestor = p
		for _ = 1, 3 do
			ancestor = ancestor.Parent
			if not ancestor or not ancestor:IsA("GuiObject") then break end
			ancestor.ClipsDescendants = false
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
				img.AnchorPoint = Vector2.new(img.AnchorPoint.X, icondir)
				img.Position = UDim2.new(img.Position.X.Scale, img.Position.X.Offset, icondir, 0)
			end
		end

		if conn then conn:Disconnect(); conn = nil end
	end

	conn = cg.DescendantAdded:Connect(function(d) task.defer(run, d) end)

	task.spawn(function()
		while not done do
			if os.clock() - start > timeout then
				if conn then conn:Disconnect(); conn = nil end
				break
			end
			task.wait(0.15)
			local m = cg:FindFirstChild("DevConsoleMaster")
			if not m then continue end
			for _, d in m:GetDescendants() do
				if done then break end
				run(d)
			end
		end
	end)
end

return uPrint -- :o
