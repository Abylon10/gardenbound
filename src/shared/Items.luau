-- Every stackable item a player can hold (saved in PlayerData.items and
-- mirrored to the client as the "Item_<id>" attribute). Seeds and crops
-- are separate (see Crops).

export type Item = {
	displayName: string,
	-- "material" | "sapling" | "egg" | "potion"
	kind: string,
	color: Color3,
	description: string,
	order: number,
}

local Items: { [string]: Item } = {
	Wood = {
		displayName = "Wood",
		kind = "material",
		color = Color3.fromRGB(150, 105, 65),
		description = "From trees in your back garden. Used for building.",
		order = 10,
	},

	-- Saplings (Seed Shop)
	BirchSapling = {
		displayName = "Birch Sapling",
		kind = "sapling",
		color = Color3.fromRGB(150, 200, 80),
		description = "Plant in your back garden.",
		order = 20,
	},
	AppleSapling = {
		displayName = "Apple Sapling",
		kind = "sapling",
		color = Color3.fromRGB(70, 150, 60),
		description = "Plant in your back garden.",
		order = 21,
	},
	CoconutSapling = {
		displayName = "Coconut Sapling",
		kind = "sapling",
		color = Color3.fromRGB(110, 170, 50),
		description = "A rare tree. Plant in your back garden.",
		order = 22,
	},

	-- Monster drops and resources
	SlimeGel = {
		displayName = "Slime Gel",
		kind = "material",
		color = Color3.fromRGB(120, 220, 120),
		description = "From slimes. Basic potion and crafting material.",
		order = 30,
	},
	SlimeCore = {
		displayName = "Slime Core",
		kind = "material",
		color = Color3.fromRGB(60, 200, 150),
		description = "Uncommon, from dungeon slimes. Used for forging.",
		order = 31,
	},
	WildBerry = {
		displayName = "Wild Berry",
		kind = "material",
		color = Color3.fromRGB(200, 40, 120),
		description = "Sometimes dropped by wilderness slimes. Used in potions.",
		order = 32,
	},
	BatWing = {
		displayName = "Bat Wing",
		kind = "material",
		color = Color3.fromRGB(60, 50, 70),
		description = "From dungeon bats. Used in Swiftness Potions.",
		order = 33,
	},
	ShadowEssence = {
		displayName = "Shadow Essence",
		kind = "material",
		color = Color3.fromRGB(90, 40, 140),
		description = "Rare, from dungeon bats. Used for shadow gear.",
		order = 34,
	},
	GoblinFang = {
		displayName = "Goblin Fang",
		kind = "material",
		color = Color3.fromRGB(230, 220, 170),
		description = "From goblins. Used for forging and Strength Potions.",
		order = 35,
	},
	RoughHide = {
		displayName = "Rough Hide",
		kind = "material",
		color = Color3.fromRGB(150, 110, 70),
		description = "From goblins. Used for armor.",
		order = 36,
	},
	CopperOre = {
		displayName = "Copper Ore",
		kind = "material",
		color = Color3.fromRGB(200, 120, 70),
		description = "Mined in the Abandoned Mine. Used for forging.",
		order = 37,
	},
	IronOre = {
		displayName = "Iron Ore",
		kind = "material",
		color = Color3.fromRGB(170, 170, 180),
		description = "Mined deep in the Abandoned Mine. Used for forging.",
		order = 38,
	},

	-- Eggs (found in the wilderness, hatch from the Bag)
	CommonEgg = {
		displayName = "Common Egg",
		kind = "egg",
		color = Color3.fromRGB(240, 235, 215),
		description = "Found near the Meadow entrance. Hatch it from your Bag.",
		order = 40,
	},
	ForestEgg = {
		displayName = "Forest Egg",
		kind = "egg",
		color = Color3.fromRGB(110, 190, 110),
		description = "Found deeper in the Meadow. Better pets inside.",
		order = 41,
	},
	AncientEgg = {
		displayName = "Ancient Egg",
		kind = "egg",
		color = Color3.fromRGB(190, 120, 255),
		description = "Found far from the entrance or in hidden spots. The best pets.",
		order = 42,
	},

	-- Potions (brew at your cauldron, use from the Bag)
	HealthPotion = {
		displayName = "Health Potion",
		kind = "potion",
		color = Color3.fromRGB(230, 60, 70),
		description = "Restores 30% of your max health. 15 s cooldown.",
		order = 50,
	},
	SwiftnessPotion = {
		displayName = "Swiftness Potion",
		kind = "potion",
		color = Color3.fromRGB(90, 200, 230),
		description = "+25% movement speed for 10 s. 30 s cooldown.",
		order = 51,
	},
	StrengthPotion = {
		displayName = "Strength Potion",
		kind = "potion",
		color = Color3.fromRGB(240, 140, 40),
		description = "+15% damage for 15 s. 30 s cooldown.",
		order = 52,
	},
}

return Items
