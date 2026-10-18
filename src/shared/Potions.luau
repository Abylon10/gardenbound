-- Potion recipes (brewed at the cauldron by your house) and effects (used
-- from the Bag). Each potion is also an item in Items. Proposed starting
-- values for balancing.
-- effect.type:
--   "heal"  restore healFraction of max health
--   "buff"  for `duration` seconds: Bonuses keys in `bonus`, and/or
--           speedMultiplier on running speed
-- cooldown: seconds before the same potion can be used again.

export type Recipe = {
	coins: number?,
	crops: { [string]: number }?,
	items: { [string]: number }?,
}

export type Effect = {
	type: string,
	healFraction: number?,
	bonus: { [string]: number }?,
	speedMultiplier: number?,
	duration: number?,
}

export type Potion = {
	recipe: Recipe,
	effect: Effect,
	cooldown: number,
	order: number,
}

local Potions: { [string]: Potion } = {
	HealthPotion = {
		recipe = { items = { SlimeGel = 2, WildBerry = 1 } },
		effect = { type = "heal", healFraction = 0.3 },
		cooldown = 15,
		order = 1,
	},
	SwiftnessPotion = {
		recipe = { items = { BatWing = 1, WildBerry = 2 } },
		effect = { type = "buff", speedMultiplier = 1.25, duration = 10 },
		cooldown = 30,
		order = 2,
	},
	StrengthPotion = {
		recipe = { items = { SlimeGel = 2, GoblinFang = 1 } },
		effect = { type = "buff", bonus = { damageMultiplier = 1.15 }, duration = 15 },
		cooldown = 30,
		order = 3,
	},
}

return Potions
