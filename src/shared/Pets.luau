-- Pets hatch from eggs found in the wilderness. You can equip one farm pet
-- and one battle pet. Proposed values for balancing.
-- bonus keys (combined in the server Bonuses module):
--   cropGrowth    multiplier on crop grow time (0.85 = 15% faster)
--   treeGrowth    multiplier on tree grow time
--   doubleHarvest chance to harvest 2 crops instead of 1
--   sellPrice     multiplier on crop sell price
--   wood          multiplier on wood from chopping
--   eggFind       chance to find a Common Egg when harvesting a crop
--   damage        extra sword damage
--   maxHealth     extra max health
--   crit          chance to deal double damage

export type Pet = {
	displayName: string,
	type: string, -- "farm" | "battle"
	rarity: string,
	ability: string,
	color: Color3,
	bonus: { [string]: number },
	description: string,
}

local Pets: { [string]: Pet } = {
	Hen = {
		displayName = "Hen",
		type = "farm",
		rarity = "Common",
		ability = "Egg Drop",
		color = Color3.fromRGB(250, 250, 245),
		bonus = { eggFind = 0.05 },
		description = "5% chance to find a Common Egg when you harvest.",
	},
	GiantEarthworm = {
		displayName = "Giant Earthworm",
		type = "farm",
		rarity = "Common",
		ability = "Soil Enrich",
		color = Color3.fromRGB(230, 140, 140),
		bonus = { cropGrowth = 0.85 },
		description = "Crops grow 15% faster.",
	},
	Butterfly = {
		displayName = "Butterfly",
		type = "farm",
		rarity = "Rare",
		ability = "Bloom Boost",
		color = Color3.fromRGB(90, 170, 240),
		bonus = { doubleHarvest = 0.2, sellPrice = 1.1 },
		description = "20% chance of double crops, and crops sell for 10% more.",
	},
	Dog = {
		displayName = "Dog",
		type = "battle",
		rarity = "Uncommon",
		ability = "Pack Rush",
		color = Color3.fromRGB(190, 130, 80),
		bonus = { damage = 8 },
		description = "+8 sword damage.",
	},
	Cat = {
		displayName = "Cat",
		type = "battle",
		rarity = "Uncommon",
		ability = "Shadow Pounce",
		color = Color3.fromRGB(35, 35, 45),
		bonus = { crit = 0.2, damage = 2 },
		description = "20% chance of double damage, +2 damage.",
	},
}

-- What each egg can hatch into, with weights. Eggs are found in the
-- wilderness; rarer eggs further from the entrance and in hidden areas.
-- Epic and Special eggs get their own pets once those are designed.
local EggTables: { [string]: { [string]: number } } = {
	CommonEgg = { Hen = 45, GiantEarthworm = 45, Dog = 5, Cat = 5 },
	UncommonEgg = { Hen = 20, GiantEarthworm = 20, Dog = 28, Cat = 28, Butterfly = 4 },
	RareEgg = { Dog = 35, Cat = 35, Butterfly = 30 },
	EpicEgg = { Dog = 25, Cat = 25, Butterfly = 50 },
	SpecialEgg = { Dog = 15, Cat = 15, Butterfly = 70 },
}

-- Glow color for each egg in the world.
local EggGlow: { [string]: Color3 } = {
	CommonEgg = Color3.fromRGB(150, 230, 120),
	UncommonEgg = Color3.fromRGB(80, 170, 255),
	RareEgg = Color3.fromRGB(180, 90, 255),
	EpicEgg = Color3.fromRGB(255, 140, 40),
	SpecialEgg = Color3.fromRGB(255, 200, 255),
}

local RarityColors: { [string]: Color3 } = {
	Common = Color3.fromRGB(120, 200, 100),
	Uncommon = Color3.fromRGB(70, 160, 240),
	Rare = Color3.fromRGB(170, 100, 240),
	Epic = Color3.fromRGB(250, 160, 50),
	Special = Color3.fromRGB(240, 150, 240),
}

local RarityOrder: { [string]: number } = {
	Special = 1,
	Epic = 2,
	Rare = 3,
	Uncommon = 4,
	Common = 5,
}

return {
	list = Pets,
	eggs = EggTables,
	eggGlow = EggGlow,
	rarityColors = RarityColors,
	rarityOrder = RarityOrder,
}
