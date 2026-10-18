-- Weapons and armor, crafted and upgraded at the Forge (Gear Shop).
-- Enhancement +N raises the main stat (damage or health) by 10% per level,
-- up to +10. Armor also blocks a fraction of damage (defense).

export type Cost = { coins: number?, items: { [string]: number }? }

export type GearItem = {
	displayName: string,
	slot: string, -- "weapon" | "armor"
	tier: string,
	damage: number?,
	defense: number?, -- fraction of damage blocked, e.g. 0.1
	health: number?, -- extra max health
	color: Color3,
	order: number,
	craft: Cost?, -- nil = can't be crafted (starter gear)
	upgradeItem: string, -- material used to upgrade
	upgradeCoins: number, -- coins per level step
}

local Gear: { [string]: GearItem } = {
	WoodenSword = {
		displayName = "Wooden Sword",
		slot = "weapon",
		tier = "Common",
		damage = 10,
		color = Color3.fromRGB(160, 115, 70),
		order = 1,
		craft = nil,
		upgradeItem = "Wood",
		upgradeCoins = 10,
	},
	CopperSword = {
		displayName = "Copper Sword",
		slot = "weapon",
		tier = "Rare",
		damage = 18,
		color = Color3.fromRGB(200, 120, 70),
		order = 2,
		craft = { coins = 80, items = { CopperOre = 8, GoblinTooth = 2 } },
		upgradeItem = "CopperOre",
		upgradeCoins = 20,
	},
	IronSword = {
		displayName = "Iron Sword",
		slot = "weapon",
		tier = "Epic",
		damage = 30,
		color = Color3.fromRGB(190, 190, 200),
		order = 3,
		craft = { coins = 200, items = { IronOre = 10, Bone = 4 } },
		upgradeItem = "IronOre",
		upgradeCoins = 40,
	},
	GolemGreatsword = {
		displayName = "Golem Greatsword",
		slot = "weapon",
		tier = "Legendary",
		damage = 48,
		color = Color3.fromRGB(240, 140, 60),
		order = 4,
		craft = { coins = 500, items = { IronOre = 12, GolemCore = 2 } },
		upgradeItem = "IronOre",
		upgradeCoins = 80,
	},
	LeatherArmor = {
		displayName = "Leather Armor",
		slot = "armor",
		tier = "Common",
		health = 25,
		defense = 0.05,
		color = Color3.fromRGB(150, 100, 60),
		order = 10,
		craft = { coins = 60, items = { RabbitFluff = 6, SlimeGoo = 4 } },
		upgradeItem = "RabbitFluff",
		upgradeCoins = 15,
	},
	CopperArmor = {
		displayName = "Copper Armor",
		slot = "armor",
		tier = "Rare",
		health = 50,
		defense = 0.1,
		color = Color3.fromRGB(200, 120, 70),
		order = 11,
		craft = { coins = 120, items = { CopperOre = 10 } },
		upgradeItem = "CopperOre",
		upgradeCoins = 25,
	},
	IronArmor = {
		displayName = "Iron Armor",
		slot = "armor",
		tier = "Epic",
		health = 90,
		defense = 0.18,
		color = Color3.fromRGB(190, 190, 200),
		order = 12,
		craft = { coins = 300, items = { IronOre = 14, Bone = 6 } },
		upgradeItem = "IronOre",
		upgradeCoins = 50,
	},
	GolemPlate = {
		displayName = "Golem Plate",
		slot = "armor",
		tier = "Legendary",
		health = 140,
		defense = 0.25,
		color = Color3.fromRGB(240, 140, 60),
		order = 13,
		craft = { coins = 700, items = { IronOre = 16, GolemCore = 3 } },
		upgradeItem = "IronOre",
		upgradeCoins = 100,
	},
}

local MAX_LEVEL = 10

-- Damage (weapon) or health (armor) with enhancement applied.
local function statFor(id: string, level: number): number
	local item = Gear[id]
	if not item then
		return 0
	end
	local base = item.damage or item.health or 0
	return math.floor(base * (1 + 0.1 * math.clamp(level, 0, MAX_LEVEL)) + 0.5)
end

-- Cost to go from level to level + 1.
local function upgradeCost(id: string, level: number): Cost
	local item = Gear[id]
	local step = level + 1
	return {
		coins = item.upgradeCoins * step,
		items = { [item.upgradeItem] = 2 * step },
	}
end

return {
	list = Gear,
	statFor = statFor,
	upgradeCost = upgradeCost,
	MAX_LEVEL = MAX_LEVEL,
}
