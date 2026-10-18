-- Formats and checks costs ({ coins, items, crops }) against what the
-- player has, using the attributes PlayerData publishes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)

export type Cost = { coins: number?, items: { [string]: number }?, crops: { [string]: number }? }

local Costs = {}

local player = Players.LocalPlayer

function Costs.coins(): number
	local leaderstats = player:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild("Coins") :: IntValue?
	return if value then value.Value else 0
end

-- "80 coins · Copper Ore 3/8 · Tomato 2/2"
function Costs.describe(cost: Cost): string
	local parts = {}
	if cost.coins and cost.coins > 0 then
		table.insert(parts, `{cost.coins} coins`)
	end
	local items: { [string]: number } = cost.items or {}
	for itemId, amount in items do
		local item = Items[itemId]
		local have = player:GetAttribute("Item_" .. itemId) or 0
		table.insert(parts, `{if item then item.displayName else itemId} {have}/{amount}`)
	end
	local crops: { [string]: number } = cost.crops or {}
	for cropName, amount in crops do
		local crop = Crops[cropName]
		local have = player:GetAttribute("Crop_" .. cropName) or 0
		table.insert(parts, `{if crop then crop.displayName else cropName} {have}/{amount}`)
	end
	return table.concat(parts, " · ")
end

function Costs.canAfford(cost: Cost): boolean
	if (cost.coins or 0) > Costs.coins() then
		return false
	end
	local items: { [string]: number } = cost.items or {}
	for itemId, amount in items do
		if (player:GetAttribute("Item_" .. itemId) or 0) < amount then
			return false
		end
	end
	local crops: { [string]: number } = cost.crops or {}
	for cropName, amount in crops do
		if (player:GetAttribute("Crop_" .. cropName) or 0) < amount then
			return false
		end
	end
	return true
end

return Costs
