-- Crop definitions shared by server and client.
-- growTime is in seconds. order controls display order in the seed bar.

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
	Pumpkin = {
		displayName = "Pumpkin",
		seedPrice = 40,
		sellPrice = 100,
		growTime = 90,
		color = Color3.fromRGB(240, 120, 20),
		order = 3,
	},
}

return Crops
