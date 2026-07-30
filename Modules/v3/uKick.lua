local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local uKick = function(title, message)
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local promptGui = game.CoreGui:FindFirstChild("RobloxPromptGui")
        local overlay = promptGui and promptGui:FindFirstChild("promptOverlay")
        local prompt = overlay and overlay:FindFirstChild("ErrorPrompt")

        if not prompt then return end

        prompt.Active = true
        prompt.Draggable = true
        prompt.BackgroundTransparency = 0.2
        prompt.BackgroundColor3 = Color3.fromHex("0b0b0d")

        if prompt:IsA("ImageLabel") or prompt:IsA("ImageButton") then
            prompt.ImageTransparency = 1
        end

        if not prompt:FindFirstChild("CustomStroke") then
            local stroke = Instance.new("UIStroke")
            stroke.Name = "CustomStroke"
            stroke.Color = Color3.fromHex("262434")
            stroke.Thickness = 1
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = prompt
        else
            prompt.CustomStroke.Thickness = 1.5
        end

        if not prompt:FindFirstChild("CustomCorner") then
            local corner = Instance.new("UICorner")
            corner.Name = "UNX_Corner1"
            corner.CornerRadius = UDim.new(0, 9)
            corner.Parent = prompt
        end

        local msgArea = prompt:FindFirstChild("MessageArea")
        local errorFrame = msgArea and msgArea:FindFirstChild("ErrorFrame")
        local buttonArea = errorFrame and errorFrame:FindFirstChild("ButtonArea")
        local leaveButton = buttonArea and (buttonArea:FindFirstChildOfClass("TextButton") or buttonArea:FindFirstChildOfClass("ImageButton"))

        if leaveButton then
            if leaveButton:IsA("ImageButton") then
                leaveButton.Image = ""
                leaveButton.ImageTransparency = 1
            end
            
            leaveButton.BackgroundColor3 = Color3.new(1, 1, 1)
            leaveButton.BackgroundTransparency = 0
            leaveButton.BorderSizePixel = 0
            leaveButton.AutoButtonColor = false

            local baseColor = Color3.fromHex("0b0b0d")
            local lightColor = Color3.new(
                math.min(baseColor.R + 0.01, 1), 
                math.min(baseColor.G + 0.01, 1), 
                math.min(baseColor.B + 0.01, 1)
            )
            
            local btnGradient = leaveButton:FindFirstChild("ButtonGradient")
            if not btnGradient then
                btnGradient = Instance.new("UIGradient")
                btnGradient.Name = "UNX_Gradient1"
                btnGradient.Parent = leaveButton
            end
            btnGradient.Rotation = 45
            btnGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, baseColor),
                ColorSequenceKeypoint.new(1, lightColor)
            })

            local btnText = leaveButton:FindFirstChildOfClass("TextLabel") or leaveButton
            if btnText then
                btnText.Text = "Quit Game"
                btnText.Font = Enum.Font.SourceSansLight
                btnText.TextColor3 = Color3.fromHex("e8e6f2")
            end

            local btnStroke = leaveButton:FindFirstChild("ButtonOutline")
            if not btnStroke then
                btnStroke = Instance.new("UIStroke")
                btnStroke.Name = "ButtonOutline"
                btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                btnStroke.Parent = leaveButton
            end
            btnStroke.Color = Color3.new(1, 1, 1)
            btnStroke.Thickness = 1

            local strokeGradient = btnStroke:FindFirstChild("StrokeGradient")
            if not strokeGradient then
                strokeGradient = Instance.new("UIGradient")
                strokeGradient.Name = "UNX_Gradient2"
                strokeGradient.Parent = btnStroke
            end
            strokeGradient.Rotation = 45
            
            local sStart = Color3.new(baseColor.R * 0.9, baseColor.G * 0.9, baseColor.B * 0.9)
            local sEnd = Color3.new(lightColor.R * 0.9, lightColor.G * 0.9, lightColor.B * 0.9)
            strokeGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, sStart),
                ColorSequenceKeypoint.new(1, sEnd)
            })

            local btnCorner = leaveButton:FindFirstChild("ButtonCorner")
            if not btnCorner then
                btnCorner = Instance.new("UICorner")
                btnCorner.Name = "UNX_Corner2"
                btnCorner.CornerRadius = UDim.new(0, 9)
                btnCorner.Parent = leaveButton
            end
        end

        local titleLabel = prompt:FindFirstChild("TitleFrame") and prompt.TitleFrame:FindFirstChild("ErrorTitle")
        local msgFrame = errorFrame and errorFrame:FindFirstChild("ErrorMessage")
        local splitLine = prompt:FindFirstChild("SplitLine")

        if splitLine then
            splitLine.BackgroundColor3 = Color3.fromHex("262434")
            splitLine.BorderSizePixel = 0
        end

        if titleLabel then
            titleLabel.Font = Enum.Font.SourceSansLight
            titleLabel.Text = title
            titleLabel.TextColor3 = Color3.fromHex("e8e6f2")
        end

        if msgFrame then
            msgFrame.Font = Enum.Font.SourceSansLight
            msgFrame.RichText = true
            msgFrame.Text = message
            msgFrame.TextScaled = true
            msgFrame.TextColor3 = Color3.fromHex("e8e6f2")
        end
    end)

    LocalPlayer:Kick("Oops!, Something Went Wrong!, Press 'F9' For More Details And Report This To The Developer!")
end

return { uKick = uKick }
