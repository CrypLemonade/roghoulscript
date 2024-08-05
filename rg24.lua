--[[
 ██████╗██████╗ ██╗   ██╗██████╗ ██╗     ███████╗███╗   ███╗ ██████╗ ███╗   ██╗ █████╗ ██████╗ ███████╗
██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗██║     ██╔════╝████╗ ████║██╔═══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝
██║     ██████╔╝ ╚████╔╝ ██████╔╝██║     █████╗  ██╔████╔██║██║   ██║██╔██╗ ██║███████║██║  ██║█████╗  
██║     ██╔══██╗  ╚██╔╝  ██╔═══╝ ██║     ██╔══╝  ██║╚██╔╝██║██║   ██║██║╚██╗██║██╔══██║██║  ██║██╔══╝  
╚██████╗██║  ██║   ██║   ██║     ███████╗███████╗██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║  ██║██████╔╝███████╗
 ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═════╝ ╚══════╝
]]--                                                                                                     

-- Settings
local Settings = {
    Mobs = {
        -- Ghoul's
        ["High Rank Aogiri Member"] = true,
        ["Mid Rank Aogiri Member"] = true,
        ["Low Rank Aogiri Member"] = true,
        -- CCG's
        ["Rank 1 Investigator"] = true,
        ["Rank 2 Investigator"] = true,
        ["First Class Investigator"] = true,
        -- Mob's
        ["Human"] = true,
        ["Athlete"] = true
    },
    Speed = 200,  -- Speed for teleportation
    ClickInterval = 0.5,  -- Auto-click interval in seconds
    ClickDuration = 5.5,  -- Duration for auto-clicking the corpse
    TeleportWaitTime = 5  -- Time to wait before clicking after teleportation
}

-- Services
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Toggle = false

-- Functions
local function RandomWait(min, max)
    wait(math.random() * (max - min) + min)
end

local function Teleport(CFrame)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - CFrame.Position).Magnitude
        local Time = Distance / Settings.Speed
        if Distance < 10 then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame
        else
            TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = CFrame}):Play()
            wait(Time)
        end
    end
end

local function ClickPart(Part)
    local Click = Part:FindFirstChild("ClickDetector")
    if Click then
        local Start = tick()
        while tick() - Start < Settings.ClickDuration do
            RandomWait(0.1, 0.3)  -- Random delay to simulate human clicking
            fireclickdetector(Click)
        end
    end
end

local function AutoClickPart(Part)
    local Start = tick()
    while tick() - Start < Settings.ClickDuration do
        RandomWait(Settings.ClickInterval - 0.1, Settings.ClickInterval + 0.1)  -- Randomize clicking interval
        Mouse.Button1Down:Fire()
        wait(0.1)
        Mouse.Button1Up:Fire()
    end
end

local function HandleMobs()
    for _, mob in pairs(Workspace.NPCSpawns:GetDescendants()) do
        if not Toggle then return end
        if Settings.Mobs[mob.Name] == true then
            local Mob, Corpse, Connection, HealthConnection = mob, nil, nil, nil
            Connection = Mob.ChildAdded:Connect(function(Child)
                if string.find(Child.Name, "Corpse") then Corpse = Child Connection:Disconnect() end
            end)
            if Mob:FindFirstChild("Humanoid") then
                HealthConnection = Mob.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                    if Mob.Humanoid.Health <= 0 then
                        if Corpse and Corpse:FindFirstChild("HumanoidRootPart") then
                            -- Move mouse to torso part
                            if Corpse:FindFirstChild("UpperTorso") then
                                local torsoPosition = Camera:WorldToScreenPoint(Corpse.UpperTorso.Position)
                                Mouse.X = torsoPosition.X
                                Mouse.Y = torsoPosition.Y
                            end
                            -- Wait before clicking
                            wait(Settings.TeleportWaitTime)
                            AutoClickPart(Corpse.HumanoidRootPart)
                        end
                        HealthConnection:Disconnect()
                        HandleMobs()  -- Re-run to handle next mobs
                    end
                end)
                repeat 
                    Wait(
                        10
                    )  -- Random delay to simulate human reaction time
                    pcall(function()
                        Teleport(Mob.HumanoidRootPart.CFrame + Mob.HumanoidRootPart.CFrame.LookVector * -4)
                    end)
                until not Mob or not Mob:FindFirstChild("Humanoid")
            end
        end
    end
end

-- Toggle function
UserInputService.InputBegan:Connect(function(Input)
    if Input.KeyCode == Enum.KeyCode.Z then
        Toggle = not Toggle
        if Toggle then
            wait(7)
            HandleMobs()
        end
    end
end)
