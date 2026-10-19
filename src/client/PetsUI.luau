-- Pets in the Bag: a "Pets" tab listing every pet you own with an
-- Equip/Unequip button, and a "Hatch" button on eggs in the Items tab.
-- Reads the "Pets" and "EquippedPets" JSON attributes.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local Items = require(ReplicatedStorage.Shared.Items)
local Pets = require(ReplicatedStorage.Shared.Pets)
local Inventory = require(script.Parent.Inventory)
local UI = require(script.Parent.UI)

local PetsUI = {}

local player = Players.LocalPlayer

local function decode(attribute: string, fallback: any): any
	local raw = player:GetAttribute(attribute)
	if type(raw) ~= "string" then
		return fallback
	end
	local ok, value = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok then value else fallback
end

-- The hatch reveal: the egg wobbles, flashes, and the pet appears.
local function playHatch(gui: ScreenGui, eggId: string, kind: string)
	local def = Pets.list[kind]
	local egg = Items[eggId]
	if not def or not egg then
		return
	end
	local frame = UI.panel(gui, UDim2.fromOffset(360, 300), UDim2.fromScale(0.5, 0.45))
	local shell = Instance.new("Frame")
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.42)
	shell.Size = UDim2.fromOffset(110, 140)
	shell.BackgroundColor3 = egg.color
	shell.BorderSizePixel = 0
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = shell
	local glow = Instance.new("UIStroke")
	glow.Color = Pets.eggGlow[eggId] or Color3.new(1, 1, 1)
	glow.Thickness = 4
	glow.Parent = shell
	shell.Parent = frame
	local title = UI.label(frame, `Hatching a {egg.displayName}...`, UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 10), 20, UI.colors.gold)
	title.TextXAlignment = Enum.TextXAlignment.Center

	-- Wobble, faster and faster.
	for i = 1, 10 do
		local angle = if i % 2 == 0 then 12 else -12
		TweenService:Create(shell, TweenInfo.new(0.16 - i * 0.008), { Rotation = angle }):Play()
		task.wait(0.16 - i * 0.008)
	end
	shell.Rotation = 0
	TweenService:Create(shell, TweenInfo.new(0.25), { Size = UDim2.fromOffset(170, 200), BackgroundTransparency = 1 }):Play()
	glow.Transparency = 1
	task.wait(0.25)

	-- Reveal.
	shell.BackgroundColor3 = def.color
	shell.Size = UDim2.fromOffset(40, 40)
	shell.BackgroundTransparency = 0
	glow.Transparency = 0
	glow.Color = Pets.rarityColors[def.rarity] or Color3.new(1, 1, 1)
	TweenService:Create(shell, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(110, 110) }):Play()
	title.Text = `You hatched a {def.displayName}!`
	local rarity = UI.label(frame, `{def.rarity} {if def.type == "farm" then "farm" else "battle"} pet`, UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 1, -78), 17, Pets.rarityColors[def.rarity])
	rarity.TextXAlignment = Enum.TextXAlignment.Center
	local ability = UI.label(frame, `{def.ability}: {def.description}`, UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 1, -54), 14, UI.colors.muted)
	ability.TextXAlignment = Enum.TextXAlignment.Center
	task.wait(4)
	frame:Destroy()
end

function PetsUI.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local hatchEgg = remotes:WaitForChild("HatchEgg") :: RemoteEvent
	local equipPet = remotes:WaitForChild("EquipPet") :: RemoteEvent

	Inventory.addItemAction("egg", "Hatch", function(itemId)
		hatchEgg:FireServer(itemId)
	end)

	local revealGui = UI.screen("HatchReveal", 40)
	revealGui.Parent = player:WaitForChild("PlayerGui")
	local hatched = remotes:WaitForChild("Hatched") :: RemoteEvent
	hatched.OnClientEvent:Connect(function(eggId, kind)
		if type(eggId) == "string" and type(kind) == "string" then
			playHatch(revealGui, eggId, kind)
		end
	end)

	Inventory.addTab("Pets", 2, function(list)
		local pets = decode("Pets", {})
		local equipped = decode("EquippedPets", { farm = 0, battle = 0 })
		if #pets == 0 then
			UI.row(list, 1, "No pets yet", "Find glowing eggs in the Meadow, then hatch them from the Items tab.", UI.colors.gray)
			return
		end
		-- Equipped first, then by rarity.
		local rarityOrder = Pets.rarityOrder
		table.sort(pets, function(a, b)
			local aOn = a.id == equipped.farm or a.id == equipped.battle
			local bOn = b.id == equipped.farm or b.id == equipped.battle
			if aOn ~= bOn then
				return aOn
			end
			local ra = Pets.list[a.kind] and rarityOrder[Pets.list[a.kind].rarity] or 9
			local rb = Pets.list[b.kind] and rarityOrder[Pets.list[b.kind].rarity] or 9
			if ra ~= rb then
				return ra < rb
			end
			return a.id < b.id
		end)
		for i, pet in pets do
			local def = Pets.list[pet.kind]
			if def then
				local isEquipped = pet.id == equipped.farm or pet.id == equipped.battle
				local typeLabel = if def.type == "farm" then "Farm pet" else "Battle pet"
				local row = UI.row(list, i, `{def.displayName} ({def.rarity})`, `{typeLabel} · {def.ability}: {def.description}`, def.color)
				local title = row:FindFirstChild("Title") :: TextLabel
				title.TextColor3 = Pets.rarityColors[def.rarity] or UI.colors.text
				local button = UI.button(
					row,
					if isEquipped then "Unequip" else "Equip",
					UDim2.fromOffset(100, 34),
					UDim2.new(1, -110, 0, 12),
					if isEquipped then UI.colors.gray else UI.colors.green
				)
				button.Activated:Connect(function()
					equipPet:FireServer(pet.id)
				end)
			end
		end
	end)
end

return PetsUI
