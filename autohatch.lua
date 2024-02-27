getgenv().autoHatch = true

local amountsToHatch = {
    ["TheCoolPokeDiger13"] = 64,
    ["ShwaDevW"] = 19,
    ["ShwaDevY"] = 19,
    ["ShwaDevZ"] = 19,
    ["ShwaDev"] = 19
    -- Add more usernames and corresponding amounts as needed
}

local username = game.Players.LocalPlayer.Name

local AMOUNT_TO_HATCH = 64

if amountsToHatch[username] then
    AMOUNT_TO_HATCH = amountsToHatch[username]
end

--anti afk shit
game.Players.LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
game.Players.LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Disabled = true

local EGG_TO_HATCH = "Tech Ciruit Egg"

local function getEgg()
    local counterEggs = 113
    while true do
        local eggData = require(game:GetService("ReplicatedStorage").Library.Util.EggsUtil).GetByNumber(counterEggs)
        if eggData then
            print(eggData.name)
            print(eggData.eggNumber)
            if eggData.name == EGG_TO_HATCH then
                return eggData
            end
            counterEggs = counterEggs + 1
        else
            break
        end
    end
    return nil
end

local eggData = getEgg()
local eggCFrame
for _, v in pairs(game:GetService("Workspace").__THINGS.Eggs.World2:GetChildren()) do
    if string.find(v.Name, tostring(eggData.eggNumber) .. " - ") then
        eggCFrame = v.Tier.CFrame
    end
end

game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = eggCFrame

-- disable egg animation cause its stupid asf
hookfunction(getsenv(game.Players.LocalPlayer.PlayerScripts.Scripts.Game["Egg Opening Frontend"]).PlayEggAnimation, function()
    return
end)

--low cpu shit
local Lib = require(game.ReplicatedStorage.Library)

function xTab(TABLE)
    for i,v in pairs(TABLE) do
        if type(v) == "function" then
            TABLE[i] = function(...) return end
        end
        if type(v) == "table" then
            xTab(v)
        end
    end
end
xTab(Lib.WorldFX)
xTab(Lib.NotificationCmds.Item)

for i,v in pairs(game:GetDescendants()) do
    if v:IsA("MeshPart") then
        v.MeshId = ""
    end
    if v:IsA("BasePart") or v:IsA("MeshPart") then
        v.Transparency = 1
    end
    if v:IsA("Texture") or v:IsA("Decal") then
        v.Texture = ""
    end
    if v:IsA("ParticleEmitter") then
        v.Lifetime = NumberRange.new(0)
        v.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,0)})
        v.Enabled = false
    end
    if v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("Trail") or v:IsA("Beam") then
        v.Enabled = false
    end
    if v:IsA("Highlight") then
        v.OutlineTransparency = 1
        v.FillTransparency = 1
    end
end

game:GetService("RunService"):Set3dRenderingEnabled(false)

while getgenv().autoHatch do
    game:GetService("ReplicatedStorage").Network.Eggs_RequestPurchase:InvokeServer(EGG_TO_HATCH, AMOUNT_TO_HATCH)
    task.wait()
end
