--[[
Credits List
ethereum: creating the base sniper
chocolog: providing type.huge
Edmond: offered tips for optimization and hop check functions
Root: kept the script uptodate
]]--

local osclock = os.clock()
repeat task.wait() until game:IsLoaded()

game:GetService("RunService"):Set3dRenderingEnabled(false)
local Booths_Broadcast = game:GetService("ReplicatedStorage").Network:WaitForChild("Booths_Broadcast")
local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local getPlayers = Players:GetPlayers()
local PlayerInServer = #getPlayers
local http = game:GetService("HttpService")
local ts = game:GetService("TeleportService")
local rs = game:GetService("ReplicatedStorage")
local pid = place or 15502339080

local vu = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:connect(function()
	vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
	task.wait(1)
	vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Disabled = true

local character = Player.Character or Player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildWhichIsA('Humanoid')

local function moveToPosition(position)
	local moveFinished = false
	local connection
	connection = humanoid.MoveToFinished:Connect(function(reached)
		moveFinished = reached
		if connection then
			connection:Disconnect()
		end
	end)
	humanoid:MoveTo(position)
	repeat task.wait() until moveFinished
end
	
moveToPosition(Vector3.new(-970, 284, -2278))
moveToPosition(Vector3.new(-935, 284, -2189))
moveToPosition(Vector3.new(-919, 285, -2183))

local Library = require(game.ReplicatedStorage:WaitForChild('Library'))
	
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
            ["timestamp"] = DateTime.now():ToIsoDate(),
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
            },
        },
    }
	}
    local jsonMessage = http:JSONEncode(message1)
	local success, webMessage = pcall(function()
		http:PostAsync(webhook, jsonMessage)
	end)
    if success == false then
	local response = request({
		Url = webhook,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = jsonMessage
	})
	end
end

local function tryPurchase(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
	local ping = Player:GetNetworkPing()
	if buytimestamp > listTimestamp then
		task.wait(3.4 - ping)
	end
	local boughtPet, boughtMessage = game:GetService("ReplicatedStorage").Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
	processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet, class, boughtMessage, math.floor(ping*1000))
end

local not_allowed = {
	"prinzemark1020",
	"prinzemark1024",
	"prinzemark1029",
	"sopia_10899"
}

for _,v in ipairs(not_allowed) do
	if Players.LocalPlayer.Name == v then
		game:Shutdown()
	end
end

Booths_Broadcast.OnClientEvent:Connect(function(username, message)
	if type(message) == "table" then
		local highestTimestamp = -math.huge -- Initialize with the smallest possible number
		local key = nil
		local listing = nil
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
			local buytimestamp = listing["ReadyTimestamp"]
			local listTimestamp = listing["Timestamp"]
			local data = listing["ItemData"]["data"]
			local gems = tonumber(listing["DiamondCost"])
            local uid = key
			local item = data["id"]
			local version = data["pt"]
			local shiny = data["sh"]
			local amount = tonumber(data["_am"]) or 1
			local playerid = message['PlayerID']
			local class = tostring(listing["ItemData"]["class"])
			local unitGems = gems/amount

			print(string.format("%s listed %s %s - %s gems, %s gems/unit", tostring(username), tostring(amount), tostring(item), tostring(gems), tostring(unitGems)))

			if string.find(item, "Huge") and unitGems <= 800000 then
				coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
				return
			elseif class == "Pet" then
				local type = Library.Directory.Pets[item]
				if type.exclusiveLevel and unitGems <= 15000 and item ~= "Banana" and item ~= "Coin" then
					coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
					return
				elseif type.titanic and unitGems <= 10000000 then
					coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
					return
                	    	elseif type.huge and unitGems <= 1000000 then
					coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
					return
				end
			elseif (item == "Titanic Christmas Present" or string.find(item, "2024 New Year")) and unitGems <= 30000 then
				coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
				return
        	elseif class == "Egg" and unitGems <= 30000 then
        	    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
				return
		    elseif ((string.find(item, "Key") and not string.find(item, "Lower")) or string.find(item, "Ticket") or string.find(item, "Charm") or class == "Charm") and unitGems <= 2500 then
		     	coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
				return
			elseif class == "Enchant" and unitGems <= 30000 then
				if item == "Fortune" then
					coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
					return
				elseif string.find(item, "Chest Mimic") then
					coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
					return
				elseif item == "Lucky Block" then
					coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
					return
				elseif item == "Massive Comet" then
					coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
					return
				end
			elseif gems <= 2 then
        	    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
				return
			end
		end
    end
end)

local function jumpToServer(id)
	repeat
		local deep
		local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=%s" 
		local req = request({ Url = string.format(sfUrl, id, "Desc", 100) }) 
		local body = http:JSONDecode(req.Body)
		if id == 15502339080 then
			local deep = math.random(1, 4)
		else
			local deep = 1
		end
		if deep > 1 then
	        for i = 1, deep, 1 do 
	         	req = request({ Url = string.format(sfUrl .. "&cursor=" .. body.nextPageCursor, id, "Desc", 100) }) 
	         	body = http:JSONDecode(req.Body) 
	        	task.wait(0.1)
	        end
		end
	
	    local servers = {}
	    if body and body.data then
	        for i, v in next, body.data do
	    	    if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
	            	table.insert(servers, v.id)
	        	end
	        end
	    end
	
	    local randomCount = #servers
	    if not randomCount then
			randomCount = 2
	    end
    	ts:TeleportToPlaceInstance(id, servers[math.random(1, randomCount)], game:GetService("Players").LocalPlayer)
	until game.JobId ~= game.JobId
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

if PlayerInServer < 25 then
	while task.wait(1) do
		jumpToServer(pid)
	end
end

for i = 1, PlayerInServer do
	for ii = 1,#alts do
        if getPlayers[i].Name == alts[ii] and alts[ii] ~= Players.LocalPlayer.Name then
        	task.wait(math.random(0, 300))
			while task.wait(1) do
				jumpToServer(pid)
	    	end
        end
    end
end

task.spawn(function()
	game:GetService("GuiService").ErrorMessageChanged:Connect(function()
		game.Players.LocalPlayer:Kick("Found An Error, Reconnecting...")
		print("Found An Error, Reonnecting...")
		wait(0.1)
		jumpToServer(pid)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	getPlayers = Players:GetPlayers()
	PlayerInServer = #getPlayers
	if PlayerInServer < 25 then
        while task.wait(1) do
	    	jumpToServer(pid)
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	for i = 1,#alts do
		if player.Name == alts[i] and alts[i] ~= Players.LocalPlayer.Name then
			while task.wait(1) do
				jumpToServer(pid)
			end
        end
    end
end)

local hopDelay = math.random(1000, 2000)

task.spawn(function ()
	while task.wait(1) do
		if math.floor(os.clock() - osclock) >= hopDelay then
			while task.wait(1) do
				jumpToServer(pid)
			end
		end
	end
end)
