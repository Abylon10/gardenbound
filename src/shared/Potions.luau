-- Potion recipes (brewed at the cauldron by your house) and effects
-- (used from the Bag). Each potion is also an item in Items.
-- effect.type:
--   "heal"    restore `amount` health
--   "buff"    Bonuses keys in `bonus` for `duration` seconds;
--             `walkSpeed` adds to running speed
--   "growAll" finish every crop growing in your front garden

export type Recipe = {
	coins: number?,
	crops: { [string]: number }?,
	items: { [string]: number }?,
}

export type Effect = {
	type: string,
	amount: number?,
	bonus: { [string]: number }?,
	walkSpeed: number?,
	duration: number?,
}

export type Potion = {
	recipe: Recipe,
	effect: Effect,
	order: number,
}

local Potions: { [string]: Potion } = {
	HealthPotion = {
		recipe = { coins = 10, crops = { Tomato = 2 }, items = { SlimeGoo = 1 } },
		effect = { type = "heal", amount = 60 },
		order = 1,
	},
	StrengthPotion = {
		recipe = { crops = { Pumpkin = 1 }, items = { GoblinTooth = 2 } },
		effect = { type = "buff", bonus = { damage = 10 }, duration = 120 },
		order = 2,
	},
	IronSkinPotion = {
		recipe = { items = { BatWing = 2, Bone = 1 } },
		effect = { type = "buff", bonus = { defense = 0.15 }, duration = 120 },
		order = 3,
	},
	SwiftnessPotion = {
		recipe = { crops = { Carrot = 2 }, items = { RabbitFluff = 2 } },
		effect = { type = "buff", walkSpeed = 8, duration = 120 },
		order = 4,
	},
	GrowthPotion = {
		recipe = { crops = { Carrot = 3 }, items = { SlimeGoo = 2 } },
		effect = { type = "growAll" },
		order = 5,
	},
}

return Potions
