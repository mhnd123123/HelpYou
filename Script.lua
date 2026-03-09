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

-- سرعة التنقل الأساسية (للأهداف) = 80، وسرعة التباطؤ = 10
local NAVIGATION_SPEED = 80
local SLOW_SPEED = 10
local SLOW_DISTANCE = 50 -- نبدأ التباطؤ عندما نكون على بعد 50 وحدة من الهدف (زيادة للاستقرار)

-- سرعة العودة للقاعدة (ثابتة بدون تباطؤ)
local RETURN_SPEED = 80

LoadSettings()
_G.Running = true

-- التيار المتر المتابع للحركة (سنستخدم BodyVelocity بشكل أساسي)
local CurrentBodyVelocity = nil
local CurrentStabilizer = nil

-- مستوى الماء (أي هدف فوق هذا المستوى يتم تجاهله)
local WATER_LEVEL = 2

-- ================== أولويات الأنواع ==================
local PriorityMap = {
Divine = 0, -- أعلى أولوية
Secret = 1,
Limited = 2,
Exotic = 3,
Mythic = 4
}

-- ================== نظام التخزين المؤقت وتجاهل الأهداف القديمة ==================
local TargetCache = {
Time = 0,
List = {}
}
local CACHE_DURATION = 4
local targetFirstSeen = setmetatable({}, {__mode = "k"})
local IGNORE_TIME = 60

-- ================== دوال مساعدة ==================
local function DebugPrint(...)
if _G.DebugMode then
print("[DEBUG]", ...)
end
end

local function RemoveStabilizer()
if CurrentStabilizer and CurrentStabilizer.Parent then
CurrentStabilizer:Destroy()
CurrentStabilizer = nil
end
end

local function RemoveCurrentMovers()
if CurrentBodyVelocity and CurrentBodyVelocity.Parent then
CurrentBodyVelocity:Destroy()
CurrentBodyVelocity = nil
end
RemoveStabilizer()
end

local function StabilizePlayer(position)
local character = LocalPlayer.Character
if not character then return end
local hrp = character:FindFirstChild("HumanoidRootPart")
if not hrp then return end

RemoveStabilizer()

local bp = Instance.new("BodyPosition")
bp.Parent = hrp
bp.MaxForce = Vector3.new(9e9, 9e9, 9e9)
bp.P = 25000
bp.D = 10000
bp.Position = position

CurrentStabilizer = bp
DebugPrint("تم تثبيت اللاعب في", position)

task.spawn(function()
task.wait(7)
if CurrentStabilizer then
DebugPrint("إزالة التثبيت بعد 7 ثوانٍ")
RemoveStabilizer()
end
end)
end

-- ================== دالة الحركة إلى هدف (مع تباطؤ) - محسنة ==================
-- targetPosition: الموقع المطلوب الوصول إليه
-- optionalTargetObject: (اختياري) كائن الهدف لفحص وجوده أثناء الحركة
local function MoveToTarget(targetPosition, optionalTargetObject)
local character = LocalPlayer.Character
if not character then DebugPrint("لا يوجد شخصية") return false end
local hrp = character:FindFirstChild("HumanoidRootPart")
if not hrp then DebugPrint("لا يوجد HumanoidRootPart") return false end

RemoveCurrentMovers()

-- إنشاء BodyVelocity للتحكم المباشر بالسرعة
local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
bv.P = 10000 -- قوة دفع معتدلة
bv.Parent = hrp
CurrentBodyVelocity = bv

local startPos = hrp.Position
local distance = (targetPosition - startPos).Magnitude
if distance < 1 then
bv:Destroy()
CurrentBodyVelocity = nil
return true
end

local currentSpeed = NAVIGATION_SPEED
local reached = false

-- حلقة الحركة المتصلة بـ Heartbeat (تحديث كل إطار)
local connection
connection = RunService.Heartbeat:Connect(function()
-- التحقق من وجود الهدف إذا تم تمريره
if optionalTargetObject and not optionalTargetObject.Parent then
DebugPrint("الهدف اختفى أثناء التحرك، نلغي الحركة")
reached = false
connection:Disconnect()
return
end

-- التأكد من وجود الـ HumanoidRootPart
if not hrp or not hrp.Parent then
connection:Disconnect()
return
end

local currentPos = hrp.Position
local remaining = (targetPosition - currentPos).Magnitude

-- التحقق من الوصول
if remaining <= 2.0 then
bv.Velocity = Vector3.new(0,0,0)
hrp.CFrame = CFrame.new(targetPosition)
reached = true
connection:Disconnect()
return
end

-- تحديث السرعة بناءً على المسافة المتبقية
if remaining <= SLOW_DISTANCE then
currentSpeed = SLOW_SPEED
else
currentSpeed = NAVIGATION_SPEED
end

-- حساب الاتجاه وتطبيق السرعة
local direction = (targetPosition - currentPos).Unit
bv.Velocity = direction * currentSpeed
end)

-- انتظار انتهاء الحركة (حتى يتم فصل الاتصال)
repeat
task.wait()
until not connection or not connection.Connected

-- تنظيف
if bv and bv.Parent then
bv:Destroy()
end
CurrentBodyVelocity = nil

return reached
end

-- ================== دالة العودة إلى القاعدة بسرعة ثابتة (بدون تباطؤ) ==================
local BasePosition = Vector3.new(-45, 38, -510)

local function ReturnToBaseFast()
DebugPrint("بدء العودة السريعة إلى القاعدة (سرعة ثابتة 80)")
_G.ReturningToBase = true

local character = LocalPlayer.Character
if not character then DebugPrint("لا يوجد شخصية") return end
local hrp = character:FindFirstChild("HumanoidRootPart")
if not hrp then DebugPrint("لا يوجد HumanoidRootPart") return end

RemoveCurrentMovers()

local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
bv.P = 10000
bv.Parent = hrp
CurrentBodyVelocity = bv

local targetPos = BasePosition + Vector3.new(0, 50, 0) -- ارتفاع آمن
local startPos = hrp.Position
local distance = (targetPos - startPos).Magnitude
if distance < 1 then
bv:Destroy()
CurrentBodyVelocity = nil
_G.ReturningToBase = false
return
end

local reached = false
local connection
connection = RunService.Heartbeat:Connect(function()
if not hrp or not hrp.Parent then
connection:Disconnect()
return
end

local currentPos = hrp.Position
local remaining = (targetPos - currentPos).Magnitude

if remaining <= 2.0 then
bv.Velocity = Vector3.new(0,0,0)
hrp.CFrame = CFrame.new(targetPos)
reached = true
connection:Disconnect()
return
end

local direction = (targetPos - currentPos).Unit
bv.Velocity = direction * RETURN_SPEED
end)

repeat task.wait() until not connection or not connection.Connected

if bv and bv.Parent then
bv:Destroy()
end
CurrentBodyVelocity = nil
DebugPrint("تم الوصول إلى القاعدة")
_G.ReturningToBase = false
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

-- ================== البحث عن الأهداف تحت الماء ==================
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

if pos and pos.Y < WATER_LEVEL then
table.insert(targets, {
Object = obj,
Position = pos,
Distance = (hrp.Position - pos).Magnitude,
Type = keyword,
Priority = PriorityMap[targetType] or 5
})
DebugPrint("هدف " .. keyword .. " تحت الماء:", obj.Name, "عند Y:", pos.Y)
end
end
end
end

table.sort(targets, function(a, b) return a.Distance < b.Distance end)
return targets
end

-- ================== الحصول على جميع الأهداف النشطة ==================
local function GetAllActiveTargets()
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

table.sort(targets, function(a, b)
if a.Priority == b.Priority then
return a.Distance < b.Distance
else
return a.Priority < b.Priority
end
end)

local now = tick()
local filteredTargets = {}
for _, t in ipairs(targets) do
local obj = t.Object
if not targetFirstSeen[obj] then
targetFirstSeen[obj] = now
end

local timeSinceFirstSeen = now - targetFirstSeen[obj]
if timeSinceFirstSeen <= IGNORE_TIME then
table.insert(filteredTargets, t)
else
DebugPrint("تجاهل هدف " .. t.Type .. " بسبب مرور " .. IGNORE_TIME .. " ثانية دون جمعه")
end
end

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
task.wait(4.0)

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
DebugPrint("لا توجد أهداف تحت الماء مفعلة حالياً")
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

-- إذا كان هناك فشل متكرر في نفس الموقع، نتخطاه
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
local approachPos = Vector3.new(targetPos.X, targetPos.Y + 7, targetPos.Z)

-- نمرر كائن الهدف لفحص وجوده أثناء الحركة
local moveSuccess = MoveToTarget(approachPos, target.Object)

if moveSuccess then
StabilizePlayer(approachPos)
task.wait(0.5)
InteractWithObject(target.Object, 3)
task.wait(0.5)
RemoveStabilizer()
else
DebugPrint("فشل التحرك إلى الهدف، ننتقل للهدف التالي")
end
end

-- العودة إلى القاعدة بسرعة ثابتة 80 (بدون تباطؤ)
ReturnToBaseFast()

_G.FarmBusy = false
end)
end
end)

-- ================== Noclip دائم ==================
task.spawn(function()
while _G.Running do
task.wait(0.3)
pcall(function()
if LocalPlayer.Character then
for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
end
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
LoadingTitle = "Ultimate Script (Stable Movement + No Camera Fix | Speed 80)",
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
Name = "🏠 Return To Base (Fast - 80)",
Callback = function()
task.spawn(ReturnToBaseFast)
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
RemoveCurrentMovers()
SaveSettings()
Rayfield:Destroy()
task.wait(1)
error("Script stopped by user")
end,
})

-- اختصارات لوحة المفاتيح
UserInputService.InputBegan:Connect(function(input, gp)
if gp then return end
if input.KeyCode == Enum.KeyCode.T then
task.spawn(ReturnToBaseFast)
elseif input.KeyCode == Enum.KeyCode.G then
_G.SpeedEnabled = not _G.SpeedEnabled
speedToggle:Set(_G.SpeedEnabled)
SaveSettings()
end
end)
end

task.spawn(CreateUI)

end)

print("✅ Diving For Brainrots Loaded Successfully!")
print("👤 Owner: Skan_Dev")
print("🌊 الهدف: فقط الأهداف تحت الماء (Y < 2)")
print("💎 أولوية: Divine > Secret > Limited > Exotic > Mythic")
print("🎯 يتم جمع أول هدفين فقط ثم العودة للقاعدة")
print("⏱️ البحث عن الأهداف كل 4 ثوانٍ - تجاهل الهدف بعد 60 ثانية")
print("🚀 سرعة الذهاب للأهداف: 80 (مع تباطؤ إلى 10 عند الاقتراب)")
print("🏠 سرعة العودة للقاعدة: 80 ثابتة (بدون تباطؤ)")
print("🛑 Noclip دائم (شغال 24/7)")
print("📍 يتم التوجه إلى Y+7 وتثبيت اللاعب هناك")
print("🔄 تحسين الحركة باستخدام BodyVelocity + Heartbeat (لمنع التراجع)")
print("📏 مسافة التباطؤ: 50 وحدة (لثبات أفضل)")
print("📷 تمت إزالة جميع أكواد إصلاح الكاميرا")
