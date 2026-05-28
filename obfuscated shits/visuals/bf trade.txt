local CorrectPlaceId = 4442272183

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

-- Auto travel to Sea 2 if wrong place
if game.PlaceId ~= CorrectPlaceId then
    print("[RAYZ HUB] Not in Sea 2 → Traveling to Dressrosa (Sea 2)...")
    
    local args = {
        "TravelDressrosa"
    }
    local success, err = pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
    end)
    
    if not success then
        warn("[RAYZ HUB] Travel failed: " .. tostring(err))
    end
    
    -- Wait a bit and stop execution (let the teleport happen)
    task.wait(6)
    return
end

print("[RAYZ HUB] Loaded successfully in Sea 2")

-- Chair mappings
local chairMappings = {
    ["-298_72_271"] = Vector3.new(-298, 73, 282),
    ["-298_72_282"] = Vector3.new(-298, 73, 271),
    ["-298_73_271"] = Vector3.new(-298, 73, 282),
    ["-298_73_282"] = Vector3.new(-298, 73, 271),
    ["-463_72_271"] = Vector3.new(-463, 73, 282),
    ["-463_72_282"] = Vector3.new(-463, 73, 271),
    ["-463_73_271"] = Vector3.new(-463, 73, 282),
    ["-463_73_282"] = Vector3.new(-463, 73, 271),
}

local function getPositionKey(position)
    return string.format("%d_%d_%d",
        math.floor(position.X + 0.5),
        math.floor(position.Y + 0.5),
        math.floor(position.Z + 0.5)
    )
end

local function findSeatAtPosition(pos)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Seat") and (obj.Position - pos).Magnitude < 3 then
            return obj
        end
    end
    return nil
end

local function getPlayerFromCharacter(char)
    return Players:GetPlayerFromCharacter(char)
end

-- Custom Notification (purple style)
local notificationGui = Instance.new("ScreenGui")
notificationGui.Name = "RayzNotifications"
notificationGui.ResetOnSpawn = false
notificationGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function createCustomNotification(title, text)
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0.32, 0, 0.11, 0)
    notifFrame.Position = UDim2.new(1.1, 0, 0.88, 0)
    notifFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = notificationGui

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 10)
    uicorner.Parent = notifFrame

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 40, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 20, 60))
    }
    gradient.Rotation = 45
    gradient.Parent = notifFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0.38, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 19
    titleLabel.TextColor3 = Color3.fromRGB(220, 180, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notifFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 0.5, -10)
    textLabel.Position = UDim2.new(0, 10, 0.38, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 15
    textLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
    textLabel.TextWrapped = true
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = notifFrame

    TweenService:Create(notifFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.68, 0, 0.88, 0),
        BackgroundTransparency = 0
    }):Play()

    task.delay(5.5, function()
        TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
            Position = UDim2.new(1.1, 0, 0.88, 0),
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(titleLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        task.delay(0.5, function()
            notifFrame:Destroy()
        end)
    end)
end

-- Sound
local openSound = Instance.new("Sound")
openSound.SoundId = "rbxassetid://1837849284"
openSound.Volume = 0.6
openSound.Parent = SoundService
openSound:Play()

-- Main GUI - RAYZ HUB
local gui = Instance.new("ScreenGui")
gui.Name = "RayzHubGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 420)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 15, 45)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 30, 110)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 20, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 10, 50))
}
mainGradient.Rotation = 90
mainGradient.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(180, 120, 255)
uiStroke.Thickness = 2
uiStroke.Transparency = 0.4
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiStroke.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 25, 90)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 60, 180)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 120))
}
titleGradient.Parent = titleBar

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.75, 0, 1, 0)
titleText.Position = UDim2.new(0.04, 0, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "RAYZ HUB"
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 24
titleText.TextColor3 = Color3.fromRGB(220, 180, 255)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -42, 0.5, -18)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 80)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(220, 60, 100)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(180, 40, 80)}):Play()
end)

-- Status
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(0.9, 0, 0.18, 0)
statusText.Position = UDim2.new(0.05, 0, 0.14, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "Waiting to sit on a chair..."
statusText.Font = Enum.Font.GothamSemibold
statusText.TextSize = 19
statusText.TextColor3 = Color3.fromRGB(200, 160, 255)
statusText.TextWrapped = true
statusText.Parent = mainFrame

-- Avatar
local avatarHolder = Instance.new("Frame")
avatarHolder.Size = UDim2.new(0, 110, 0, 110)
avatarHolder.Position = UDim2.new(0.5, -55, 0.32, 0)
avatarHolder.BackgroundTransparency = 1
avatarHolder.Parent = mainFrame

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(1, 0, 1, 0)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = ""
avatarImage.Visible = false
avatarImage.Parent = avatarHolder

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatarImage

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(200, 140, 255)
avatarStroke.Thickness = 2.5
avatarStroke.Transparency = 0.3
avatarStroke.Parent = avatarImage

-- Buttons frame
local buttonsFrame = Instance.new("Frame")
buttonsFrame.Size = UDim2.new(0.88, 0, 0.18, 0)
buttonsFrame.Position = UDim2.new(0.06, 0, 0.74, 0)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.Parent = mainFrame

-- Draggable (already implemented)
local dragging, dragStart, startPos = false, nil, nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -170, 1.5, 0),
        Transparency = 1
    }):Play()
    task.delay(0.4, function()
        gui:Destroy()
    end)
end)

-- Open animation
mainFrame.Position = UDim2.new(0.5, -170, 1.5, 0)
mainFrame.Transparency = 1
mainFrame.Visible = true

TweenService:Create(mainFrame, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -170, 0.5, -210),
    Transparency = 0
}):Play()

-- Player detection logic (same as before)
local oppositePlayer = nil
local seatedConnection, oppositeCheckConnection

local function updateGUI(player)
    oppositePlayer = player
    statusText.Text = "Opposite: " .. player.DisplayName .. " (@" .. player.Name .. ")"

    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size150x150
    local content, isReady = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
    if isReady then
        avatarImage.Image = content
        avatarImage.Visible = true
        avatarImage.ImageTransparency = 1
        TweenService:Create(avatarImage, TweenInfo.new(0.7, Enum.EasingStyle.Back), {ImageTransparency = 0}):Play()
        TweenService:Create(avatarHolder, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Size = UDim2.new(0, 118, 0, 118)
        }):Play()
    end

    -- Freeze Button
    local freezeBtn = Instance.new("TextButton")
    freezeBtn.Size = UDim2.new(0.48, 0, 1, 0)
    freezeBtn.BackgroundColor3 = Color3.fromRGB(90, 50, 160)
    freezeBtn.Text = "Freeze"
    freezeBtn.Font = Enum.Font.GothamBold
    freezeBtn.TextSize = 19
    freezeBtn.TextColor3 = Color3.fromRGB(230, 210, 255)
    freezeBtn.Parent = buttonsFrame

    local fbCorner = Instance.new("UICorner")
    fbCorner.CornerRadius = UDim.new(0, 10)
    fbCorner.Parent = freezeBtn

    local fbGradient = Instance.new("UIGradient")
    fbGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 90, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 50, 160))
    }
    fbGradient.Parent = freezeBtn

    freezeBtn.MouseButton1Click:Connect(function()
        createCustomNotification("RAYZ HUB", "Freezing target...")
    end)

    -- Accept Button
    local acceptBtn = Instance.new("TextButton")
    acceptBtn.Size = UDim2.new(0.48, 0, 1, 0)
    acceptBtn.Position = UDim2.new(0.52, 0, 0, 0)
    acceptBtn.BackgroundColor3 = Color3.fromRGB(70, 140, 100)
    acceptBtn.Text = "Accept"
    acceptBtn.Font = Enum.Font.GothamBold
    acceptBtn.TextSize = 19
    acceptBtn.TextColor3 = Color3.fromRGB(220, 255, 220)
    acceptBtn.Parent = buttonsFrame

    local abCorner = Instance.new("UICorner")
    abCorner.CornerRadius = UDim.new(0, 10)
    abCorner.Parent = acceptBtn

    local abGradient = Instance.new("UIGradient")
    abGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 200, 140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 140, 100))
    }
    abGradient.Parent = acceptBtn

    acceptBtn.MouseButton1Click:Connect(function()
        createCustomNotification("RAYZ HUB", "Accepting target...")
    end)
end

local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

seatedConnection = hum.Seated:Connect(function(isSeated, seat)
    if isSeated then
        statusText.Text = "Waiting for someone to sit opposite..."
        if oppositeCheckConnection then oppositeCheckConnection:Disconnect() end

        oppositeCheckConnection = RunService.Heartbeat:Connect(function()
            if not hum.Sit then
                oppositeCheckConnection:Disconnect()
                return
            end
            local key = getPositionKey(seat.Position)
            local oppPos = chairMappings[key]
            if oppPos then
                local oppSeat = findSeatAtPosition(oppPos)
                if oppSeat and oppSeat.Occupant then
                    local oppChar = oppSeat.Occupant.Parent
                    local oppPlr = getPlayerFromCharacter(oppChar)
                    if oppPlr and oppPlr ~= LocalPlayer then
                        updateGUI(oppPlr)
                        oppositeCheckConnection:Disconnect()
                    end
                end
            end
        end)
    else
        statusText.Text = "Waiting to sit on a chair..."
        if oppositeCheckConnection then oppositeCheckConnection:Disconnect() end
        avatarImage.Visible = false
        avatarImage.ImageTransparency = 1
        for _, child in ipairs(buttonsFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        oppositePlayer = nil
    end
end)

createCustomNotification("RAYZ HUB", "Loaded successfully!")