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
