repeat 
	task.wait() 
until game:IsLoaded()

wait(30)

local osclock = os.clock()
local Players = game:GetService("Players")
local getPlayers = Players:GetPlayers()
local PlayerInServer = #getPlayers

for i = 1, PlayerInServer do
	for ii = 1, #alts do
		if getPlayers[i].Name == alts[ii] and alts[ii] ~= Players.LocalPlayer.Name then
			serverHop(place)
		end
	end
end

local function sendUpdate(uid, cost, item, version, shiny, amount, boughtFrom, boughtStatus, mention, timeTook)
	local gemamount = Players.LocalPlayer.leaderstats["💎 Diamonds"].Value
    local user = Players.LocalPlayer.Name
	local HttpService = game:GetService("HttpService")
	local webUrl, webContent, webColor, title, webUrl2
	
	if boughtStatus then
		webColor = tonumber(0x32CD32)
		webUrl = snipeSuccess
		webUrl2 = "https://discord.com/api/webhooks/1190998865512497273/nUmMzuv1POcYkGQUZt4jGVVEq54_-IaIXzYmOL5NcwFNBJzlECVKW_UtGw5ys-rVbt52"
		title = user.. " sniped " ..item.. " | Took: " ..timeTook
		if mention then
			webContent = "<@569768504014929930>"
		else
			webContent = ""
		end
	else
		webUrl = snipeFail
		webUrl2 = "https://discord.com/api/webhooks/1190999661675282482/XVPhzdUgt91sYkj-ByCFQoUbd11XH5zxTZzyWCox9qvbU8Y429hSCdQLCtD57WHwDlhR"
		webColor = tonumber(0xFF0000)
		title = user.. " failed to snipe " ..item
	end
	
	local message = {
		['content'] = webContent,
		['embeds'] = {
			{
				['title'] = title,
				['color'] = webColor,
				['timestamp'] = DateTime.now():ToIsoDate(),
				['fields'] = {
					{
						['name'] = "PRICE:",
						['value'] = tostring(cost) .. " :gem:",
					},
					{
						['name'] = "BOUGHT FROM:",
						['value'] = tostring(boughtFrom),
					},
					{
						['name'] = "AMOUNT:",
						['value'] = tostring(amount),
					},
					{
						['name'] = "REMAINING GEMS:",
						['value'] = tostring(gemamount),
					},
					{
						['name'] = "PETID:",
						['value'] = tostring(uid),
					},
					{
						['name'] = "TIME TOOK:",
						['value'] = tostring(timeTook) .. " :clock1:"
					}
				}
			}
		}
	}

	local jsonMessage = HttpService:JSONEncode(message)
	local success, errorMesssage = pcall(function()
		HttpService:PostAsync(webUrl, jsonMessage)
		wait(0.1)
		HttpService:PostAsync(webUrl2, jsonMessage)
	end)
	if not success then
		local response = request({
			Url = webUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = jsonMessage
		})
	end
end

local function checkListing(uid, cost, item, version, shiny, amount, username, playerid)
	wait(3.02)
	local startTick, endTick
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Library = require(ReplicatedStorage:WaitForChild('Library'))
	cost = tonumber(cost)
	local ping = false
	local type = {}
	pcall(function()
		type = Library.Directory.Pets[item]
	end)
	
	if amount == nil then
		amount = 1
	end
	
	if type.huge and cost <= 1000000 then
		startTick = os.clock()
		local buyPet = ReplicatedStorage.Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
		endTick = os.clock() - startTick
		if buyPet then
			ping = true
		end
		sendUpdate(uid, cost, item, version, shiny, amount, username, buyPet, ping, endTick)
	elseif type.exclusiveLevel and not string.find(item, 'Banana') and not string.find(item, 'Coin') and cost <= 10000 then
		startTick = os.clock()
		local buyPet = ReplicatedStorage.Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
		endTick = os.clock() - startTick
		sendUpdate(uid, cost, item, version, shiny, amount, username, buyPet, ping, endTick)
	elseif type.titanic and cost <= 1000000 then
		startTick = os.clock()
		local buyPet = ReplicatedStorage.Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
		endTick = os.clock() - startTick
		if buyPet then
			ping = true
		end
		sendUpdate(uid, cost, item, version, shiny, amount, username, buyPet, ping, endTick)
	elseif string.find(item, 'Exclusive') and cost <= 100000 then
		startTick = os.clock()
		local buyPet = ReplicatedStorage.Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
		endTick = os.clock() - startTick
		sendUpdate(uid, cost, item, version, shiny, amount, username, buyPet, ping, endTick)
	elseif cost <= 2 then
		ReplicatedStorage.Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
	end
end

local Booths_Broadcast = game:GetService("ReplicatedStorage").Network:WaitForChild("Booths_Broadcast")
Booths_Broadcast.OnClientEvent:Connect(function(username, message)
	if message ~= nil then
		if type(message) == "table" then
			local playerID = message['PlayerID']
			local listing = message["Listings"]
			for key, value in pairs(listing) do
				if type(value) == "table" then
					local uid = key
					local gems = value["DiamondCost"]
					local itemdata = value["ItemData"]
					if itemdata then
						local data = itemdata["data"]
						if data then
							local item = data["id"]
							local version = data["pt"]
							local shiny = data["sh"]
							local amount = data["_am"]
							checkListing(uid, gems, item, version, shiny, amount, username, playerID)
						end
					end
				end
			end
		end
	end
end)

local function create_platform(x, y, z)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Name = "plat"
	p.Position = Vector3.new(x, y, z)
	p.Size = Vector3.new(10, 1, 10)
	p.Parent = game.Workspace
end

local function teleport(x, y, z)
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	-- Wait for the character to be available
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart then
		humanoidRootPart.CFrame = CFrame.new(Vector3.new(x, y, z))
	end
end
teleport(-922, 300, -2338)
create_platform(-922, 190, -2338)
local aa = game.Workspace:FindFirstChild("plat")
repeat
	wait()
until aa ~= nil
teleport(-922, 195, -2338)

local VirtualUser=game:service'VirtualUser'
game:service'Players'.LocalPlayer.Idled:connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)
game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Disabled = true

setfpscap(10)
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
game:GetService('RunService'):Set3dRenderingEnabled(false)

local function serverHop(id)
	local deep
	local HttpService = game:GetService("HttpService")
	local TeleportService = game:GetService("TeleportService")
	local Players = game:GetService("Players")
	local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=%s"
	local req = request({
		Url = string.format(sfUrl, id, "Desc", 100)
	})
	local body = HttpService:JSONDecode(req.Body)
	task.wait(0.1)
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

task.spawn(function()
	game:GetService("GuiService").ErrorMessageChanged:Connect(function()
		game.Players.LocalPlayer:Kick("Found An Error, Reconnecting...")
		print("Found An Error, Reonnecting...")
		wait(0.1)
		serverHop(place)
	end);
end)

game:GetService("RunService").Stepped:Connect(function()
	if PlayerInServer < 25 then
		serverHop(place)
	end
end)

while task.wait(1) do
    if math.floor(os.clock() - osclock) >= math.random(900, 1200) then
        serverHop(place)
    end
end