-- Enemy stats and drops. Eggs are never dropped by enemies; they are found
-- in the wilderness (see server EggSpawns).
--   coins     coins per kill
--   drops     item id -> chance (0-1) to drop one
--   gearDrops gear id -> chance to drop that gear (if not already owned)
-- shape picks how the server builds the model (see server Enemies).

export type EnemyType = {
	displayName: string,
	health: number,
	damage: number,
	attackCooldown: number,
	speed: number,
	aggroRange: number,
	size: number,
	color: Color3,
	shape: string,
	coins: number,
	drops: { [string]: number },
	gearDrops: { [string]: number }?,
	respawn: number?, -- seconds; default 10
}

local EnemyTypes: { [string]: EnemyType } = {
	-- Wilderness (Meadow)
	Slime = {
		displayName = "Slime",
		health = 30,
		damage = 5,
		attackCooldown = 1.2,
		speed = 8,
		aggroRange = 30,
		size = 4,
		color = Color3.fromRGB(110, 220, 110),
		shape = "slime",
		coins = 3,
		drops = { SlimeGel = 0.7, WildBerry = 0.3 },
	},
	Goblin = {
		displayName = "Goblin",
		health = 70,
		damage = 10,
		attackCooldown = 1.5,
		speed = 11,
		aggroRange = 35,
		size = 5,
		color = Color3.fromRGB(90, 150, 60),
		shape = "goblin",
		coins = 10,
		drops = { GoblinFang = 0.6, RoughHide = 0.5 },
		gearDrops = { RustySword = 0.05 },
	},

	-- Dungeon (Abandoned Mine)
	CaveSlime = {
		displayName = "Slime",
		health = 60,
		damage = 10,
		attackCooldown = 1.2,
		speed = 9,
		aggroRange = 28,
		size = 5,
		color = Color3.fromRGB(70, 170, 200),
		shape = "slime",
		coins = 6,
		drops = { SlimeGel = 0.8, SlimeCore = 0.25 },
	},
	Bat = {
		displayName = "Bat",
		health = 45,
		damage = 8,
		attackCooldown = 0.9,
		speed = 16,
		aggroRange = 28,
		size = 3,
		color = Color3.fromRGB(60, 50, 70),
		shape = "bat",
		coins = 5,
		drops = { BatWing = 0.7, ShadowEssence = 0.08 },
	},
}

return EnemyTypes
