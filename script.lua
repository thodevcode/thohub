-- // Blox Fruits Advanced Script by Axiom — FIXED
-- // UI: Floating Button + Modern Blue Theme + Tab System

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- // ===================== SETTINGS ===================== //
local Config = {
    FarmEnabled = false,
    FarmLevel = "Test",
    AutoQuest = true,
    BringMobs = true,
    BringRadius = 30,
    AttackSpeed = 0.15,
    HitTwoMobs = true,
    FastAttack = false,
    FarmDistance = 50,
    FlySpeed = 80,
    BringMode = true,
}

-- // ===================== MOB DATABASE ===================== //
local MobData = {
    ["Test"] = {
        Name = "Test Zone (all mobs)",
        Level = "Mixed",
        Mobs = {"Bandit","Monkey","Gorilla","Pirate","Prisoner","Sword Bandit","Fishman Warrior","Fishman Commando","Sky Bandit"},
        QuestNPC = "Military Detective",
        QuestName = "Bandit Hunt",
        Location = nil, -- không có vị trí cố định
    },
    ["Starter Island"] = { Name="Starter Island", Level="1-15", Mobs={"Bandit","Monkey"}, QuestNPC="Military Detective", QuestName="Bandit Hunt", Location=Vector3.new(977,120,1818) },
    ["Middle Town"] = { Name="Middle Town", Level="15-30", Mobs={"Gorilla","Pirate"}, QuestNPC="Military Detective", QuestName="Gorilla Hunt", Location=Vector3.new(-1050,266,-700) },
    ["Jungle"] = { Name="Jungle", Level="30-60", Mobs={"Gorilla","Jungle Pirate"}, QuestNPC="Military Detective", QuestName="Jungle Hunt", Location=Vector3.new(-1600,172,310) },
    ["Pirate Village"] = { Name="Pirate Village", Level="60-90", Mobs={"Pirate","Pistol Pirate","Sword Pirate"}, QuestNPC="Military Detective", QuestName="Pirate Hunt", Location=Vector3.new(-2530,40,1712) },
    ["Marineford"] = { Name="Marineford", Level="120-175", Mobs={"Marine","Marine Captain","Marine Lieutenant"}, QuestNPC="Soldier", QuestName="Marine Hunt", Location=Vector3.new(4757,38,3185) },
    ["Skylands"] = { Name="Skylands", Level="190-275", Mobs={"Sky Bandit","Dark Master","Shanda"}, QuestNPC="Gatekeeper", QuestName="Skylands Quest", Location=Vector3.new(-4820,870,1817) },
    ["Prison"] = { Name="Prison", Level="90-120", Mobs={"Prisoner","Dangerous Prisoner","Sword Bandit"}, QuestNPC="Sergeant", QuestName="Prison Hunt", Location=Vector3.new(-4974,38,1873) },
    ["Colosseum"] = { Name="Colosseum", Level="225-300", Mobs={"Toga Warrior","Gladiator"}, QuestNPC="Bartolomeo", QuestName="Colosseum Quest", Location=Vector3.new(-3804,27,1020) },
    ["Magma Village"] = { Name="Magma Village", Level="300-375", Mobs={"Magma Ninja","Lava Pirate"}, QuestNPC="Magma Admiral", QuestName="Magma Hunt", Location=Vector3.new(-1128,38,-3380) },
    ["Underwater City"] = { Name="Underwater City", Level="375-450", Mobs={"Fishman Warrior","Fishman Commando","Fishman Lord"}, QuestNPC="Fishman Admiral", QuestName="Fishman Hunt", Location=Vector3.new(63400,-1900,-300) },
    ["Upper Skylands"] = { Name="Upper Skylands", Level="700-850", Mobs={"Royal Soldier","Royal Squad","Galley Pirate","Dark Soul"}, QuestNPC="Royal Soldier Officer", QuestName="Upper Skylands Quest", Location=Vector3.new(-3143,3100,3573) },
    ["Ice Castle"] = { Name="Ice Castle", Level="850-925", Mobs={"Snow Lurker","Arctic Warrior"}, QuestNPC="Ice Admiral", QuestName="Ice Castle Quest", Location=Vector3.new(-3500,3560,-3900) },
    ["Third Sea Starter"] = { Name="Third Sea - Port Town", Level="1500-1575", Mobs={"Pirate Millionaire","Golden Pirate"}, QuestNPC="Quest Giver", QuestName="Port Town Quest", Location=Vector3.new(-26505,23,4669) },
}

-- // ===================== UTILITIES ===================== //
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
    return hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart") ~= nil
end

local function Tween(obj, time, props)
    local info = TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

-- Cache folder quái
local MobFolderCache = nil
local function GetMobFolder()
    if MobFolderCache and MobFolderCache.Parent then return MobFolderCache end
    MobFolderCache = Workspace:FindFirstChild("Enemies")
        or Workspace:FindFirstChild("Mobs")
        or Workspace:FindFirstChild("_Enemies")
        or Workspace:FindFirstChild("NPCs")
        or Workspace
    return MobFolderCache
end

local function GetMobsInWorkspace(mobNames)
    local mobs = {}
    local folder = GetMobFolder()
    for _, obj in pairs(folder:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local hum = obj.Humanoid
            if hum.Health > 0 then
                local lname = obj.Name:lower()
                for _, name in pairs(mobNames) do
                    if lname:find(name:lower(), 1, true) then
                        table.insert(mobs, obj)
                        break
                    end
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
    for _, mob in pairs(GetMobsInWorkspace(mobNames)) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        if root then
            local dist = (RootPart.Position - root.Position).Magnitude
            if dist < nearestDist and dist <= maxDist then
                nearest, nearestDist = mob, dist
            end
        end
    end
    return nearest
end

-- // FlyTo KHÔNG blocking — chỉ set velocity, loop tự check khoảng cách
local function FlyTo(position)
    if not IsAlive() then return end
    local bodyVel = RootPart:FindFirstChild("__AXFly")
    if not bodyVel then
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "__AXFly"
        bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
        bodyVel.P = 5000
        bodyVel.Parent = RootPart
    end
    local bodyGyro = RootPart:FindFirstChild("__AXGyro")
    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "__AXGyro"
        bodyGyro.MaxTorque = Vector3.new(4e5,4e5,4e5)
        bodyGyro.P = 5000
        bodyGyro.Parent = RootPart
    end
    local delta = position - RootPart.Position
    local dist = delta.Magnitude
    if dist < 1 then
        bodyVel.Velocity = Vector3.new()
        return
    end
    bodyVel.Velocity = delta.Unit * math.min(Config.FlySpeed, dist * 3)
    bodyGyro.CFrame = CFrame.lookAt(RootPart.Position, position)
end

local function StopFly()
    if RootPart then
        local v = RootPart:FindFirstChild("__AXFly"); if v then v:Destroy() end
        local g = RootPart:FindFirstChild("__AXGyro"); if g then g:Destroy() end
    end
end

local function BringMobToPlayer(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root or not RootPart then return end
    local old = root:FindFirstChild("__BringPos"); if old then old:Destroy() end
    local bodyPos = Instance.new("BodyPosition")
    bodyPos.Name = "__BringPos"
    bodyPos.MaxForce = Vector3.new(1e6,1e6,1e6)
    bodyPos.P = 1e4
    -- Mang quái về sát player (bán kính nhỏ để melee đánh trúng)
    local offR = math.min(Config.BringRadius, 6)
    bodyPos.Position = RootPart.Position + Vector3.new(
        math.random(-offR, offR), 3, math.random(-offR, offR)
    )
    bodyPos.Parent = root
    task.delay(4, function() if bodyPos.Parent then bodyPos:Destroy() end end)
end

-- // TẤN CÔNG — dùng VirtualUser click (cách chuẩn cho melee/fruit)
local function SimulateAttack()
    if not IsAlive() then return end
    local char = LocalPlayer.Character
    if not char then return end

    -- Tự equip tool nếu chưa có
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            local anyTool = bp:FindFirstChildOfClass("Tool")
            if anyTool then anyTool.Parent = char; tool = anyTool end
        end
    end

    -- 1) Fire ClickDetector nếu có (exploit function)
    if tool then
        local cd = tool:FindFirstChildWhichIsA("ClickDetector", true)
        if cd and typeof(fireclickdetector) == "function" then
            pcall(fireclickdetector, cd)
        end
    end

    -- 2) Virtual click — hoạt động với Tool.Activated & skill trên hotbar
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    end)
end

-- // ===================== QUEST ===================== //
local QuestActive = false

local function FindNPC(npcName)
    -- Ưu tiên folder NPC
    local folders = {
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Enemies"),
        Workspace,
    }
    local lname = npcName:lower()
    for _, root in pairs(folders) do
        if root then
            for _, obj in pairs(root:GetDescendants()) do
                if obj:IsA("Model") and obj.Name:lower():find(lname, 1, true) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function AcceptQuest(zoneData)
    if QuestActive then return end
    local npc = FindNPC(zoneData.QuestNPC)
    if not npc then return end
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then return end

    -- Bay tới NPC
    local target = npcRoot.Position + Vector3.new(0,0,3)
    local t0 = tick()
    repeat
        if not IsAlive() then return end
        FlyTo(target)
        task.wait(0.1)
    until (RootPart.Position - target).Magnitude < 10 or tick() - t0 > 8
    StopFly()
    task.wait(0.5)

    -- Fire ProximityPrompt (cách chuẩn)
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and typeof(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
    end

    -- Fallback: fire remote quest
    local rsQuests = ReplicatedStorage:FindFirstChild("Quests")
        or ReplicatedStorage:FindFirstChild("Quest")
        or ReplicatedStorage:FindFirstChild("AcceptQuest")
    if rsQuests and rsQuests:IsA("RemoteEvent") then
        pcall(function() rsQuests:FireServer(zoneData.QuestName) end)
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
    if not zoneData then FarmRunning = false; return end

    FarmThread = task.spawn(function()
        while FarmRunning do
            -- Chờ respawn nếu chết
            if not IsAlive() then
                StopFly()
                while FarmRunning and not IsAlive() do
                    task.wait(1)
                    GetCharacter()
                end
                if not FarmRunning then break end
                task.wait(1)
            end

            -- Quest
            if Config.AutoQuest and not QuestActive then
                AcceptQuest(zoneData)
                task.wait(0.5)
            end

            local mobs = GetMobsInWorkspace(zoneData.Mobs)
            if #mobs == 0 then
                -- Không thấy quái → bay về vị trí zone (nếu có)
                if zoneData.Location then FlyTo(zoneData.Location) end
                task.wait(1)
                goto continue
            end

            -- Bring mobs
            if Config.BringMode then
                local brought = 0
                local maxBring = Config.HitTwoMobs and 2 or 1
                for _, mob in pairs(mobs) do
                    if brought >= maxBring then break end
                    local root = mob:FindFirstChild("HumanoidRootPart")
                    if root and (RootPart.Position - root.Position).Magnitude <= Config.BringRadius then
                        BringMobToPlayer(mob)
                        brought += 1
                    end
                end
            end

            -- Target gần nhất
            local target = GetNearestMob(zoneData.Mobs, Config.FarmDistance)
            if target then
                local tr = target:FindFirstChild("HumanoidRootPart")
                if tr then
                    local dist = (RootPart.Position - tr.Position).Magnitude
                    if dist > 8 then
                        FlyTo(tr.Position + Vector3.new(0,2,0))
                    else
                        StopFly()
                        -- Face target
                        RootPart.CFrame = CFrame.lookAt(RootPart.Position, tr.Position)
                        SimulateAttack()
                    end
                end
            elseif zoneData.Location then
                FlyTo(zoneData.Location)
            end

            task.wait(Config.FastAttack and 0.05 or Config.AttackSpeed)
            ::continue::
        end
        StopFly()
    end)
end

local function StopFarm()
    FarmRunning = false
    StopFly()
    if FarmThread then task.cancel(FarmThread); FarmThread = nil end
end

-- // ===================== GUI ===================== //
-- Parent fallback an toàn
local parentGui
if typeof(gethui) == "function" then
    parentGui = gethui()
else
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then parentGui = cg
    else parentGui = LocalPlayer:WaitForChild("PlayerGui") end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AxiomBF"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

-- Floating Toggle Button
local FloatBtn = Instance.new("Frame")
FloatBtn.Name = "FloatBtn"
FloatBtn.Size = UDim2.new(0, 50, 0, 50)
FloatBtn.Position = UDim2.new(0, 20, 0.5, -25)
FloatBtn.BackgroundColor3 = Color3.fromRGB(10,30,80)
FloatBtn.BorderSizePixel = 0
FloatBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner"); FloatCorner.CornerRadius = UDim.new(1,0); FloatCorner.Parent = FloatBtn
local FloatGrad = Instance.new("UIGradient")
FloatGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(0,120,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(0,60,180))})
FloatGrad.Rotation = 135; FloatGrad.Parent = FloatBtn
local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(0,180,255); FloatStroke.Thickness = 1.5; FloatStroke.Transparency = 0.3; FloatStroke.Parent = FloatBtn

local FloatLabel = Instance.new("TextLabel")
FloatLabel.Size = UDim2.new(1,0,1,0); FloatLabel.BackgroundTransparency = 1
FloatLabel.Text = "⚡"; FloatLabel.TextScaled = true; FloatLabel.Font = Enum.Font.GothamBold
FloatLabel.TextColor3 = Color3.fromRGB(255,255,255); FloatLabel.Parent = FloatBtn

local FloatBtnBtn = Instance.new("TextButton")
FloatBtnBtn.Size = UDim2.new(1,0,1,0); FloatBtnBtn.BackgroundTransparency = 1; FloatBtnBtn.Text = ""; FloatBtnBtn.Parent = FloatBtn

-- (MainFrame được tạo sau — toggle dùng FindFirstChild)
local draggingFloat, floatDragStart, floatStartPos
FloatBtnBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFloat = true; floatDragStart = input.Position; floatStartPos = FloatBtn.Position
    end
end)
FloatBtnBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if draggingFloat then
            local delta = input.Position - floatDragStart
            local totalMove = math.abs(delta.X) + math.abs(delta.Y)
            draggingFloat = false
            if totalMove < 5 then
                local mf = ScreenGui:FindFirstChild("MainFrame")
                if mf then mf.Visible = not mf.Visible end
            end
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingFloat and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - floatDragStart
        FloatBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset+delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset+delta.Y)
    end
end)
task.spawn(function()
    while true do
        Tween(FloatStroke, 0.8, {Transparency=0.0}); task.wait(0.8)
        Tween(FloatStroke, 0.8, {Transparency=0.6}); task.wait(0.8)
    end
end)

-- // MAIN WINDOW
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0,580,0,420)
MainFrame.Position = UDim2.new(0.5,-290,0.5,-210)
MainFrame.BackgroundColor3 = Color3.fromRGB(5,10,28)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,14)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0,120,255); MainStroke.Thickness = 1.5; MainStroke.Transparency = 0.2; MainStroke.Parent = MainFrame

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,50); TitleBar.BackgroundColor3 = Color3.fromRGB(0,20,60); TitleBar.BorderSizePixel = 0; TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,14)
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1,0,0.5,0); TitleFix.Position = UDim2.new(0,0,0.5,0)
TitleFix.BackgroundColor3 = Color3.fromRGB(0,20,60); TitleFix.BorderSizePixel = 0; TitleFix.Parent = TitleBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0,40,1,0); TitleIcon.Position = UDim2.new(0,10,0,0)
TitleIcon.BackgroundTransparency = 1; TitleIcon.Text = "⚡"; TitleIcon.TextScaled = true
TitleIcon.Font = Enum.Font.GothamBold; TitleIcon.TextColor3 = Color3.fromRGB(100,200,255); TitleIcon.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0,200,1,0); TitleText.Position = UDim2.new(0,55,0,0)
TitleText.BackgroundTransparency = 1; TitleText.Text = "AXIOM BF"; TitleText.TextSize = 18
TitleText.Font = Enum.Font.GothamBold; TitleText.TextColor3 = Color3.fromRGB(255,255,255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left; TitleText.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,32,0,32); CloseBtn.Position = UDim2.new(1,-42,0,9)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180,30,30); CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255); CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.BorderSizePixel = 0; CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1,0)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Drag
local dragging, dragStart, startPos
local TitleDrag = Instance.new("TextButton")
TitleDrag.Size = UDim2.new(1,-90,1,0); TitleDrag.BackgroundTransparency = 1; TitleDrag.Text = ""; TitleDrag.Parent = TitleBar
TitleDrag.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
TitleDrag.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)

-- Content layout
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1,0,1,-50); ContentArea.Position = UDim2.new(0,0,0,50)
ContentArea.BackgroundTransparency = 1; ContentArea.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,140,1,0); Sidebar.BackgroundColor3 = Color3.fromRGB(5,15,40); Sidebar.BorderSizePixel = 0; Sidebar.Parent = ContentArea
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,14)
local SideFix = Instance.new("Frame")
SideFix.Size = UDim2.new(0.5,0,1,0); SideFix.Position = UDim2.new(0.5,0,0,0)
SideFix.BackgroundColor3 = Color3.fromRGB(5,15,40); SideFix.BorderSizePixel = 0; SideFix.Parent = Sidebar
local SideList = Instance.new("UIListLayout"); SideList.SortOrder = Enum.SortOrder.LayoutOrder; SideList.Padding = UDim.new(0,6); SideList.Parent = Sidebar
local SidePad = Instance.new("UIPadding"); SidePad.PaddingTop = UDim.new(0,12); SidePad.PaddingLeft = UDim.new(0,8); SidePad.PaddingRight = UDim.new(0,8); SidePad.Parent = Sidebar

local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1,-148,1,0); RightPanel.Position = UDim2.new(0,148,0,0)
RightPanel.BackgroundTransparency = 1; RightPanel.Parent = ContentArea

local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(0,1,1,-20); Separator.Position = UDim2.new(0,140,0,10)
Separator.BackgroundColor3 = Color3.fromRGB(0,80,200); Separator.BorderSizePixel = 0; Separator.BackgroundTransparency = 0.7; Separator.Parent = ContentArea

-- Tab system
local Tabs, ActiveTab = {}, nil

local function CreateTabButton(name, icon, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1,0,0,44); Btn.BackgroundColor3 = Color3.fromRGB(10,25,70)
    Btn.Text = ""; Btn.BorderSizePixel = 0; Btn.LayoutOrder = order; Btn.Parent = Sidebar
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,10)

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0,30,1,0); Icon.Position = UDim2.new(0,6,0,0)
    Icon.BackgroundTransparency = 1; Icon.Text = icon; Icon.TextSize = 16
    Icon.Font = Enum.Font.GothamBold; Icon.TextColor3 = Color3.fromRGB(100,160,255); Icon.Parent = Btn

    local Txt = Instance.new("TextLabel")
    Txt.Size = UDim2.new(1,-40,1,0); Txt.Position = UDim2.new(0,38,0,0)
    Txt.BackgroundTransparency = 1; Txt.Text = name; Txt.TextSize = 13
    Txt.Font = Enum.Font.GothamSemibold; Txt.TextColor3 = Color3.fromRGB(180,210,255)
    Txt.TextXAlignment = Enum.TextXAlignment.Left; Txt.Parent = Btn

    local ActiveBar = Instance.new("Frame")
    ActiveBar.Size = UDim2.new(0,3,0.6,0); ActiveBar.Position = UDim2.new(0,-8,0.2,0)
    ActiveBar.BackgroundColor3 = Color3.fromRGB(0,160,255); ActiveBar.BorderSizePixel = 0
    ActiveBar.Visible = false; ActiveBar.Parent = Btn
    Instance.new("UICorner", ActiveBar).CornerRadius = UDim.new(1,0)

    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Size = UDim2.new(1,-8,1,-12); ContentFrame.Position = UDim2.new(0,4,0,6)
    ContentFrame.BackgroundTransparency = 1; ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 3; ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(0,120,255)
    ContentFrame.CanvasSize = UDim2.new(0,0,0,0) -- auto-resize nhờ UIListLayout
    ContentFrame.Visible = false; ContentFrame.Parent = RightPanel

    local CL = Instance.new("UIListLayout")
    CL.SortOrder = Enum.SortOrder.LayoutOrder; CL.Padding = UDim.new(0,8); CL.Parent = ContentFrame
    CL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentFrame.CanvasSize = UDim2.new(0,0,0,CL.AbsoluteContentSize.Y + 20)
    end)
    local CP = Instance.new("UIPadding"); CP.PaddingTop = UDim.new(0,8); CP.PaddingRight = UDim.new(0,4); CP.Parent = ContentFrame

    Tabs[name] = {Button=Btn, Content=ContentFrame, ActiveBar=ActiveBar, BtnText=Txt}
    Btn.MouseButton1Click:Connect(function()
        for _, tab in pairs(Tabs) do
            tab.Content.Visible = false; tab.ActiveBar.Visible = false
            Tween(tab.Button, 0.2, {BackgroundColor3=Color3.fromRGB(10,25,70)})
            tab.BtnText.TextColor3 = Color3.fromRGB(180,210,255)
        end
        ContentFrame.Visible = true; ActiveBar.Visible = true
        Tween(Btn, 0.2, {BackgroundColor3=Color3.fromRGB(0,50,150)})
        Txt.TextColor3 = Color3.fromRGB(255,255,255)
        ActiveTab = name
    end)
    return ContentFrame
end

-- UI Components
local function CreateSectionLabel(parent, text, order)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1,0,0,24); L.BackgroundTransparency = 1
    L.Text = "  "..text:upper(); L.TextSize = 10; L.Font = Enum.Font.GothamBold
    L.TextColor3 = Color3.fromRGB(0,150,255); L.TextXAlignment = Enum.TextXAlignment.Left
    L.LayoutOrder = order; L.Parent = parent; return L
end

local function CreateToggle(parent, text, defaultVal, callback, order)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1,0,0,40); Row.BackgroundColor3 = Color3.fromRGB(10,22,55)
    Row.BorderSizePixel = 0; Row.LayoutOrder = order; Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,8)
    local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(0,60,150); st.Thickness = 1; st.Transparency = 0.6; st.Parent = Row

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1,-60,1,0); Lbl.Position = UDim2.new(0,14,0,0)
    Lbl.BackgroundTransparency = 1; Lbl.Text = text; Lbl.TextSize = 13
    Lbl.Font = Enum.Font.Gotham; Lbl.TextColor3 = Color3.fromRGB(200,225,255)
    Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Row

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(0,44,0,22); Bg.Position = UDim2.new(1,-54,0.5,-11)
    Bg.BackgroundColor3 = defaultVal and Color3.fromRGB(0,100,255) or Color3.fromRGB(30,40,70)
    Bg.BorderSizePixel = 0; Bg.Parent = Row
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1,0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0,16,0,16)
    Knob.Position = defaultVal and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    Knob.BackgroundColor3 = Color3.fromRGB(255,255,255); Knob.BorderSizePixel = 0; Knob.Parent = Bg
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

    local state = defaultVal
    local Click = Instance.new("TextButton")
    Click.Size = UDim2.new(1,0,1,0); Click.BackgroundTransparency = 1; Click.Text = ""; Click.Parent = Row
    Click.MouseButton1Click:Connect(function()
        state = not state
        Tween(Bg, 0.2, {BackgroundColor3 = state and Color3.fromRGB(0,100,255) or Color3.fromRGB(30,40,70)})
        Tween(Knob, 0.2, {Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)})
        callback(state)
    end)
    return Row
end

local function CreateSlider(parent, text, min, max, defaultVal, callback, order)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1,0,0,58); Row.BackgroundColor3 = Color3.fromRGB(10,22,55)
    Row.BorderSizePixel = 0; Row.LayoutOrder = order; Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,8)
    local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(0,60,150); st.Thickness = 1; st.Transparency = 0.6; st.Parent = Row

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1,-60,0,22); Lbl.Position = UDim2.new(0,14,0,4)
    Lbl.BackgroundTransparency = 1; Lbl.Text = text; Lbl.TextSize = 12
    Lbl.Font = Enum.Font.Gotham; Lbl.TextColor3 = Color3.fromRGB(200,225,255)
    Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Row

    local Val = Instance.new("TextLabel")
    Val.Size = UDim2.new(0,50,0,22); Val.Position = UDim2.new(1,-60,0,4)
    Val.BackgroundTransparency = 1; Val.Text = tostring(defaultVal); Val.TextSize = 12
    Val.Font = Enum.Font.GothamBold; Val.TextColor3 = Color3.fromRGB(0,180,255)
    Val.TextXAlignment = Enum.TextXAlignment.Right; Val.Parent = Row

    local SBg = Instance.new("Frame")
    SBg.Size = UDim2.new(1,-28,0,6); SBg.Position = UDim2.new(0,14,0,36)
    SBg.BackgroundColor3 = Color3.fromRGB(20,40,90); SBg.BorderSizePixel = 0; SBg.Parent = Row
    Instance.new("UICorner", SBg).CornerRadius = UDim.new(1,0)

    local initScale = (defaultVal - min) / (max - min)
    local SFill = Instance.new("Frame")
    SFill.Size = UDim2.new(initScale,0,1,0); SFill.BackgroundColor3 = Color3.fromRGB(0,120,255)
    SFill.BorderSizePixel = 0; SFill.Parent = SBg
    Instance.new("UICorner", SFill).CornerRadius = UDim.new(1,0)

    local SKnob = Instance.new("Frame")
    SKnob.Size = UDim2.new(0,14,0,14); SKnob.Position = UDim2.new(initScale,-7,0.5,-7)
    SKnob.BackgroundColor3 = Color3.fromRGB(255,255,255); SKnob.BorderSizePixel = 0; SKnob.Parent = SBg
    Instance.new("UICorner", SKnob).CornerRadius = UDim.new(1,0)

    local isDrag = false
    local SBtn = Instance.new("TextButton")
    SBtn.Size = UDim2.new(1,0,0,20); SBtn.Position = UDim2.new(0,0,0,-7)
    SBtn.BackgroundTransparency = 1; SBtn.Text = ""; SBtn.Parent = SBg

    local function update(inputX)
        local x0 = SBg.AbsolutePosition.X
        local w = SBg.AbsoluteSize.X
        if w <= 0 then return end
        local rel = math.clamp((inputX - x0)/w, 0, 1)
        local v = math.floor(min + rel*(max-min))
        Val.Text = tostring(v); SFill.Size = UDim2.new(rel,0,1,0); SKnob.Position = UDim2.new(rel,-7,0.5,-7)
        callback(v)
    end
    SBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDrag = true; update(input.Position.X) end
    end)
    SBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDrag = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDrag and input.UserInputType == Enum.UserInputType.MouseMovement then update(input.Position.X) end
    end)
    return Row
end

local function CreateDropdown(parent, text, options, defaultVal, callback, order)
    local isOpen, selected = false, defaultVal
    local Cont = Instance.new("Frame")
    Cont.Size = UDim2.new(1,0,0,42); Cont.BackgroundColor3 = Color3.fromRGB(10,22,55)
    Cont.BorderSizePixel = 0; Cont.LayoutOrder = order; Cont.ClipsDescendants = false; Cont.Parent = parent
    Instance.new("UICorner", Cont).CornerRadius = UDim.new(0,8)
    local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(0,60,150); st.Thickness = 1; st.Transparency = 0.6; st.Parent = Cont

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(0,120,0,42); Lbl.Position = UDim2.new(0,14,0,0)
    Lbl.BackgroundTransparency = 1; Lbl.Text = text; Lbl.TextSize = 12
    Lbl.Font = Enum.Font.Gotham; Lbl.TextColor3 = Color3.fromRGB(200,225,255)
    Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Cont

    local Sel = Instance.new("TextButton")
    Sel.Size = UDim2.new(1,-140,0,30); Sel.Position = UDim2.new(0,136,0,6)
    Sel.BackgroundColor3 = Color3.fromRGB(0,40,120); Sel.Text = selected.." ▾"; Sel.TextSize = 11
    Sel.Font = Enum.Font.GothamSemibold; Sel.TextColor3 = Color3.fromRGB(100,200,255); Sel.BorderSizePixel = 0; Sel.Parent = Cont
    Instance.new("UICorner", Sel).CornerRadius = UDim.new(0,6)

    local DL = Instance.new("Frame")
    DL.Size = UDim2.new(1,-140,0,math.min(#options,5)*30+8); DL.Position = UDim2.new(0,136,0,44)
    DL.BackgroundColor3 = Color3.fromRGB(5,15,45); DL.BorderSizePixel = 0; DL.Visible = false; DL.ZIndex = 10; DL.Parent = Cont
    Instance.new("UICorner", DL).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", DL).Color = Color3.fromRGB(0,80,200)
    local DLList = Instance.new("UIListLayout"); DLList.Padding = UDim.new(0,2); DLList.Parent = DL
    Instance.new("UIPadding", DL).PaddingTop = UDim.new(0,4)

    for _, opt in pairs(options) do
        local O = Instance.new("TextButton")
        O.Size = UDim2.new(1,-8,0,26); O.BackgroundTransparency = 1; O.Text = opt; O.TextSize = 11
        O.Font = Enum.Font.Gotham; O.TextColor3 = Color3.fromRGB(180,220,255); O.ZIndex = 11; O.Parent = DL
        O.MouseEnter:Connect(function() O.BackgroundTransparency = 0.6; O.BackgroundColor3 = Color3.fromRGB(0,60,180) end)
        O.MouseLeave:Connect(function() O.BackgroundTransparency = 1 end)
        O.MouseButton1Click:Connect(function()
            selected = opt; Sel.Text = opt.." ▾"; DL.Visible = false; isOpen = false
            Cont.Size = UDim2.new(1,0,0,42); callback(opt)
        end)
    end

    Sel.MouseButton1Click:Connect(function()
        isOpen = not isOpen; DL.Visible = isOpen
        Cont.Size = UDim2.new(1,0,0, isOpen and (42 + math.min(#options,5)*30 + 12) or 42)
    end)
    return Cont
end

local function CreateButton(parent, text, icon, callback, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1,0,0,38); Btn.BackgroundColor3 = Color3.fromRGB(0,70,200)
    Btn.Text = (icon and icon.."  " or "")..text; Btn.TextSize = 13
    Btn.Font = Enum.Font.GothamBold; Btn.TextColor3 = Color3.fromRGB(255,255,255)
    Btn.BorderSizePixel = 0; Btn.LayoutOrder = order; Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,8)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(0,120,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(0,60,200))})
    g.Rotation = 90; g.Parent = Btn
    Btn.MouseEnter:Connect(function() Tween(Btn,0.15,{BackgroundColor3=Color3.fromRGB(0,100,255)}) end)
    Btn.MouseLeave:Connect(function() Tween(Btn,0.15,{BackgroundColor3=Color3.fromRGB(0,70,200)}) end)
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

-- // BUILD TABS
local FarmContent = CreateTabButton("Farm", "⚔️", 1)
CreateSectionLabel(FarmContent, "🌾 Farm Zone", 1)

local zoneNames = {}
for k in pairs(MobData) do table.insert(zoneNames, k) end
table.sort(zoneNames)

local selectedZone = "Test"
CreateDropdown(FarmContent, "Select Zone", zoneNames, "Test", function(val) selectedZone = val end, 2)

CreateSectionLabel(FarmContent, "⚙️ Farm Options", 5)
CreateToggle(FarmContent, "Auto Quest", Config.AutoQuest, function(v) Config.AutoQuest = v end, 6)
CreateToggle(FarmContent, "Bring Mobs", Config.BringMode, function(v) Config.BringMode = v end, 7)
CreateToggle(FarmContent, "Hit 2 Mobs", Config.HitTwoMobs, function(v) Config.HitTwoMobs = v end, 8)

CreateSectionLabel(FarmContent, "🚀 Controls", 10)
local farmToggleState = false
local FarmBtnRef

FarmBtnRef = CreateButton(FarmContent, "START FARM", "▶", function()
    farmToggleState = not farmToggleState
    if farmToggleState then
        FarmBtnRef.Text = "⏹  STOP FARM"
        Tween(FarmBtnRef, 0.2, {BackgroundColor3 = Color3.fromRGB(180,30,30)})
        StartFarm(selectedZone)
    else
        FarmBtnRef.Text = "▶  START FARM"
        Tween(FarmBtnRef, 0.2, {BackgroundColor3 = Color3.fromRGB(0,70,200)})
        StopFarm()
    end
end, 11)

local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1,0,0,40); StatusFrame.BackgroundColor3 = Color3.fromRGB(5,15,40)
StatusFrame.BorderSizePixel = 0; StatusFrame.LayoutOrder = 12; StatusFrame.Parent = FarmContent
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0,8)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1,-10,1,0); StatusLabel.Position = UDim2.new(0,10,0,0)
StatusLabel.BackgroundTransparency = 1; StatusLabel.Text = "⬤  Idle"; StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.GothamSemibold; StatusLabel.TextColor3 = Color3.fromRGB(100,150,255)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left; StatusLabel.Parent = StatusFrame

task.spawn(function()
    while true do
        task.wait(0.5)
        if FarmRunning then
            local zone = MobData[selectedZone]
            StatusLabel.Text = "⬤  Farming: "..(zone and zone.Name or selectedZone)
            StatusLabel.TextColor3 = Color3.fromRGB(0,255,120)
        else
            StatusLabel.Text = "⬤  Idle"
            StatusLabel.TextColor3 = Color3.fromRGB(100,150,255)
        end
    end
end)

-- SETTINGS TAB
local SettingsContent = CreateTabButton("Settings", "⚙️", 2)
CreateSectionLabel(SettingsContent, "⚡ Combat", 1)
CreateToggle(SettingsContent, "Fast Attack", Config.FastAttack, function(v) Config.FastAttack = v end, 2)
CreateSlider(SettingsContent, "Attack Speed (s)", 5, 100, 15, function(v) Config.AttackSpeed = v/100 end, 3)

CreateSectionLabel(SettingsContent, "🎯 Detection", 6)
CreateSlider(SettingsContent, "Farm Distance", 20, 200, Config.FarmDistance, function(v) Config.FarmDistance = v end, 7)
CreateSlider(SettingsContent, "Bring Radius", 10, 100, Config.BringRadius, function(v) Config.BringRadius = v end, 8)

CreateSectionLabel(SettingsContent, "✈️ Movement", 11)
CreateSlider(SettingsContent, "Fly Speed", 20, 300, Config.FlySpeed, function(v) Config.FlySpeed = v end, 12)

CreateSectionLabel(SettingsContent, "💡 Misc", 15)
CreateButton(SettingsContent, "Teleport to Zone", "📍", function()
    local zone = MobData[selectedZone]
    if zone and zone.Location and IsAlive() then
        StopFly()
        RootPart.CFrame = CFrame.new(zone.Location)
    end
end, 16)
CreateButton(SettingsContent, "Reset Character", "🔄", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end, 17)

-- Active first tab
Tabs["Farm"].Content.Visible = true
Tabs["Farm"].ActiveBar.Visible = true
Tween(Tabs["Farm"].Button, 0.2, {BackgroundColor3=Color3.fromRGB(0,50,150)})
Tabs["Farm"].BtnText.TextColor3 = Color3.fromRGB(255,255,255)
ActiveTab = "Farm"

-- Character respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    QuestActive = false
end)

print("✅ Axiom BF Script loaded (fixed build)")
