-- The "Gear" tab in the Bag: your weapons and armor with Equip buttons.
-- Reads "Gear" (JSON id -> level), "EquippedWeapon", "EquippedArmor".

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gear = require(ReplicatedStorage.Shared.Gear)
local Inventory = require(script.Parent.Inventory)
local UI = require(script.Parent.UI)

local GearUI = {}

local player = Players.LocalPlayer

function GearUI.start()
	local equipRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipGear") :: RemoteEvent

	Inventory.addTab("Gear", 3, function(list)
		local ok, owned = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Gear") or "{}")
		if not ok or type(owned) ~= "table" then
			owned = {}
		end
		local weapon = player:GetAttribute("EquippedWeapon")
		local armor = player:GetAttribute("EquippedArmor")
		local ids = {}
		for id in owned do
			if Gear.list[id] then
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(a, b)
			return Gear.list[a].order < Gear.list[b].order
		end)
		for i, id in ids do
			local item = Gear.list[id]
			local level = owned[id]
			local isEquipped = id == weapon or id == armor
			local stat = if item.slot == "weapon"
				then `{Gear.statFor(id, level)} damage`
				else `+{Gear.statFor(id, level)} health, {math.floor((item.defense or 0) * 100)}% defense`
			local title = if level > 0 then `{item.displayName} +{level}` else item.displayName
			local row = UI.row(list, i, title, `{item.tier} {item.slot}. {stat}`, item.color)
			local canToggle = item.slot == "armor" or not isEquipped
			local button = UI.button(
				row,
				if isEquipped then (if item.slot == "armor" then "Unequip" else "Equipped") else "Equip",
				UDim2.fromOffset(100, 34),
				UDim2.new(1, -110, 0, 12),
				if isEquipped then UI.colors.gray else UI.colors.green
			)
			if canToggle then
				button.Activated:Connect(function()
					equipRemote:FireServer(id)
				end)
			end
		end
		if #ids == 0 then
			UI.row(list, 1, "No gear", "Craft gear at the Forge (Gear Shop).", UI.colors.gray)
		end
	end)
end

return GearUI
