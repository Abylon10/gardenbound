-- Pets in the Bag: a "Pets" tab listing every pet you own with an
-- Equip/Unequip button, and a "Hatch" button on eggs in the Items tab.
-- Reads the "Pets" and "EquippedPets" JSON attributes.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

function PetsUI.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local hatchEgg = remotes:WaitForChild("HatchEgg") :: RemoteEvent
	local equipPet = remotes:WaitForChild("EquipPet") :: RemoteEvent

	Inventory.addItemAction("egg", "Hatch", function(itemId)
		hatchEgg:FireServer(itemId)
	end)

	Inventory.addTab("Pets", 2, function(list)
		local pets = decode("Pets", {})
		local equipped = decode("EquippedPets", { farm = 0, battle = 0 })
		if #pets == 0 then
			UI.row(list, 1, "No pets yet", "Defeat Meadow creatures for eggs, then hatch them from the Items tab.", UI.colors.gray)
			return
		end
		-- Equipped first, then by rarity.
		local rarityOrder = { Legendary = 1, Epic = 2, Rare = 3, Common = 4 }
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
				local row = UI.row(list, i, `{def.displayName} ({def.rarity})`, `{typeLabel}: {def.description}`, def.color)
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
