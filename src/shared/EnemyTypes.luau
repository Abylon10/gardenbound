-- Enemy stats. drops: chance (0-1) to drop one of an item when killed.
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
}

local EnemyTypes: { [string]: EnemyType } = {
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
		drops = { SlimeGoo = 0.6, CommonEgg = 0.1 },
	},
	Rabbit = {
		displayName = "Wild Rabbit",
		health = 20,
		damage = 3,
		attackCooldown = 1,
		speed = 14,
		aggroRange = 22,
		size = 3,
		color = Color3.fromRGB(235, 225, 210),
		shape = "rabbit",
		coins = 2,
		drops = { RabbitFluff = 0.6, CommonEgg = 0.1 },
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
		coins = 8,
		drops = { GoblinTooth = 0.5, CommonEgg = 0.15, ForestEgg = 0.08 },
	},
}

return EnemyTypes
