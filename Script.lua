--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.9) ~  Much Love, Ferib 

]]--

task.wait(5);
if (game.PlaceId ~= 70503141143371) then
	return;
end
local function NoErrors(func)
	return pcall(func);
end
NoErrors(function()
	local UserInputService = game:GetService("UserInputService");
	local HttpService = game:GetService("HttpService");
	local Players = game:GetService("Players");
	local VirtualUser = game:GetService("VirtualUser");
	local ReplicatedStorage = game:GetService("ReplicatedStorage");
	local Workspace = game:GetService("Workspace");
	local RunService = game:GetService("RunService");
	local Debris = game:GetService("Debris");
	local LocalPlayer = Players.LocalPlayer;
	local PlayerId = LocalPlayer.UserId;
	local SettingsFileName = "DivingForBrainrots_Rayfield.json";
	local SettingsFolder = "DivingBrainrots_" .. PlayerId;
	local function SaveSettings()
		local settings = {AutoCollect=(_G.AutoCollect or false),AntiAfk=(_G.AntiAfk or false),Noclip=(_G.Noclip or false),AutoFreeChest=(_G.AutoFreeChest or false),SpeedEnabled=(_G.SpeedEnabled or false),SpeedValue=(_G.SpeedValue or 16),AutoPickupRare=(_G.AutoPickupRare or false),MoveSpeed=(_G.MoveSpeed or 35),GodMode=(_G.GodMode or false),DebugMode=(_G.DebugMode or false),AutoBuy={}};
		local blocks = {301,302,303,304,305,306,307};
		for _, id in ipairs(blocks) do
			settings.AutoBuy["Buy" .. id] = _G["Buy" .. id] or false;
		end
		pcall(function()
			if not isfolder(SettingsFolder) then
				makefolder(SettingsFolder);
			end
			writefile(SettingsFolder .. "/" .. SettingsFileName, HttpService:JSONEncode(settings));
		end);
	end
	local function LoadSettings()
		pcall(function()
			if not isfolder(SettingsFolder) then
				makefolder(SettingsFolder);
			end
			local path = SettingsFolder .. "/" .. SettingsFileName;
			if isfile(path) then
				local data = HttpService:JSONDecode(readfile(path));
				_G.AutoCollect = data.AutoCollect or false;
				_G.AntiAfk = data.AntiAfk or false;
				_G.Noclip = data.Noclip or false;
				_G.AutoFreeChest = data.AutoFreeChest or false;
				_G.SpeedEnabled = data.SpeedEnabled or false;
				_G.SpeedValue = data.SpeedValue or 16;
				_G.AutoPickupRare = data.AutoPickupRare or false;
				_G.MoveSpeed = data.MoveSpeed or 35;
				_G.GodMode = data.GodMode or false;
				_G.DebugMode = data.DebugMode or false;
				if data.AutoBuy then
					for k, v in pairs(data.AutoBuy) do
						_G[k] = v or false;
					end
				end
			end
		end);
	end
	_G.AutoCollect = _G.AutoCollect or false;
	_G.AntiAfk = _G.AntiAfk or false;
	_G.Noclip = _G.Noclip or false;
	_G.AutoFreeChest = _G.AutoFreeChest or false;
	_G.SpeedEnabled = _G.SpeedEnabled or false;
	_G.SpeedValue = _G.SpeedValue or 16;
	_G.AutoPickupRare = _G.AutoPickupRare or false;
	_G.MoveSpeed = _G.MoveSpeed or 35;
	_G.GodMode = _G.GodMode or false;
	_G.DebugMode = _G.DebugMode or false;
	_G.FarmBusy = false;
	_G.ReturningToBase = false;
	for i = 301, 307 do
		_G["Buy" .. i] = _G["Buy" .. i] or false;
	end
	LoadSettings();
	_G.Running = true;
	local CurrentStabilizer = nil;
	local GodModeConnections = {};
	local function DebugPrint(...)
		if _G.DebugMode then
			print("[DEBUG]", ...);
		end
	end
	local function RemoveStabilizer()
		if (CurrentStabilizer and CurrentStabilizer.Parent) then
			CurrentStabilizer:Destroy();
			CurrentStabilizer = nil;
			DebugPrint("Stabilizer removed");
		end
	end
	local function StabilizePlayer(position)
		local character = LocalPlayer.Character;
		if not character then
			return;
		end
		local hrp = character:FindFirstChild("HumanoidRootPart");
		if not hrp then
			return;
		end
		RemoveStabilizer();
		local bp = Instance.new("BodyPosition");
		bp.Parent = hrp;
		bp.MaxForce = Vector3.new(9000000000, 9000000000, 9000000000);
		bp.P = 50000;
		bp.D = 5000;
		bp.Position = position;
		CurrentStabilizer = bp;
		DebugPrint("Player stabilized at", position);
	end
	local function MoveToPositionSmooth(targetPosition, speed, stabilize)
		stabilize = ((stabilize == nil) and true) or stabilize;
		local character = LocalPlayer.Character;
		if not character then
			DebugPrint("No character");
			return false;
		end
		local hrp = character:FindFirstChild("HumanoidRootPart");
		if not hrp then
			DebugPrint("No HumanoidRootPart");
			return false;
		end
		local humanoid = character:FindFirstChild("Humanoid");
		if not humanoid then
			DebugPrint("No Humanoid");
			return false;
		end
		RemoveStabilizer();
		hrp.Velocity = Vector3.new(0, 0, 0);
		for _, v in ipairs(hrp:GetChildren()) do
			if v:IsA("BodyMover") then
				v:Destroy();
			end
		end
		local originalNoclip = _G.Noclip;
		_G.Noclip = true;
		local bv = Instance.new("BodyVelocity");
		bv.Parent = hrp;
		bv.MaxForce = Vector3.new(9000000000, 9000000000, 9000000000);
		bv.P = 30000;
		local startTime = tick();
		local maxDuration = 60;
		local lastDistance = (targetPosition - hrp.Position).Magnitude;
		local stuckCounter = 0;
		local completed = false;
		while _G.Running do
			local currentPos = hrp.Position;
			local distance = (targetPosition - currentPos).Magnitude;
			if (distance < 2) then
				DebugPrint("Reached target, distance:", distance);
				completed = true;
				break;
			end
			if ((tick() - startTime) > maxDuration) then
				DebugPrint("Movement timeout");
				break;
			end
			if (math.abs(lastDistance - distance) < 0.3) then
				stuckCounter = stuckCounter + 1;
			else
				stuckCounter = 0;
			end
			lastDistance = distance;
			if (stuckCounter > 40) then
				DebugPrint("Stuck, jumping with CFrame");
				hrp.CFrame = CFrame.new(targetPosition);
				task.wait(0.2);
				completed = true;
				break;
			end
			local direction = (targetPosition - currentPos).Unit;
			bv.Velocity = direction * speed;
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false;
				end
			end
			task.wait(0.05);
		end
		bv:Destroy();
		hrp.Velocity = Vector3.new(0, 0, 0);
		_G.Noclip = originalNoclip;
		local finalPos = targetPosition;
		if (finalPos.Y < -500) then
			finalPos = Vector3.new(finalPos.X, -490, finalPos.Z);
			DebugPrint("Adjusted Y to prevent falling");
		end
		hrp.CFrame = CFrame.new(finalPos);
		task.wait(0.1);
		if (stabilize and completed) then
			StabilizePlayer(finalPos);
		else
			RemoveStabilizer();
		end
		DebugPrint("Moved to", finalPos, "stabilize:", stabilize, "completed:", completed);
		return completed;
	end
	local function SetupGodMode(character)
		if not character then
			return;
		end
		local humanoid = character:FindFirstChild("Humanoid");
		if not humanoid then
			return;
		end
		if GodModeConnections[character] then
			for _, conn in ipairs(GodModeConnections[character]) do
				conn:Disconnect();
			end
		end
		local connections = {};
		connections[#connections + 1] = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			if (_G.GodMode and humanoid and humanoid.Parent) then
				if (humanoid.Health < humanoid.MaxHealth) then
					humanoid.Health = humanoid.MaxHealth;
				end
			end
		end);
		connections[#connections + 1] = humanoid.StateChanged:Connect(function(_, newState)
			if (_G.GodMode and (newState == Enum.HumanoidStateType.Dead)) then
				humanoid.Health = humanoid.MaxHealth;
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false);
				wait(0.1);
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true);
			end
		end);
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				connections[#connections + 1] = part.Touched:Connect(function(hit)
					if not _G.GodMode then
						return;
					end
					local parent = hit.Parent;
					if (parent and parent:IsA("Model")) then
						local name = parent.Name:lower();
						if (name:find("shark") or name:find("requin") or name:find("enemy") or name:find("predator")) then
							local hrp = character:FindFirstChild("HumanoidRootPart");
							if (hrp and hit:IsA("BasePart")) then
								hit.Velocity = (hit.Position - hrp.Position).Unit * 100;
							end
						end
					end
				end);
			end
		end
		connections[#connections + 1] = RunService.Heartbeat:Connect(function()
			if not _G.GodMode then
				return;
			end
			if (not character or not character.Parent) then
				return;
			end
			for _, obj in ipairs(character:GetDescendants()) do
				if (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
					local name = obj.Name:lower();
					if (name:find("breath") or name:find("oxygen") or name:find("drown") or name:find("air")) then
						obj.Value = 100;
					end
				end
			end
		end);
		GodModeConnections[character] = connections;
	end
	if LocalPlayer.Character then
		SetupGodMode(LocalPlayer.Character);
	end
	LocalPlayer.CharacterAdded:Connect(function(newCharacter)
		DebugPrint("Character respawned, reapplying God Mode");
		task.wait(1);
		SetupGodMode(newCharacter);
		RemoveStabilizer();
		_G.FarmBusy = false;
		_G.ReturningToBase = false;
	end);
	task.spawn(function()
		while _G.Running do
			task.wait(1);
			pcall(function()
				if not _G.GodMode then
					return;
				end
				local character = LocalPlayer.Character;
				if not character then
					return;
				end
				local hrp = character:FindFirstChild("HumanoidRootPart");
				if not hrp then
					return;
				end
				local parts = Workspace:FindPartsInRadius(hrp.Position, 50);
				for _, part in ipairs(parts) do
					local parent = part.Parent;
					if (parent and parent:IsA("Model")) then
						local name = parent.Name:lower();
						if (name:find("shark") or name:find("requin") or name:find("tiburon")) then
							parent:Destroy();
							DebugPrint("Removed shark:", parent.Name);
						end
					end
				end
			end);
		end
	end);
	task.spawn(function()
		while _G.Running do
			task.wait(0.1);
			pcall(function()
				if (_G.Noclip and LocalPlayer.Character) then
					for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
						if p:IsA("BasePart") then
							p.CanCollide = false;
						end
					end
				end
			end);
		end
	end);
	task.spawn(function()
		while _G.Running do
			task.wait(0.5);
			pcall(function()
				local c = LocalPlayer.Character;
				if c then
					local h = c:FindFirstChild("Humanoid");
					if h then
						if _G.SpeedEnabled then
							h.WalkSpeed = _G.SpeedValue;
						elseif (h.WalkSpeed ~= 16) then
							h.WalkSpeed = 16;
						end
					end
				end
			end);
		end
	end);
	local BasePosition = Vector3.new(-45, 38, -510);
	local function ReturnToBase()
		DebugPrint("Returning to base");
		_G.ReturningToBase = true;
		MoveToPositionSmooth(BasePosition + Vector3.new(0, 50, 0), _G.MoveSpeed, false);
		_G.ReturningToBase = false;
		DebugPrint("Return to base completed");
	end
	local function InteractWithObject(obj, maxAttempts)
		maxAttempts = maxAttempts or 4;
		for attempt = 1, maxAttempts do
			local success = false;
			pcall(function()
				for _, child in ipairs(obj:GetDescendants()) do
					if child:IsA("ClickDetector") then
						fireclickdetector(child);
						success = true;
						DebugPrint("Interacted via ClickDetector attempt", attempt);
						break;
					elseif child:IsA("ProximityPrompt") then
						game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game);
						task.wait(0.1);
						game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game);
						success = true;
						DebugPrint("Interacted via ProximityPrompt attempt", attempt);
						break;
					end
				end
			end);
			if success then
				return true;
			end
			task.wait(0.5);
		end
		DebugPrint("No ClickDetector or ProximityPrompt, pressing E for 4 seconds");
		game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game);
		task.wait(4);
		game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game);
		return false;
	end
	local function FindRareUnderwaterTargets()
		local char = LocalPlayer.Character;
		if not char then
			return {};
		end
		local hrp = char:FindFirstChild("HumanoidRootPart");
		if not hrp then
			return {};
		end
		local waterLevel = 2;
		local targetKeywords = {"Mythic","Exotic","Limited"};
		local targets = {};
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if (obj:IsA("BasePart") or obj:IsA("Model")) then
				local name = obj.Name;
				local matchedKeyword = nil;
				for _, kw in ipairs(targetKeywords) do
					if name:find(kw, 1, true) then
						matchedKeyword = kw;
						break;
					end
				end
				if matchedKeyword then
					local pos;
					if obj:IsA("BasePart") then
						pos = obj.Position;
					elseif (obj:IsA("Model") and obj.PrimaryPart) then
						pos = obj.PrimaryPart.Position;
					else
						for _, part in ipairs(obj:GetDescendants()) do
							if part:IsA("BasePart") then
								pos = part.Position;
								break;
							end
						end
					end
					if (pos and (pos.Y < waterLevel)) then
						table.insert(targets, {Object=obj,Position=pos,Distance=(hrp.Position - pos).Magnitude,Keyword=matchedKeyword});
						DebugPrint("Rare underwater target:", obj.Name, "Y=", pos.Y, "keyword:", matchedKeyword);
					end
				end
			end
		end
		table.sort(targets, function(a, b)
			return a.Distance < b.Distance;
		end);
		return targets;
	end
	task.spawn(function()
		local failedAttempts = 0;
		while _G.Running do
			task.wait(1.25);
			pcall(function()
				if (not _G.AutoPickupRare or _G.FarmBusy or _G.ReturningToBase) then
					return;
				end
				local char = LocalPlayer.Character;
				if not char then
					DebugPrint("No character");
					return;
				end
				local targets = FindRareUnderwaterTargets();
				if (#targets == 0) then
					DebugPrint("No rare underwater targets");
					failedAttempts = failedAttempts + 1;
					if (failedAttempts > 10) then
						task.wait(3);
					end
					return;
				end
				local target = targets[1];
				failedAttempts = 0;
				_G.FarmBusy = true;
				DebugPrint("Targeting:", target.Object.Name, "distance:", target.Distance);
				MoveToPositionSmooth(target.Position + Vector3.new(0, 3, 0), _G.MoveSpeed, true);
				task.wait(0.75);
				InteractWithObject(target.Object, 4);
				ReturnToBase();
				_G.FarmBusy = false;
			end);
		end
	end);
	task.spawn(function()
		while _G.Running do
			task.wait(60);
			pcall(function()
				if (_G.AntiAfk and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")) then
					LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false);
					VirtualUser:CaptureController();
					VirtualUser:ClickButton2(Vector2.new());
				end
			end);
		end
	end);
	for _, id in ipairs({301,302,303,304,305,306,307}) do
		task.spawn(function()
			while _G.Running do
				task.wait(0.35);
				pcall(function()
					if _G["Buy" .. id] then
						ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PurchaseStock"):InvokeServer(id, 1, "LuckyBlocksStock");
					end
				end);
			end
		end);
	end
	local stands = {"stand1","stand2","stand3","stand4","stand5","stand6","stand7","stand8","stand9","stand10"};
	task.spawn(function()
		while _G.Running do
			task.wait(300);
			pcall(function()
				if _G.AutoCollect then
					for _, stand in ipairs(stands) do
						ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CollectMuseumIncome"):FireServer(stand);
						task.wait(0.2);
					end
				end
			end);
		end
	end);
	task.spawn(function()
		while _G.Running do
			task.wait(60);
			pcall(function()
				if _G.AutoFreeChest then
					ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClaimCustomReward"):FireServer(1);
				end
			end);
		end
	end);
	local function CreateUI()
		if not LocalPlayer:FindFirstChild("PlayerGui") then
			task.wait(5);
			CreateUI();
			return;
		end
		local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))();
		local Window = Rayfield:CreateWindow({Name="Diving For Brainrots",LoadingTitle="Ultimate God Mode",LoadingSubtitle=("Account: " .. LocalPlayer.Name),KeySystem=true,KeySettings={Title="Activation key required",Subtitle="Enter the correct key to load the script",Note="",FileName="Diving2030Key",SaveKey=true,GrabKeyFromSite=false,Key={"Diving2030"}}});
		local BuyTab = Window:CreateTab("Auto Buy", 4483362458);
		local blocks = {{301,"Common"},{302,"Uncommon"},{303,"Rare"},{304,"Epic"},{305,"Legendary"},{306,"Mythic"},{307,"Exotic"}};
		for _, b in ipairs(blocks) do
			BuyTab:CreateToggle({Name=("Buy " .. b[2]),CurrentValue=_G["Buy" .. b[1]],Callback=function(v)
				_G["Buy" .. b[1]] = v;
				SaveSettings();
			end});
		end
		local CollectTab = Window:CreateTab("Auto Collect", 4483362458);
		CollectTab:CreateToggle({Name="⚡ Auto collect (museum)",CurrentValue=_G.AutoCollect,Callback=function(s)
			_G.AutoCollect = s;
			SaveSettings();
		end});
		CollectTab:CreateToggle({Name="🎁 Free exclusive chest",CurrentValue=_G.AutoFreeChest,Callback=function(s)
			_G.AutoFreeChest = s;
			SaveSettings();
		end});
		CollectTab:CreateToggle({Name="💎 Auto pickup rare (mythic/exotic/limited)",CurrentValue=_G.AutoPickupRare,Callback=function(s)
			_G.AutoPickupRare = s;
			SaveSettings();
		end});
		local MiscTab = Window:CreateTab("Misc", 4483362458);
		local noclipToggle = MiscTab:CreateToggle({Name="🚀 Noclip (r)",CurrentValue=_G.Noclip,Callback=function(s)
			_G.Noclip = s;
			SaveSettings();
		end});
		local antiAfkToggle = MiscTab:CreateToggle({Name="🛡️ Anti afk",CurrentValue=_G.AntiAfk,Callback=function(s)
			_G.AntiAfk = s;
			SaveSettings();
		end});
		local speedToggle = MiscTab:CreateToggle({Name="⚡ Speed boost (g)",CurrentValue=_G.SpeedEnabled,Callback=function(s)
			_G.SpeedEnabled = s;
			SaveSettings();
		end});
		local speedSlider = MiscTab:CreateSlider({Name="Speed value",Range={16,100},Increment=1,Suffix=" walkspeed",CurrentValue=_G.SpeedValue,Callback=function(v)
			_G.SpeedValue = v;
			SaveSettings();
		end});
		MiscTab:CreateButton({Name="🏠 Teleport to base (t) [height 50]",Callback=function()
			task.spawn(ReturnToBase);
		end});
		local godModeToggle = MiscTab:CreateToggle({Name="🛡️ God mode (real anti-death)",CurrentValue=_G.GodMode,Callback=function(s)
			_G.GodMode = s;
			SaveSettings();
			print("God mode:", (s and "on (full death protection)") or "off");
		end});
		local debugToggle = MiscTab:CreateToggle({Name="🐞 Debug mode",CurrentValue=_G.DebugMode,Callback=function(s)
			_G.DebugMode = s;
			SaveSettings();
			print("Debug mode:", (s and "on") or "off");
		end});
		local SettingsTab = Window:CreateTab("Settings", 4483362458);
		SettingsTab:CreateButton({Name="💾 Save settings",Callback=SaveSettings});
		SettingsTab:CreateButton({Name="📂 Load settings",Callback=function()
			LoadSettings();
			noclipToggle:Set(_G.Noclip);
			antiAfkToggle:Set(_G.AntiAfk);
			speedToggle:Set(_G.SpeedEnabled);
			speedSlider:Set(_G.SpeedValue);
			godModeToggle:Set(_G.GodMode);
			debugToggle:Set(_G.DebugMode);
		end});
		SettingsTab:CreateButton({Name="❌ Destroy ui (stop script)",Callback=function()
			_G.Running = false;
			RemoveStabilizer();
			SaveSettings();
			Rayfield:Destroy();
			task.wait(1);
			error("Script stopped by user");
		end});
		UserInputService.InputBegan:Connect(function(input, gp)
			if gp then
				return;
			end
			if (input.KeyCode == Enum.KeyCode.R) then
				_G.Noclip = not _G.Noclip;
				noclipToggle:Set(_G.Noclip);
				SaveSettings();
			elseif (input.KeyCode == Enum.KeyCode.T) then
				task.spawn(ReturnToBase);
			elseif (input.KeyCode == Enum.KeyCode.G) then
				_G.SpeedEnabled = not _G.SpeedEnabled;
				speedToggle:Set(_G.SpeedEnabled);
				SaveSettings();
			end
		end);
	end
	task.spawn(CreateUI);
end);
print("✅ Diving For Brainrots - Final version with real god mode");
print("🔍 Targets: mythic, exotic, limited only (any distance)");
print("🛡️ God mode: prevents death entirely + removes sharks");
print("🐞 Enable debug mode in misc tab for details");
print("⏱️ Auto farm timings: search cycle 1.25s, after arrival 0.75s, e press 4s, after fail 3s");
print("📍 Tp base at height 50 (very safe)");
