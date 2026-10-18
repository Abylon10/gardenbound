-- Every stackable item a player can hold (saved in PlayerData.items and
-- mirrored to the client as the "Item_<id>" attribute). Seeds and crops
-- are separate (see Crops). Later phases add eggs, materials, potions.

export type Item = {
	displayName: string,
	-- "material" | "sapling" | "egg" | "potion"
	kind: string,
	color: Color3,
	description: string,
	order: number,
}

local Items: { [string]: Item } = {
	-- Eggs (hatch from the Bag)
	CommonEgg = {
		displayName = "Common Egg",
		kind = "egg",
		color = Color3.fromRGB(240, 230, 200),
		description = "Dropped by Meadow creatures. Hatch it from your Bag.",
		order = 40,
	},
	ForestEgg = {
		displayName = "Forest Egg",
		kind = "egg",
		color = Color3.fromRGB(110, 170, 90),
		description = "A rarer egg from goblins. Better pets inside.",
		order = 41,
	},
	-- Monster materials (used for potions and forging)
	SlimeGoo = {
		displayName = "Slime Goo",
		kind = "material",
		color = Color3.fromRGB(120, 220, 120),
		description = "Sticky. Used in potions.",
		order = 30,
	},
	RabbitFluff = {
		displayName = "Rabbit Fluff",
		kind = "material",
		color = Color3.fromRGB(245, 245, 245),
		description = "Soft and light. Used in potions.",
		order = 31,
	},
	CopperOre = {
		displayName = "Copper Ore",
		kind = "material",
		color = Color3.fromRGB(200, 120, 70),
		description = "Mined in the Abandoned Mine. Used for forging.",
		order = 33,
	},
	IronOre = {
		displayName = "Iron Ore",
		kind = "material",
		color = Color3.fromRGB(170, 170, 180),
		description = "Mined deep in the Abandoned Mine. Used for forging.",
		order = 34,
	},
	Bone = {
		displayName = "Bone",
		kind = "material",
		color = Color3.fromRGB(235, 230, 210),
		description = "From skeleton miners. Used for forging and potions.",
		order = 35,
	},
	BatWing = {
		displayName = "Bat Wing",
		kind = "material",
		color = Color3.fromRGB(60, 50, 70),
		description = "From cave bats. Used in potions.",
		order = 36,
	},
	GolemCore = {
		displayName = "Golem Core",
		kind = "material",
		color = Color3.fromRGB(240, 140, 60),
		description = "Dropped by the Rock Golem. Used for the best gear.",
		order = 37,
	},
	-- Potions (brew at your cauldron, use from the Bag)
	HealthPotion = {
		displayName = "Health Potion",
		kind = "potion",
		color = Color3.fromRGB(230, 60, 70),
		description = "Restores 60 health.",
		order = 50,
	},
	StrengthPotion = {
		displayName = "Strength Potion",
		kind = "potion",
		color = Color3.fromRGB(240, 140, 40),
		description = "+10 damage for 2 minutes.",
		order = 51,
	},
	IronSkinPotion = {
		displayName = "Iron Skin Potion",
		kind = "potion",
		color = Color3.fromRGB(150, 160, 175),
		description = "Take 15% less damage for 2 minutes.",
		order = 52,
	},
	SwiftnessPotion = {
		displayName = "Swiftness Potion",
		kind = "potion",
		color = Color3.fromRGB(90, 200, 230),
		description = "Run faster for 2 minutes.",
		order = 53,
	},
	GrowthPotion = {
		displayName = "Growth Potion",
		kind = "potion",
		color = Color3.fromRGB(120, 220, 90),
		description = "Instantly finishes every crop growing in your front garden.",
		order = 54,
	},
	GoblinTooth = {
		displayName = "Goblin Tooth",
		kind = "material",
		color = Color3.fromRGB(230, 220, 170),
		description = "Sharp. Used for forging.",
		order = 32,
	},
	Wood = {
		displayName = "Wood",
		kind = "material",
		color = Color3.fromRGB(150, 105, 65),
		description = "From trees in your back garden. Used for building.",
		order = 10,
	},
	OakSapling = {
		displayName = "Oak Sapling",
		kind = "sapling",
		color = Color3.fromRGB(110, 170, 70),
		description = "Plant in your back garden.",
		order = 20,
	},
	PineSapling = {
		displayName = "Pine Sapling",
		kind = "sapling",
		color = Color3.fromRGB(50, 120, 80),
		description = "Plant in your back garden.",
		order = 21,
	},
	MapleSapling = {
		displayName = "Maple Sapling",
		kind = "sapling",
		color = Color3.fromRGB(220, 110, 50),
		description = "A rare tree. Plant in your back garden.",
		order = 22,
	},
}

return Items
