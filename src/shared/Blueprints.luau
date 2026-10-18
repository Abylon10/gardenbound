-- Blueprints sold at the Blueprint Shop. Buying one (coins) unlocks it;
-- building it at your homestead costs wood.
--   kind "house": upgrades the house to `level` (needs the previous level).
--     Level 2 unlocks a 4th row of front-garden tiles.
--     Level 3 unlocks 2 more back-garden tree spots.
--   kind "decor": built on the matching build spot next to the house.

export type Blueprint = {
	displayName: string,
	kind: string,
	price: number,
	wood: number,
	level: number?,
	description: string,
	order: number,
}

local Blueprints: { [string]: Blueprint } = {
	HouseLevel2 = {
		displayName = "House Upgrade II",
		kind = "house",
		level = 2,
		price = 150,
		wood = 30,
		description = "A bigger house with a porch. +4 garden tiles.",
		order = 1,
	},
	HouseLevel3 = {
		displayName = "House Upgrade III",
		kind = "house",
		level = 3,
		price = 600,
		wood = 90,
		description = "A two-story house. +2 tree spots.",
		order = 2,
	},
	Bench = {
		displayName = "Garden Bench",
		kind = "decor",
		price = 40,
		wood = 8,
		description = "A place to rest by your house.",
		order = 10,
	},
	Lantern = {
		displayName = "Lantern Post",
		kind = "decor",
		price = 50,
		wood = 6,
		description = "Lights up your homestead at night.",
		order = 11,
	},
	FlowerBed = {
		displayName = "Flower Bed",
		kind = "decor",
		price = 60,
		wood = 10,
		description = "Colorful flowers beside your house.",
		order = 12,
	},
	Scarecrow = {
		displayName = "Scarecrow",
		kind = "decor",
		price = 80,
		wood = 12,
		description = "Guards your front garden.",
		order = 13,
	},
	Well = {
		displayName = "Stone Well",
		kind = "decor",
		price = 150,
		wood = 25,
		description = "A classic homestead well.",
		order = 14,
	},
}

return Blueprints
