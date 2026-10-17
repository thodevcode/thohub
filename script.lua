-- // ============================================================
-- //  THO HUB  |  VERSION: V3
-- //  Blox Fruits Auto Farm (Level 1 → 2800) - Full Database Edition
-- // ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- // ===================== CONFIG =====================
local Config = {
    AutoFarmLevel   = false,
    AutoFarmBoss    = false,

    SelectedWeapon  = "Melee",      -- Melee | Sword | Fruit | Gun
    SelectedBoss    = nil,

    AutoQuest       = true,
    BringMobs       = true,
    BringRadius     = 30,
    AttackDistance  = 8,            -- melee range
    LongRangeAttack = false,        -- "Đánh xa"
    LongRangeDist   = 40,

    FastAttack      = false,
    AttackDelay     = 0.15,
    FlySpeed        = 90,

    FarmDistance    = 60,           -- max distance to search mobs
}

-- // ===================== SAFE CHARACTER =====================
local Character, Humanoid, RootPart

local function RefreshCharacter()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        RootPart = Character:FindFirstChild("HumanoidRootPart")
    end
end

local function IsAlive()
    RefreshCharacter()
    return Character and Humanoid and Humanoid.Health > 0 and RootPart ~= nil
end

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    RootPart  = char:WaitForChild("HumanoidRootPart")
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if not IsAlive() then RefreshCharacter() end
    end
end)

-- // ===================== UTILITY =====================
local function Tween(obj, time, props)
    local info = TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function GetMobFolder()
    return Workspace:FindFirstChild("Enemies")
        or Workspace:FindFirstChild("Mobs")
        or Workspace:FindFirstChild("_Enemies")
        or Workspace
end

local function IsMob(obj)
    return obj:IsA("Model")
        and obj:FindFirstChild("Humanoid")
        and obj:FindFirstChild("HumanoidRootPart")
        and obj.Humanoid.Health > 0
end

-- Tìm quái theo danh sách tên (substring, không phân biệt hoa thường)
local function GetMobsByNames(nameList)
    if not nameList then return {} end
    local folder = GetMobFolder()
    local result = {}
    for _, obj in pairs(folder:GetDescendants()) do
        if IsMob(obj) then
            local lname = obj.Name:lower()
            for _, target in pairs(nameList) do
                if lname:find(target:lower(), 1, true) then
                    table.insert(result, obj)
                    break
                end
            end
        end
    end
    return result
end

local function GetNearestMob(nameList, maxDist)
    if not IsAlive() then return nil end
    maxDist = maxDist or Config.FarmDistance
    local best, bestDist = nil, math.huge
    for _, mob in pairs(GetMobsByNames(nameList)) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        if root then
            local d = (RootPart.Position - root.Position).Magnitude
            if d < bestDist and d <= maxDist then
                best, bestDist = mob, d
            end
        end
    end
    return best
end

-- ===================== FLY =====================
local function FlyTo(position)
    if not IsAlive() then return end

    local bv = RootPart:FindFirstChild("__ThoFly")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name     = "__ThoFly"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.P        = 3000
        bv.Parent   = RootPart
    end

    local bg = RootPart:FindFirstChild("__ThoGyro")
    if not bg then
        bg = Instance.new("BodyGyro")
        bg.Name      = "__ThoGyro"
        bg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
        bg.P         = 3000
        bg.Parent    = RootPart
    end

    local delta = position - RootPart.Position
    local dist  = delta.Magnitude

    if dist < 1 then
        bv.Velocity = Vector3.zero
        return
    end

    bv.Velocity = delta.Unit * math.min(Config.FlySpeed, dist * 3)
    bg.CFrame   = CFrame.lookAt(RootPart.Position, position)
end

local function StopFly()
    if RootPart then
        local bv = RootPart:FindFirstChild("__ThoFly")
        local bg = RootPart:FindFirstChild("__ThoGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
end

-- ===================== BRING MOB =====================
local function BringMob(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root or not RootPart then return end

    local old = root:FindFirstChild("__ThoBring")
    if old then old:Destroy() end

    local bp = Instance.new("BodyPosition")
    bp.Name     = "__ThoBring"
    bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bp.P        = 8000

    local r = math.min(Config.BringRadius, 6)
    bp.Position = RootPart.Position + Vector3.new(
        math.random(-r, r),
        3,
        math.random(-r, r)
    )
    bp.Parent = root

    task.delay(3, function()
        if bp.Parent then bp:Destroy() end
    end)
end

-- ===================== WEAPON =====================
local function GetToolType(tool)
    local n = tool.Name:lower()
    if n:find("sword") or n:find("katana") or n:find("blade")
    or n:find("saber") or n:find("cutlass") or n:find("dark blade") then
        return "Sword"
    elseif n:find("gun") or n:find("pistol") or n:find("rifle")
    or n:find("cannon") or n:find("bazooka") or n:find("slingshot") then
        return "Gun"
    elseif n:find("fruit") or n:find("bomb") or n:find("chop")
    or n:find("flame") or n:find("ice") or n:find("light") then
        return "Fruit"
    end
    return "Melee"
end

local function EquipWeapon()
    if not IsAlive() then return nil end
    local char = Character

    local current = char:FindFirstChildOfClass("Tool")
    if current and GetToolType(current) == Config.SelectedWeapon then
        return current
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return current end

    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and GetToolType(tool) == Config.SelectedWeapon then
            tool.Parent = char
            return tool
        end
    end
    return current
end

-- ===================== ATTACK =====================
local function SimulateAttack(targetRoot)
    if not IsAlive() then return end

    local tool = EquipWeapon()
    if not tool then return end

    if targetRoot then
        RootPart.CFrame = CFrame.lookAt(RootPart.Position, targetRoot.Position)
    end

    local cd = tool:FindFirstChildWhichIsA("ClickDetector", true)
    if cd and typeof(fireclickdetector) == "function" then
        pcall(fireclickdetector, cd)
    end

    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)

    pcall(function()
        if tool.Activate then
            tool:Activate()
        end
    end)
end

-- ===================== QUEST =====================
local QuestActive = false

local function FindNPC(npcName)
    if not npcName then return nil end
    local lname = npcName:lower()
    local folders = {
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Enemies"),
        Workspace,
    }
    for _, folder in pairs(folders) do
        if folder then
            for _, obj in pairs(folder:GetDescendants()) do
                if obj:IsA("Model") and obj.Name:lower():find(lname, 1, true) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function AcceptQuest(questNPCName, questName)
    if QuestActive or not questNPCName then return end

    local npc = FindNPC(questNPCName)
    if not npc then return end

    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then return end

    local target = npcRoot.Position + Vector3.new(0, 0, 3)
    local t0 = tick()
    repeat
        if not IsAlive() then return end
        FlyTo(target)
        task.wait(0.1)
    until (RootPart.Position - target).Magnitude < 10 or tick() - t0 > 8
    StopFly()
    task.wait(0.3)

    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and typeof(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
    end

    local comm = ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
    if comm then
        pcall(function()
            comm:InvokeServer("StartQuest", questName)
        end)
    end

    QuestActive = true
    task.delay(300, function() QuestActive = false end)
end

-- // ============================================================
-- //  DATABASE - ĐẦY ĐỦ 3 SEA
-- // ============================================================

-- Cấu trúc: [Sea] = { [IslandName] = { MinLv, MaxLv, Mobs, QuestNPC, Location } }
local FullDatabase = {
    -- ===================== SEA 1 (Level 1 - 700) =====================
    [1] = {
        {
            Name = "Starter Island (Pirate)", MinLv = 1, MaxLv = 10,
            Mobs = {"Bandit"},
            QuestNPC = "Bandit Quest Giver",
            Location = Vector3.new(1040, 60, 1320),
        },
        {
            Name = "Starter Island (Marine)", MinLv = 1, MaxLv = 10,
            Mobs = {"Trainee"},
            QuestNPC = "Marine Quest Giver",
            Location = Vector3.new(976, 60, 1444),
        },
        {
            Name = "Jungle", MinLv = 10, MaxLv = 30,
            Mobs = {"Monkey", "Gorilla"},
            QuestNPC = "Jungle Quest Giver",
            Location = Vector3.new(-1600, 172, 310),
        },
        {
            Name = "Pirate Village", MinLv = 30, MaxLv = 60,
            Mobs = {"Pirate", "Brute"},
            QuestNPC = "Pirate Village Quest Giver",
            Location = Vector3.new(-2530, 40, 1712),
        },
        {
            Name = "Desert", MinLv = 60, MaxLv = 90,
            Mobs = {"Desert Bandit", "Desert Officer"},
            QuestNPC = "Desert Quest Giver",
            Location = Vector3.new(-1150, 50, -550),
        },
        {
            Name = "Frozen Village", MinLv = 90, MaxLv = 120,
            Mobs = {"Snow Bandit", "Snowman"},
            QuestNPC = "Frozen Village Quest Giver",
            Location = Vector3.new(-100, 50, -1100),
        },
        {
            Name = "Marine Fortress", MinLv = 120, MaxLv = 150,
            Mobs = {"Chief Petty Officer"},
            QuestNPC = "Marine Fortress Quest Giver",
            Location = Vector3.new(-4950, 30, 4200),
        },
        {
            Name = "Middle Town", MinLv = 100, MaxLv = 150,
            Mobs = {"Saw"},
            QuestNPC = "Middle Town Quest Giver",
            Location = Vector3.new(-1050, 266, -700),
        },
        {
            Name = "Skylands", MinLv = 150, MaxLv = 190,
            Mobs = {"Sky Bandit", "Dark Master"},
            QuestNPC = "Skylands Quest Giver",
            Location = Vector3.new(-4820, 870, 1817),
        },
        {
            Name = "Prison", MinLv = 190, MaxLv = 250,
            Mobs = {"Prisoner", "Dangerous Prisoner"},
            QuestNPC = "Prison Quest Giver",
            Location = Vector3.new(-4974, 38, 1873),
        },
        {
            Name = "Colosseum", MinLv = 250, MaxLv = 300,
            Mobs = {"Toga Warrior", "Gladiator"},
            QuestNPC = "Colosseum Quest Giver",
            Location = Vector3.new(-3804, 27, 1020),
        },
        {
            Name = "Magma Village", MinLv = 300, MaxLv = 375,
            Mobs = {"Military Soldier", "Military Spy"},
            QuestNPC = "Magma Village Quest Giver",
            Location = Vector3.new(-1128, 38, -3380),
        },
        {
            Name = "Underwater City", MinLv = 375, MaxLv = 450,
            Mobs = {"Fishman Warrior", "Fishman Commando"},
            QuestNPC = "Underwater City Quest Giver",
            Location = Vector3.new(63400, -1900, -300),
        },
        {
            Name = "Upper Skylands", MinLv = 450, MaxLv = 625,
            Mobs = {"Shanda", "Royal Squad", "Royal Soldier", "God's Guard"},
            QuestNPC = "Upper Skylands Quest Giver",
            Location = Vector3.new(-3143, 3100, 3573),
        },
        {
            Name = "Fountain City", MinLv = 625, MaxLv = 700,
            Mobs = {"Galley Pirate", "Galley Captain"},
            QuestNPC = "Fountain City Quest Giver",
            Location = Vector3.new(-5050, 30, -3200),
        },
    },

    -- ===================== SEA 2 (Level 700 - 1500) =====================
    [2] = {
        {
            Name = "Kingdom of Rose", MinLv = 700, MaxLv = 875,
            Mobs = {"Raider", "Mercenary", "Swan Pirate", "Factory Staff"},
            QuestNPC = "Kingdom of Rose Quest Giver",
            Location = Vector3.new(-2600, 50, -100),
        },
        {
            Name = "Green Zone", MinLv = 875, MaxLv = 950,
            Mobs = {"Marine Lieutenant", "Marine Captain"},
            QuestNPC = "Green Zone Quest Giver",
            Location = Vector3.new(-3300, 50, 2200),
        },
        {
            Name = "Graveyard Island", MinLv = 950, MaxLv = 1000,
            Mobs = {"Zombie", "Vampire"},
            QuestNPC = "Graveyard Quest Giver",
            Location = Vector3.new(-3100, 50, 3500),
        },
        {
            Name = "Snow Mountain", MinLv = 1000, MaxLv = 1100,
            Mobs = {"Snow Trooper", "Winter Warrior"},
            QuestNPC = "Snow Mountain Quest Giver",
            Location = Vector3.new(-1500, 50, 4500),
        },
        {
            Name = "Hot and Cold (Cold)", MinLv = 1100, MaxLv = 1175,
            Mobs = {"Lab Subordinate", "Horned Warrior"},
            QuestNPC = "Ice Quest Giver",
            Location = Vector3.new(-500, 50, 5000),
        },
        {
            Name = "Hot and Cold (Hot)", MinLv = 1175, MaxLv = 1250,
            Mobs = {"Magma Ninja", "Lava Pirate"},
            QuestNPC = "Fire Quest Giver",
            Location = Vector3.new(-200, 50, 5200),
        },
        {
            Name = "Cursed Ship", MinLv = 1250, MaxLv = 1350,
            Mobs = {"Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer"},
            QuestNPC = "Cursed Ship Quest Giver",
            Location = Vector3.new(-400, 50, 5800),
        },
        {
            Name = "Ice Castle", MinLv = 1350, MaxLv = 1425,
            Mobs = {"Arctic Warrior", "Snow Lurker"},
            QuestNPC = "Ice Castle Quest Giver",
            Location = Vector3.new(-3500, 3560, -3900),
        },
        {
            Name = "Forgotten Island", MinLv = 1425, MaxLv = 1500,
            Mobs = {"Sea Soldier", "Water Fighter"},
            QuestNPC = "Forgotten Quest Giver",
            Location = Vector3.new(-3000, 50, 6000),
        },
    },

    -- ===================== SEA 3 (Level 1500 - 2800) =====================
    [3] = {
        {
            Name = "Port Town", MinLv = 1500, MaxLv = 1575,
            Mobs = {"Pirate Millionaire", "Pistol Billionaire"},
            QuestNPC = "Pirate Port Quest Giver",
            Location = Vector3.new(-26505, 23, 4669),
        },
        {
            Name = "Hydra Island", MinLv = 1575, MaxLv = 1700,
            Mobs = {"Dragon Crew Warrior", "Dragon Crew Archer", "Female Islander", "Giant Islander"},
            QuestNPC = "Hydra Town Quest Giver",
            Location = Vector3.new(-28000, 50, 5000),
        },
        {
            Name = "Great Tree", MinLv = 1700, MaxLv = 1775,
            Mobs = {"Marine Commodore", "Marine Rear Admiral"},
            QuestNPC = "Great Tree Quest Giver",
            Location = Vector3.new(-29000, 100, 5500),
        },
        {
            Name = "Floating Turtle", MinLv = 1775, MaxLv = 1975,
            Mobs = {"Fishman Raider", "Fishman Captain", "Forest Pirate", "Mythological Pirate", "Jungle Pirate"},
            QuestNPC = "Floating Turtle Quest Giver",
            Location = Vector3.new(-30000, 100, 6000),
        },
        {
            Name = "Haunted Castle", MinLv = 1975, MaxLv = 2075,
            Mobs = {"Living Zombie", "Demonic Soul", "Posessed Mummy"},
            QuestNPC = "Haunted Castle Quest Giver",
            Location = Vector3.new(-31000, 100, 6500),
        },
        {
            Name = "Sea of Treats", MinLv = 2075, MaxLv = 2450,
            Mobs = {"Peanut President", "Cookie Crafter", "Candy Pirate"},
            QuestNPC = "Cake Quest Giver 1",
            Location = Vector3.new(-32000, 100, 7000),
        },
        {
            Name = "Tiki Outpost", MinLv = 2450, MaxLv = 2600,
            Mobs = {"Island Boy", "Island Champion"},
            QuestNPC = "Tiki Outpost Quest Giver",
            Location = Vector3.new(-33000, 100, 7500),
        },
        {
            Name = "Submerged Island", MinLv = 2600, MaxLv = 2800,
            Mobs = {"Reef Bandit", "Coral Pirate", "Sea Chanter"},
            QuestNPC = "Submerged Quest Giver",
            Location = Vector3.new(-34000, 100, 8000),
        },
    },
}

-- Boss Database
local BossDatabase = {
    -- Sea 1
    { Name = "Gorilla King",    Level = 25,  Sea = 1, Location = "Jungle",          QuestNPC = "Jungle Quest Giver" },
    { Name = "Chef",            Level = 55,  Sea = 1, Location = "Pirate Village",  QuestNPC = "Pirate Village Quest Giver" },
    { Name = "Yeti",            Level = 105, Sea = 1, Location = "Frozen Village",  QuestNPC = "Frozen Village Quest Giver" },
    { Name = "Vice Admiral",    Level = 130, Sea = 1, Location = "Marine Fortress", QuestNPC = "Marine Fortress Quest Giver" },
    { Name = "Warden",          Level = 220, Sea = 1, Location = "Prison",          QuestNPC = "Prison Quest Giver" },
    { Name = "Chief Warden",    Level = 230, Sea = 1, Location = "Prison",          QuestNPC = "Prison Quest Giver" },
    { Name = "Swan",            Level = 240, Sea = 1, Location = "Prison",          QuestNPC = "Prison Quest Giver" },
    { Name = "Magma Admiral",   Level = 350, Sea = 1, Location = "Magma Village",   QuestNPC = "Magma Village Quest Giver" },
    { Name = "Fishman Lord",    Level = 425, Sea = 1, Location = "Underwater City", QuestNPC = "Underwater City Quest Giver" },
    { Name = "Wysper",          Level = 500, Sea = 1, Location = "Upper Skylands",  QuestNPC = "Upper Skylands Quest Giver" },
    { Name = "Thunder God",     Level = 575, Sea = 1, Location = "Upper Skylands",  QuestNPC = "Upper Skylands Quest Giver" },
    { Name = "Cyborg",          Level = 675, Sea = 1, Location = "Fountain City",   QuestNPC = "Fountain City Quest Giver" },

    -- Sea 2
    { Name = "Diamond",         Level = 750,  Sea = 2, Location = "Kingdom of Rose", QuestNPC = "Kingdom of Rose Quest Giver" },
    { Name = "Jeremy",          Level = 850,  Sea = 2, Location = "Kingdom of Rose", QuestNPC = "Kingdom of Rose Quest Giver" },
    { Name = "Orbitus",         Level = 925,  Sea = 2, Location = "Green Zone",      QuestNPC = "Green Zone Quest Giver" },
    { Name = "Smoke Admiral",   Level = 1150, Sea = 2, Location = "Hot and Cold",    QuestNPC = "Fire Quest Giver" },
    { Name = "Cursed Captain",  Level = 1325, Sea = 2, Location = "Cursed Ship",     QuestNPC = "Cursed Ship Quest Giver" },
    { Name = "Awakened Ice Admiral", Level = 1400, Sea = 2, Location = "Ice Castle", QuestNPC = "Ice Castle Quest Giver" },
    { Name = "Tide Keeper",     Level = 1475, Sea = 2, Location = "Forgotten Island", QuestNPC = "Forgotten Quest Giver" },
    { Name = "Don Swan",        Level = 1000, Sea = 2, Location = "Mansion",         QuestNPC = "Kingdom of Rose Quest Giver" },

    -- Sea 3
    { Name = "Stone",           Level = 1550, Sea = 3, Location = "Port Town",        QuestNPC = "Pirate Port Quest Giver" },
    { Name = "Hydra Leader",    Level = 1675, Sea = 3, Location = "Hydra Island",     QuestNPC = "Hydra Town Quest Giver" },
    { Name = "Kilo Admiral",    Level = 1750, Sea = 3, Location = "Great Tree",       QuestNPC = "Great Tree Quest Giver" },
    { Name = "Captain Elephant",Level = 1900, Sea = 3, Location = "Floating Turtle",  QuestNPC = "Floating Turtle Quest Giver" },
    { Name = "Beautiful Pirate",Level = 1950, Sea = 3, Location = "Floating Turtle",  QuestNPC = "Floating Turtle Quest Giver" },
    { Name = "Longma",          Level = 2000, Sea = 3, Location = "Floating Turtle",  QuestNPC = "Floating Turtle Quest Giver" },
    { Name = "Cursed Skeleton", Level = 2025, Sea = 3, Location = "Floating Turtle",  QuestNPC = "Floating Turtle Quest Giver" },
    { Name = "Soul Reaper",     Level = 2100, Sea = 3, Location = "Haunted Castle",   QuestNPC = "Haunted Castle Quest Giver" },
    { Name = "Cake Queen",      Level = 2175, Sea = 3, Location = "Sea of Treats",    QuestNPC = "Cake Quest Giver 1" },
    { Name = "Dough King",      Level = 2300, Sea = 3, Location = "Sea of Treats",    QuestNPC = "Cake Quest Giver 1" },
    { Name = "Tyrant of the Skies", Level = 2600, Sea = 3, Location = "Submerged Island", QuestNPC = "Submerged Quest Giver" },
}

-- ===================== FARM CONTROLLER =====================
local FarmRunning      = false
local FarmThread       = nil
local BossTarget       = nil

local function GetZoneForLevel(level)
    for _, zone in ipairs(FullDatabase[1]) do
        if level >= zone.MinLv and level <= zone.MaxLv then return zone end
    end
    for _, zone in ipairs(FullDatabase[2]) do
        if level >= zone.MinLv and level <= zone.MaxLv then return zone end
    end
    for _, zone in ipairs(FullDatabase[3]) do
        if level >= zone.MinLv and level <= zone.MaxLv then return zone end
    end
    -- Nếu vượt quá 2800, trả về zone cuối của Sea 3
    return FullDatabase[3][#FullDatabase[3]]
end

local function RunFarm()
    while FarmRunning do
        -- 1) Đảm bảo còn sống
        if not IsAlive() then
            StopFly()
            repeat task.wait(1) until IsAlive() or not FarmRunning
            if not FarmRunning then break end
            task.wait(1)
        end

        -- 2) Xác định mục tiêu
        local targetMobs, targetQuestNPC, targetZone = nil, nil, nil

        if Config.AutoFarmBoss and BossTarget then
            targetMobs     = { BossTarget.Name }
            targetQuestNPC = BossTarget.QuestNPC
        else
            local level = Humanoid.Level.Value
            targetZone  = GetZoneForLevel(level)
            targetMobs  = targetZone.Mobs
            targetQuestNPC = targetZone.QuestNPC
        end

        -- 3) Tự động nhận nhiệm vụ
        if Config.AutoQuest and targetQuestNPC and not QuestActive then
            AcceptQuest(targetQuestNPC, targetZone and targetZone.Name or BossTarget.Name)
            task.wait(0.3)
        end

        -- 4) Tìm quái
        local mobs = GetMobsByNames(targetMobs)

        if #mobs == 0 then
            if targetZone and targetZone.Location then
                FlyTo(targetZone.Location)
            end
            task.wait(0.8)
            continue
        end

        -- 5) Bring mobs
        if Config.BringMobs then
            local maxBring = (Config.SelectedWeapon == "Melee") and 2 or 3
            local brought = 0
            for _, mob in pairs(mobs) do
                if brought >= maxBring then break end
                local mroot = mob:FindFirstChild("HumanoidRootPart")
                if mroot and (RootPart.Position - mroot.Position).Magnitude <= Config.BringRadius then
                    BringMob(mob)
                    brought += 1
                end
            end
        end

        -- 6) Tấn công
        local searchRange = Config.LongRangeAttack and Config.LongRangeDist or Config.FarmDistance
        local target = GetNearestMob(targetMobs, searchRange)

        if target then
            local tr = target:FindFirstChild("HumanoidRootPart")
            if tr then
                local dist = (RootPart.Position - tr.Position).Magnitude
                local attackRange = Config.LongRangeAttack and Config.LongRangeDist or Config.AttackDistance

                if dist > attackRange then
                    FlyTo(tr.Position + Vector3.new(0, 2, 0))
                else
                    StopFly()
                    SimulateAttack(tr)
                end
            end
        elseif targetZone and targetZone.Location then
            FlyTo(targetZone.Location)
        end

        task.wait(Config.FastAttack and 0.05 or Config.AttackDelay)
    end

    StopFly()
end

local function StartFarm()
    if FarmRunning then return end
    FarmRunning = true
    FarmThread = task.spawn(RunFarm)
end

local function StopFarm()
    FarmRunning = false
    StopFly()
    if FarmThread then
        task.cancel(FarmThread)
        FarmThread = nil
    end
end

-- ============================================================
-- //  GUI CREATION
-- ============================================================

local function GetSafeGuiParent()
    if typeof(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then
        local test = Instance.new("ScreenGui")
        local success = pcall(function() test.Parent = core end)
        if success then test:Destroy(); return core end
        test:Destroy()
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = GetSafeGuiParent()

-- Xóa GUI cũ nếu tồn tại
local oldGui = GuiParent:FindFirstChild("ThoHubV3")
    or LocalPlayer.PlayerGui:FindFirstChild("ThoHubV3")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "ThoHubV3"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = GuiParent

-- ===================== FLOATING BUTTON =====================
local FloatBtn = Instance.new("Frame")
FloatBtn.Name             = "FloatBtn"
FloatBtn.Size             = UDim2.new(0, 52, 0, 52)
FloatBtn.Position         = UDim2.new(0, 20, 0.5, -26)
FloatBtn.BackgroundColor3 = Color3.fromRGB(10, 30, 80)
FloatBtn.BorderSizePixel  = 0
FloatBtn.Parent           = ScreenGui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)

local FloatGrad = Instance.new("UIGradient")
FloatGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 60, 180)),
})
FloatGrad.Rotation = 135
FloatGrad.Parent   = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color        = Color3.fromRGB(0, 180, 255)
FloatStroke.Thickness    = 1.5
FloatStroke.Transparency = 0.3
FloatStroke.Parent       = FloatBtn

local FloatLabel = Instance.new("TextLabel")
FloatLabel.Size                  = UDim2.new(1, 0, 1, 0)
FloatLabel.BackgroundTransparency = 1
FloatLabel.Text                  = "⚡"
FloatLabel.TextScaled            = true
FloatLabel.Font                  = Enum.Font.GothamBold
FloatLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
FloatLabel.Parent                = FloatBtn

local FloatClick = Instance.new("TextButton")
FloatClick.Size                  = UDim2.new(1, 0, 1, 0)
FloatClick.BackgroundTransparency = 1
FloatClick.Text                  = ""
FloatClick.Parent                = FloatBtn

local dragFloat, dragStartFloat, startPosFloat
FloatClick.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragFloat = true; dragStartFloat = input.Position; startPosFloat = FloatBtn.Position
    end
end)
FloatClick.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if dragFloat then
            local delta = input.Position - dragStartFloat
            local moved = math.abs(delta.X) + math.abs(delta.Y)
            dragFloat = false
            if moved < 5 then
                local main = ScreenGui:FindFirstChild("MainFrame")
                if main then main.Visible = not main.Visible end
            end
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragFloat and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartFloat
        FloatBtn.Position = UDim2.new(
            startPosFloat.X.Scale, startPosFloat.X.Offset + delta.X,
            startPosFloat.Y.Scale, startPosFloat.Y.Offset + delta.Y
        )
    end
end)

task.spawn(function()
    while true do
        Tween(FloatStroke, 0.8, {Transparency = 0.0}); task.wait(0.8)
        Tween(FloatStroke, 0.8, {Transparency = 0.6}); task.wait(0.8)
    end
end)

-- ===================== MAIN WINDOW =====================
local MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 640, 0, 460)
MainFrame.Position         = UDim2.new(0.5, -320, 0.5, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 10, 28)
MainFrame.BorderSizePixel  = 0
MainFrame.Visible          = false
MainFrame.Parent           = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color        = Color3.fromRGB(0, 120, 255)
MainStroke.Thickness    = 1.5
MainStroke.Transparency = 0.2
MainStroke.Parent       = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 20, 60)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TitleFix = Instance.new("Frame")
TitleFix.Size             = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position         = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3 = Color3.fromRGB(0, 20, 60)
TitleFix.BorderSizePixel  = 0
TitleFix.Parent           = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size                  = UDim2.new(0, 260, 1, 0)
TitleText.Position              = UDim2.new(0, 50, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text                  = "THO HUB  |  V3"
TitleText.TextSize              = 17
TitleText.Font                  = Enum.Font.GothamBold
TitleText.TextColor3            = Color3.fromRGB(255, 255, 255)
TitleText.TextXAlignment        = Enum.TextXAlignment.Left
TitleText.Parent                = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 32, 0, 32)
CloseBtn.Position         = UDim2.new(1, -42, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize         = 14
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.BorderSizePixel  = 0
CloseBtn.Parent           = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Drag
local dragMain, dragStartMain, startPosMain
local TitleDrag = Instance.new("TextButton")
TitleDrag.Size                  = UDim2.new(1, -90, 1, 0)
TitleDrag.BackgroundTransparency = 1
TitleDrag.Text                  = ""
TitleDrag.Parent                = TitleBar
TitleDrag.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragMain = true; dragStartMain = input.Position; startPosMain = MainFrame.Position
    end
end)
TitleDrag.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragMain = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragMain and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(
            startPosMain.X.Scale, startPosMain.X.Offset + delta.X,
            startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y
        )
    end
end)

-- Layout: Tab trái | Nội dung phải
local ContentArea = Instance.new("Frame")
ContentArea.Size                  = UDim2.new(1, 0, 1, -52)
ContentArea.Position              = UDim2.new(0, 0, 0, 52)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent                = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size             = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(5, 15, 40)
Sidebar.BorderSizePixel  = 0
Sidebar.Parent           = ContentArea
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 14)

local SideFix = Instance.new("Frame")
SideFix.Size             = UDim2.new(0.5, 0, 1, 0)
SideFix.Position         = UDim2.new(0.5, 0, 0, 0)
SideFix.BackgroundColor3 = Color3.fromRGB(5, 15, 40)
SideFix.BorderSizePixel  = 0
SideFix.Parent           = Sidebar

local SideList = Instance.new("UIListLayout")
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding   = UDim.new(0, 6)
SideList.Parent    = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop   = UDim.new(0, 12)
SidePad.PaddingLeft  = UDim.new(0, 8)
SidePad.PaddingRight = UDim.new(0, 8)
SidePad.Parent       = Sidebar

local RightPanel = Instance.new("Frame")
RightPanel.Size                  = UDim2.new(1, -158, 1, 0)
RightPanel.Position              = UDim2.new(0, 158, 0, 0)
RightPanel.BackgroundTransparency = 1
RightPanel.Parent                = ContentArea

local Separator = Instance.new("Frame")
Separator.Size                  = UDim2.new(0, 1, 1, -20)
Separator.Position              = UDim2.new(0, 150, 0, 10)
Separator.BackgroundColor3      = Color3.fromRGB(0, 80, 200)
Separator.BorderSizePixel       = 0
Separator.BackgroundTransparency = 0.7
Separator.Parent                = ContentArea

-- Tab System
local Tabs = {}

local function CreateTabButton(name, icon, order)
    local Btn = Instance.new("TextButton")
    Btn.Size             = UDim2.new(1, 0, 0, 44)
    Btn.BackgroundColor3 = Color3.fromRGB(10, 25, 70)
    Btn.Text             = ""
    Btn.BorderSizePixel  = 0
    Btn.LayoutOrder      = order
    Btn.Parent           = Sidebar
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)

    local IconLbl = Instance.new("TextLabel")
    IconLbl.Size                  = UDim2.new(0, 30, 1, 0)
    IconLbl.Position              = UDim2.new(0, 6, 0, 0)
    IconLbl.BackgroundTransparency = 1
    IconLbl.Text                  = icon
    IconLbl.TextSize              = 16
    IconLbl.Font                  = Enum.Font.GothamBold
    IconLbl.TextColor3            = Color3.fromRGB(100, 160, 255)
    IconLbl.Parent                = Btn

    local Txt = Instance.new("TextLabel")
    Txt.Size                  = UDim2.new(1, -40, 1, 0)
    Txt.Position              = UDim2.new(0, 38, 0, 0)
    Txt.BackgroundTransparency = 1
    Txt.Text                  = name
    Txt.TextSize              = 13
    Txt.Font                  = Enum.Font.GothamSemibold
    Txt.TextColor3            = Color3.fromRGB(180, 210, 255)
    Txt.TextXAlignment        = Enum.TextXAlignment.Left
    Txt.Parent                = Btn

    local ActiveBar = Instance.new("Frame")
    ActiveBar.Size             = UDim2.new(0, 3, 0.6, 0)
    ActiveBar.Position         = UDim2.new(0, -8, 0.2, 0)
    ActiveBar.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
    ActiveBar.BorderSizePixel  = 0
    ActiveBar.Visible          = false
    ActiveBar.Parent           = Btn
    Instance.new("UICorner", ActiveBar).CornerRadius = UDim.new(1, 0)

    local Content = Instance.new("ScrollingFrame")
    Content.Size                  = UDim2.new(1, -8, 1, -12)
    Content.Position              = UDim2.new(0, 4, 0, 6)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel       = 0
    Content.ScrollBarThickness    = 3
    Content.ScrollBarImageColor3  = Color3.fromRGB(0, 120, 255)
    Content.CanvasSize            = UDim2.new(0, 0, 0, 0)
    Content.Visible               = false
    Content.Parent                = RightPanel

    local CL = Instance.new("UIListLayout")
    CL.SortOrder = Enum.SortOrder.LayoutOrder
    CL.Padding   = UDim.new(0, 8)
    CL.Parent    = Content
    CL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, CL.AbsoluteContentSize.Y + 20)
    end)

    local CP = Instance.new("UIPadding")
    CP.PaddingTop   = UDim.new(0, 8)
    CP.PaddingRight = UDim.new(0, 4)
    CP.Parent       = Content

    Tabs[name] = { Button = Btn, Content = Content, ActiveBar = ActiveBar, BtnText = Txt }

    Btn.MouseButton1Click:Connect(function()
        for _, tab in pairs(Tabs) do
            tab.Content.Visible   = false
            tab.ActiveBar.Visible = false
            Tween(tab.Button, 0.2, {BackgroundColor3 = Color3.fromRGB(10, 25, 70)})
            tab.BtnText.TextColor3 = Color3.fromRGB(180, 210, 255)
        end
        Content.Visible   = true
        ActiveBar.Visible = true
        Tween(Btn, 0.2, {BackgroundColor3 = Color3.fromRGB(0, 50, 150)})
        Txt.TextColor3    = Color3.fromRGB(255, 255, 255)
    end)

    return Content
end

-- UI Components
local function CreateSectionLabel(parent, text, order)
    local L = Instance.new("TextLabel")
    L.Size                  = UDim2.new(1, 0, 0, 24)
    L.BackgroundTransparency = 1
    L.Text                  = "  " .. text:upper()
    L.TextSize              = 10
    L.Font                  = Enum.Font.GothamBold
    L.TextColor3            = Color3.fromRGB(0, 150, 255)
    L.TextXAlignment        = Enum.TextXAlignment.Left
    L.LayoutOrder           = order
    L.Parent                = parent
    return L
end

local function CreateToggle(parent, text, default, callback, order)
    local Row = Instance.new("Frame")
    Row.Size             = UDim2.new(1, 0, 0, 40)
    Row.BackgroundColor3 = Color3.fromRGB(10, 22, 55)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order
    Row.Parent           = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 60, 150); stroke.Thickness = 1; stroke.Transparency = 0.6; stroke.Parent = Row

    local Lbl = Instance.new("TextLabel")
    Lbl.Size                  = UDim2.new(1, -60, 1, 0)
    Lbl.Position              = UDim2.new(0, 14, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text                  = text
    Lbl.TextSize              = 13
    Lbl.Font                  = Enum.Font.Gotham
    Lbl.TextColor3            = Color3.fromRGB(200, 225, 255)
    Lbl.TextXAlignment        = Enum.TextXAlignment.Left
    Lbl.Parent                = Row

    local Bg = Instance.new("Frame")
    Bg.Size             = UDim2.new(0, 44, 0, 22)
    Bg.Position         = UDim2.new(1, -54, 0.5, -11)
    Bg.BackgroundColor3 = default and Color3.fromRGB(0, 100, 255) or Color3.fromRGB(30, 40, 70)
    Bg.BorderSizePixel  = 0
    Bg.Parent           = Row
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size             = UDim2.new(0, 16, 0, 16)
    Knob.Position         = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel  = 0
    Knob.Parent           = Bg
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local state = default
    local Click = Instance.new("TextButton")
    Click.Size                  = UDim2.new(1, 0, 1, 0)
    Click.BackgroundTransparency = 1
    Click.Text                  = ""
    Click.Parent                = Row
    Click.MouseButton1Click:Connect(function()
        state = not state
        Tween(Bg, 0.2, {BackgroundColor3 = state and Color3.fromRGB(0, 100, 255) or Color3.fromRGB(30, 40, 70)})
        Tween(Knob, 0.2, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
        callback(state)
    end)
    return Row
end

local function CreateSlider(parent, text, min, max, default, callback, order)
    local Row = Instance.new("Frame")
    Row.Size             = UDim2.new(1, 0, 0, 58)
    Row.BackgroundColor3 = Color3.fromRGB(10, 22, 55)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order
    Row.Parent           = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 60, 150); stroke.Thickness = 1; stroke.Transparency = 0.6; stroke.Parent = Row

    local Lbl = Instance.new("TextLabel")
    Lbl.Size                  = UDim2.new(1, -60, 0, 22)
    Lbl.Position              = UDim2.new(0, 14, 0, 4)
    Lbl.BackgroundTransparency = 1
    Lbl.Text                  = text
    Lbl.TextSize              = 12
    Lbl.Font                  = Enum.Font.Gotham
    Lbl.TextColor3            = Color3.fromRGB(200, 225, 255)
    Lbl.TextXAlignment        = Enum.TextXAlignment.Left
    Lbl.Parent                = Row

    local Val = Instance.new("TextLabel")
    Val.Size                  = UDim2.new(0, 50, 0, 22)
    Val.Position              = UDim2.new(1, -60, 0, 4)
    Val.BackgroundTransparency = 1
    Val.Text                  = tostring(default)
    Val.TextSize              = 12
    Val.Font                  = Enum.Font.GothamBold
    Val.TextColor3            = Color3.fromRGB(0, 180, 255)
    Val.TextXAlignment        = Enum.TextXAlignment.Right
    Val.Parent                = Row

    local SBg = Instance.new("Frame")
    SBg.Size             = UDim2.new(1, -28, 0, 6)
    SBg.Position         = UDim2.new(0, 14, 0, 36)
    SBg.BackgroundColor3 = Color3.fromRGB(20, 40, 90)
    SBg.BorderSizePixel  = 0
    SBg.Parent           = Row
    Instance.new("UICorner", SBg).CornerRadius = UDim.new(1, 0)

    local initScale = (default - min) / (max - min)
    local SFill = Instance.new("Frame")
    SFill.Size             = UDim2.new(initScale, 0, 1, 0)
    SFill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    SFill.BorderSizePixel  = 0
    SFill.Parent           = SBg
    Instance.new("UICorner", SFill).CornerRadius = UDim.new(1, 0)

    local SKnob = Instance.new("Frame")
    SKnob.Size             = UDim2.new(0, 14, 0, 14)
    SKnob.Position         = UDim2.new(initScale, -7, 0.5, -7)
    SKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SKnob.BorderSizePixel  = 0
    SKnob.Parent           = SBg
    Instance.new("UICorner", SKnob).CornerRadius = UDim.new(1, 0)

    local isDrag = false
    local SBtn = Instance.new("TextButton")
    SBtn.Size                  = UDim2.new(1, 0, 0, 20)
    SBtn.Position              = UDim2.new(0, 0, 0, -7)
    SBtn.BackgroundTransparency = 1
    SBtn.Text                  = ""
    SBtn.Parent                = SBg

    local function update(inputX)
        local x0 = SBg.AbsolutePosition.X
        local w  = SBg.AbsoluteSize.X
        if w <= 0 then return end
        local rel = math.clamp((inputX - x0) / w, 0, 1)
        local v   = math.floor(min + rel * (max - min))
        Val.Text       = tostring(v)
        SFill.Size     = UDim2.new(rel, 0, 1, 0)
        SKnob.Position = UDim2.new(rel, -7, 0.5, -7)
        callback(v)
    end

    SBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDrag = true; update(input.Position.X)
        end
    end)
    SBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDrag = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end)

    return Row
end

local function CreateDropdown(parent, text, options, default, callback, order)
    local isOpen, selected = false, default

    local Cont = Instance.new("Frame")
    Cont.Size             = UDim2.new(1, 0, 0, 42)
    Cont.BackgroundColor3 = Color3.fromRGB(10, 22, 55)
    Cont.BorderSizePixel  = 0
    Cont.LayoutOrder      = order
    Cont.ClipsDescendants = false
    Cont.Parent           = parent
    Instance.new("UICorner", Cont).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 60, 150); stroke.Thickness = 1; stroke.Transparency = 0.6; stroke.Parent = Cont

    local Lbl = Instance.new("TextLabel")
    Lbl.Size                  = UDim2.new(0, 120, 0, 42)
    Lbl.Position              = UDim2.new(0, 14, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text                  = text
    Lbl.TextSize              = 12
    Lbl.Font                  = Enum.Font.Gotham
    Lbl.TextColor3            = Color3.fromRGB(200, 225, 255)
    Lbl.TextXAlignment        = Enum.TextXAlignment.Left
    Lbl.Parent                = Cont

    local Sel = Instance.new("TextButton")
    Sel.Size             = UDim2.new(1, -140, 0, 30)
    Sel.Position         = UDim2.new(0, 136, 0, 6)
    Sel.BackgroundColor3 = Color3.fromRGB(0, 40, 120)
    Sel.Text             = selected .. " ▾"
    Sel.TextSize         = 11
    Sel.Font             = Enum.Font.GothamSemibold
    Sel.TextColor3       = Color3.fromRGB(100, 200, 255)
    Sel.BorderSizePixel  = 0
    Sel.Parent           = Cont
    Instance.new("UICorner", Sel).CornerRadius = UDim.new(0, 6)

    local DL = Instance.new("Frame")
    DL.Size             = UDim2.new(1, -140, 0, math.min(#options, 5) * 30 + 8)
    DL.Position         = UDim2.new(0, 136, 0, 44)
    DL.BackgroundColor3 = Color3.fromRGB(5, 15, 45)
    DL.BorderSizePixel  = 0
    DL.Visible          = false
    DL.ZIndex           = 10
    DL.Parent           = Cont
    Instance.new("UICorner", DL).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", DL).Color = Color3.fromRGB(0, 80, 200)

    local DLList = Instance.new("UIListLayout")
    DLList.Padding = UDim.new(0, 2); DLList.Parent = DL
    Instance.new("UIPadding", DL).PaddingTop = UDim.new(0, 4)

    for _, opt in ipairs(options) do
        local O = Instance.new("TextButton")
        O.Size                  = UDim2.new(1, -8, 0, 26)
        O.BackgroundTransparency = 1
        O.Text                  = opt
        O.TextSize              = 11
        O.Font                  = Enum.Font.Gotham
        O.TextColor3            = Color3.fromRGB(180, 220, 255)
        O.ZIndex                = 11
        O.Parent                = DL

        O.MouseEnter:Connect(function()
            O.BackgroundTransparency = 0.6; O.BackgroundColor3 = Color3.fromRGB(0, 60, 180)
        end)
        O.MouseLeave:Connect(function() O.BackgroundTransparency = 1 end)
        O.MouseButton1Click:Connect(function()
            selected    = opt
            Sel.Text    = opt .. " ▾"
            DL.Visible  = false
            isOpen      = false
            Cont.Size   = UDim2.new(1, 0, 0, 42)
            callback(opt)
        end)
    end

    Sel.MouseButton1Click:Connect(function()
        isOpen     = not isOpen
        DL.Visible = isOpen
        Cont.Size  = UDim2.new(1, 0, 0, isOpen and (42 + math.min(#options, 5) * 30 + 12) or 42)
    end)

    return Cont
end

local function CreateButton(parent, text, icon, callback, order)
    local Btn = Instance.new("TextButton")
    Btn.Size             = UDim2.new(1, 0, 0, 38)
    Btn.BackgroundColor3 = Color3.fromRGB(0, 70, 200)
    Btn.Text             = (icon and icon .. "  " or "") .. text
    Btn.TextSize         = 13
    Btn.Font             = Enum.Font.GothamBold
    Btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    Btn.BorderSizePixel  = 0
    Btn.LayoutOrder      = order
    Btn.Parent           = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 60, 200)),
    })
    grad.Rotation = 90; grad.Parent = Btn

    Btn.MouseEnter:Connect(function() Tween(Btn, 0.15, {BackgroundColor3 = Color3.fromRGB(0, 100, 255)}) end)
    Btn.MouseLeave:Connect(function() Tween(Btn, 0.15, {BackgroundColor3 = Color3.fromRGB(0, 70, 200)}) end)
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

-- ===================== TAB FARM LEVEL =====================
local FarmContent = CreateTabButton("Farm Level", "🌾", 1)

CreateSectionLabel(FarmContent, "⚔️ Chọn vũ khí farm", 1)
CreateDropdown(FarmContent, "Weapon", {"Melee", "Sword", "Fruit", "Gun"}, "Melee",
    function(v) Config.SelectedWeapon = v end, 2)

CreateSectionLabel(FarmContent, "⚙️ Tùy chọn farm", 4)
CreateToggle(FarmContent, "Auto Quest", Config.AutoQuest, function(v) Config.AutoQuest = v end, 5)
CreateToggle(FarmContent, "Bring Mobs (Gom quái)", Config.BringMobs, function(v) Config.BringMobs = v end, 6)
CreateToggle(FarmContent, "Fast Attack", Config.FastAttack, function(v) Config.FastAttack = v end, 7)

CreateSectionLabel(FarmContent, "🚀 Điều khiển", 9)
local farmLevelState = false
local FarmLevelBtnRef

FarmLevelBtnRef = CreateButton(FarmContent, "START FARM LEVEL", "▶", function()
    farmLevelState = not farmLevelState
    if farmLevelState then
        Config.AutoFarmLevel = true
        Config.AutoFarmBoss  = false
        FarmLevelBtnRef.Text = "⏹  STOP FARM LEVEL"
        Tween(FarmLevelBtnRef, 0.2, {BackgroundColor3 = Color3.fromRGB(180, 30, 30)})
        StartFarm()
    else
        Config.AutoFarmLevel = false
        FarmLevelBtnRef.Text = "▶  START FARM LEVEL"
        Tween(FarmLevelBtnRef, 0.2, {BackgroundColor3 = Color3.fromRGB(0, 70, 200)})
        StopFarm()
    end
end, 10)

-- Status
local StatusFrame = Instance.new("Frame")
StatusFrame.Size             = UDim2.new(1, 0, 0, 40)
StatusFrame.BackgroundColor3 = Color3.fromRGB(5, 15, 40)
StatusFrame.BorderSizePixel  = 0
StatusFrame.LayoutOrder      = 11
StatusFrame.Parent           = FarmContent
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size                  = UDim2.new(1, -10, 1, 0)
StatusLabel.Position              = UDim2.new(0, 10, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text                  = "⬤  Idle"
StatusLabel.TextSize              = 12
StatusLabel.Font                  = Enum.Font.GothamSemibold
StatusLabel.TextColor3            = Color3.fromRGB(100, 150, 255)
StatusLabel.TextXAlignment        = Enum.TextXAlignment.Left
StatusLabel.Parent                = StatusFrame

task.spawn(function()
    while true do
        task.wait(0.5)
        if FarmRunning and not Config.AutoFarmBoss then
            local lv = (Humanoid and Humanoid.Level) and Humanoid.Level.Value or "?"
            local z  = IsAlive() and GetZoneForLevel(Humanoid.Level.Value) or nil
            StatusLabel.Text = "⬤  Farm Lv " .. lv .. (z and (" | " .. z.Name) or "")
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        elseif not FarmRunning then
            StatusLabel.Text       = "⬤  Idle"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
        end
    end
end)

-- ===================== TAB FARM BOSS =====================
local BossContent = CreateTabButton("Farm Boss", "👹", 2)

CreateSectionLabel(BossContent, "👹 Chọn boss", 1)

local bossDisplayNames = {}
for _, b in ipairs(BossDatabase) do
    table.insert(bossDisplayNames, b.Name .. " (Lv." .. b.Level .. ")")
end

CreateDropdown(BossContent, "Boss", bossDisplayNames, bossDisplayNames[1] or "",
    function(selected)
        local bossName = selected:match("^([^%(]+)")
        bossName = bossName and bossName:gsub("%s+$", "")
        for _, b in ipairs(BossDatabase) do
            if b.Name == bossName then BossTarget = b; break end
        end
    end, 2)

CreateSectionLabel(BossContent, "🚀 Điều khiển", 4)
local farmBossState = false
local FarmBossBtnRef

FarmBossBtnRef = CreateButton(BossContent, "START FARM BOSS", "▶", function()
    farmBossState = not farmBossState
    if farmBossState then
        Config.AutoFarmBoss  = true
        Config.AutoFarmLevel = false
        FarmBossBtnRef.Text  = "⏹  STOP FARM BOSS"
        Tween(FarmBossBtnRef, 0.2, {BackgroundColor3 = Color3.fromRGB(180, 30, 30)})
        StartFarm()
    else
        Config.AutoFarmBoss = false
        FarmBossBtnRef.Text = "▶  START FARM BOSS"
        Tween(FarmBossBtnRef, 0.2, {BackgroundColor3 = Color3.fromRGB(0, 70, 200)})
        StopFarm()
    end
end, 5)

local BossStatusFrame = Instance.new("Frame")
BossStatusFrame.Size             = UDim2.new(1, 0, 0, 40)
BossStatusFrame.BackgroundColor3 = Color3.fromRGB(5, 15, 40)
BossStatusFrame.BorderSizePixel  = 0
BossStatusFrame.LayoutOrder      = 6
BossStatusFrame.Parent           = BossContent
Instance.new("UICorner", BossStatusFrame).CornerRadius = UDim.new(0, 8)

local BossStatusLabel = Instance.new("TextLabel")
BossStatusLabel.Size                  = UDim2.new(1, -10, 1, 0)
BossStatusLabel.Position              = UDim2.new(0, 10, 0, 0)
BossStatusLabel.BackgroundTransparency = 1
BossStatusLabel.Text                  = "⬤  Idle"
BossStatusLabel.TextSize              = 12
BossStatusLabel.Font                  = Enum.Font.GothamSemibold
BossStatusLabel.TextColor3            = Color3.fromRGB(100, 150, 255)
BossStatusLabel.TextXAlignment        = Enum.TextXAlignment.Left
BossStatusLabel.Parent                = BossStatusFrame

task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoFarmBoss and FarmRunning and BossTarget then
            BossStatusLabel.Text       = "⬤  Đang farm: " .. BossTarget.Name
            BossStatusLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
        else
            BossStatusLabel.Text       = "⬤  Idle"
            BossStatusLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
        end
    end
end)

-- ===================== TAB SETTINGS =====================
local SettingsContent = CreateTabButton("Settings", "⚙️", 3)

CreateSectionLabel(SettingsContent, "⚡ Chiến đấu", 1)
CreateToggle(SettingsContent, "Đánh xa (Long Range Attack)", Config.LongRangeAttack,
    function(v) Config.LongRangeAttack = v end, 2)
CreateSlider(SettingsContent, "Tầm đánh xa (studs)", 20, 150, Config.LongRangeDist,
    function(v) Config.LongRangeDist = v end, 3)
CreateSlider(SettingsContent, "Tốc độ đánh (x100s)", 5, 100, math.floor(Config.AttackDelay * 100),
    function(v) Config.AttackDelay = v / 100 end, 4)

CreateSectionLabel(SettingsContent, "🎯 Phát hiện", 6)
CreateSlider(SettingsContent, "Farm Distance (studs)", 30, 200, Config.FarmDistance,
    function(v) Config.FarmDistance = v end, 7)
CreateSlider(SettingsContent, "Bring Radius (studs)", 10, 100, Config.BringRadius,
    function(v) Config.BringRadius = v end, 8)

CreateSectionLabel(SettingsContent, "✈️ Di chuyển", 10)
CreateSlider(SettingsContent, "Fly Speed", 30, 300, Config.FlySpeed,
    function(v) Config.FlySpeed = v end, 11)

CreateSectionLabel(SettingsContent, "💡 Khác", 13)
CreateButton(SettingsContent, "Reset Character", "🔄", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end, 14)

-- ===================== KÍCH HOẠT TAB ĐẦU =====================
Tabs["Farm Level"].Content.Visible   = true
Tabs["Farm Level"].ActiveBar.Visible = true
Tween(Tabs["Farm Level"].Button, 0.2, {BackgroundColor3 = Color3.fromRGB(0, 50, 150)})
Tabs["Farm Level"].BtnText.TextColor3 = Color3.fromRGB(255, 255, 255)

if #BossDatabase > 0 then BossTarget = BossDatabase[1] end

print("✅ THO HUB V3 loaded — Full database, stable farm engine.")
