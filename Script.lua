-- Diving For Brainrots - Rayfield UI (بدون God Mode)
-- تعديل مدة الضغط على E إلى 4 ثواني
-- تعديل سرعة التنقل (Auto Farm / TP Base) إلى 60 ثابتة
-- إضافة Auto Collect Reward (1-12) كل 60 ثانية

task.wait(30)

if game.PlaceId ~= 70503141143371 then return end

local function NoErrors(func) return pcall(func) end

NoErrors(function()

-- الخدمات
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

-- ================== إعدادات الحفظ لكل حساب ==================
local PlayerId = LocalPlayer.UserId
local SettingsFileName = "DivingForBrainrots_Rayfield.json"
local SettingsFolder = "DivingBrainrots_" .. PlayerId

local function SaveSettings()
    local settings = {
        AutoCollect = _G.AutoCollect or false,
        AntiAfk = _G.AntiAfk or false,
        Noclip = _G.Noclip or false,
        AutoFreeChest = _G.AutoFreeChest or false,
        SpeedEnabled = _G.SpeedEnabled or false,
        SpeedValue = _G.SpeedValue or 16,
        AutoPickupRare = _G.AutoPickupRare or false,
        DebugMode = _G.DebugMode or false,
        AutoCollectReward = _G.AutoCollectReward or false,
        AutoBuy = {}
    }
    local blocks = {301,302,303,304,305,306,307}
    for _, id in ipairs(blocks) do
        settings.AutoBuy["Buy"..id] = _G["Buy"..id] or false
    end
    pcall(function()
        if not isfolder(SettingsFolder) then makefolder(SettingsFolder) end
        writefile(SettingsFolder.."/"..SettingsFileName, HttpService:JSONEncode(settings))
    end)
end

local function LoadSettings()
    pcall(function()
        if not isfolder(SettingsFolder) then makefolder(SettingsFolder) end
        local path = SettingsFolder.."/"..SettingsFileName
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            _G.AutoCollect = data.AutoCollect or false
            _G.AntiAfk = data.AntiAfk or false
            _G.Noclip = data.Noclip or false
            _G.AutoFreeChest = data.AutoFreeChest or false
            _G.SpeedEnabled = data.SpeedEnabled or false
            _G.SpeedValue = data.SpeedValue or 16
            _G.AutoPickupRare = data.AutoPickupRare or false
            _G.DebugMode = data.DebugMode or false
            _G.AutoCollectReward = data.AutoCollectReward or false
            if data.AutoBuy then
                for k,v in pairs(data.AutoBuy) do _G[k] = v or false end
            end
        end
    end)
end

-- ================== المتغيرات العامة ==================
_G.AutoCollect = _G.AutoCollect or false
_G.AntiAfk = _G.AntiAfk or false
_G.Noclip = _G.Noclip or false
_G.AutoFreeChest = _G.AutoFreeChest or false
_G.SpeedEnabled = _G.SpeedEnabled or false
_G.SpeedValue = _G.SpeedValue or 16
_G.AutoPickupRare = _G.AutoPickupRare or false
_G.DebugMode = _G.DebugMode or false
_G.AutoCollectReward = _G.AutoCollectReward or false
_G.FarmBusy = false
_G.ReturningToBase = false
for i=301,307 do _G["Buy"..i] = _G["Buy"..i] or false end

-- سرعة التنقل ثابتة 60
local NAVIGATION_SPEED = 60

LoadSettings()
_G.Running = true

local CurrentStabilizer = nil

-- ================== دالة الطباعة للتصحيح ==================
local function DebugPrint(...)
    if _G.DebugMode then
        print("[DEBUG]", ...)
    end
end

-- ================== دالة إزالة أي مثبت سابق ==================
local function RemoveStabilizer()
    if CurrentStabilizer and CurrentStabilizer.Parent then
        CurrentStabilizer:Destroy()
        CurrentStabilizer = nil
        DebugPrint("تم إزالة المثبت")
    end
end

-- ================== دالة تثبيت اللاعب في المكان ==================
local function StabilizePlayer(position)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    RemoveStabilizer()

    local bp = Instance.new("BodyPosition")
    bp.Parent = hrp
    bp.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bp.P = 50000
    bp.D = 5000
    bp.Position = position

    CurrentStabilizer = bp
    DebugPrint("تم تثبيت اللاعب في", position)
end

-- ================== دالة الحركة السلسة (بسرعة ثابتة 60) ==================
local function MoveToPositionSmooth(targetPosition, stabilize)
    stabilize = stabilize == nil and true or stabilize

    local character = LocalPlayer.Character
    if not character then DebugPrint("لا يوجد شخصية") return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then DebugPrint("لا يوجد HumanoidRootPart") return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then DebugPrint("لا يوجد Humanoid") return false end

    RemoveStabilizer()

    hrp.Velocity = Vector3.new(0,0,0)
    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyMover") then
            v:Destroy()
        end
    end

    local originalNoclip = _G.Noclip
    _G.Noclip = true

    local bv = Instance.new("BodyVelocity")
    bv.Parent = hrp
    bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    bv.P = 30000

    local startTime = tick()
    local maxDuration = 60
    local lastDistance = (targetPosition - hrp.Position).Magnitude
    local stuckCounter = 0
    local completed = false

    while _G.Running do
        local currentPos = hrp.Position
        local distance = (targetPosition - currentPos).Magnitude

        if distance < 2.0 then
            DebugPrint("وصلنا إلى الهدف، المسافة:", distance)
            completed = true
            break
        end

        if tick() - startTime > maxDuration then
            DebugPrint("انتهى وقت الحركة")
            break
        end

        if math.abs(lastDistance - distance) < 0.3 then
            stuckCounter = stuckCounter + 1
        else
            stuckCounter = 0
        end
        lastDistance = distance

        if stuckCounter > 40 then
            DebugPrint("انحشار، نستخدم CFrame للقفز")
            hrp.CFrame = CFrame.new(targetPosition)
            task.wait(0.2)
            completed = true
            break
        end

        local direction = (targetPosition - currentPos).Unit
        bv.Velocity = direction * NAVIGATION_SPEED

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        task.wait(0.05)
    end

    bv:Destroy()
    hrp.Velocity = Vector3.new(0,0,0)
    _G.Noclip = originalNoclip

    local finalPos = targetPosition
    if finalPos.Y < -500 then
        finalPos = Vector3.new(finalPos.X, -490, finalPos.Z)
        DebugPrint("تم تعديل Y لمنع السقوط")
    end

    hrp.CFrame = CFrame.new(finalPos)
    task.wait(0.1)

    if stabilize and completed then
        StabilizePlayer(finalPos)
    else
        RemoveStabilizer()
    end

    DebugPrint("تمت الحركة إلى", finalPos, "التثبيت:", stabilize, "مكتملة:", completed)
    return completed
end

-- ================== العودة إلى القاعدة (بارتفاع 50) ==================
local BasePosition = Vector3.new(-45, 38, -510)
local function ReturnToBase()
    DebugPrint("بدء العودة إلى القاعدة")
    _G.ReturningToBase = true
    MoveToPositionSmooth(BasePosition + Vector3.new(0, 50, 0), false)
    _G.ReturningToBase = false
    DebugPrint("اكتملت العودة إلى القاعدة")
end

-- ================== التفاعل مع الكائن ==================
local function InteractWithObject(obj, maxAttempts)
    maxAttempts = maxAttempts or 4
    for attempt = 1, maxAttempts do
        local success = false
        pcall(function()
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("ClickDetector") then
                    fireclickdetector(child)
                    success = true
                    DebugPrint("تفاعل عبر ClickDetector في المحاولة", attempt)
                    break
                elseif child:IsA("ProximityPrompt") then
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.1)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    success = true
                    DebugPrint("تفاعل عبر ProximityPrompt في المحاولة", attempt)
                    break
                end
            end
        end)
        if success then return true end
        task.wait(0.5)
    end
    DebugPrint("لم نجد ClickDetector أو ProximityPrompt، نضغط E لمدة 4 ثوانٍ")
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(4)
    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
    return false
end

-- ================== البحث عن الأهداف النادرة تحت الماء ==================
local function FindRareUnderwaterTargets()
    local char = LocalPlayer.Character
    if not char then return {} end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end

    local waterLevel = 2
    local targetKeywords = {"Mythic", "Exotic", "Limited", "Secret"}
    local targets = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name
            local matchedKeyword = nil

            for _, kw in ipairs(targetKeywords) do
                if name:find(kw, 1, true) then
                    matchedKeyword = kw
                    break
                end
            end

            if matchedKeyword then
                local pos
                if obj:IsA("BasePart") then
                    pos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then
                    pos = obj.PrimaryPart.Position
                else
                    for _, part in ipairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            pos = part.Position
                            break
                        end
                    end
                end

                if pos and pos.Y < waterLevel then
                    table.insert(targets, {
                        Object = obj,
                        Position = pos,
                        Distance = (hrp.Position - pos).Magnitude,
                        Keyword = matchedKeyword
                    })
                    DebugPrint("هدف نادر تحت الماء:", obj.Name, "عند Y=", pos.Y, "الكلمة:", matchedKeyword)
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.Distance < b.Distance end)
    return targets
end

-- ================== حلقة Auto Pickup الرئيسية ==================
task.spawn(function()
    local failedAttempts = 0

    while _G.Running do
        task.wait(1.25)

        pcall(function()
            if not _G.AutoPickupRare or _G.FarmBusy or _G.ReturningToBase then
                return
            end

            local char = LocalPlayer.Character
            if not char then
                DebugPrint("لا توجد شخصية")
                return
            end

            local targets = FindRareUnderwaterTargets()

            if #targets == 0 then
                DebugPrint("لا توجد أهداف نادرة تحت الماء")
                failedAttempts = failedAttempts + 1
                if failedAttempts > 10 then
                    task.wait(3)
                end
                return
            end

            local target = targets[1]
            failedAttempts = 0
            _G.FarmBusy = true
            DebugPrint("نتعامل مع الهدف:", target.Object.Name, "المسافة:", target.Distance)

            MoveToPositionSmooth(target.Position + Vector3.new(0,3,0), true)
            task.wait(0.75)
            InteractWithObject(target.Object, 4)
            ReturnToBase()

            _G.FarmBusy = false
        end)
    end
end)

-- ================== Anti Afk ==================
task.spawn(function()
    while _G.Running do
        task.wait(60)
        pcall(function()
            if _G.AntiAfk and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:Move(Vector3.new(0,0,0), false)
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end
        end)
    end
end)

-- ================== Auto Buy ==================
for _, id in ipairs({301,302,303,304,305,306,307}) do
    task.spawn(function()
        while _G.Running do
            task.wait(0.35)
            pcall(function()
                if _G["Buy"..id] then
                    ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PurchaseStock"):InvokeServer(id, 1, "LuckyBlocksStock")
                end
            end)
        end
    end)
end

-- ================== Auto Collect Museum ==================
local stands = {"stand1","stand2","stand3","stand4","stand5","stand6","stand7","stand8","stand9","stand10"}
task.spawn(function()
    while _G.Running do
        task.wait(60)
        pcall(function()
            if _G.AutoCollect then
                for _, stand in ipairs(stands) do
                    ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CollectMuseumIncome"):FireServer(stand)
                    task.wait(0.2)
                end
            end
        end)
    end
end)

-- ================== Auto Free Exclusive Chest ==================
task.spawn(function()
    while _G.Running do
        task.wait(60)
        pcall(function()
            if _G.AutoFreeChest then
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClaimCustomReward"):FireServer(1)
            end
        end)
    end
end)

-- ================== Auto Collect Reward (1-12) ==================
task.spawn(function()
    while _G.Running do
        task.wait(60)
        pcall(function()
            if _G.AutoCollectReward then
                for i = 1, 12 do
                    ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClaimReward"):FireServer(i)
                    task.wait(0.1)
                end
                DebugPrint("تم جمع المكافآت (1-12)")
            end
        end)
    end
end)

-- ================== حلقة Noclip ==================
task.spawn(function()
    while _G.Running do
        task.wait(0.1)
        pcall(function()
            if _G.Noclip and LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end)

-- ================== حلقة السرعة (للمشي فقط) ==================
task.spawn(function()
    while _G.Running do
        task.wait(0.5)
        pcall(function()
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChild("Humanoid")
                if h then
                    if _G.SpeedEnabled then 
                        h.WalkSpeed = _G.SpeedValue
                    elseif h.WalkSpeed ~= 16 then 
                        h.WalkSpeed = 16 
                    end
                end
            end
        end)
    end
end)

-- ================== إنشاء واجهة Rayfield ==================
local function CreateUI()
    if not LocalPlayer:FindFirstChild("PlayerGui") then
        task.wait(5)
        CreateUI()
        return
    end

    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local Window = Rayfield:CreateWindow({
        Name = "Diving For Brainrots",
        LoadingTitle = "Ultimate Script",
        LoadingSubtitle = "Account: " .. LocalPlayer.Name,
    })

    -- تبويب Auto Buy
    local BuyTab = Window:CreateTab("Auto Buy", 4483362458)
    local blocks = {
        {301, "Common"}, {302, "Uncommon"}, {303, "Rare"},
        {304, "Epic"}, {305, "Legendary"}, {306, "Mythic"}, {307, "Exotic"}
    }
    for _, b in ipairs(blocks) do
        BuyTab:CreateToggle({
            Name = "Buy " .. b[2],
            CurrentValue = _G["Buy"..b[1]],
            Callback = function(v)
                _G["Buy"..b[1]] = v
                SaveSettings()
            end,
        })
    end

    -- تبويب Auto Collect
    local CollectTab = Window:CreateTab("Auto Collect", 4483362458)

    CollectTab:CreateToggle({
        Name = "⚡ Auto Collect (Base)",
        CurrentValue = _G.AutoCollect,
        Callback = function(s)
            _G.AutoCollect = s
            SaveSettings()
        end,
    })

    CollectTab:CreateToggle({
        Name = "🎁 Free Exclusive Chest",
        CurrentValue = _G.AutoFreeChest,
        Callback = function(s)
            _G.AutoFreeChest = s
            SaveSettings()
        end,
    })

    CollectTab:CreateToggle({
        Name = "💎 Auto Pickup Rare (Mythic/Exotic/Secret/Limited)",
        CurrentValue = _G.AutoPickupRare,
        Callback = function(s)
            _G.AutoPickupRare = s
            SaveSettings()
        end,
    })

    CollectTab:CreateToggle({
        Name = "🎁 Auto Collect Reward (1-12)",
        CurrentValue = _G.AutoCollectReward,
        Callback = function(s)
            _G.AutoCollectReward = s
            SaveSettings()
        end,
    })

    -- تبويب Misc
    local MiscTab = Window:CreateTab("Misc", 4483362458)

    local noclipToggle = MiscTab:CreateToggle({
        Name = "🚀 Noclip (R)",
        CurrentValue = _G.Noclip,
        Callback = function(s)
            _G.Noclip = s
            SaveSettings()
        end,
    })

    local antiAfkToggle = MiscTab:CreateToggle({
        Name = "🛡️ Anti Afk",
        CurrentValue = _G.AntiAfk,
        Callback = function(s)
            _G.AntiAfk = s
            SaveSettings()
        end,
    })

    local speedToggle = MiscTab:CreateToggle({
        Name = "⚡ Speed Boost (G)",
        CurrentValue = _G.SpeedEnabled,
        Callback = function(s)
            _G.SpeedEnabled = s
            SaveSettings()
        end,
    })

    local speedSlider = MiscTab:CreateSlider({
        Name = "Speed Value",
        Range = {16, 100},
        Increment = 1,
        Suffix = " WalkSpeed",
        CurrentValue = _G.SpeedValue,
        Callback = function(v)
            _G.SpeedValue = v
            SaveSettings()
        end,
    })

    MiscTab:CreateButton({
        Name = "🏠 Teleport To Base (T) [ارتفاع 50]",
        Callback = function()
            task.spawn(ReturnToBase)
        end,
    })

    local debugToggle = MiscTab:CreateToggle({
        Name = "🐞 Debug Mode",
        CurrentValue = _G.DebugMode,
        Callback = function(s)
            _G.DebugMode = s
            SaveSettings()
            print("Debug Mode:", s and "ON" or "OFF")
        end,
    })

    -- تبويب Settings
    local SettingsTab = Window:CreateTab("Settings", 4483362458)

    SettingsTab:CreateButton({
        Name = "💾 Save Settings",
        Callback = SaveSettings,
    })

    SettingsTab:CreateButton({
        Name = "📂 Load Settings",
        Callback = function()
            LoadSettings()
            noclipToggle:Set(_G.Noclip)
            antiAfkToggle:Set(_G.AntiAfk)
            speedToggle:Set(_G.SpeedEnabled)
            speedSlider:Set(_G.SpeedValue)
            debugToggle:Set(_G.DebugMode)
        end,
    })

    SettingsTab:CreateButton({
        Name = "❌ Destroy UI (Stop Script)",
        Callback = function()
            _G.Running = false
            RemoveStabilizer()
            SaveSettings()
            Rayfield:Destroy()
            task.wait(1)
            error("Script stopped by user")
        end,
    })

    -- اختصارات لوحة المفاتيح
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.R then
            _G.Noclip = not _G.Noclip
            noclipToggle:Set(_G.Noclip)
            SaveSettings()
        elseif input.KeyCode == Enum.KeyCode.T then
            task.spawn(ReturnToBase)
        elseif input.KeyCode == Enum.KeyCode.G then
            _G.SpeedEnabled = not _G.SpeedEnabled
            speedToggle:Set(_G.SpeedEnabled)
            SaveSettings()
        end
    end)
end

task.spawn(CreateUI)

end) -- نهاية NoErrors

print("✅ Diving For Brainrots - الإصدار بدون God Mode")
print("🔍 يستهدف: Mythic, Exotic, Limited فقط (أي مسافة)")
print("🐞 فعّل Debug Mode في تبويب Misc لرؤية التفاصيل")
print("⏱️ توقيتات Auto Farm: دورة البحث 1.25ث، بعد الوصول 0.75ث، ضغط E 4ث، بعد فشل البحث 3ث")
print("📍 TP Base بارتفاع 50 وحدة (آمن جداً)")
print("⚡ سرعة التنقل (Auto Farm / TP Base) ثابتة 60")
print("🎁 Auto Collect Reward (1-12) كل 60 ثانية")
