-- Diving For Brainrots - Rayfield UI (النسخة المعدلة حسب الطلب)
-- الآلية: يروح مباشرة إلى الهدف (بدون مسار آمن) - فقط الأهداف تحت الماء
-- OWNER: Skan_Dev
-- تعديل: أولوية الأهداف: Divine > Secret > Limited > Exotic > Mythic + تحت الماء فقط
-- تحديث: جمع أول هدفين فقط ثم العودة للقاعدة
-- تحديث: إذا مر على الهدف 90 ثانية دون جمعه، يتم تجاهله

task.wait(5)

if game.PlaceId ~= 70503141143371 then 
    print("❌ Game not supported!")
    return 
end

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
local TweenService = game:GetService("TweenService")
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
        AutoPickupMythic = _G.AutoPickupMythic or false,
        AutoPickupExotic = _G.AutoPickupExotic or false,
        AutoPickupLimited = _G.AutoPickupLimited or false,
        AutoPickupSecret = _G.AutoPickupSecret or false,
        AutoPickupDivine = _G.AutoPickupDivine or false,
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
            _G.AutoPickupMythic = data.AutoPickupMythic or false
            _G.AutoPickupExotic = data.AutoPickupExotic or false
            _G.AutoPickupLimited = data.AutoPickupLimited or false
            _G.AutoPickupSecret = data.AutoPickupSecret or false
            _G.AutoPickupDivine = data.AutoPickupDivine or false
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
_G.AutoPickupMythic = _G.AutoPickupMythic or false
_G.AutoPickupExotic = _G.AutoPickupExotic or false
_G.AutoPickupLimited = _G.AutoPickupLimited or false
_G.AutoPickupSecret = _G.AutoPickupSecret or false
_G.AutoPickupDivine = _G.AutoPickupDivine or false
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
local CurrentBodyVelocity = nil
local CurrentTween = nil

-- مستوى الماء (أي هدف فوق هذا المستوى يتم تجاهله)
local WATER_LEVEL = 2

-- ================== أولويات الأنواع (الأصغر = الأعلى أولوية) ==================
local PriorityMap = {
    Divine = 0,      -- أعلى أولوية
    Secret = 1,
    Limited = 2,
    Exotic = 3,
    Mythic = 4
}

-- ================== نظام التخزين المؤقت (Cache) لتجنب البحث المتكرر ==================
local TargetCache = {
    Time = 0,
    List = {}
}
local CACHE_DURATION = 6  -- تحديث كل 6 ثوانٍ

-- جدول لتخزين وقت أول ظهور لكل كائن (باستخدام weak keys لتجنب تسريب الذاكرة)
local targetFirstSeen = setmetatable({}, {__mode = "k"})

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
    end
    if CurrentBodyVelocity and CurrentBodyVelocity.Parent then
        CurrentBodyVelocity:Destroy()
        CurrentBodyVelocity = nil
    end
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
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

-- ================== دالة الحركة باستخدام Tween (أكثر سلاسة) ==================
local function MoveToPositionTween(targetPosition, duration)
    local character = LocalPlayer.Character
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    RemoveStabilizer()
    
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    
    local goal = {CFrame = CFrame.new(targetPosition)}
    local tween = TweenService:Create(hrp, tweenInfo, goal)
    CurrentTween = tween
    tween:Play()
    
    local success = false
    local startTime = tick()
    while tween.PlaybackState == Enum.PlaybackState.Playing do
        if tick() - startTime > duration + 2 then
            tween:Cancel()
            break
        end
        task.wait()
    end
    
    success = (hrp.Position - targetPosition).Magnitude < 5
    CurrentTween = nil
    return success
end

-- ================== دالة الحركة السلسة (بسرعة ثابتة 60) مع تحسين تحت/فوق البحر ==================
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

    -- حساب المسافة وتقدير الوقت
    local distance = (targetPosition - hrp.Position).Magnitude
    local estimatedTime = distance / NAVIGATION_SPEED
    
    -- إذا كانت المسافة صغيرة، استخدم Tween
    if distance < 30 then
        DebugPrint("مسافة قصيرة، استخدام Tween")
        local success = MoveToPositionTween(targetPosition, estimatedTime)
        _G.Noclip = originalNoclip
        if stabilize and success then
            StabilizePlayer(targetPosition)
        end
        return success
    end

    -- للمسافات الطويلة، استخدم BodyVelocity مع تحسينات
    local bv = Instance.new("BodyVelocity")
    bv.Parent = hrp
    bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    bv.P = 30000
    CurrentBodyVelocity = bv

    local startTime = tick()
    local maxDuration = math.min(60, estimatedTime * 1.5)
    local lastDistance = distance
    local stuckCounter = 0
    local completed = false
    local lastPosition = hrp.Position
    local samePositionCounter = 0

    while _G.Running do
        local currentPos = hrp.Position
        local currentDistance = (targetPosition - currentPos).Magnitude

        -- التحقق من الوصول
        if currentDistance < 3.0 then
            DebugPrint("وصلنا إلى الهدف، المسافة:", currentDistance)
            completed = true
            break
        end

        -- التحقق من الوقت
        if tick() - startTime > maxDuration then
            DebugPrint("انتهى وقت الحركة")
            break
        end

        -- التحقق من الانحشار
        if math.abs(lastDistance - currentDistance) < 0.2 then
            stuckCounter = stuckCounter + 1
        else
            stuckCounter = 0
        end
        lastDistance = currentDistance

        -- التحقق من الوقوف في نفس المكان
        if (currentPos - lastPosition).Magnitude < 0.1 then
            samePositionCounter = samePositionCounter + 1
        else
            samePositionCounter = 0
        end
        lastPosition = currentPos

        -- إذا كان عالقاً، حاول القفز أو الدوران
        if stuckCounter > 30 or samePositionCounter > 50 then
            DebugPrint("انحشار، نحاول فكه")
            hrp.Velocity = Vector3.new(0, 50, 0)
            task.wait(0.2)
            
            local randomDir = Vector3.new(math.random(-10,10)/10, 0, math.random(-10,10)/10).Unit
            bv.Velocity = randomDir * NAVIGATION_SPEED
            task.wait(0.5)
            
            stuckCounter = 0
            samePositionCounter = 0
            continue
        end

        -- حساب اتجاه الحركة
        local direction = (targetPosition - currentPos).Unit
        
        -- تعديل الارتفاع تدريجياً
        if currentPos.Y < WATER_LEVEL and targetPosition.Y > WATER_LEVEL then
            direction = Vector3.new(direction.X, 0.5, direction.Z).Unit
        elseif currentPos.Y > WATER_LEVEL and targetPosition.Y < WATER_LEVEL then
            direction = Vector3.new(direction.X, -0.3, direction.Z).Unit
        end
        
        bv.Velocity = direction * NAVIGATION_SPEED

        -- تفعيل Noclip
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        task.wait(0.05)
    end

    if CurrentBodyVelocity then
        CurrentBodyVelocity:Destroy()
        CurrentBodyVelocity = nil
    end
    
    hrp.Velocity = Vector3.new(0,0,0)
    _G.Noclip = originalNoclip

    -- تصحيح الموقع النهائي
    local finalPos = targetPosition
    if finalPos.Y < -500 then
        finalPos = Vector3.new(finalPos.X, -490, finalPos.Z)
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
                end
            end
            
            if not success then
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("ProximityPrompt") then
                        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.1)
                        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        success = true
                        DebugPrint("تفاعل عبر ProximityPrompt في المحاولة", attempt)
                        break
                    end
                end
            end
        end)
        
        if success then 
            task.wait(1)
            return true 
        end
        task.wait(0.5)
    end
    
    DebugPrint("لم نجد ClickDetector أو ProximityPrompt، نضغط E لمدة 4 ثوانٍ")
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(4)
    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
    return false
end

-- ================== البحث عن الأهداف تحت الماء فقط حسب النوع ==================
local function FindTargetsByType(targetType)
    local char = LocalPlayer.Character
    if not char then return {} end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end

    local targets = {}
    local keyword = targetType

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name
            
            if name:find(keyword, 1, true) then
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

                -- فقط الأهداف التي تكون تحت الماء (Y < WATER_LEVEL)
                if pos and pos.Y < WATER_LEVEL then
                    table.insert(targets, {
                        Object = obj,
                        Position = pos,
                        Distance = (hrp.Position - pos).Magnitude,
                        Type = keyword,
                        Priority = PriorityMap[targetType] or 5
                    })
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.Distance < b.Distance end)
    return targets
end

-- ================== البحث عن جميع الأهداف النشطة تحت الماء مع الترتيب حسب الأولوية ثم المسافة ==================
local function GetAllActiveTargets()
    -- إذا كان الكاش لا يزال صالحاً، نعيد النتائج المخزنة مباشرة
    if tick() - TargetCache.Time < CACHE_DURATION then
        return TargetCache.List
    end

    local targets = {}
    
    if _G.AutoPickupDivine then
        local divineTargets = FindTargetsByType("Divine")
        for _, t in ipairs(divineTargets) do
            table.insert(targets, t)
        end
    end
    
    if _G.AutoPickupSecret then
        local secretTargets = FindTargetsByType("Secret")
        for _, t in ipairs(secretTargets) do
            table.insert(targets, t)
        end
    end
    
    if _G.AutoPickupLimited then
        local limitedTargets = FindTargetsByType("Limited")
        for _, t in ipairs(limitedTargets) do
            table.insert(targets, t)
        end
    end
    
    if _G.AutoPickupExotic then
        local exoticTargets = FindTargetsByType("Exotic")
        for _, t in ipairs(exoticTargets) do
            table.insert(targets, t)
        end
    end
    
    if _G.AutoPickupMythic then
        local mythicTargets = FindTargetsByType("Mythic")
        for _, t in ipairs(mythicTargets) do
            table.insert(targets, t)
        end
    end
    
    -- ترتيب حسب الأولوية (الأصغر = الأكثر ندرة) ثم المسافة
    table.sort(targets, function(a, b)
        if a.Priority == b.Priority then
            return a.Distance < b.Distance
        else
            return a.Priority < b.Priority
        end
    end)
    
    -- تطبيق شرط الـ 90 ثانية: استبعاد الأهداف القديمة
    local now = tick()
    local filteredTargets = {}
    for _, t in ipairs(targets) do
        local obj = t.Object
        if not targetFirstSeen[obj] then
            -- أول مرة نرى هذا الهدف
            targetFirstSeen[obj] = now
        end
        
        local timeSinceFirstSeen = now - targetFirstSeen[obj]
        if timeSinceFirstSeen <= 90 then
            table.insert(filteredTargets, t)
        else
            DebugPrint("تجاهل هدف " .. t.Type .. " بسبب مرور 90 ثانية دون جمعه")
        end
    end
    
    -- تحديث الكاش
    TargetCache.Time = tick()
    TargetCache.List = filteredTargets

    return filteredTargets
end

-- ================== حلقة Auto Pickup الرئيسية ==================
task.spawn(function()
    local failedAttempts = 0
    local lastTargetPosition = nil
    local retryCount = 0

    while _G.Running do
        task.wait(3.5)

        pcall(function()
            local anyEnabled = _G.AutoPickupDivine or _G.AutoPickupSecret or _G.AutoPickupLimited or _G.AutoPickupExotic or _G.AutoPickupMythic
            
            if not anyEnabled or _G.FarmBusy or _G.ReturningToBase then
                return
            end

            local char = LocalPlayer.Character
            if not char then
                DebugPrint("لا توجد شخصية")
                return
            end

            local allTargets = GetAllActiveTargets()

            if #allTargets == 0 then
                DebugPrint("لا توجد أهداف تحت الماء مفعلة حالياً (أو كلها تجاوزت 90 ثانية)")
                failedAttempts = failedAttempts + 1
                if failedAttempts > 5 then
                    task.wait(3)
                    failedAttempts = 0
                end
                return
            end

            -- نأخذ أول هدفين فقط
            local targetsToCollect = {}
            for i = 1, math.min(2, #allTargets) do
                table.insert(targetsToCollect, allTargets[i])
            end

            failedAttempts = 0
            _G.FarmBusy = true
            DebugPrint("عدد الأهداف المقرر جمعها:", #targetsToCollect)

            for index, target in ipairs(targetsToCollect) do
                DebugPrint("نتعامل مع الهدف رقم", index, ":", target.Object.Name, "النوع:", target.Type)

                if lastTargetPosition and (lastTargetPosition - target.Position).Magnitude < 1 then
                    retryCount = retryCount + 1
                    if retryCount > 3 then
                        DebugPrint("فشل متكرر في نفس الهدف، نتخطاه")
                        lastTargetPosition = nil
                        retryCount = 0
                        break
                    end
                else
                    lastTargetPosition = target.Position
                    retryCount = 0
                end

                local targetPos = target.Position
                local approachPos = Vector3.new(targetPos.X, targetPos.Y + 2, targetPos.Z)

                local moveSuccess = MoveToPositionSmooth(approachPos, true)

                if moveSuccess then
                    task.wait(0.5)
                    InteractWithObject(target.Object, 3)
                    task.wait(0.5)
                else
                    DebugPrint("فشل التحرك إلى الهدف، ننتقل للهدف التالي")
                end
            end

            -- بعد الانتهاء من أول هدفين، نعود إلى القاعدة
            ReturnToBase()

            _G.FarmBusy = false
        end)
    end
end)

-- ================== Anti Afk ==================
task.spawn(function()
    while _G.Running do
        task.wait(180)
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
            task.wait(5.0)
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
        task.wait(3000)
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
        task.wait(120)
        pcall(function()
            if _G.AutoFreeChest then
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClaimCustomReward"):FireServer(1)
            end
        end)
    end
end)

-- ================== Auto Collect Reward ==================
task.spawn(function()
    while _G.Running do
        task.wait(120)
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

-- ================== Noclip ==================
task.spawn(function()
    while _G.Running do
        task.wait(1.0)
        pcall(function()
            if _G.Noclip and LocalPlayer.Character then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end)

-- ================== Speed ==================
task.spawn(function()
    while _G.Running do
        task.wait(2.0)
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

-- ================== Garbage Collection ==================
task.spawn(function()
    while _G.Running do
        task.wait(120)
        pcall(function()
            Debris:AddItem(Instance.new("Part"), 0)
            collectgarbage()
            collectgarbage("collect")
            DebugPrint("تم تنظيف الذاكرة")
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
        Name = "Diving For Brainrots | Skan_Dev",
        LoadingTitle = "Ultimate Script (Optimized + 90s Ignore)",
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
        Name = "🎁 Auto Collect Reward (1-12)",
        CurrentValue = _G.AutoCollectReward,
        Callback = function(s)
            _G.AutoCollectReward = s
            SaveSettings()
        end,
    })

    CollectTab:CreateLabel("─── Auto Pickup (تحت الماء فقط) ───")

    local divineToggle = CollectTab:CreateToggle({
        Name = "💎 Divine (أعلى أولوية)",
        CurrentValue = _G.AutoPickupDivine,
        Callback = function(s)
            _G.AutoPickupDivine = s
            SaveSettings()
        end,
    })

    local secretToggle = CollectTab:CreateToggle({
        Name = "⚪ Secret",
        CurrentValue = _G.AutoPickupSecret,
        Callback = function(s)
            _G.AutoPickupSecret = s
            SaveSettings()
        end,
    })

    local limitedToggle = CollectTab:CreateToggle({
        Name = "🟡 Limited",
        CurrentValue = _G.AutoPickupLimited,
        Callback = function(s)
            _G.AutoPickupLimited = s
            SaveSettings()
        end,
    })

    local exoticToggle = CollectTab:CreateToggle({
        Name = "🟣 Exotic",
        CurrentValue = _G.AutoPickupExotic,
        Callback = function(s)
            _G.AutoPickupExotic = s
            SaveSettings()
        end,
    })

    local mythicToggle = CollectTab:CreateToggle({
        Name = "🔴 Mythic",
        CurrentValue = _G.AutoPickupMythic,
        Callback = function(s)
            _G.AutoPickupMythic = s
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
        Name = "🏠 Teleport To Base (T)",
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
            divineToggle:Set(_G.AutoPickupDivine)
            secretToggle:Set(_G.AutoPickupSecret)
            limitedToggle:Set(_G.AutoPickupLimited)
            exoticToggle:Set(_G.AutoPickupExotic)
            mythicToggle:Set(_G.AutoPickupMythic)
        end,
    })

    SettingsTab:CreateButton({
        Name = "❌ Destroy UI",
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

print("✅ Diving For Brainrots Loaded Successfully!")
print("👤 Owner: Skan_Dev")
print("🌊 الهدف: فقط الأهداف تحت الماء (Y < 2)")
print("💎 أولوية: Divine > Secret > Limited > Exotic > Mythic")
print("🎯 يتم جمع أول هدفين فقط ثم العودة للقاعدة")
print("⏱️ إذا مر 90 ثانية على الهدف دون جمعه، يتم تجاهله")
print("🔄 تحديث الكاش كل 6 ثوانٍ")
