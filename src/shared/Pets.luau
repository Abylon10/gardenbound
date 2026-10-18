-- Pets hatch from eggs. You can equip one farm pet and one battle pet.
-- bonus keys (combined in the server Bonuses module):
--   cropGrowth    multiplier on crop grow time (0.85 = 15% faster)
--   treeGrowth    multiplier on tree grow time
--   doubleHarvest chance to harvest 2 crops instead of 1
--   sellPrice     multiplier on crop sell price
--   wood          multiplier on wood from chopping
--   damage        extra sword damage
--   maxHealth     extra max health
--   crit          chance to deal double damage

export type Pet = {
	displayName: string,
	type: string, -- "farm" | "battle"
	rarity: string,
	color: Color3,
	bonus: { [string]: number },
	description: string,
}

local Pets: { [string]: Pet } = {
	Bee = {
		displayName = "Bee",
		type = "farm",
		rarity = "Common",
		color = Color3.fromRGB(250, 200, 40),
		bonus = { cropGrowth = 0.85 },
		description = "Crops grow 15% faster.",
	},
	Rabbit = {
		displayName = "Rabbit",
		type = "farm",
		rarity = "Common",
		color = Color3.fromRGB(240, 240, 240),
		bonus = { doubleHarvest = 0.15 },
		description = "15% chance to harvest double crops.",
	},
	Butterfly = {
		displayName = "Butterfly",
		type = "farm",
		rarity = "Rare",
		color = Color3.fromRGB(150, 110, 240),
		bonus = { sellPrice = 1.2 },
		description = "Crops sell for 20% more.",
	},
	Turtle = {
		displayName = "Turtle",
		type = "farm",
		rarity = "Rare",
		color = Color3.fromRGB(70, 150, 90),
		bonus = { treeGrowth = 0.75 },
		description = "Trees grow 25% faster.",
	},
	Treant = {
		displayName = "Treant",
		type = "farm",
		rarity = "Epic",
		color = Color3.fromRGB(120, 90, 50),
		bonus = { wood = 1.5, treeGrowth = 0.9 },
		description = "+50% wood, trees grow 10% faster.",
	},
	Wolf = {
		displayName = "Wolf",
		type = "battle",
		rarity = "Common",
		color = Color3.fromRGB(150, 150, 160),
		bonus = { damage = 5 },
		description = "+5 sword damage.",
	},
	FireSprite = {
		displayName = "Fire Sprite",
		type = "battle",
		rarity = "Rare",
		color = Color3.fromRGB(255, 120, 40),
		bonus = { damage = 10 },
		description = "+10 sword damage.",
	},
	Golem = {
		displayName = "Golem",
		type = "battle",
		rarity = "Rare",
		color = Color3.fromRGB(130, 120, 110),
		bonus = { maxHealth = 50, damage = 3 },
		description = "+50 max health, +3 damage.",
	},
	Hawk = {
		displayName = "Hawk",
		type = "battle",
		rarity = "Epic",
		color = Color3.fromRGB(170, 110, 60),
		bonus = { crit = 0.2, damage = 5 },
		description = "20% chance of double damage, +5 damage.",
	},
	Dragon = {
		displayName = "Dragon",
		type = "battle",
		rarity = "Legendary",
		color = Color3.fromRGB(200, 40, 50),
		bonus = { damage = 25, maxHealth = 50, crit = 0.1 },
		description = "+25 damage, +50 max health, 10% crits.",
	},
}

-- What each egg can hatch into, with weights. Eggs are found in the
-- wilderness: Common near the entrance, Forest further in, Ancient far
-- away or in hidden spots.
local EggTables: { [string]: { [string]: number } } = {
	CommonEgg = { Bee = 30, Rabbit = 30, Wolf = 30, Butterfly = 5, FireSprite = 5 },
	ForestEgg = { Rabbit = 15, Wolf = 15, Turtle = 20, Golem = 20, Butterfly = 12, Treant = 10, Hawk = 6, Dragon = 2 },
	AncientEgg = { Butterfly = 15, Turtle = 15, Golem = 15, Treant = 20, Hawk = 20, Dragon = 15 },
}

-- Glow color for each egg in the world.
local EggGlow: { [string]: Color3 } = {
	CommonEgg = Color3.fromRGB(255, 255, 230),
	ForestEgg = Color3.fromRGB(80, 150, 255),
	AncientEgg = Color3.fromRGB(190, 90, 255),
}

local RarityColors: { [string]: Color3 } = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(180, 90, 240),
	Legendary = Color3.fromRGB(255, 190, 40),
}

return {
	list = Pets,
	eggs = EggTables,
	eggGlow = EggGlow,
	rarityColors = RarityColors,
}
