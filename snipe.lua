repeat task.wait(1) until game:IsLoaded()
local osclock = os.clock()
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local http = game:GetService("HttpService")
local vu = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)
game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Disabled = true

local Library = require(game.ReplicatedStorage:WaitForChild('Library'))
local webhook = "https://discord.com/api/webhooks/1102031995506266162/qoP0abw3x1dRilmnwUeZyC__qJl87J2C8yxD6R_vwicx6FRfQ2Bo9ZZmWkIKaDo0vdNZ"

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
        ['embeds'] = {
            {
                ['title'] = snipeMessage,
                ["color"] = tonumber(colourcheck),
                ["timestamp"] = os.time(),
                ['fields'] = {
                    {
                        ['name'] = "*LISTING INFO* :",
                        ['value'] = string.format("**Price :** %s gems \n**Amount :** %s\n**Seller :** ||%s||\n**Listing ID : ** ||%s||", tostring(gems), tostring(amount or 1), tostring(boughtFrom), tostring(uid)),
                    },
                    {
                        ['name'] = "*USER INFO* :",
                        ['value'] = string.format("**User :** ||%s||\n**Remaining gems :** %s", Player.Name, tostring(gemamount)),
                    },
                    {
                        ['name'] = "*SNIPER INFO* :",
                        ['value'] = string.format("**Status :** %s\n**Ping :** %s ms", failMessage, tostring(ping)),
                    },
                },
                ['footer'] = {
                    ['text'] = "V 3.2 by edmond.yv"
                },
                ['thumbnail'] = {
                    ['url'] = "https://cdn.discordapp.com/attachments/1057080336313495614/1190229689126621235/target_PNG42.png?ex=65a10ac7&is=658e95c7&hm=51fb914c7330c90326660077f6487ce9238a26ad483ad38bbccc41cbc216ad59&"
                }
            }
        }
    }
    local jsonMessage = http:JSONEncode(message1)
    http:PostAsync(webhook, jsonMessage)
end

local function tryPurchase(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
    local ping = Player:GetNetworkPing()
    if buytimestamp > listTimestamp then
        task.wait(3.4 - ping)
    end
    local boughtPet, boughtMessage = game:GetService("ReplicatedStorage").Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
    processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet, class, boughtMessage, math.floor(ping*1000))
end

local function trySnipe(listing)
    local buytimestamp = listing.ReadyTimestamp
    local listTimestamp = listing.Timestamp
    local data = listing.ItemData.data
    local gems = tonumber(listing.DiamondCost)
    local uid = listing.Id
    local item = data.id
    local version = data.pt
    local shiny = data.sh
    local amount = tonumber(data._am) or 1
    local playerid = listing.PlayerID
    local class = tostring(listing.ItemData.class)
    local unitGems = gems/amount

    if string.find(item, "Huge") and unitGems <= 100 then
        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
    elseif class == "Pet" then
        local type = Library.Directory.Pets[item]
        if type.exclusiveLevel and gems <= 25000 and item ~= "Banana" and item ~= "Coin" then
            coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
        elseif type.titanic and unitGems <= 10000000 then
            coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
        elseif type.huge and gems <= 1000000 then
            coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
        end
    elseif gems <= 2 then
        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
    elseif (item == "Titanic Christmas Present" or string.find(item, "2024 New Year")) and unitGems <= 30000 then
        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
    elseif class == "Egg" and gems <= 100000 then
        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
    elseif ((string.find(item, "Key") and not string.find(item, "Lower")) or string.find(item, "Ticket") or string.find(item, "Charm") or class == "Charm") and gems <= 100 then
        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
    elseif class == "Enchant" and unitGems <= 30000 then
        if item == "Fortune" then
            coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
        elseif string.find(item, "Chest Mimic") then
            coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
        elseif item == "Lucky Block" then
            coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
        elseif item == "Massive Comet" then
            coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, listing.Username, class, playerid, buytimestamp, listTimestamp)
        end
    end
end

local function serverHop(id)
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local req = HttpService:JSONDecode(HttpService:GetAsync("https://games.roblox.com/v1/games/" .. id .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"))
    local servers = {}
    for i, v in next, req.data do
        if v.playing >= 35 and v.id ~= game.JobId then
            table.insert(servers, v.id)
        end
    end
    TeleportService:TeleportToPlaceInstance(id, servers[math.random(#servers)], Players.LocalPlayer)
end

local function optimizeGraphics()
    game:GetService("RunService"):Set3dRenderingEnabled(false)
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

    for i, v in pairs(game:GetDescendants()) do
        if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
            v.Material = "Plastic"
            v.Reflectance = 0
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("MeshPart") then
            v.Material = "Plastic"
            v.Reflectance = 0
        end
    end

    for i, e in pairs(lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = false
        end
    end
end

optimizeGraphics()

local place = 15502339080 -- replace with the place id you want to snipe in
local alts = { "ShwaDev", "ShwaDevW", "ShwaDevY", "ShwaDevZ", "historianaverage", "assistancereaction" } -- replace with the names of your alts

local Booths_Broadcast = game:GetService("ReplicatedStorage").Network:WaitForChild("Booths_Broadcast")

Booths_Broadcast.OnClientEvent:Connect(function(username, message)
    if type(message) == "table" then
        local listing = message["Listings"][next(message["Listings"])]
        if listing then
            trySnipe(listing)
        end
    end
end)

local function handlePlayerEvents()
	if PlayerInServer < 25 then
		while task.wait(1) do
			serverHop(place)
		end
	end

	for i = 1, PlayerInServer do
		for ii = 1,#alts do
			if getPlayers[i].Name == alts[ii] and alts[ii] ~= Players.LocalPlayer.Name then
				task.wait(math.random(0, 300))
				while task.wait(1) do
					serverHop(place)
				end
			end
		end
	end

	game:GetService("GuiService").ErrorMessageChanged:Connect(function()
		serverHop(place)
		game.Players.LocalPlayer:Kick("Found An Error, Reconnecting...")
		wait(0.1)
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
end

handlePlayerEvents() -- call the function to handle player events
