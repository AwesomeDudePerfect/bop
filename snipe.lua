local osclock = os.clock()
repeat task.wait(1) until game:IsLoaded()

print("booty works V7")
--// loadstring(game:HttpGet('https://raw.githubusercontent.com/jayzekituze/Utomel/main/MabootySnipe'))()
local MainPrices = {
    HugePrice = 5000000,
    TitanicPetPrice = 10000000,
    ExclusivePetPrice = 100000,
	EggPrice = 100000,
    buyAnything = 2
}

local EnchantsPS99 = {
    ["Chest Mimic"] = 10000000,
    ["Diamond Chest Mimic"] = 10000000,
    ["Boss Chest Mimic"] = 10000000
}

wait(10)
game:GetService("RunService"):Set3dRenderingEnabled(false)
local Booths_Broadcast = game:GetService("ReplicatedStorage").Network:WaitForChild("Booths_Broadcast")
local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local http = game:GetService("HttpService")
local vu = game:GetService("VirtualUser")
local Library = require(game.ReplicatedStorage:WaitForChild('Library'))

Player.Idled:Connect(function()
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)
Player.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
Player.PlayerScripts.Scripts.Core["Server Closing"].Enabled = false

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
                ['name'] = "*USER INFO* :",
                ['value'] = string.format("**User :** ||%s||\n**Remaining gems :** %s", Player.Name, tostring(gemamount)),
            }, {
                ['name'] = "*SNIPER INFO* :",
                ['value'] = string.format("**Price: ** %s", tostring(gems))
            }},
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

local function tryPurchase(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
    local args = {
        [1] = playerid, --sellers roblox id
        [2] = {
            [tostring(uid)] = 1 --id of the item and the amount
        }
    }
    local ping = Player:GetNetworkPing()
    if buytimestamp > listTimestamp then
        task.wait(3.4 - ping)
    end
    local boughtPet, boughtMessage = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_RequestPurchase"):InvokeServer(unpack(args))
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
            local class = tostring(listing["ItemData"]["class"])

            if string.find(item, "Huge") and gems <= 100 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif class == "Pet" then
                local type = Library.Directory.Pets[item]
                if type.exclusiveLevel and gems <= MainPrices.ExclusivePetPrice and item ~= "Banana" and item ~= "Coin" then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                elseif type.titanic and gems <= MainPrices.TitanicPetPrice then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                elseif type.huge and gems <= MainPrices.HugePrice then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                end
            elseif class == "Egg" and gems <= MainPrices.EggPrice then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif class == "Enchant" then
                for i, v in pairs(EnchantsPS99) do
                    if item == i and gems <= v then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                        return
                    end
                end
            end
            if buyAnthing then
                if gems <= 2 then
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
            if type(v) == "table" and v.playing >= 2 and v.id ~= game.JobId then
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

local getPlayers = Players:GetPlayers()
local PlayerInServer = #getPlayers
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
        game.Players.LocalPlayer:Kick("Found An Error, Reconnecting...")
        serverHop(place)
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

local hopDelay = math.random(1000, 1500)

task.spawn(function ()
    while task.wait(1) do
        if math.floor(os.clock() - osclock) >= hopDelay then
            while task.wait(1) do
                serverHop(place)
            end
        end
    end
end)
