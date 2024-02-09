repeat wait() until game:IsLoaded()
wait(10)

print('executed')

local Players = game:GetService("Players")

local magnanakaw = {
    "prinzemark1020",
    "prinzemark1029",
    "prinzemark1021",
    "prinzemark1026",
    "sofia_10899"
}

for _,v in ipairs(magnanakaw) do
    if Players.LocalPlayer.Name == v then
        game:Shutdown()
    end
end

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
	if id == 15502339080 then
		deep = math.random(1, 4)
	else
		deep = 1
	end
	
	if deep > 1 then
		for i = 1, deep, 1 do
			req = request({
				Url = string.format(sfUrl .. "&cursor=" ..body.nextPageCursor, id, "Desc", 100)
			})
			body = HttpService:JSONDecode(req.Body)
			task.wait(0.1)
		end
	end
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

while wait(1) do
	serverHop(15502339080)
end
