-- Front-garden crops, shared by server and client.
-- growTime is in seconds. order controls display order (seed bar, shops).

export type Crop = {
	displayName: string,
	seedPrice: number,
	sellPrice: number,
	growTime: number,
	color: Color3,
	order: number,
}

local Crops: { [string]: Crop } = {
	Carrot = {
		displayName = "Carrot",
		seedPrice = 5,
		sellPrice = 12,
		growTime = 20,
		color = Color3.fromRGB(255, 140, 0),
		order = 1,
	},
	Tomato = {
		displayName = "Tomato",
		seedPrice = 15,
		sellPrice = 35,
		growTime = 45,
		color = Color3.fromRGB(220, 40, 40),
		order = 2,
	},
	Eggplant = {
		displayName = "Eggplant",
		seedPrice = 25,
		sellPrice = 60,
		growTime = 70,
		color = Color3.fromRGB(110, 50, 140),
		order = 3,
	},
	Cabbage = {
		displayName = "Cabbage",
		seedPrice = 40,
		sellPrice = 100,
		growTime = 100,
		color = Color3.fromRGB(150, 210, 110),
		order = 4,
	},
	Chilli = {
		displayName = "Chilli",
		seedPrice = 70,
		sellPrice = 180,
		growTime = 150,
		color = Color3.fromRGB(235, 50, 30),
		order = 5,
	},
}

return Crops
