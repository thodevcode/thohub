-- // Blox Fruits Advanced Script by Axiom
-- // UI: Floating Button + Modern Blue Theme + Tab System

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- // ===================== SETTINGS ===================== //
local Config = {
    -- Farm
    FarmEnabled = false,
    FarmLevel = "Test",
    AutoQuest = true,
    BringMobs = true,
    BringRadius = 20,
    AttackSpeed = 0.15,
    HitTwoMobs = true,

    -- Settings
    FastAttack = false,
    FarmDistance = 50,
    FlySpeed = 80,
    BringMode = true,
}

-- // ===================== MOB DATABASE ===================== //
local MobData = {
    ["Test"] = {
        Name = "Test Zone",
        Level = "1-50",
        Mobs = {
            "Bandit", "Monkey", "Gorilla", "Pirate",
            "Skullette", "Prisoner", "Dangerous Prisoner",
            "Sword Bandit", "Nether Bandit", "Fishman Warrior",
            "Fishman Commando", "Sky Bandit",
        },
        QuestNPC = "Military Detective",
        QuestName = "Bandit Hunt",
        Location = Vector3.new(0, 0, 0),
    },
    ["Starter Island"] = {
        Name = "Starter Island",
        Level = "1-15",
        Mobs = {"Bandit", "Monkey"},
        QuestNPC = "Military Detective",
        QuestName = "Bandit Hunt",
        Location = Vector3.new(977, 120, 1818),
    },
    ["Middle Town"] = {
        Name = "Middle Town",
        Level = "15-30",
        Mobs = {"Gorilla", "Pirate"},
        QuestNPC = "Military Detective",
        QuestName = "Gorilla Hunt",
        Location = Vector3.new(-1050, 266, -700),
    },
    ["Jungle"] = {
        Name = "Jungle",
        Level = "30-60",
        Mobs = {"Gorilla", "Jungle Pirate"},
        QuestNPC = "Military Detective",
        QuestName = "Jungle Hunt",
        Location = Vector3.new(-1600, 172, 310),
    },
    ["Pirate Village"] = {
        Name = "Pirate Village",
        Level = "60-90",
        Mobs = {"Pirate", "Pistol Pirate", "Sword Pirate"},
        QuestNPC = "Military Detective",
        QuestName = "Pirate Hunt",
        Location = Vector3.new(-2530, 40, 1712),
    },
    ["Marineford"] = {
        Name = "Marineford",
        Level = "120-175",
        Mobs = {"Marine", "Marine Captain", "Marine Lieutenant"},
        QuestNPC = "Soldier",
        QuestName = "Marine Hunt",
        Location = Vector3.new(4757, 38, 3185),
    },
    ["Skylands"] = {
        Name = "Skylands",
        Level = "190-275",
        Mobs = {"Sky Bandit", "Dark Master", "Shanda"},
        QuestNPC = "Gatekeeper",
        QuestName = "Skylands Quest",
        Location = Vector3.new(-4820, 870, 1817),
    },
    ["Prison"] = {
        Name = "Prison",
        Level = "90-120",
        Mobs = {"Prisoner", "Dangerous Prisoner", "Sword Bandit"},
        QuestNPC = "Sergeant",
        QuestName = "Prison Hunt",
        Location = Vector3.new(-4974, 38, 1873),
    },
    ["Colosseum"] = {
        Name = "Colosseum",
        Level = "225-300",
        Mobs = {"Toga Warrior", "Gladiator"},
        QuestNPC = "Bartolomeo",
        QuestName = "Colosseum Quest",
        Location = Vector3.new(-3804, 27, 1020),
    },
    ["Magma Village"] = {
        Name = "Magma Village",
        Level = "300-375",
        Mobs = {"Magma Ninja", "Lava Pirate"},
        QuestNPC = "Magma Admiral",
        QuestName = "Magma Hunt",
        Location = Vector3.new(-1128, 38, -3380),
    },
    ["Underwater City"] = {
        Name = "Underwater City",
        Level = "375-450",
        Mobs = {"Fishman Warrior", "Fishman Commando", "Fishman Lord"},
        QuestNPC = "Fishman Admiral",
        QuestName = "Fishman Hunt",
        Location = Vector3.new(63400, -1900, -300),
    },
    ["Upper Skylands"] = {
        Name = "Upper Skylands",
        Level = "700-850",
        Mobs = {"Royal Soldier", "Royal Squad", "Galley Pirate", "Dark Soul"},
        QuestNPC = "Royal Soldier Officer",
        QuestName = "Upper Skylands Quest",
        Location = Vector3.new(-3143, 3100, 3573),
    },
    ["Ice Castle"] = {
        Name = "Ice Castle",
        Level = "850-925",
        Mobs = {"Snow Lurker", "Arctic Warrior"},
        QuestNPC = "Ice Admiral",
        QuestName = "Ice Castle Quest",
        Location = Vector3.new(-3500, 3560, -3900),
    },
    ["Third Sea Starter"] = {
        Name = "Third Sea - Port Town",
        Level = "1500-1575",
        Mobs = {"Pirate Millionaire", "Golden Pirate"},
        QuestNPC = "Quest Giver",
        QuestName = "Port Town Quest",
        Location = Vector3.new(-26505, 23, 4669),
    },
}

-- // ===================== UTILITY FUNCTIONS ===================== //
local function GetCharacter()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:FindFirstChild("Humanoid")
        RootPart = Character:FindFirstChild("HumanoidRootPart")
    end
    return Character
end

local function IsAlive()
    local char = GetCharacter()
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function Tween(obj, time, props)
    local info = TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function GetMobsInWorkspace(mobNames)
    local mobs = {}
    local workspace = game:GetService("Workspace")
    local mobFolder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mobs") or workspace

    for _, obj in pairs(mobFolder:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            for _, name in pairs(mobNames) do
                if obj.Name:lower():find(name:lower()) then
                    if obj.Humanoid.Health > 0 then
                        table.insert(mobs, obj)
                    end
                    break
                end
            end
        end
    end
    return mobs
end

local function GetNearestMob(mobNames, maxDist)
    if not IsAlive() then return nil end
    maxDist = maxDist or Config.FarmDistance
    local nearest, nearestDist = nil, math.huge

    local mobs = GetMobsInWorkspace(mobNames)
    for _, mob in pairs(mobs) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        if root then
            local dist = (RootPart.Position - root.Position).Magnitude
            if dist < nearestDist and dist <= maxDist then
                nearest = mob
                nearestDist = dist
            end
        end
    end
    return nearest
end

local function FlyTo(position)
    if not IsAlive() then return end
    local bodyVel = RootPart:FindFirstChild("__AXFly") or Instance.new("BodyVelocity")
    bodyVel.Name = "__AXFly"
    bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVel.P = 9e4
    bodyVel.Parent = RootPart

    local bodyGyro = RootPart:FindFirstChild("__AXGyro") or Instance.new("BodyGyro")
    bodyGyro.Name = "__AXGyro"
    bodyGyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    bodyGyro.P = 2e4
    bodyGyro.Parent = RootPart

    local direction = (position - RootPart.Position).Unit
    bodyVel.Velocity = direction * Config.FlySpeed
    bodyGyro.CFrame = CFrame.new(RootPart.Position, position)

    local dist = (position - RootPart.Position).Magnitude
    local eta = dist / Config.FlySpeed + 0.5
    task.wait(math.min(eta, 3))

    bodyVel:Destroy()
    bodyGyro:Destroy()
end

local function BringMobToPlayer(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local bodyPos = root:FindFirstChild("__BringPos") or Instance.new("BodyPosition")
    bodyPos.Name = "__BringPos"
    bodyPos.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyPos.P = 1e4
    bodyPos.Position = RootPart.Position + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
    bodyPos.Parent = root

    task.delay(3, function()
        if bodyPos and bodyPos.Parent then
            bodyPos:Destroy()
        end
    end)
end

local function SimulateAttack()
    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("RemoteFunction")
    if remote then
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer()
            end
        end)
    end
    -- Trigger click detector / activate
    pcall(function()
        tool:Activate()
    end)
end

-- // ===================== QUEST SYSTEM ===================== //
local QuestActive = false

local function FindNPC(npcName)
    for _, obj in pairs(game:GetService("Workspace"):GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find(npcName:lower()) then
            return obj
        end
    end
    return nil
end

local function AcceptQuest(zoneData)
    if QuestActive then return end
    local npc = FindNPC(zoneData.QuestNPC)
    if not npc then return end

    local root = npc:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Fly to NPC
    FlyTo(root.Position + Vector3.new(0, 0, 3))
    task.wait(0.5)

    -- Try remote quest events
    local questRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Quests", true)
        or game:GetService("ReplicatedStorage"):FindFirstChild("AcceptQuest", true)
        or game:GetService("ReplicatedStorage"):FindFirstChild("Quest", true)

    if questRemote and questRemote:IsA("RemoteEvent") then
        pcall(function()
            questRemote:FireServer(zoneData.QuestName)
        end)
    end

    -- Also try proximity prompt
    local prompt = npc:FindFirstChildOfClass("ProximityPrompt", true)
    if prompt then
        pcall(function()
            local fireProximityPrompt = game:GetService("ReplicatedStorage"):FindFirstChild("FireProximityPrompt", true)
            if fireProximityPrompt then
                fireProximityPrompt:FireServer(prompt)
            end
        end)
    end

    QuestActive = true
    task.delay(300, function() QuestActive = false end)
end

-- // ===================== FARM LOOP ===================== //
local FarmRunning = false
local FarmThread = nil

local function StartFarm(zoneKey)
    if FarmRunning then return end
    FarmRunning = true
    local zoneData = MobData[zoneKey]
    if not zoneData then FarmRunning = false return end

    FarmThread = task.spawn(function()
        while FarmRunning do
            if not IsAlive() then
                task.wait(3)
                Character = LocalPlayer.CharacterAdded:Wait()
                task.wait(1)
                GetCharacter()
                continue
            end

            -- Quest
            if Config.AutoQuest and not QuestActive then
                AcceptQuest(zoneData)
                task.wait(1)
            end

            -- Get target mob(s)
            local mobs = GetMobsInWorkspace(zoneData.Mobs)
            if #mobs == 0 then
                task.wait(1)
                continue
            end

            -- Bring mobs
            if Config.BringMode then
                local bringCount = 0
                for _, mob in pairs(mobs) do
                    if bringCount >= (Config.HitTwoMobs and 2 or 1) then break end
                    local root = mob:FindFirstChild("HumanoidRootPart")
                    if root and (RootPart.Position - root.Position).Magnitude <= Config.FarmDistance then
                        BringMobToPlayer(mob)
                        bringCount = bringCount + 1
                    end
                end
            end

            -- Target nearest mob
            local target = GetNearestMob(zoneData.Mobs, Config.FarmDistance)
            if target then
                local targetRoot = target:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (RootPart.Position - targetRoot.Position).Magnitude
                    if dist > 8 then
                        FlyTo(targetRoot.Position + Vector3.new(0, 2, 0))
                    end
                    -- Face target
                    RootPart.CFrame = CFrame.lookAt(RootPart.Position, targetRoot.Position)
                    SimulateAttack()
                end
            else
                -- No nearby mob, move to zone
                FlyTo(zoneData.Location)
                task.wait(1)
            end

            local delay = Config.FastAttack and 0.05 or Config.AttackSpeed
            task.wait(delay)
        end
    end)
end

local function StopFarm()
    FarmRunning = false
    if FarmThread then
        task.cancel(FarmThread)
        FarmThread = nil
    end
end

-- // ===================== GUI CREATION ===================== //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AxiomBF"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- // Floating Toggle Button
local FloatBtn = Instance.new("Frame")
FloatBtn.Name = "FloatBtn"
FloatBtn.Size = UDim2.new(0, 50, 0, 50)
FloatBtn.Position = UDim2.new(0, 20, 0.5, -25)
FloatBtn.BackgroundColor3 = Color3.fromRGB(10, 30, 80)
FloatBtn.BorderSizePixel = 0
FloatBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatBtn

local FloatGrad = Instance.new("UIGradient")
FloatGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 60, 180)),
})
FloatGrad.Rotation = 135
FloatGrad.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(0, 180, 255)
FloatStroke.Thickness = 1.5
FloatStroke.Transparency = 0.3
FloatStroke.Parent = FloatBtn

local FloatLabel = Instance.new("TextLabel")
FloatLabel.Size = UDim2.new(1, 0, 1, 0)
FloatLabel.BackgroundTransparency = 1
FloatLabel.Text = "⚡"
FloatLabel.TextScaled = true
FloatLabel.Font = Enum.Font.GothamBold
FloatLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatLabel.Parent = FloatBtn

-- Drag for Float Button
local draggingFloat, floatDragStart, floatStartPos
local FloatBtnBtn = Instance.new("TextButton")
FloatBtnBtn.Size = UDim2.new(1, 0, 1, 0)
FloatBtnBtn.BackgroundTransparency = 1
FloatBtnBtn.Text = ""
FloatBtnBtn.Parent = FloatBtn

FloatBtnBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFloat = true
        floatDragStart = input.Position
        floatStartPos = FloatBtn.Position
    end
end)

FloatBtnBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if draggingFloat then
            local delta = input.Position - floatDragStart
            local totalMove = math.abs(delta.X) + math.abs(delta.Y)
            draggingFloat = false
            if totalMove < 5 then
                -- Toggle main window
                local MainFrame = ScreenGui:FindFirstChild("MainFrame")
                if MainFrame then
                    MainFrame.Visible = not MainFrame.Visible
                end
            end
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingFloat and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - floatDragStart
        FloatBtn.Position = UDim2.new(
            floatStartPos.X.Scale,
            floatStartPos.X.Offset + delta.X,
            floatStartPos.Y.Scale,
            floatStartPos.Y.Offset + delta.Y
        )
    end
end)

-- Pulse animation for float button
task.spawn(function()
    while true do
        Tween(FloatStroke, 0.8, {Transparency = 0.0})
        task.wait(0.8)
        Tween(FloatStroke, 0.8, {Transparency = 0.6})
        task.wait(0.8)
    end
end)

-- // ===================== MAIN WINDOW ===================== //
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 420)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 10, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 120, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.2
MainStroke.Parent = MainFrame

-- Glow effect (shadow)
local Glow = Instance.new("ImageLabel")
Glow.Size = UDim2.new(1, 40, 1, 40)
Glow.Position = UDim2.new(0, -20, 0, -20)
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://5028857472"
Glow.ImageColor3 = Color3.fromRGB(0, 100, 255)
Glow.ImageTransparency = 0.6
Glow.ScaleType = Enum.ScaleType.Slice
Glow.SliceCenter = Rect.new(24, 24, 276, 276)
Glow.ZIndex = -1
Glow.Parent = MainFrame

-- // Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 20, 60)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 14)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3 = Color3.fromRGB(0, 20, 60)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleGrad = Instance.new("UIGradient")
TitleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 80, 200)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 50, 160)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 20, 80)),
})
TitleGrad.Rotation = 90
TitleGrad.Parent = TitleBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 40, 1, 0)
TitleIcon.Position = UDim2.new(0, 10, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "⚡"
TitleIcon.TextScaled = true
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
TitleIcon.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 200, 1, 0)
TitleText.Position = UDim2.new(0, 55, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "AXIOM BF"
TitleText.TextSize = 18
TitleText.Font = Enum.Font.GothamBold
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local SubText = Instance.new("TextLabel")
SubText.Size = UDim2.new(0, 200, 1, 0)
SubText.Position = UDim2.new(0, 55, 0, 20)
SubText.BackgroundTransparency = 1
SubText.Text = "Blox Fruits Script"
SubText.TextSize = 11
SubText.Font = Enum.Font.Gotham
SubText.TextColor3 = Color3.fromRGB(100, 160, 255)
SubText.TextXAlignment = Enum.TextXAlignment.Left
SubText.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0, 9)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -80, 0, 9)
MinBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 180)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

-- Drag main window
local dragging, dragStart, startPos
local TitleDragArea = Instance.new("TextButton")
TitleDragArea.Size = UDim2.new(1, -130, 1, 0)
TitleDragArea.BackgroundTransparency = 1
TitleDragArea.Text = ""
TitleDragArea.Parent = TitleBar

TitleDragArea.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TitleDragArea.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- // ===================== LAYOUT: LEFT TABS + RIGHT CONTENT ===================== //
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, 0, 1, -50)
ContentArea.Position = UDim2.new(0, 0, 0, 50)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- LEFT SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(5, 15, 40)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = ContentArea

local SidebarLeft = Instance.new("UICorner")
SidebarLeft.CornerRadius = UDim.new(0, 14)
SidebarLeft.Parent = Sidebar

local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0.5, 0, 1, 0)
SidebarFix.Position = UDim2.new(0.5, 0, 0, 0)
SidebarFix.BackgroundColor3 = Color3.fromRGB(5, 15, 40)
SidebarFix.BorderSizePixel = 0
SidebarFix.Parent = Sidebar

local SideList = Instance.new("UIListLayout")
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding = UDim.new(0, 6)
SideList.Parent = Sidebar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 12)
SidePadding.PaddingLeft = UDim.new(0, 8)
SidePadding.PaddingRight = UDim.new(0, 8)
SidePadding.Parent = Sidebar

-- RIGHT PANEL
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1, -148, 1, 0)
RightPanel.Position = UDim2.new(0, 148, 0, 0)
RightPanel.BackgroundTransparency = 1
RightPanel.Parent = ContentArea

-- RIGHT SEPARATOR LINE
local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(0, 1, 1, -20)
Separator.Position = UDim2.new(0, 140, 0, 10)
Separator.BackgroundColor3 = Color3.fromRGB(0, 80, 200)
Separator.BorderSizePixel = 0
Separator.BackgroundTransparency = 0.7
Separator.Parent = ContentArea

-- // ===================== TAB SYSTEM ===================== //
local Tabs = {}
local ActiveTab = nil

local function CreateTabButton(name, icon, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 44)
    Btn.BackgroundColor3 = Color3.fromRGB(10, 25, 70)
    Btn.Text = ""
    Btn.BorderSizePixel = 0
    Btn.LayoutOrder = order
    Btn.Parent = Sidebar

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 10)
    BtnCorner.Parent = Btn

    local BtnIconL = Instance.new("TextLabel")
    BtnIconL.Size = UDim2.new(0, 30, 1, 0)
    BtnIconL.Position = UDim2.new(0, 6, 0, 0)
    BtnIconL.BackgroundTransparency = 1
    BtnIconL.Text = icon
    BtnIconL.TextSize = 16
    BtnIconL.Font = Enum.Font.GothamBold
    BtnIconL.TextColor3 = Color3.fromRGB(100, 160, 255)
    BtnIconL.Parent = Btn

    local BtnText = Instance.new("TextLabel")
    BtnText.Size = UDim2.new(1, -40, 1, 0)
    BtnText.Position = UDim2.new(0, 38, 0, 0)
    BtnText.BackgroundTransparency = 1
    BtnText.Text = name
    BtnText.TextSize = 13
    BtnText.Font = Enum.Font.GothamSemibold
    BtnText.TextColor3 = Color3.fromRGB(180, 210, 255)
    BtnText.TextXAlignment = Enum.TextXAlignment.Left
    BtnText.Parent = Btn

    -- Active indicator
    local ActiveBar = Instance.new("Frame")
    ActiveBar.Size = UDim2.new(0, 3, 0.6, 0)
    ActiveBar.Position = UDim2.new(0, -8, 0.2, 0)
    ActiveBar.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
    ActiveBar.BorderSizePixel = 0
    ActiveBar.Visible = false
    ActiveBar.Parent = Btn
    Instance.new("UICorner", ActiveBar).CornerRadius = UDim.new(1, 0)

    -- Content frame
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Size = UDim2.new(1, -8, 1, -12)
    ContentFrame.Position = UDim2.new(0, 4, 0, 6)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 3
    ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 255)
    ContentFrame.Visible = false
    ContentFrame.Parent = RightPanel

    local ContentList = Instance.new("UIListLayout")
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Padding = UDim.new(0, 8)
    ContentList.Parent = ContentFrame

    local ContentPad = Instance.new("UIPadding")
    ContentPad.PaddingTop = UDim.new(0, 8)
    ContentPad.PaddingRight = UDim.new(0, 4)
    ContentPad.Parent = ContentFrame

    Tabs[name] = {
        Button = Btn,
        Content = ContentFrame,
        ActiveBar = ActiveBar,
        BtnText = BtnText,
        BtnIconL = BtnIconL,
    }

    Btn.MouseButton1Click:Connect(function()
        -- Hide all
        for tabName, tab in pairs(Tabs) do
            tab.Content.Visible = false
            tab.ActiveBar.Visible = false
            Tween(tab.Button, 0.2, {BackgroundColor3 = Color3.fromRGB(10, 25, 70)})
            tab.BtnText.TextColor3 = Color3.fromRGB(180, 210, 255)
        end
        -- Show active
        ContentFrame.Visible = true
        ActiveBar.Visible = true
        Tween(Btn, 0.2, {BackgroundColor3 = Color3.fromRGB(0, 50, 150)})
        BtnText.TextColor3 = Color3.fromRGB(255, 255, 255)
        ActiveTab = name
    end)

    return ContentFrame
end

-- // ===================== UI COMPONENTS ===================== //
local function CreateSectionLabel(parent, text, order)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 24)
    Label.BackgroundTransparency = 1
    Label.Text = "  " .. text:upper()
    Label.TextSize = 10
    Label.Font = Enum.Font.GothamBold
    Label.TextColor3 = Color3.fromRGB(0, 150, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.LayoutOrder = order
    Label.Parent = parent
    return Label
end

local function CreateToggle(parent, text, defaultVal, callback, order)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 40)
    Row.BackgroundColor3 = Color3.fromRGB(10, 22, 55)
    Row.BorderSizePixel = 0
    Row.LayoutOrder = order
    Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local RowStroke = Instance.new("UIStroke")
    RowStroke.Color = Color3.fromRGB(0, 60, 150)
    RowStroke.Thickness = 1
    RowStroke.Transparency = 0.6
    RowStroke.Parent = Row

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextColor3 = Color3.fromRGB(200, 225, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local ToggleBg = Instance.new("Frame")
    ToggleBg.Size = UDim2.new(0, 44, 0, 22)
    ToggleBg.Position = UDim2.new(1, -54, 0.5, -11)
    ToggleBg.BackgroundColor3 = defaultVal and Color3.fromRGB(0, 100, 255) or Color3.fromRGB(30, 40, 70)
    ToggleBg.BorderSizePixel = 0
    ToggleBg.Parent = Row
    Instance.new("UICorner", ToggleBg).CornerRadius = UDim.new(1, 0)

    local ToggleKnob = Instance.new("Frame")
    ToggleKnob.Size = UDim2.new(0, 16, 0, 16)
    ToggleKnob.Position = defaultVal and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    ToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleKnob.BorderSizePixel = 0
    ToggleKnob.Parent = ToggleBg
    Instance.new("UICorner", ToggleKnob).CornerRadius = UDim.new(1, 0)

    local state = defaultVal
    local ClickArea = Instance.new("TextButton")
    ClickArea.Size = UDim2.new(1, 0, 1, 0)
    ClickArea.BackgroundTransparency = 1
    ClickArea.Text = ""
    ClickArea.Parent = Row

    ClickArea.MouseButton1Click:Connect(function()
        state = not state
        Tween(ToggleBg, 0.2, {BackgroundColor3 = state and Color3.fromRGB(0, 100, 255) or Color3.fromRGB(30, 40, 70)})
        Tween(ToggleKnob, 0.2, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
        callback(state)
    end)

    return Row
end

local function CreateSlider(parent, text, min, max, defaultVal, callback, order)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 58)
    Row.BackgroundColor3 = Color3.fromRGB(10, 22, 55)
    Row.BorderSizePixel = 0
    Row.LayoutOrder = order
    Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local RowStroke = Instance.new("UIStroke")
    RowStroke.Color = Color3.fromRGB(0, 60, 150)
    RowStroke.Thickness = 1
    RowStroke.Transparency = 0.6
    RowStroke.Parent = Row

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 0, 22)
    Label.Position = UDim2.new(0, 14, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextSize = 12
    Label.Font = Enum.Font.Gotham
    Label.TextColor3 = Color3.fromRGB(200, 225, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(0, 50, 0, 22)
    ValLabel.Position = UDim2.new(1, -60, 0, 4)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = tostring(defaultVal)
    ValLabel.TextSize = 12
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.Parent = Row

    local SliderBg = Instance.new("Frame")
    SliderBg.Size = UDim2.new(1, -28, 0, 6)
    SliderBg.Position = UDim2.new(0, 14, 0, 36)
    SliderBg.BackgroundColor3 = Color3.fromRGB(20, 40, 90)
    SliderBg.BorderSizePixel = 0
    SliderBg.Parent = Row
    Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)

    local SliderFill = Instance.new("Frame")
    local initScale = (defaultVal - min) / (max - min)
    SliderFill.Size = UDim2.new(initScale, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBg
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

    local SliderKnob = Instance.new("Frame")
    SliderKnob.Size = UDim2.new(0, 14, 0, 14)
    SliderKnob.Position = UDim2.new(initScale, -7, 0.5, -7)
    SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderKnob.BorderSizePixel = 0
    SliderKnob.Parent = SliderBg
    Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

    local draggingSlider = false
    local SliderBtn = Instance.new("TextButton")
    SliderBtn.Size = UDim2.new(1, 0, 0, 20)
    SliderBtn.Position = UDim2.new(0, 0, 0, -7)
    SliderBtn.BackgroundTransparency = 1
    SliderBtn.Text = ""
    SliderBtn.Parent = SliderBg

    local function UpdateSlider(inputPos)
        local sliderAbsPos = SliderBg.AbsolutePosition.X
        local sliderWidth = SliderBg.AbsoluteSize.X
        local rel = math.clamp((inputPos - sliderAbsPos) / sliderWidth, 0, 1)
        local value = math.floor(min + rel * (max - min))
        ValLabel.Text = tostring(value)
        SliderFill.Size = UDim2.new(rel, 0, 1, 0)
        SliderKnob.Position = UDim2.new(rel, -7, 0.5, -7)
        callback(value)
    end

    SliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            UpdateSlider(input.Position.X)
        end
    end)
    SliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input.Position.X)
        end
    end)

    return Row
end

local function CreateDropdown(parent, text, options, defaultVal, callback, order)
    local isOpen = false
    local selected = defaultVal

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 42)
    Container.BackgroundColor3 = Color3.fromRGB(10, 22, 55)
    Container.BorderSizePixel = 0
    Container.LayoutOrder = order
    Container.ClipsDescendants = false
    Container.Parent = parent
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 8)

    local ContStroke = Instance.new("UIStroke")
    ContStroke.Color = Color3.fromRGB(0, 60, 150)
    ContStroke.Thickness = 1
    ContStroke.Transparency = 0.6
    ContStroke.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 120, 0, 42)
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextSize = 12
    Label.Font = Enum.Font.Gotham
    Label.TextColor3 = Color3.fromRGB(200, 225, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local SelectBtn = Instance.new("TextButton")
    SelectBtn.Size = UDim2.new(1, -140, 0, 30)
    SelectBtn.Position = UDim2.new(0, 136, 0, 6)
    SelectBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 120)
    SelectBtn.Text = selected .. " ▾"
    SelectBtn.TextSize = 11
    SelectBtn.Font = Enum.Font.GothamSemibold
    SelectBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
    SelectBtn.BorderSizePixel = 0
    SelectBtn.Parent = Container
    Instance.new("UICorner", SelectBtn).CornerRadius = UDim.new(0, 6)

    local DropList = Instance.new("Frame")
    DropList.Size = UDim2.new(1, -140, 0, math.min(#options, 5) * 30 + 8)
    DropList.Position = UDim2.new(0, 136, 0, 44)
    DropList.BackgroundColor3 = Color3.fromRGB(5, 15, 45)
    DropList.BorderSizePixel = 0
    DropList.Visible = false
    DropList.ZIndex = 10
    DropList.Parent = Container
    Instance.new("UICorner", DropList).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", DropList).Color = Color3.fromRGB(0, 80, 200)

    local DropLayout = Instance.new("UIListLayout")
    DropLayout.Padding = UDim.new(0, 2)
    DropLayout.Parent = DropList
    Instance.new("UIPadding", DropList).PaddingTop = UDim.new(0, 4)

    for _, opt in pairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, -8, 0, 26)
        OptBtn.BackgroundTransparency = 1
        OptBtn.Text = opt
        OptBtn.TextSize = 11
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.TextColor3 = Color3.fromRGB(180, 220, 255)
        OptBtn.ZIndex = 11
        OptBtn.Parent = DropList

        OptBtn.MouseEnter:Connect(function()
            Tween(OptBtn, 0.1, {BackgroundTransparency = 0.6})
            OptBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 180)
        end)
        OptBtn.MouseLeave:Connect(function()
            Tween(OptBtn, 0.1, {BackgroundTransparency = 1})
        end)
        OptBtn.MouseButton1Click:Connect(function()
            selected = opt
            SelectBtn.Text = opt .. " ▾"
            DropList.Visible = false
            isOpen = false
            Container.Size = UDim2.new(1, 0, 0, 42)
            callback(opt)
        end)
    end

    SelectBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        DropList.Visible = isOpen
        if isOpen then
            Container.Size = UDim2.new(1, 0, 0, 42 + math.min(#options, 5) * 30 + 12)
        else
            Container.Size = UDim2.new(1, 0, 0, 42)
        end
    end)

    return Container
end

local function CreateButton(parent, text, icon, callback, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 38)
    Btn.BackgroundColor3 = Color3.fromRGB(0, 70, 200)
    Btn.Text = (icon and icon .. "  " or "") .. text
    Btn.TextSize = 13
    Btn.Font = Enum.Font.GothamBold
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.BorderSizePixel = 0
    Btn.LayoutOrder = order
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    local BtnGrad = Instance.new("UIGradient")
    BtnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 60, 200)),
    })
    BtnGrad.Rotation = 90
    BtnGrad.Parent = Btn

    Btn.MouseEnter:Connect(function()
        Tween(Btn, 0.15, {BackgroundColor3 = Color3.fromRGB(0, 100, 255)})
    end)
    Btn.MouseLeave:Connect(function()
        Tween(Btn, 0.15, {BackgroundColor3 = Color3.fromRGB(0, 70, 200)})
    end)
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

-- // ===================== BUILD TABS ===================== //

-- FARM TAB
local FarmContent = CreateTabButton("Farm", "⚔️", 1)

CreateSectionLabel(FarmContent, "🌾 Farm Zone", 1)

local zoneNames = {}
for k, _ in pairs(MobData) do table.insert(zoneNames, k) end
table.sort(zoneNames)

local selectedZone = "Test"
CreateDropdown(FarmContent, "Select Zone", zoneNames, "Test", function(val)
    selectedZone = val
end, 2)

CreateSectionLabel(FarmContent, "⚙️ Farm Options", 5)

CreateToggle(FarmContent, "Auto Quest", Config.AutoQuest, function(v)
    Config.AutoQuest = v
end, 6)

CreateToggle(FarmContent, "Bring Mobs (Gom Quái)", Config.BringMode, function(v)
    Config.BringMode = v
end, 7)

CreateToggle(FarmContent, "Hit 2 Mobs at Once", Config.HitTwoMobs, function(v)
    Config.HitTwoMobs = v
end, 8)

CreateSectionLabel(FarmContent, "🚀 Controls", 10)

local farmToggleState = false
local FarmBtnRef

FarmBtnRef = CreateButton(FarmContent, "START FARM", "▶", function()
    farmToggleState = not farmToggleState
    if farmToggleState then
        FarmBtnRef.Text = "⏹  STOP FARM"
        Tween(FarmBtnRef, 0.2, {BackgroundColor3 = Color3.fromRGB(180, 30, 30)})
        StartFarm(selectedZone)
    else
        FarmBtnRef.Text = "▶  START FARM"
        Tween(FarmBtnRef, 0.2, {BackgroundColor3 = Color3.fromRGB(0, 70, 200)})
        StopFarm()
    end
end, 11)

-- Status display
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, 0, 0, 40)
StatusFrame.BackgroundColor3 = Color3.fromRGB(5, 15, 40)
StatusFrame.BorderSizePixel = 0
StatusFrame.LayoutOrder = 12
StatusFrame.Parent = FarmContent
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 1, 0)
StatusLabel.Position = UDim2.new(0, 10, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "⬤  Idle"
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

-- Update status
task.spawn(function()
    while true do
        task.wait(0.5)
        if FarmRunning then
            local zone = MobData[selectedZone]
            StatusLabel.Text = "⬤  Farming: " .. (zone and zone.Name or selectedZone)
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        else
            StatusLabel.Text = "⬤  Idle"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
        end
    end
end)

-- SETTINGS TAB
local SettingsContent = CreateTabButton("Settings", "⚙️", 2)

CreateSectionLabel(SettingsContent, "⚡ Combat", 1)

CreateToggle(SettingsContent, "Fast Attack", Config.FastAttack, function(v)
    Config.FastAttack = v
end, 2)

CreateSlider(SettingsContent, "Attack Speed (s)", 5, 100, 15, function(v)
    Config.AttackSpeed = v / 100
end, 3)

CreateSectionLabel(SettingsContent, "🎯 Detection", 6)

CreateSlider(SettingsContent, "Farm Distance (studs)", 20, 200, Config.FarmDistance, function(v)
    Config.FarmDistance = v
end, 7)

CreateSlider(SettingsContent, "Bring Radius (studs)", 5, 80, Config.BringRadius, function(v)
    Config.BringRadius = v
end, 8)

CreateSectionLabel(SettingsContent, "✈️ Movement", 11)

CreateSlider(SettingsContent, "Fly Speed", 20, 300, Config.FlySpeed, function(v)
    Config.FlySpeed = v
end, 12)

CreateSectionLabel(SettingsContent, "💡 Misc", 15)

CreateButton(SettingsContent, "Teleport to Zone", "📍", function()
    local zone = MobData[selectedZone]
    if zone and zone.Location ~= Vector3.new(0,0,0) then
        RootPart.CFrame = CFrame.new(zone.Location)
    end
end, 16)

CreateButton(SettingsContent, "Reset Character", "🔄", function()
    LocalPlayer.Character.Humanoid.Health = 0
end, 17)

-- // Activate first tab
Tabs["Farm"].Content.Visible = true
Tabs["Farm"].ActiveBar.Visible = true
Tween(Tabs["Farm"].Button, 0.2, {BackgroundColor3 = Color3.fromRGB(0, 50, 150)})
Tabs["Farm"].BtnText.TextColor3 = Color3.fromRGB(255, 255, 255)
ActiveTab = "Farm"

-- // CharacterAdded handler
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    QuestActive = false
end)

print("✅ Axiom BF Script loaded — fuck yeah, that's what the hell is going on boss man")
