-- Albanian Hub | Grow a Garden (enhanced)
-- This script adds remote-detection helpers, character handlers, and WindUI fallback.
-- Replace the WindUI URL with your hosted/local WindUI source if available.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

-- WindUI loader with safe fallback
local function loadWindUI()
    local sources = {
        -- primary: external raw URL (replace this with your hosted WindUI)
        "https://raw.githubusercontent.com/UI-Library-Link/WindUI/main/init.lua",
        -- add more fallback URLs here if you host WindUI elsewhere
    }

    for _, url in ipairs(sources) do
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)

        if ok and lib then
            return lib
        end
    end

    -- Last resort: try to find a WindUI ModuleScript in ReplicatedStorage
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name:lower():find("windui") then
            local ok, lib = pcall(require, v)
            if ok and lib then
                return lib
            end
        end
    end

    error("WindUI could not be loaded; please add WindUI to sources or ReplicatedStorage")
end

local WindUI = loadWindUI()

local Window = WindUI:CreateWindow({
    Title = "Albanian Hub | Grow a Garden",
    Icon = "rbxassetid://1000000",
    Theme = "Dark"
})

-- CONFIG & GLOBAL STATE
getgenv().Settings = getgenv().Settings or {
    AutoFarm = false,
    AutoWater = false,
    AutoSell = false,
    Noclip = false,
    Speed = 16,
    ShopPosition = Vector3.new(0, 0, 0)
}

-- Helper: find remote by candidate name fragments
local function findRemoteByNames(names)
    local candidates = {ReplicatedStorage, workspace, game:GetService("ReplicatedFirst")}
    for _, container in ipairs(candidates) do
        for _, desc in ipairs(container:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                local lname = desc.Name:lower()
                for _, frag in ipairs(names) do
                    if lname:find(frag, 1, true) then
                        return desc
                    end
                end
            end
        end
    end
    return nil
end

-- Generic invoke helper (handles RemoteEvent/RemoteFunction)
local function remoteCall(remote, ...)
    if not remote then return nil end
    local ok, res
    if remote:IsA("RemoteEvent") then
        ok, res = pcall(function() remote:FireServer(...) end)
    elseif remote:IsA("RemoteFunction") then
        ok, res = pcall(function() return remote:InvokeServer(...) end)
    end
    if not ok then
        warn("Remote call failed for", remote:GetFullName())
    end
    return res
end

-- You can optionally provide explicit remote names here (exact name strings),
-- e.g. Remotes = { Harvest = "HarvestV2", Plant = "PlantSeed", Water = "WaterTool", Sell = "SellAll" }
-- If left nil, the script will attempt to auto-detect by common name fragments.
local Remotes = getgenv().AlbanianHubRemotes or {
    Harvest = nil,
    Plant = nil,
    Water = nil,
    Sell = nil
}

local harvestRemote = Remotes.Harvest and findRemoteByNames({Remotes.Harvest}) or findRemoteByNames({"harvest", "pick", "collect"})
local plantRemote = Remotes.Plant and findRemoteByNames({Remotes.Plant}) or findRemoteByNames({"plant", "seed"})
local waterRemote = Remotes.Water and findRemoteByNames({Remotes.Water}) or findRemoteByNames({"water", "sprle", "sprinkle"})
local sellRemote = Remotes.Sell and findRemoteByNames({Remotes.Sell}) or findRemoteByNames({"sell", "sellall", "cashout"})

-- CORE LOGIC MODULES
local function FarmLoop()
    task.spawn(function()
        while task.wait(0.6) do
            if getgenv().Settings.AutoFarm then
                if harvestRemote then
                    remoteCall(harvestRemote)
                else
                    -- fallback: try to activate interact parts in workspace
                    for _, part in ipairs(workspace:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name:lower():find("plot") then
                            pcall(function() part:ClickDetector():Click() end)
                        end
                    end
                end
            end

            if getgenv().Settings.AutoWater and waterRemote then
                remoteCall(waterRemote)
            end

            if getgenv().Settings.AutoSell and sellRemote then
                remoteCall(sellRemote)
            end
        end
    end)
end

-- Character and player utilities
local function applyWalkSpeed(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = getgenv().Settings.Speed or 16
        if getgenv().Settings.Noclip then
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end
end

local function onCharacterAdded(character)
    applyWalkSpeed(character)
    character:WaitForChild("HumanoidRootPart")
end

if player then
    if player.Character then onCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Noclip enforcement on Stepped (keeps physics state when enabled)
RunService.Stepped:Connect(function()
    if player and player.Character and getgenv().Settings.Noclip then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end
end)

-- Anti-AFK management
local AntiAFKConnection
local function setAntiAFK(enabled)
    if enabled then
        if not AntiAFKConnection and player then
            AntiAFKConnection = player.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil
        end
    end
end

-- UI
local FarmTab = Window:Tab({Title = "Farming", Icon = "sprout"})
local EconTab = Window:Tab({Title = "Economy", Icon = "dollar-sign"})
local PlayerTab = Window:Tab({Title = "Player", Icon = "user"})
local UtilTab = Window:Tab({Title = "Utility", Icon = "settings"})

-- Farming
FarmTab:Toggle({Title = "Auto Farm (Harvest/Plant)", Callback = function(v) getgenv().Settings.AutoFarm = v end})
FarmTab:Toggle({Title = "Auto Water", Callback = function(v) getgenv().Settings.AutoWater = v end})

-- Economy
EconTab:Toggle({Title = "Auto Sell", Callback = function(v) getgenv().Settings.AutoSell = v end})

-- Player
PlayerTab:Toggle({Title = "Noclip", Callback = function(v) getgenv().Settings.Noclip = v end})
PlayerTab:Slider({Title = "WalkSpeed", Min = 16, Max = 100, Default = getgenv().Settings.Speed or 16, Callback = function(v) getgenv().Settings.Speed = v if player and player.Character then applyWalkSpeed(player.Character) end end})

-- Utility
UtilTab:Button({Title = "Teleport: Shop", Callback = function()
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().Settings.ShopPosition)
    end
end})

UtilTab:Toggle({Title = "Anti-AFK", Callback = function(v) setAntiAFK(v) end})

-- Start
FarmLoop()

print("[Albanian Hub] Main.lua loaded. Detected remotes:", harvestRemote and harvestRemote.Name, plantRemote and plantRemote.Name, waterRemote and waterRemote.Name, sellRemote and sellRemote.Name)
