-- Adds up every bonus a player has right now: equipped pets, and buffs
-- from potions (Phase 4 registers those with Bonuses.addSource). Other
-- systems read the totals through the hooks set in Bonuses.start.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pets = require(ReplicatedStorage.Shared.Pets)
local Farming = require(script.Parent.Farming)
local Forestry = require(script.Parent.Forestry)
local Plaza = require(script.Parent.Plaza)
local PlayerData = require(script.Parent.PlayerData)

local Bonuses = {}

-- A source returns a bonus table (same keys as Pets bonus) for a player.
local sources: { (Player) -> { [string]: number } } = {}

function Bonuses.addSource(source: (Player) -> { [string]: number })
	table.insert(sources, source)
end

local MULTIPLIERS = { cropGrowth = true, treeGrowth = true, sellPrice = true, wood = true }

-- The combined value of one bonus key. Multipliers start at 1 and multiply;
-- everything else starts at 0 and adds.
function Bonuses.get(player: Player, key: string): number
	local isMultiplier = MULTIPLIERS[key] == true
	local total = if isMultiplier then 1 else 0
	for _, source in sources do
		local value = source(player)[key]
		if value then
			total = if isMultiplier then total * value else total + value
		end
	end
	return total
end

local function petBonuses(player: Player): { [string]: number }
	local data = PlayerData.get(player)
	if not data then
		return {}
	end
	local combined: { [string]: number } = {}
	for _, petId in { data.equippedPets.farm, data.equippedPets.battle } do
		for _, pet in data.pets do
			if pet.id == petId then
				local kind = Pets.list[pet.kind]
				for key, value in (if kind then kind.bonus else {}) :: { [string]: number } do
					if MULTIPLIERS[key] then
						combined[key] = (combined[key] or 1) * value
					else
						combined[key] = (combined[key] or 0) + value
					end
				end
			end
		end
	end
	return combined
end

function Bonuses.start()
	Bonuses.addSource(petBonuses)

	Farming.growthMultiplier = function(player)
		return Bonuses.get(player, "cropGrowth")
	end
	Farming.harvestAmount = function(player)
		return if math.random() < Bonuses.get(player, "doubleHarvest") then 2 else 1
	end
	Forestry.growthMultiplier = function(player)
		return Bonuses.get(player, "treeGrowth")
	end
	Forestry.woodAmount = function(player, baseWood)
		return math.floor(baseWood * Bonuses.get(player, "wood") + 0.5)
	end
	Plaza.sellMultiplier = function(player)
		return Bonuses.get(player, "sellPrice")
	end
end

return Bonuses
