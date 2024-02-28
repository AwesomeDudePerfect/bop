repeat
    wait(1)
until game:IsLoaded()

EggNumber = 113;

local ReplicatedStorage = game:GetService("ReplicatedStorage") :: ReplicatedStorage & {Library: ModuleScript; Network: ModuleScript & {Eggs_RequestPurchase: RemoteFunction}}
local Workspace = game:GetService("Workspace") :: Workspace & {__THINGS: Folder & {Eggs: Folder}}
local Things = Workspace.__THINGS
local Players = game:GetService("Players")
local Player = Players.LocalPlayer :: Player & {PlayerScripts: Folder & {Scripts: Folder & {Game: Folder & {["Egg Opening Frontend"]: LocalScript}}}, Character: Model & {HumanoidRootPart: Part}}
local Library: {Save: {Get: () -> {MaximumAvailableEgg: number; EggHatchCount: number;}}}  = require(ReplicatedStorage.Library)
local EggsUtilMod: {GetIdByNumber: (number) -> number} = require(ReplicatedStorage.Library.Util.EggsUtil)
local PlayerInfo = Library.Save.Get()
local EggAnim : {PlayEggAnimation: () -> nil} = getsenv(Player.PlayerScripts.Scripts.Game["Egg Opening Frontend"])
local Eggs: Folder = Things.Eggs:FindFirstChild("Main") or Things.Eggs:FindFirstChild("World2")
local Egg = Eggs[EggNumber .. " - Egg Capsule"] :: Model & {Tier: Part}
local Teleport = Egg.Tier.CFrame

hookfunction(EggAnim.PlayEggAnimation, function()
    return
end)

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
    
moveToPosition(Vector3.new(-10042.6162109375, 16.804433822631836, -315.94561767578125))

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

--anti afk shit
game.Players.LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
game.Players.LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Disabled = true
game:GetService("RunService"):Set3dRenderingEnabled(false)

while task.wait(0.1) do
    local BestEggName = EggsUtilMod.GetIdByNumber(EggNumber)
    local EggHatchCount = PlayerInfo.EggHatchCount

    repeat
        local success: boolean = ReplicatedStorage.Network.Eggs_RequestPurchase:InvokeServer(BestEggName, EggHatchCount)
    until success
end
