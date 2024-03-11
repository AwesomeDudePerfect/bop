local osclock = os.clock()
repeat task.wait(1) until game:IsLoaded()

wait(15)
local MainPrices = {
    HugePrice = 10000000,
    TitanicPetPrice = 10000000,
    ExclusivePetPrice = 100000,
	EggPrice = 100000,
    buyAnything = 2
}

local EnchantsPS99 = {
    ["Lucky Block"] = 1000000,
    ["Huge Hunter"] = 1000000,
    ["Boss Chest Mimic"] = 10000000,
    ["Chest Mimic"] = 10000000
}

wait(10)
game:GetService("RunService"):Set3dRenderingEnabled(false)

--// Variable Region
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService('Players')
local http = game:GetService("HttpService")
local vu = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local getPlayers = Players:GetPlayers()
local PlayerInServer = #getPlayers

local Booths_Broadcast = ReplicatedStorage.Network:WaitForChild("Booths_Broadcast")
local Library = require(game.ReplicatedStorage:WaitForChild('Library'))

--// Server Check
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

if PlayerInServer < 25 then
    while task.wait(1) do
        serverHop(place)
    end
end

for i = 1, PlayerInServer do
    for _, alts in pairs(alt) do
        if getPlayers[i].Name == alts and alts ~= Player.Name then
            task.wait(math.random(0, 300))
            while task.wait(1) do
                serverHop(place)
            end
        end
    end
end

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
            }}
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
            [tostring(uid)] = amount --id of the item and the amount
        }
    }
    local ping = Player:GetNetworkPing()
    if buytimestamp > listTimestamp then
        task.wait(3.4 - ping)
    end
    local boughtPet, boughtMessage = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Booths_RequestPurchase"):InvokeServer(unpack(args))
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
            elseif ((string.find(item, "Key") and not string.find(item, "Lower")) or string.find(item, "Ticket") or string.find(item, "Charm") or class == "Charm") and gems <= 200 then
		if amount >= 10 then
		    amount = 10
		end
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif class == "Enchant" then
                for i, v in pairs(EnchantsPS99) do
                    if item == i and gems <= v then
			amount = 1
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                        return
                    end
                end
            end
        end
    end
end)

--//Anti-AFK
local virtualuser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    virtualuser:CaptureController()
    virtualuser:ClickButton2(Vector2.new())
end)
game.Players.LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
game.Players.LocalPlayer.PlayerScripts.Scripts.Core["Server Closing"].Enabled = false
ChatProperties = {
    Color = Color3.fromRGB(0,255,255); 
    Font = Enum.Font.SourceSansBold;
    TextSize = 18;
}
local StarterGui = game:GetService("StarterGui")
game:GetService("Players").LocalPlayer.Idled:connect(
    function()
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame);
        wait(0.5);
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame);
    end
);
local function chat(msg)
    ChatProperties.Text = msg
    StarterGui:SetCore("ChatMakeSystemMessage", ChatProperties)
end
chat("Anti Afk Enabled")

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

local hopDelay = 1140

task.spawn(function ()
    while task.wait(1) do
        if math.floor(os.clock() - osclock) >= hopDelay then
            while task.wait(1) do
                serverHop(place)
            end
        end
    end
end)
