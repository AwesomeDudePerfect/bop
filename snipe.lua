local osclock = os.clock()
repeat task.wait(1) until game:IsLoaded()

game:GetService("RunService"):Set3dRenderingEnabled(false)
local Booths_Broadcast = game:GetService("ReplicatedStorage").Network:WaitForChild("Booths_Broadcast")
local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local getPlayers = Players:GetPlayers()
local PlayerInServer = #getPlayers
local http = game:GetService("HttpService")
local vu = game:GetService("VirtualUser")
local Library = require(game.ReplicatedStorage:WaitForChild('Library'))

Players.LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
game.Players.LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Disabled = true

local function processListingInfo(uid, gems, item, version, shiny, amount, boughtFrom, boughtPet, class, boughtMessage, ping)
    local gemamount = Player.leaderstats["💎 Diamonds"] and Player.leaderstats["💎 Diamonds"].Value or 0
    local versionVal = { [2] = "Rainbow", [1] = "Golden" }
    local versionStr = versionVal[version] or (version == nil and "Normal" or "")
    local snipeMessage = string.format("Found a %s%s%s!", versionStr, shiny and " Shiny " or " ", item)
    local tag = string.find(item, "Huge") and "@everyone" or ""
    local colourcheck = boughtPet and 0x05ff00 or 0xff000f
    local failMessage = boughtPet and "Sniped! No errors occured!" or tostring(boughtMessage)

    local message1 = {
        ['content'] = tag,
        ['embeds'] = {{
            ['title'] = snipeMessage,
            ["color"] = tonumber(colourcheck),
            ["timestamp"] = DateTime.now():ToIsoDate(),
            ['fields'] = {{
                ['name'] = "*LISTING INFO* :",
                ['value'] = string.format("**Price :** %s gems \n**Amount :** %s\n**Seller :** ||%s||\n**Listing ID : ** ||%s||", tostring(gems), tostring(amount or 1), tostring(boughtFrom), tostring(uid)),
            }, {
                ['name'] = "*USER INFO* :",
                ['value'] = string.format("**User :** ||%s||\n**Remaining gems :** %s", Player.Name, tostring(gemamount)),
            }, {
                ['name'] = "*SNIPER INFO* :",
                ['value'] = string.format("**Status :** %s\n**Ping :** %s ms", failMessage, tostring(ping)),
            }},
            ['footer'] = {
                ['text'] = "V 3.2 by edmond.yv"
            },
            ['thumbnail'] = {
                ['url'] = "https://cdn.discordapp.com/attachments/1057080336313495614/1190229689126621235/target_PNG42.png?ex=65a10ac7&is=658e95c7&hm=51fb914c7330c90326660077f6487ce9238a26ad483ad38bbccc41cbc216ad59&"
            },
        }},
    }

    local jsonMessage = http:JSONEncode(message1)
    local success, webMessage = pcall(function()
        http:PostAsync(webhook, jsonMessage)
    end)
    if not success then
        local response = request({
            Url = webhook,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonMessage
        })
    end
end

local function tryPurchase(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
    if buytimestamp > listTimestamp then
        task.wait(3.4 - ping)
    end
    local boughtPet, boughtMessage = game:GetService("ReplicatedStorage").Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
    processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet, class, boughtMessage, math.floor(ping*1000))
end

Booths_Broadcast.OnClientEvent:Connect(function(username, message)
    if type(message) == "table" then
        local highestTimestamp = -math.huge
        local key, listing
        for v, value in pairs(message["Listings"] or {}) do
            if type(value) == "table" and value["ItemData"] and value["ItemData"]["data"] then
                local timestamp = value["Timestamp"]
                if timestamp > highestTimestamp then
                    highestTimestamp = timestamp
                    key = v
                    listing = value
                end
            end
        end
        if listing then
            local buytimestamp, listTimestamp = listing["ReadyTimestamp"], listing["Timestamp"]
            local data, playerid = listing["ItemData"]["data"], message['PlayerID']
            local gems, uid = tonumber(listing["DiamondCost"]), key
            local item, version, shiny = data["id"], data["pt"], data["sh"]
            local amount = tonumber(data["_am"]) or 1
            local class, unitGems = tostring(listing["ItemData"]["class"]), gems / amount

            if string.find(item, "Huge") and unitGems <= 100 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif class == "Pet" then
                local type = Library.Directory.Pets[item]
                if type.exclusiveLevel and gems <= 25000 and item ~= "Banana" and item ~= "Coin" then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                elseif type.titanic and unitGems <= 10000000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                elseif type.huge and gems <= 1000000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                end
            elseif gems <= 2 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif (item == "Titanic Christmas Present" or string.find(item, "2024 New Year")) and unitGems <= 30000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif class == "Egg" and gems <= 100000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif ((string.find(item, "Key") and not string.find(item, "Lower")) or string.find(item, "Ticket") or string.find(item, "Charm") or class == "Charm") and gems <= 100 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif class == "Enchant" and unitGems <= 30000 then
                if item == "Fortune" or string.find(item, "Chest Mimic") or item == "Lucky Block" or item == "Massive Comet" then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                end
            end
        end
    end
end)

local function serverHop(id)
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=%s&excludeFullGames=true"
    local req = request({
        Url = string.format(sfUrl, id, "Desc", 100)
    })
    local body = HttpService:JSONDecode(req.Body)
    task.wait(0.2)
    local servers = {}
    if body and body.data then
        for i, v in next, body.data do
            if type(v) == "table" and v.playing >= 35 and v.id ~= game.JobId then
                table.insert(servers, 1, v.id)
            end
        end
    end
    local randomCount = #servers
    if not randomCount then
        randomCount = 2
    end
    TeleportService:TeleportToPlaceInstance(id, servers[math.random(1, randomCount)], Players.LocalPlayer)
end

local lighting = game.Lighting
local terrain = game.Workspace.Terrain
terrain.WaterWaveSize = 0
terrain.WaterWaveSpeed = 0
terrain.WaterReflectance = 0
terrain.WaterTransparency = 0
lighting.GlobalShadows = false
lighting.FogStart = 0
lighting.FogEnd = 0
lighting.Brightness = 0

for _, v in pairs(game:GetDescendants()) do
    if v:IsA("BasePart") or v:IsA("MeshPart") then
        v.Material = "Plastic"
        v.Reflectance = 0
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
        v.Lifetime = NumberRange.new(0)
    elseif v:IsA("Explosion") then
        v.BlastPressure = 1
        v.BlastRadius = 1
    elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
        v.Enabled = false
    end
end

for _, e in pairs(lighting:GetChildren()) do
    if e:IsA("PostEffect") then
        e.Enabled = false
    end
end

if PlayerInServer < 25 then
    while task.wait(1) do
        serverHop(place)
    end
end

for i = 1, PlayerInServer do
    for _, alt in pairs(alts) do
        if getPlayers[i].Name == alt and alt ~= Players.LocalPlayer.Name then
            task.wait(math.random(0, 300))
            while task.wait(1) do
                serverHop(place)
            end
        end
    end
end

task.spawn(function()
    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        serverHop(place)
        game.Players.LocalPlayer:Kick("Found An Error, Reconnecting...")
        wait(0.1)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    getPlayers = Players:GetPlayers()
    PlayerInServer = #getPlayers
    if PlayerInServer < 25 then
        while task.wait(1) do
            serverHop(place)
        end
    end
end)

local hopDelay = math.random(1500, 1800)

task.spawn(function ()
    while task.wait(1) do
        if math.floor(os.clock() - osclock) >= hopDelay then
            while task.wait(1) do
                serverHop(place)
            end
        end
    end
end)
