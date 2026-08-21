local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local lighting = game:GetService("Lighting")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGui"
ScreenGui.ResetOnSpawn = false
local parentSet = false
if type(gethui) == "function" then
	local ok, hui = pcall(gethui)
	if ok and hui then
		ScreenGui.Parent = hui
		parentSet = true
	end
end
if not parentSet then
	ScreenGui.Parent = player:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 420, 0, 480)
Main.Position = UDim2.new(0.5, -210, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 12)
TitleBarCorner.Parent = TitleBar

local FixCorner = Instance.new("Frame")
FixCorner.Size = UDim2.new(1, 0, 0, 12)
FixCorner.Position = UDim2.new(0, 0, 1, -12)
FixCorner.BackgroundColor3 = TitleBar.BackgroundColor3
FixCorner.BorderSizePixel = 0
FixCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Larper920's RBLX Gui"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.Size = UDim2.new(0, 24, 0, 24)
Close.Position = UDim2.new(1, -32, 0, 6)
Close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextSize = 14
Close.Font = Enum.Font.GothamBold
Close.AutoButtonColor = false
Close.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = Close

local Watermark = Instance.new("TextLabel")
Watermark.Name = "Watermark"
Watermark.Size = UDim2.new(0, 190, 0, 26)
Watermark.Position = UDim2.new(1, -200, 1, -34)
Watermark.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Watermark.BackgroundTransparency = 0.4
Watermark.BorderSizePixel = 0
Watermark.Text = "discord.gg/ZvCstEN6F2"
Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
Watermark.TextTransparency = 0.45
Watermark.TextSize = 13
Watermark.Font = Enum.Font.Gotham
Watermark.Parent = ScreenGui

local WatermarkCorner = Instance.new("UICorner")
WatermarkCorner.CornerRadius = UDim.new(0, 8)
WatermarkCorner.Parent = Watermark

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.Size = UDim2.new(0, 24, 0, 24)
crosshair.BackgroundTransparency = 1
crosshair.Visible = false
crosshair.Parent = ScreenGui

local function crossBar(x, y, w, h)
	local b = Instance.new("Frame")
	b.Size = UDim2.new(0, w, 0, h)
	b.Position = UDim2.new(0, x, 0, y)
	b.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	b.BorderSizePixel = 0
	b.Parent = crosshair
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(0, 0, 0)
	st.Thickness = 1
	st.Parent = b
end

crossBar(11, 0, 2, 8)
crossBar(11, 16, 2, 8)
crossBar(0, 11, 8, 2)
crossBar(16, 11, 8, 2)
crossBar(11, 11, 2, 2)

local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "Stats"
statsLabel.Size = UDim2.new(0, 170, 0, 24)
statsLabel.Position = UDim2.new(0, 8, 0, 8)
statsLabel.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
statsLabel.BackgroundTransparency = 0.25
statsLabel.Text = "FPS: -- | Ping: --"
statsLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
statsLabel.TextSize = 13
statsLabel.Font = Enum.Font.Gotham
statsLabel.Visible = false
statsLabel.Parent = ScreenGui

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 6)
statsCorner.Parent = statsLabel

local chatWindow = Instance.new("Frame")
chatWindow.Name = "ChatLog"
chatWindow.Size = UDim2.new(0, 270, 0, 200)
chatWindow.Position = UDim2.new(0, 8, 0, 38)
chatWindow.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
chatWindow.BackgroundTransparency = 0.15
chatWindow.BorderSizePixel = 0
chatWindow.Visible = false
chatWindow.Parent = ScreenGui

local chatWindowCorner = Instance.new("UICorner")
chatWindowCorner.CornerRadius = UDim.new(0, 8)
chatWindowCorner.Parent = chatWindow

local chatScroll = Instance.new("ScrollingFrame")
chatScroll.Size = UDim2.new(1, -8, 1, -8)
chatScroll.Position = UDim2.new(0, 4, 0, 4)
chatScroll.BackgroundTransparency = 1
chatScroll.BorderSizePixel = 0
chatScroll.ScrollBarThickness = 4
chatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
chatScroll.Parent = chatWindow

local chatLayout = Instance.new("UIListLayout")
chatLayout.Padding = UDim.new(0, 2)
chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
chatLayout.Parent = chatScroll

local chatCount = 0

local function addChat(name, msg)
	chatCount = chatCount + 1
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -6, 0, 14)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Text = name .. ": " .. msg
	lbl.TextColor3 = Color3.fromRGB(220, 220, 225)
	lbl.TextSize = 12
	lbl.Font = Enum.Font.Gotham
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = chatCount
	lbl.Parent = chatScroll
	if chatCount > 80 then
		for _, child in ipairs(chatScroll:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
				break
			end
		end
	end
end

Close.MouseButton1Click:Connect(function()
	ScreenGui.Enabled = not ScreenGui.Enabled
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Tab then
		ScreenGui.Enabled = not ScreenGui.Enabled
	end
end)

local TAB_ACTIVE = Color3.fromRGB(80, 140, 255)
local TAB_INACTIVE = Color3.fromRGB(22, 22, 28)

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -16, 0, 24)
tabBar.Position = UDim2.new(0, 8, 0, 40)
tabBar.BackgroundTransparency = 1
tabBar.Parent = Main

local tabButtons = {}
local pages = {}

local function selectTab(name)
	for tabName, data in pairs(tabButtons) do
		data.BackgroundColor3 = (tabName == name) and TAB_ACTIVE or TAB_INACTIVE
	end
	for pageName, page in pairs(pages) do
		page.Visible = (pageName == name)
	end
end

local function createTab(name, xPos)
	local btn = Instance.new("TextButton")
	btn.Name = name .. "_Tab"
	btn.Size = UDim2.new(0, 56, 1, 0)
	btn.Position = UDim2.new(0, xPos, 0, 0)
	btn.BackgroundColor3 = TAB_INACTIVE
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamSemibold
	btn.AutoButtonColor = false
	btn.Parent = tabBar

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		selectTab(name)
	end)
	tabButtons[name] = btn

	local page = Instance.new("Frame")
	page.Name = name .. "_Page"
	page.Position = UDim2.new(0, 8, 0, 70)
	page.Size = UDim2.new(1, -16, 1, -78)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = Main
	pages[name] = page

	return page
end

local rng = Random.new()

local MAX_PARTS = 150
local orbitRadius = 12
local orbitHeight = 6
local orbitSpeed = 2
local orbitList = {}
local orbitConnection = nil
local clickOrbitEnabled = false

local flying = false
local flySpeed = 60
local flyConn = nil

local swimming = false
local swimConn = nil

local noclipSaved = setmetatable({}, { __mode = "k" })
local noclipConn = nil
local noclipFrames = 0

local walkSpeedValue = 16
local jumpPowerValue = 50

local infJumpConn = nil
local clickTPOn = false

local gravGunOn = false
local grabbedPart = nil
local gravGunConn = nil

local flingOn = false

local spinOn = false
local spinConn = nil

local rainOn = false
local rainConn = nil
local rainParts = {}
local rainAcc = 0

local espEnabled = false
local espObjects = {}
local espPlayerConns = {}
local espGlobalConns = {}

local fbSaved = nil
local nfSaved = nil

local afkConn = nil

local magnetConn = nil
local bombOn = false
local ghostConn = nil
local ghostList = {}
local ghostAcc = 0
local ghostLastPos = nil
local rainbowConn = nil
local rideOn = false
local rideTarget = nil
local rideConn = nil
local xraySaved = setmetatable({}, { __mode = "k" })
local xrayConn = nil
local xrayFrames = 0
local boostRecords = {}
local boostConn = nil
local boostFrames = 0
local boostShadowSaved = nil
local crosshairOn = false
local statsOn = false
local statsConn = nil
local statsAcc = 0
local statsFrames = 0
local chatOn = false
local chatConns = {}
local autoRejoinConn = nil
local tpPlayerOn = false

local waypoints = {}
local wpButtons = {}

local PANTS_IDS = {
	129459077, 5197702014, 144076760, 5246950670, 129458426, 398634487,
	398633812, 398635338, 382537806, 382538503, 382537569, 382537950
}

local SHIRT_IDS = {
	144076358, 607785314, 398633584, 144076436, 398634295, 3670737444,
	382538059, 398635081, 382537702, 382537085, 382538295
}

local function isInCharacter(part)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and part:IsDescendantOf(plr.Character) then
			return true
		end
	end
	return false
end

local function randomColor()
	return Color3.fromHSV(rng:NextNumber(), rng:NextNumber(0.55, 1), rng:NextNumber(0.35, 1))
end

local function startLoop()
	if orbitConnection then return end
	orbitConnection = RunService.Heartbeat:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local n = #orbitList
		if n == 0 then return end
		local base = (os.clock() * orbitSpeed) % (math.pi * 2)
		for i = n, 1, -1 do
			local part = orbitList[i]
			if not part.Parent then
				table.remove(orbitList, i)
			else
				local angle = base + (i / n) * math.pi * 2
				part.CFrame = CFrame.new(root.Position + Vector3.new(math.cos(angle) * orbitRadius, orbitHeight, math.sin(angle) * orbitRadius))
				part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
		end
	end)
end

local function stopLoopIfEmpty()
	if #orbitList == 0 and orbitConnection then
		orbitConnection:Disconnect()
		orbitConnection = nil
	end
end

local function addToOrbit(part)
	if table.find(orbitList, part) then return end
	if #orbitList >= MAX_PARTS then return end
	table.insert(orbitList, part)
	startLoop()
end

local function removeFromOrbit(part)
	local i = table.find(orbitList, part)
	if i then
		table.remove(orbitList, i)
	end
	stopLoopIfEmpty()
end

local function clearOrbit()
	for k in pairs(orbitList) do
		orbitList[k] = nil
	end
	stopLoopIfEmpty()
end

local tornadoEnabled = false
local tornadoRadius = 50
local tornadoHeight = 100
local tornadoRotSpeed = 10
local tornadoStrength = 1000
local tornadoParts = {}

local function tornadoRetain(part)
	if part:IsA("BasePart") and not part.Anchored and part:IsDescendantOf(workspace) then
		if part.Parent == player.Character or part:IsDescendantOf(player.Character) then
			return false
		end
		part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
		part.CanCollide = false
		return true
	end
	return false
end

local function tornadoAdd(part)
	if tornadoRetain(part) and not table.find(tornadoParts, part) then
		table.insert(tornadoParts, part)
	end
end

local function tornadoRemove(part)
	local i = table.find(tornadoParts, part)
	if i then
		table.remove(tornadoParts, i)
	end
end

for _, part in pairs(workspace:GetDescendants()) do
	tornadoAdd(part)
end
workspace.DescendantAdded:Connect(tornadoAdd)
workspace.DescendantRemoving:Connect(tornadoRemove)

pcall(function()
	player.ReplicationFocus = workspace
end)

RunService.Heartbeat:Connect(function()
	pcall(function()
		sethiddenproperty(player, "SimulationRadius", math.huge)
	end)
	if not tornadoEnabled then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local center = root.Position
	for _, part in pairs(tornadoParts) do
		if part.Parent and not part.Anchored then
			local pos = part.Position
			local distance = (Vector3.new(pos.X, center.Y, pos.Z) - center).Magnitude
			local angle = math.atan2(pos.Z - center.Z, pos.X - center.X)
			local newAngle = angle + math.rad(tornadoRotSpeed)
			local targetPos = Vector3.new(
				center.X + math.cos(newAngle) * math.min(tornadoRadius, distance),
				center.Y + (tornadoHeight * math.abs(math.sin((pos.Y - center.Y) / tornadoHeight))),
				center.Z + math.sin(newAngle) * math.min(tornadoRadius, distance)
			)
			local directionToTarget = (targetPos - part.Position).unit
			part.Velocity = directionToTarget * tornadoStrength
		end
	end
end)

local COOLKID_FACE = "rbxassetid://8408806737"
local coolkidApplied = false
local coolkidSavedTextures = {}
local coolkidSavedSky = nil
local coolkidSavedTime = nil
local coolkidEmitters = {}

local function applyCoolkidAttack()
	if coolkidApplied then return end
	coolkidApplied = true

	local sky = lighting:FindFirstChildOfClass("Sky")
	if sky then
		coolkidSavedSky = {
			bk = sky.SkyboxBk,
			dn = sky.SkyboxDn,
			ft = sky.SkyboxFt,
			lf = sky.SkyboxLf,
			rt = sky.SkyboxRt,
			up = sky.SkyboxUp
		}
	else
		sky = Instance.new("Sky")
		sky.Parent = lighting
	end
	coolkidSavedTime = lighting.TimeOfDay
	sky.SkyboxBk = COOLKID_FACE
	sky.SkyboxDn = COOLKID_FACE
	sky.SkyboxFt = COOLKID_FACE
	sky.SkyboxLf = COOLKID_FACE
	sky.SkyboxRt = COOLKID_FACE
	sky.SkyboxUp = COOLKID_FACE
	lighting.TimeOfDay = "12:00:00"

	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Decal") then
			coolkidSavedTextures[obj] = obj.Texture
			obj.Texture = COOLKID_FACE
		elseif obj:IsA("SpecialMesh") then
			coolkidSavedTextures[obj] = obj.TextureId
			obj.TextureId = COOLKID_FACE
		end
	end

	for _, plr in pairs(Players:GetPlayers()) do
		local char = plr.Character
		if char then
			local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
			if torso then
				local emit = Instance.new("ParticleEmitter")
				emit.Texture = COOLKID_FACE
				emit.Rate = 10
				emit.Lifetime = NumberRange.new(1, 2)
				emit.Speed = NumberRange.new(2, 5)
				emit.Parent = torso
				coolkidEmitters[emit] = true
			end
		end
	end
end

local function restoreCoolkidAttack()
	if not coolkidApplied then return end
	coolkidApplied = false

	for obj, tex in pairs(coolkidSavedTextures) do
		pcall(function()
			if obj:IsA("SpecialMesh") then
				obj.TextureId = tex
			else
				obj.Texture = tex
			end
		end)
	end
	coolkidSavedTextures = {}

	local sky = lighting:FindFirstChildOfClass("Sky")
	if sky then
		if coolkidSavedSky then
			sky.SkyboxBk = coolkidSavedSky.bk
			sky.SkyboxDn = coolkidSavedSky.dn
			sky.SkyboxFt = coolkidSavedSky.ft
			sky.SkyboxLf = coolkidSavedSky.lf
			sky.SkyboxRt = coolkidSavedSky.rt
			sky.SkyboxUp = coolkidSavedSky.up
		else
			sky:Destroy()
		end
	end
	if coolkidSavedTime then
		lighting.TimeOfDay = coolkidSavedTime
	end

	for emit in pairs(coolkidEmitters) do
		pcall(function()
			emit:Destroy()
		end)
	end
	coolkidEmitters = {}
end

local RARITY_NAMES = { "All", "Common", "Uncommon", "Rare", "Legendary", "Mythical", "Divine", "Prismatic" }
local RARITY_INDEX = { Common = 1, Uncommon = 2, Rare = 3, Legendary = 4, Mythical = 5, Divine = 6, Prismatic = 7 }

local GAG_SEED_RARITY = {
	Carrot = 1,
	Strawberry = 2,
	Blueberry = 2,
	["Orange Tulip"] = 2,
	Tomato = 3,
	Corn = 3,
	Daffodil = 3,
	Watermelon = 4,
	Pumpkin = 4,
	Apple = 4,
	Bamboo = 4,
	Coconut = 5,
	Cactus = 5,
	["Dragon Fruit"] = 5,
	Mango = 5,
	Grape = 6,
	Mushroom = 6,
	Pepper = 6,
	Beanstalk = 6
}

local gagHarvestOn = false
local gagSellOn = false
local gagBuyOn = false
local gagStealOn = false
local gagHarvestMin = 1
local gagSellMin = 1
local gagBuyMin = 1
local gagStealMin = 1

local gagSellRemote = nil
local gagBuyRemote = nil

local function gagFindRemotes()
	if gagSellRemote and gagBuyRemote then return end
	local sellNames = { "sell_inventory", "sellinventory", "sell_all", "sellall", "sell_plant", "sellplants", "sell" }
	local buyNames = { "buyseedstock", "buyseed", "buy_seeds", "buyseeds", "purchaserseed", "purchasingseed", "buy" }
	local found = {}
	pcall(function()
		for _, obj in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
			if obj:IsA("RemoteEvent") then
				table.insert(found, obj)
			end
		end
	end)
	for _, want in ipairs(sellNames) do
		for _, r in ipairs(found) do
			if string.lower(r.Name) == want then
				gagSellRemote = r
				break
			end
		end
		if gagSellRemote then break end
	end
	for _, want in ipairs(buyNames) do
		for _, r in ipairs(found) do
			if string.lower(r.Name) == want then
				gagBuyRemote = r
				break
			end
		end
		if gagBuyRemote then break end
	end
end

local function gagGetRarityValue(holder)
	local attr = holder:GetAttribute("Rarity") or holder:GetAttribute("Variant")
	if type(attr) == "string" and RARITY_INDEX[attr] then
		return RARITY_INDEX[attr]
	end
	local valObj = holder:FindFirstChild("Variant") or holder:FindFirstChild("Rarity")
	if valObj and (valObj:IsA("StringValue") or valObj:IsA("ObjectValue")) then
		local v = valObj.Value
		if type(v) == "string" and RARITY_INDEX[v] then
			return RARITY_INDEX[v]
		end
		if type(v) == "userdata" and RARITY_INDEX[v.Name] then
			return RARITY_INDEX[v.Name]
		end
	end
	return nil
end

local function gagModelRarity(model)
	if not model then return nil end
	local ok, result = pcall(gagGetRarityValue, model)
	if ok and result then return result end
	local named = GAG_SEED_RARITY[model.Name]
	if named then return named end
	local parent = model.Parent
	if parent then
		local ok2, result2 = pcall(gagGetRarityValue, parent)
		if ok2 and result2 then return result2 end
		local named2 = GAG_SEED_RARITY[parent.Name]
		if named2 then return named2 end
	end
	return nil
end

local GAG_HARVEST_WORDS = { "harvest", "collect", "pick" }
local GAG_STEAL_WORDS = { "steal", "carry", "snatch", "rob", "take" }

local function gagPromptMatches(prompt, words)
	local text = string.lower(prompt.ActionText or "") .. " " .. string.lower(prompt.ObjectText or "")
	for _, word in ipairs(words) do
		if string.find(text, word, 1, true) then
			return true
		end
	end
	return false
end

local function gagFirePrompt(prompt)
	if type(fireproximityprompt) == "function" then
		pcall(fireproximityprompt, prompt)
	else
		pcall(function()
			prompt:InputHoldBegin()
			wait(0.15)
			prompt:InputHoldEnd()
		end)
	end
end

local gagClock = 0
local gagSellTick = 0
gagLoopConn = RunService.Heartbeat:Connect(function(dt)
	gagClock = gagClock + dt
	if gagClock < 0.5 then return end
	gagClock = 0
	gagSellTick = gagSellTick + 1
	if not ScreenGui.Parent then
		gagLoopConn:Disconnect()
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if (gagHarvestOn or gagStealOn) and root then
		local prompts = {}
		pcall(function()
			for _, obj in pairs(workspace:GetDescendants()) do
				if obj:IsA("ProximityPrompt") and obj.Enabled then
					table.insert(prompts, obj)
				end
			end
		end)
		for _, prompt in ipairs(prompts) do
			local isHarvest = gagHarvestOn and gagPromptMatches(prompt, GAG_HARVEST_WORDS)
			local isSteal = gagStealOn and gagPromptMatches(prompt, GAG_STEAL_WORDS)
			if isHarvest or isSteal then
				local holder = prompt.Parent
				local pos = nil
				pcall(function()
					pos = holder:IsA("BasePart") and holder.Position or holder:FindFirstChildWhichIsA("BasePart")
					if type(pos) ~= "Vector3" and pos then
						pos = pos.Position
					end
				end)
				local inRange = true
				if pos then
					inRange = (pos - root.Position).Magnitude < 30
				end
				if inRange then
					local rarity = gagModelRarity(holder)
					local minReq = isHarvest and gagHarvestMin or gagStealMin
					if rarity == nil then
						if minReq == 1 then
							gagFirePrompt(prompt)
						end
					elseif rarity >= minReq - 1 then
						gagFirePrompt(prompt)
					end
				end
			end
		end
	end

	if gagSellOn or gagBuyOn then
		gagFindRemotes()
	end
	if gagSellOn and gagSellRemote and gagSellTick % 4 == 0 then
		pcall(function()
			gagSellRemote:FireServer()
		end)
	end
	if gagBuyOn and gagBuyRemote and gagSellTick % 4 == 0 then
		for seedName, seedRarity in pairs(GAG_SEED_RARITY) do
			if seedRarity >= gagBuyMin - 1 then
				pcall(function()
					gagBuyRemote:FireServer(seedName)
				end)
			end
		end
	end
end)

local clickFlingOn = false

local function flingCharacter(char)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	root.AssemblyLinearVelocity = Vector3.new(math.random(-200, 200), 400, math.random(-200, 200))
	root.AssemblyAngularVelocity = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))
end

mouse.Button1Down:Connect(function()
	if not clickFlingOn then return end
	local overGui = UserInputService:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
	if overGui and #overGui > 0 then return end
	local target = mouse.Target
	if not target then return end
	local hitPlayer = Players:GetPlayerFromCharacter(target.Parent)
	if not hitPlayer and target.Parent and target.Parent.Parent then
		hitPlayer = Players:GetPlayerFromCharacter(target.Parent.Parent)
	end
	if hitPlayer and hitPlayer ~= player then
		flingCharacter(hitPlayer.Character)
	end
end)

local chatSpamOn = false
local chatSpamMsg = ""
local chatSpamClock = 0

local function sendChatMessage(msg)
	local sent = false
	pcall(function()
		TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
		sent = true
	end)
	if not sent then
		pcall(function()
			local legacy = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
			if legacy and legacy:FindFirstChild("SayMessageRequest") then
				legacy.SayMessageRequest:FireServer(msg, "All")
			end
		end)
	end
end

chatSpamConn = RunService.Heartbeat:Connect(function(dt)
	if not chatSpamOn or chatSpamMsg == "" then return end
	chatSpamClock = chatSpamClock + dt
	if chatSpamClock >= 1 then
		chatSpamClock = 0
		sendChatMessage(chatSpamMsg)
	end
end)

local boardSound = Instance.new("Sound")
boardSound.Name = "LarperBoard"
boardSound.Volume = 2
boardSound.Parent = game:GetService("SoundService")

local function boardPlay(idText)
	local id = string.match(idText, "%d+")
	if not id then return end
	boardSound.SoundId = "rbxassetid://" .. id
	boardSound:Play()
end

local FLOOR_KEYWORDS = { "baseplate", "floor", "ground", "spawn", "road", "sidewalk", "pavement", "concrete" }

local function isFloorPart(part)
	local name = string.lower(part.Name)
	for _, keyword in ipairs(FLOOR_KEYWORDS) do
		if string.find(name, keyword, 1, true) then
			return true
		end
	end
	if part.Size.Y <= 3 and part.Size.X >= 80 and part.Size.Z >= 80 then
		return true
	end
	return false
end

local function applyNoclip()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not noclipSaved[obj] and obj.CanCollide and not isFloorPart(obj) and not isInCharacter(obj) then
			noclipSaved[obj] = true
			obj.CanCollide = false
		end
	end
end

local function clearNoclip()
	for part in pairs(noclipSaved) do
		if part.Parent then
			part.CanCollide = true
		end
	end
	for k in pairs(noclipSaved) do
		noclipSaved[k] = nil
	end
end

local function spawnGhost()
	local char = player.Character
	if not char then return end
	char.Archivable = true
	local c = char:Clone()
	char.Archivable = false
	if not c then return end
	c.Name = "Ghost"
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BaseScript") or d:IsA("Animator") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	c.Parent = workspace
	table.insert(ghostList, c)
	if #ghostList > 12 then
		local old = table.remove(ghostList, 1)
		if old.Parent then
			old:Destroy()
		end
	end
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			TweenService:Create(d, TweenInfo.new(0.55), { Transparency = 1 }):Play()
		end
	end
	task.delay(0.65, function()
		local idx = table.find(ghostList, c)
		if idx then
			table.remove(ghostList, idx)
		end
		if c.Parent then
			c:Destroy()
		end
	end)
end

local function applyXray()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj ~= workspace.Terrain and not isInCharacter(obj) and not xraySaved[obj] and obj.Transparency < 0.5 and obj.Size.Magnitude >= 14 then
			xraySaved[obj] = obj.Transparency
			obj.Transparency = 0.75
		end
	end
end

local function clearXray()
	for part, t in pairs(xraySaved) do
		if part.Parent then
			part.Transparency = t
		end
	end
	for k in pairs(xraySaved) do
		xraySaved[k] = nil
	end
end

local function boostApply()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("MeshPart") then
			if obj.TextureID ~= "" then
				table.insert(boostRecords, { o = obj, p = "TextureID", v = obj.TextureID })
				obj.TextureID = ""
			end
		elseif obj:IsA("SpecialMesh") then
			if obj.TextureId ~= "" then
				table.insert(boostRecords, { o = obj, p = "TextureId", v = obj.TextureId })
				obj.TextureId = ""
			end
		elseif obj:IsA("Decal") then
			if obj.Texture ~= "" then
				table.insert(boostRecords, { o = obj, p = "Texture", v = obj.Texture })
				obj.Texture = ""
			end
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
			if obj.Enabled then
				table.insert(boostRecords, { o = obj, p = "Enabled", v = true })
				obj.Enabled = false
			end
		end
	end
end

local function boostClear()
	for i = #boostRecords, 1, -1 do
		local r = boostRecords[i]
		if r.o and r.o.Parent then
			r.o[r.p] = r.v
		end
		boostRecords[i] = nil
	end
end

	local function flyStep(dt)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local cam = workspace.CurrentCamera
		if not root or not cam then return end
		if UserInputService:GetFocusedTextBox() then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum:GetState() ~= Enum.HumanoidStateType.Physics then
			hum:ChangeState(Enum.HumanoidStateType.Physics)
		end
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		local dir = Vector3.new(0, 0, 0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			dir = dir + look
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			dir = dir - look
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			dir = dir + right
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			dir = dir - right
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			dir = dir + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			dir = dir - Vector3.new(0, 1, 0)
		end
		if dir.Magnitude > 0 then
			root.CFrame = root.CFrame + dir.Unit * flySpeed * dt
		end
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end

local function applySpeedSettings()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.UseJumpPower = true
		hum.JumpPower = jumpPowerValue
		hum.WalkSpeed = walkSpeedValue
	end
end

	local function releaseGrabbed(throw)
		local p = grabbedPart
		grabbedPart = nil
		if p and p.Parent and throw then
			p.AssemblyLinearVelocity = workspace.CurrentCamera.CFrame.LookVector * 85 + Vector3.new(0, 15, 0)
		end
	end

local function espSetup(plr, char)
	local old = espObjects[plr]
	if old then
		if old.hl then old.hl:Destroy() end
		if old.bb then old.bb:Destroy() end
	end
	local c = Color3.fromHSV(rng:NextNumber(), 0.75, 1)
	local hl = Instance.new("Highlight")
	hl.FillColor = c
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.65
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = char
	local bb = Instance.new("BillboardGui")
	bb.Name = "ESP_Name"
	bb.Adornee = char
	bb.Size = UDim2.new(0, 140, 0, 22)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 500
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = plr.Name
	tl.TextColor3 = c
	tl.TextStrokeTransparency = 0.4
	tl.TextSize = 13
	tl.Font = Enum.Font.GothamBold
	tl.Parent = bb
	bb.Parent = char
	espObjects[plr] = { hl = hl, bb = bb }
end

local function espAdd(plr)
	if plr == player or espPlayerConns[plr] then return end
	if plr.Character then
		espSetup(plr, plr.Character)
	end
	espPlayerConns[plr] = plr.CharacterAdded:Connect(function(char)
		if espEnabled then
			espSetup(plr, char)
		end
	end)
end

local function espRemove(plr)
	local o = espObjects[plr]
	if o then
		if o.hl then o.hl:Destroy() end
		if o.bb then o.bb:Destroy() end
		espObjects[plr] = nil
	end
	if espPlayerConns[plr] then
		espPlayerConns[plr]:Disconnect()
		espPlayerConns[plr] = nil
	end
end

local function setESP(on)
	espEnabled = on
	if on then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				espAdd(plr)
			end
		end
		table.insert(espGlobalConns, Players.PlayerAdded:Connect(espAdd))
		table.insert(espGlobalConns, Players.PlayerRemoving:Connect(espRemove))
	else
		for _, c in ipairs(espGlobalConns) do
			c:Disconnect()
		end
		espGlobalConns = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			espRemove(plr)
		end
	end
end

local function setFullbright(on)
	if on then
		fbSaved = {
			Brightness = lighting.Brightness,
			ClockTime = lighting.ClockTime,
			FogEnd = lighting.FogEnd,
			FogStart = lighting.FogStart,
			GlobalShadows = lighting.GlobalShadows,
			Ambient = lighting.Ambient,
			OutdoorAmbient = lighting.OutdoorAmbient
		}
		lighting.Brightness = 2.5
		lighting.ClockTime = 14
		lighting.GlobalShadows = false
		lighting.FogEnd = 100000
		lighting.FogStart = 0
		lighting.Ambient = Color3.fromRGB(140, 140, 140)
		lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
	else
		if fbSaved then
			lighting.Brightness = fbSaved.Brightness
			lighting.ClockTime = fbSaved.ClockTime
			lighting.GlobalShadows = fbSaved.GlobalShadows
			lighting.Ambient = fbSaved.Ambient
			lighting.OutdoorAmbient = fbSaved.OutdoorAmbient
			fbSaved = nil
		end
	end
end

local function setNoFog(on)
	if on then
		nfSaved = { FogEnd = lighting.FogEnd, FogStart = lighting.FogStart }
		lighting.FogEnd = 100000
		lighting.FogStart = 0
	else
		if nfSaved then
			lighting.FogEnd = nfSaved.FogEnd
			lighting.FogStart = nfSaved.FogStart
			nfSaved = nil
		end
	end
end

local function refreshWaypoints()
	for _, b in ipairs(wpButtons) do
		b:Destroy()
	end
	wpButtons = {}
	local startY = 182
	for i, wp in ipairs(waypoints) do
		local tpBtn = Instance.new("TextButton")
		tpBtn.Size = UDim2.new(0, 150, 0, 26)
		tpBtn.Position = UDim2.new(0, 14, 0, startY + (i - 1) * 30)
		tpBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
		tpBtn.Text = wp.name
		tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		tpBtn.TextSize = 13
		tpBtn.Font = Enum.Font.Gotham
		tpBtn.AutoButtonColor = false
		tpBtn.Parent = pages.Util

		local tpCorner = Instance.new("UICorner")
		tpCorner.CornerRadius = UDim.new(0, 6)
		tpCorner.Parent = tpBtn

		tpBtn.MouseButton1Click:Connect(function()
			local char = player.Character
			if char then
				char:PivotTo(wp.cframe)
			end
		end)

		local delBtn = Instance.new("TextButton")
		delBtn.Size = UDim2.new(0, 26, 0, 26)
		delBtn.Position = UDim2.new(0, 170, 0, startY + (i - 1) * 30)
		delBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
		delBtn.Text = "X"
		delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		delBtn.TextSize = 12
		delBtn.Font = Enum.Font.GothamBold
		delBtn.AutoButtonColor = false
		delBtn.Parent = pages.Util

		local delCorner = Instance.new("UICorner")
		delCorner.CornerRadius = UDim.new(0, 6)
		delCorner.Parent = delBtn

		delBtn.MouseButton1Click:Connect(function()
			table.remove(waypoints, i)
			refreshWaypoints()
		end)

		table.insert(wpButtons, tpBtn)
		table.insert(wpButtons, delBtn)
	end
end

local function createToggle(parent, text, xPos, yPos, onChanged)
	local btn = Instance.new("TextButton")
	btn.Name = text
	btn.Size = UDim2.new(0, 192, 0, 32)
	btn.Position = UDim2.new(0, xPos, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	btn.Text = text .. ": OFF"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamSemibold
	btn.AutoButtonColor = false
	btn.Parent = parent

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	local state = false
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.Text = text .. (state and ": ON" or ": OFF")
		btn.BackgroundColor3 = state and Color3.fromRGB(46, 150, 88) or Color3.fromRGB(22, 22, 28)
		onChanged(state)
	end)
	return btn
end

local function createButton(parent, text, xPos, yPos, onClick)
	local btn = Instance.new("TextButton")
	btn.Name = text
	btn.Size = UDim2.new(0, 192, 0, 32)
	btn.Position = UDim2.new(0, xPos, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamSemibold
	btn.AutoButtonColor = false
	btn.Parent = parent

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function createSlider(parent, name, yPos, min, max, default, decimals, callback)
	local container = Instance.new("Frame")
	container.Name = name
	container.Size = UDim2.new(1, -28, 0, 34)
	container.Position = UDim2.new(0, 14, 0, yPos)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 16)
	label.BackgroundTransparency = 1
	label.Text = string.format("%s: %." .. decimals .. "f", name, default)
	label.TextColor3 = Color3.fromRGB(195, 195, 200)
	label.TextSize = 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 0, 22)
	bar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	bar.BorderSizePixel = 0
	bar.Parent = container

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local ratio = (default - min) / (max - min)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(ratio, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
	knob.BorderSizePixel = 0
	knob.Parent = bar

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local dragging = false

	local function setFromX(x)
		local r = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local value = min + (max - min) * r
		callback(value)
		label.Text = string.format("%s: %." .. decimals .. "f", name, value)
		fill.Size = UDim2.new(r, 0, 1, 0)
		knob.Position = UDim2.new(r, 0, 0.5, 0)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
end

local function createLabel(parent, text, yPos)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -28, 0, 20)
	lbl.Position = UDim2.new(0, 14, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextSize = 15
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
	return lbl
end

local funPage = createTab("Fun", 0)
local movePage = createTab("Move", 58)
local avatarPage = createTab("Avatar", 116)
local visPage = createTab("Vis", 174)
local utilPage = createTab("Util", 232)
local partsPage = createTab("Parts", 290)
local gag2Page = createTab("Gag 2", 348)

createToggle(funPage, "Orbit All", 14, 6, function(state)
	if state then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if #orbitList >= MAX_PARTS then break end
			if obj:IsA("BasePart") and not obj.Anchored and not isInCharacter(obj) then
				addToOrbit(obj)
			end
		end
	else
		clearOrbit()
	end
end)

createToggle(funPage, "Click Orbit", 214, 6, function(state)
	clickOrbitEnabled = state
end)

createSlider(funPage, "Distance", 44, 5, 50, 12, 0, function(value)
	orbitRadius = value
end)

createSlider(funPage, "Height", 80, 0, 40, 6, 0, function(value)
	orbitHeight = value
end)

createSlider(funPage, "Speed", 116, 0, 10, 2, 1, function(value)
	orbitSpeed = value
end)

createToggle(funPage, "Gravity Gun", 14, 154, function(state)
	gravGunOn = state
	if state then
		if not gravGunConn then
			gravGunConn = RunService.Heartbeat:Connect(function()
				if grabbedPart and grabbedPart.Parent then
					grabbedPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 2, 0))
					grabbedPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					grabbedPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				end
			end)
		end
	else
		releaseGrabbed(false)
		if gravGunConn then
			gravGunConn:Disconnect()
			gravGunConn = nil
		end
	end
end)

createToggle(funPage, "Fling", 214, 154, function(state)
	flingOn = state
end)

createToggle(funPage, "Spin", 14, 192, function(state)
	spinOn = state
	if state then
		if not spinConn then
			spinConn = RunService.Heartbeat:Connect(function(dt)
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = root.CFrame * CFrame.Angles(0, dt * 12, 0)
				end
			end)
		end
	else
		if spinConn then
			spinConn:Disconnect()
			spinConn = nil
		end
	end
end)

createToggle(funPage, "Part Rain", 214, 192, function(state)
	rainOn = state
	if state then
		rainAcc = 0
		rainConn = RunService.Heartbeat:Connect(function(dt)
			rainAcc = rainAcc + dt
			if rainAcc >= 0.2 then
				rainAcc = 0
				local targets = {}
				for _, plr in ipairs(Players:GetPlayers()) do
					local c = plr.Character
					local r = c and c:FindFirstChild("HumanoidRootPart")
					if r then
						table.insert(targets, r.Position)
					end
				end
				if #targets > 0 then
					local pos = targets[rng:NextInteger(1, #targets)]
					local s = rng:NextNumber(1, 3)
					local p = Instance.new("Part")
					p.Size = Vector3.new(s, s, s)
					p.Color = Color3.fromHSV(rng:NextNumber(), 1, 1)
					p.Material = Enum.Material.Neon
					p.CanCollide = false
					p.Anchored = false
					p.CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-10, 10), 30, rng:NextNumber(-10, 10)))
					p.Parent = workspace
					table.insert(rainParts, p)
					if #rainParts > 80 then
						local oldp = table.remove(rainParts, 1)
						if oldp.Parent then
							oldp:Destroy()
						end
					end
				end
			end
		end)
	else
		if rainConn then
			rainConn:Disconnect()
			rainConn = nil
		end
		for _, p in ipairs(rainParts) do
			if p.Parent then
				p:Destroy()
			end
		end
		rainParts = {}
	end
end)

createToggle(funPage, "Magnet", 14, 230, function(state)
	if state then
		magnetConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			params.MaxParts = 50
			for _, part in ipairs(workspace:GetPartBoundsInRadius(root.Position, 35, params)) do
				if not part.Anchored and not isInCharacter(part) then
					local dir = root.Position - part.Position
					local dist = dir.Magnitude
					if dist > 2 then
						part.AssemblyLinearVelocity = dir.Unit * math.min(90, dist * 4)
					end
				end
			end
		end)
	else
		if magnetConn then
			magnetConn:Disconnect()
			magnetConn = nil
		end
	end
end)

createToggle(funPage, "Bomb Tool", 214, 230, function(state)
	bombOn = state
end)

createToggle(funPage, "Ghost Trail", 14, 268, function(state)
	if state then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		ghostLastPos = root and root.Position or nil
		ghostAcc = 0
		ghostConn = RunService.Heartbeat:Connect(function(dt)
			ghostAcc = ghostAcc + dt
			if ghostAcc >= 0.18 then
				ghostAcc = 0
				local c = player.Character
				local r = c and c:FindFirstChild("HumanoidRootPart")
				if r then
					if not ghostLastPos or (r.Position - ghostLastPos).Magnitude > 3 then
						ghostLastPos = r.Position
						spawnGhost()
					end
				end
			end
		end)
	else
		if ghostConn then
			ghostConn:Disconnect()
			ghostConn = nil
		end
		for _, g in ipairs(ghostList) do
			if g.Parent then
				g:Destroy()
			end
		end
		ghostList = {}
	end
end)

createToggle(funPage, "Rainbow", 214, 268, function(state)
	if state then
		rainbowConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			if not char then return end
			local c = Color3.fromHSV((os.clock() * 0.6) % 1, 1, 1)
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("BasePart") then
					child.Color = c
				end
			end
		end)
	else
		if rainbowConn then
			rainbowConn:Disconnect()
			rainbowConn = nil
		end
	end
end)

createToggle(funPage, "Ride Player", 14, 306, function(state)
	rideOn = state
	if not state then
		rideTarget = nil
	end
	if rideConn then
		rideConn:Disconnect()
		rideConn = nil
	end
	if state then
		rideConn = RunService.Heartbeat:Connect(function()
			if not rideTarget then return end
			local vchar = rideTarget.Character
			local vhrp = vchar and vchar:FindFirstChild("HumanoidRootPart")
			local mychar = player.Character
			local myroot = mychar and mychar:FindFirstChild("HumanoidRootPart")
			if vhrp and myroot then
				myroot.CFrame = vhrp.CFrame * CFrame.new(0, 4.5, 0)
				myroot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			else
				rideTarget = nil
			end
		end)
	end
end)

createToggle(funPage, "Click Fling", 214, 306, function(state)
	clickFlingOn = state
end)

createButton(funPage, "Load Xester", 14, 344, function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/TheRareOcelot/roblox-fe-scripts/main/xester", true))()
	end)
end)

createButton(funPage, "Load Lolita Glitcher", 218, 344, function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Jskfhggjxu/My-Script/refs/heads/main/fe-Lolita-glitcher.lua", true))()
	end)
end)

createToggle(movePage, "Fly", 14, 6, function(state)
	flying = state
	if state then
		if not flyConn then
			flyConn = RunService.Heartbeat:Connect(flyStep)
		end
	else
		if flyConn then
			flyConn:Disconnect()
			flyConn = nil
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		if root then
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
		end
	end
end)

createToggle(movePage, "Air Swim", 214, 6, function(state)
	swimming = state
	if state then
		if not swimConn then
			swimConn = RunService.Heartbeat:Connect(function(dt)
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not hum or not root then return end
				if hum:GetState() ~= Enum.HumanoidStateType.Swimming then
					hum:ChangeState(Enum.HumanoidStateType.Swimming)
				end
				local move = hum.MoveDirection
				local target = Vector3.new(move.X, 0, move.Z) * walkSpeedValue
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					target = target + Vector3.new(0, walkSpeedValue * 0.8, 0)
				elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					target = target - Vector3.new(0, walkSpeedValue * 0.8, 0)
				end
				if target.Magnitude < 0.1 then
					target = Vector3.new(0, -1.5, 0)
				end
				local alpha = math.clamp(dt * 6, 0, 1)
				root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(target, alpha)
			end)
		end
	else
		if swimConn then
			swimConn:Disconnect()
			swimConn = nil
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			pcall(function()
				hum:ChangeState(Enum.HumanoidStateType.Freefall)
			end)
		end
	end
end)

createToggle(movePage, "Noclip", 14, 44, function(state)
	if state then
		applyNoclip()
		noclipConn = RunService.Heartbeat:Connect(function()
			noclipFrames = noclipFrames + 1
			if noclipFrames >= 30 then
				noclipFrames = 0
				applyNoclip()
			end
		end)
	else
		if noclipConn then
			noclipConn:Disconnect()
			noclipConn = nil
		end
		clearNoclip()
	end
end)

createToggle(movePage, "Inf Jump", 214, 44, function(state)
	if state then
		infJumpConn = UserInputService.JumpRequest:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	else
		if infJumpConn then
			infJumpConn:Disconnect()
			infJumpConn = nil
		end
	end
end)

createToggle(movePage, "Click TP", 14, 82, function(state)
	clickTPOn = state
end)

createSlider(movePage, "Fly Speed", 120, 10, 200, 60, 0, function(value)
	flySpeed = value
end)

createSlider(movePage, "Walk Speed", 156, 8, 200, 16, 0, function(value)
	walkSpeedValue = value
	applySpeedSettings()
end)

createSlider(movePage, "Jump Power", 192, 20, 300, 50, 0, function(value)
	jumpPowerValue = value
	applySpeedSettings()
end)

createButton(avatarPage, "Random Pants", 14, 6, function()
	local char = player.Character
	if not char then return end
	local pants = char:FindFirstChildOfClass("Pants")
	if not pants then
		pants = Instance.new("Pants")
		pants.Parent = char
	end
	pants.PantsTemplate = "rbxassetid://" .. tostring(PANTS_IDS[rng:NextInteger(1, #PANTS_IDS)])
end)

createButton(avatarPage, "Random Shirt", 214, 6, function()
	local char = player.Character
	if not char then return end
	local shirt = char:FindFirstChildOfClass("Shirt")
	if not shirt then
		shirt = Instance.new("Shirt")
		shirt.Parent = char
	end
	shirt.ShirtTemplate = "rbxassetid://" .. tostring(SHIRT_IDS[rng:NextInteger(1, #SHIRT_IDS)])
end)

createButton(avatarPage, "Hair Color", 14, 44, function()
	local char = player.Character
	if not char then return end
	local c = randomColor()
	for _, acc in ipairs(char:GetChildren()) do
		if acc:IsA("Accessory") and string.find(string.lower(acc.Name), "hair", 1, true) then
			for _, obj in ipairs(acc:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.Color = c
				end
			end
		end
	end
end)

createButton(avatarPage, "Skin Color", 214, 44, function()
	local char = player.Character
	if not char then return end
	local c = randomColor()
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("BasePart") then
			child.Color = c
		end
	end
end)

createToggle(visPage, "Player ESP", 14, 6, function(state)
	setESP(state)
end)

createToggle(visPage, "Fullbright", 214, 6, function(state)
	setFullbright(state)
end)

createToggle(visPage, "No Fog", 14, 44, function(state)
	setNoFog(state)
end)

createSlider(visPage, "FOV", 82, 30, 120, 70, 0, function(value)
	local cam = workspace.CurrentCamera
	if cam then
		cam.FieldOfView = value
	end
end)

createToggle(visPage, "X-Ray", 14, 124, function(state)
	if state then
		applyXray()
		xrayConn = RunService.Heartbeat:Connect(function()
			xrayFrames = xrayFrames + 1
			if xrayFrames >= 30 then
				xrayFrames = 0
				applyXray()
			end
		end)
	else
		if xrayConn then
			xrayConn:Disconnect()
			xrayConn = nil
		end
		clearXray()
	end
end)

createToggle(visPage, "FPS Boost", 214, 124, function(state)
	if state then
		boostShadowSaved = lighting.GlobalShadows
		lighting.GlobalShadows = false
		boostApply()
		boostConn = RunService.Heartbeat:Connect(function()
			boostFrames = boostFrames + 1
			if boostFrames >= 120 then
				boostFrames = 0
				boostApply()
			end
		end)
	else
		if boostConn then
			boostConn:Disconnect()
			boostConn = nil
		end
		boostClear()
		if boostShadowSaved ~= nil then
			lighting.GlobalShadows = boostShadowSaved
			boostShadowSaved = nil
		end
	end
end)

createToggle(visPage, "Crosshair", 14, 162, function(state)
	crosshairOn = state
	crosshair.Visible = state
end)

createToggle(visPage, "FPS / Ping", 214, 162, function(state)
	statsOn = state
	statsLabel.Visible = state
	if state then
		statsAcc = 0
		statsFrames = 0
		statsConn = RunService.Heartbeat:Connect(function(dt)
			statsAcc = statsAcc + dt
			statsFrames = statsFrames + 1
			if statsAcc >= 0.5 then
				local fps = math.floor(statsFrames / statsAcc + 0.5)
				local ping = math.floor(player:GetNetworkPing() * 1000 + 0.5)
				statsLabel.Text = "FPS: " .. tostring(fps) .. " | Ping: " .. tostring(ping) .. "ms"
				statsAcc = 0
				statsFrames = 0
			end
		end)
	else
		if statsConn then
			statsConn:Disconnect()
			statsConn = nil
		end
	end
end)

createButton(utilPage, "Rejoin Server", 14, 6, function()
	pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player })
	end)
end)

createButton(utilPage, "Server Hop", 214, 6, function()
	pcall(function()
		local httpFunc = request or http_request or (syn and syn.request)
		if not httpFunc then return end
		local res = httpFunc({
			Url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Desc&limit=100",
			Method = "GET"
		})
		local data = HttpService:JSONDecode(res.Body)
		local servers = data.data or {}
		local candidates = {}
		for _, s in ipairs(servers) do
			if s.id ~= game.JobId and s.playing < s.maxPlayers then
				table.insert(candidates, s.id)
			end
		end
		if #candidates > 0 then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[rng:NextInteger(1, #candidates)], player)
		end
	end)
end)

createToggle(utilPage, "Anti-AFK", 14, 44, function(state)
	if state then
		afkConn = player.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	else
		if afkConn then
			afkConn:Disconnect()
			afkConn = nil
		end
	end
end)

createToggle(utilPage, "TP to Player", 214, 44, function(state)
	tpPlayerOn = state
end)

createToggle(utilPage, "Chat Logger", 14, 82, function(state)
	chatOn = state
	chatWindow.Visible = state
	if state then
		local function hookPlr(plr)
			table.insert(chatConns, plr.Chatted:Connect(function(msg)
				addChat(plr.Name, msg)
			end))
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			hookPlr(plr)
		end
		table.insert(chatConns, Players.PlayerAdded:Connect(hookPlr))
		pcall(function()
			table.insert(chatConns, TextChatService.MessageReceived:Connect(function(msg)
				local src = msg.TextSource
				addChat(src and src.Name or "System", msg.Text)
			end))
		end)
	else
		for _, c in ipairs(chatConns) do
			c:Disconnect()
		end
		chatConns = {}
	end
end)

createToggle(utilPage, "Auto Rejoin", 214, 82, function(state)
	if state then
		autoRejoinConn = RunService.Heartbeat:Connect(function()
			if not player.Parent then
				pcall(function()
					TeleportService:TeleportAsync(game.PlaceId, { player })
				end)
			end
		end)
	else
		if autoRejoinConn then
			autoRejoinConn:Disconnect()
			autoRejoinConn = nil
		end
	end
end)

createLabel(utilPage, "Waypoints", 120)

createToggle(utilPage, "Chat Spam", 218, 120, function(state)
	chatSpamOn = state
end)

local chatMsgBox = Instance.new("TextBox")
chatMsgBox.Size = UDim2.new(0, 192, 0, 28)
chatMsgBox.Position = UDim2.new(0, 218, 0, 158)
chatMsgBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
chatMsgBox.PlaceholderText = "Spam message..."
chatMsgBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
chatMsgBox.Text = ""
chatMsgBox.TextColor3 = Color3.fromRGB(255, 255, 255)
chatMsgBox.TextSize = 13
chatMsgBox.Font = Enum.Font.Gotham
chatMsgBox.ClearTextOnFocus = false
chatMsgBox.Parent = utilPage

local chatMsgCorner = Instance.new("UICorner")
chatMsgCorner.CornerRadius = UDim.new(0, 6)
chatMsgCorner.Parent = chatMsgBox

chatMsgBox:GetPropertyChangedSignal("Text"):Connect(function()
	chatSpamMsg = chatMsgBox.Text
end)

local soundIdBox = Instance.new("TextBox")
soundIdBox.Size = UDim2.new(0, 192, 0, 28)
soundIdBox.Position = UDim2.new(0, 218, 0, 196)
soundIdBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
soundIdBox.PlaceholderText = "Audio ID..."
soundIdBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
soundIdBox.Text = ""
soundIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
soundIdBox.TextSize = 13
soundIdBox.Font = Enum.Font.Gotham
soundIdBox.ClearTextOnFocus = false
soundIdBox.Parent = utilPage

local soundIdCorner = Instance.new("UICorner")
soundIdCorner.CornerRadius = UDim.new(0, 6)
soundIdCorner.Parent = soundIdBox

createButton(utilPage, "Play Sound", 218, 232, function()
	boardPlay(soundIdBox.Text)
end)

createButton(utilPage, "Stop Sound", 218, 270, function()
	boardSound:Stop()
end)

local wpNameBox = Instance.new("TextBox")
wpNameBox.Size = UDim2.new(0, 160, 0, 28)
wpNameBox.Position = UDim2.new(0, 14, 0, 146)
wpNameBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
wpNameBox.PlaceholderText = "Waypoint name..."
wpNameBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
wpNameBox.Text = ""
wpNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
wpNameBox.TextSize = 13
wpNameBox.Font = Enum.Font.Gotham
wpNameBox.ClearTextOnFocus = false
wpNameBox.Parent = utilPage

local wpBoxCorner = Instance.new("UICorner")
wpBoxCorner.CornerRadius = UDim.new(0, 6)
wpBoxCorner.Parent = wpNameBox

local wpSaveBtn = Instance.new("TextButton")
wpSaveBtn.Size = UDim2.new(0, 110, 0, 28)
wpSaveBtn.Position = UDim2.new(0, 182, 0, 146)
wpSaveBtn.BackgroundColor3 = Color3.fromRGB(46, 150, 88)
wpSaveBtn.Text = "Save Spot"
wpSaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
wpSaveBtn.TextSize = 13
wpSaveBtn.Font = Enum.Font.GothamSemibold
wpSaveBtn.AutoButtonColor = false
wpSaveBtn.Parent = utilPage

local wpSaveCorner = Instance.new("UICorner")
wpSaveCorner.CornerRadius = UDim.new(0, 6)
wpSaveCorner.Parent = wpSaveBtn

wpSaveBtn.MouseButton1Click:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local n = wpNameBox.Text
	if n == "" then
		n = "Spot " .. tostring(#waypoints + 1)
	end
	table.insert(waypoints, { name = n, cframe = root.CFrame })
	if #waypoints > 6 then
		table.remove(waypoints, 1)
	end
	wpNameBox.Text = ""
	refreshWaypoints()
end)

createToggle(partsPage, "Part Tornado", 14, 6, function(state)
	tornadoEnabled = state
end)

createSlider(partsPage, "Radius", 44, 5, 150, 50, 0, function(value)
	tornadoRadius = value
end)

createSlider(partsPage, "Height", 80, 1, 200, 100, 0, function(value)
	tornadoHeight = value
end)

createSlider(partsPage, "Rotation Speed", 116, 0, 50, 10, 0, function(value)
	tornadoRotSpeed = value
end)

createSlider(partsPage, "Attraction", 152, 0, 5000, 1000, 0, function(value)
	tornadoStrength = value
end)

createButton(partsPage, "c00lkidd Attack", 14, 190, function()
	applyCoolkidAttack()
end)

createButton(partsPage, "Restore Map", 218, 190, function()
	restoreCoolkidAttack()
end)

local gagHarvestBtn = createButton(gag2Page, "Harvest Rarity: All", 218, 6, function()
	gagHarvestMin = gagHarvestMin % #RARITY_NAMES + 1
	gagHarvestBtn.Text = "Harvest Rarity: " .. RARITY_NAMES[gagHarvestMin]
end)

local gagSellBtn = createButton(gag2Page, "Sell Rarity: All", 218, 44, function()
	gagSellMin = gagSellMin % #RARITY_NAMES + 1
	gagSellBtn.Text = "Sell Rarity: " .. RARITY_NAMES[gagSellMin]
end)

local gagBuyBtn = createButton(gag2Page, "Buy Rarity: All", 218, 82, function()
	gagBuyMin = gagBuyMin % #RARITY_NAMES + 1
	gagBuyBtn.Text = "Buy Rarity: " .. RARITY_NAMES[gagBuyMin]
end)

local gagStealBtn = createButton(gag2Page, "Steal Rarity: All", 218, 120, function()
	gagStealMin = gagStealMin % #RARITY_NAMES + 1
	gagStealBtn.Text = "Steal Rarity: " .. RARITY_NAMES[gagStealMin]
end)

createToggle(gag2Page, "Auto Harvest", 14, 6, function(state)
	gagHarvestOn = state
end)

createToggle(gag2Page, "Auto Sell All", 14, 44, function(state)
	gagSellOn = state
end)

createToggle(gag2Page, "Auto Buy Seeds", 14, 82, function(state)
	gagBuyOn = state
end)

createToggle(gag2Page, "Auto Steal", 14, 120, function(state)
	gagStealOn = state
end)

createLabel(gag2Page, "Rarity buttons set the minimum tier.", 162)
createLabel(gag2Page, "Unknown plants only run on All.", 184)

local gagScanBox = Instance.new("TextBox")
gagScanBox.Size = UDim2.new(0, 392, 0, 150)
gagScanBox.Position = UDim2.new(0, 14, 0, 236)
gagScanBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
gagScanBox.Text = ""
gagScanBox.PlaceholderText = "Scan results appear here..."
gagScanBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
gagScanBox.TextColor3 = Color3.fromRGB(160, 255, 170)
gagScanBox.TextSize = 12
gagScanBox.Font = Enum.Font.Code
gagScanBox.TextMultiLine = true
gagScanBox.TextWrapped = true
gagScanBox.ClearTextOnFocus = false
gagScanBox.TextEditable = false
gagScanBox.Parent = gag2Page

local gagScanCorner = Instance.new("UICorner")
gagScanCorner.CornerRadius = UDim.new(0, 8)
gagScanCorner.Parent = gagScanBox

createButton(gag2Page, "Scan Game", 14, 210, function()
	local lines = {}
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	table.insert(lines, "-- Prompts/ClickDetectors near you --")
	if not root then
		table.insert(lines, "no character!")
	end
	local count = 0
	pcall(function()
		for _, obj in pairs(workspace:GetDescendants()) do
			local isPrompt = obj:IsA("ProximityPrompt")
			local isClick = obj:IsA("ClickDetector")
			if isPrompt or isClick then
				local dist = nil
				pcall(function()
					local h = obj.Parent
					local part = h:IsA("BasePart") and h or h:FindFirstChildWhichIsA("BasePart")
					if part then
						dist = (part.Position - root.Position).Magnitude
					end
				end)
				if dist and dist < 150 then
					count = count + 1
					if count <= 25 then
						if isPrompt then
							table.insert(lines, "PROMPT " .. obj.Parent.Name .. " | action=" .. tostring(obj.ActionText) .. " | object=" .. tostring(obj.ObjectText))
						else
							table.insert(lines, "CLICK " .. obj.Parent.Name)
						end
					end
				end
			end
		end
	end)
	table.insert(lines, "total near: " .. tostring(count))
	table.insert(lines, "-- Matching remotes --")
	pcall(function()
		for _, obj in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
			if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
				local n = string.lower(obj.Name)
				if string.find(n, "sell", 1, true) or string.find(n, "buy", 1, true) or string.find(n, "harvest", 1, true) or string.find(n, "plant", 1, true) or string.find(n, "seed", 1, true) or string.find(n, "farm", 1, true) or string.find(n, "steal", 1, true) or string.find(n, "carry", 1, true) or string.find(n, "collect", 1, true) then
					table.insert(lines, obj.ClassName .. " " .. obj:GetFullName())
				end
			end
		end
	end)
	gagScanBox.Text = table.concat(lines, "\n")
end)

selectTab("Fun")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local char = player.Character
	if clickOrbitEnabled then
		local target = mouse.Target
		if target and target:IsA("BasePart") and not target.Anchored and char and not target:IsDescendantOf(char) and not isInCharacter(target) then
			addToOrbit(target)
		end
	end
	if gravGunOn and not grabbedPart then
		local target = mouse.Target
		if target and target:IsA("BasePart") and not target.Anchored and not isInCharacter(target) then
			grabbedPart = target
		end
	end
	if flingOn then
		local target = mouse.Target
		if target then
			local model = target:FindFirstAncestorOfClass("Model")
			local victim = model and Players:GetPlayerFromCharacter(model)
			if victim and victim ~= player then
				local vchar = victim.Character
				local hrp = vchar and vchar:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.AssemblyLinearVelocity = Vector3.new(math.random(-80, 80), 250, math.random(-80, 80))
					hrp.AssemblyAngularVelocity = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))
				end
			end
		end
	end
	if clickTPOn and char then
		char:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 4, 0)))
	end
	if bombOn then
		local target = mouse.Target
		if target and target:IsA("BasePart") and not target.Anchored and not isInCharacter(target) then
			target.AssemblyLinearVelocity = Vector3.new(math.random(-40, 40), 260, math.random(-40, 40))
			target.AssemblyAngularVelocity = Vector3.new(math.random(-60, 60), math.random(-60, 60), math.random(-60, 60))
		end
	end
	if rideOn then
		local target = mouse.Target
		if target then
			local model = target:FindFirstAncestorOfClass("Model")
			local victim = model and Players:GetPlayerFromCharacter(model)
			if victim and victim ~= player then
				rideTarget = victim
			end
		end
	end
	if tpPlayerOn then
		local target = mouse.Target
		if target then
			local model = target:FindFirstAncestorOfClass("Model")
			local victim = model and Players:GetPlayerFromCharacter(model)
			if victim and victim ~= player then
				local vchar = victim.Character
				local vhrp = vchar and vchar:FindFirstChild("HumanoidRootPart")
				local mychar = player.Character
				if vhrp and mychar then
					mychar:PivotTo(vhrp.CFrame * CFrame.new(0, 0, -4))
				end
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and grabbedPart then
		releaseGrabbed(true)
	end
end)

player.CharacterAdded:Connect(function()
	applySpeedSettings()
end)

do
	local dragging = false
	local dragStart, startPos

	TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end
