-- Builds the house for each house level and the decorations built on a
-- homestead. Pure builders: they only create parts. Used by Plots (the
-- starting house) and Homestead (upgrades and decorations).
-- All CFrames are in plot space: front (-Z) faces the plaza.

local Build = require(script.Parent.Build)
local MapLayout = require(script.Parent.MapLayout)

local GROUND_TOP = MapLayout.GROUND_TOP
local WALL_COLOR = Color3.fromRGB(235, 215, 180)
local WOOD = Color3.fromRGB(150, 105, 65)
local DARK_WOOD = Color3.fromRGB(110, 75, 45)
local STONE = Color3.fromRGB(150, 145, 135)

local HomeBuilder = {}

-- Where the house stands, relative to the plot origin.
HomeBuilder.HOUSE_OFFSET = CFrame.new(-20, 0, 26)

local function block(parent: Instance, origin: CFrame, name: string, size: Vector3, offset: CFrame, props: { [string]: any }?)
	local properties: { [string]: any } = {
		Name = name,
		Size = size,
		CFrame = origin * offset,
		Color = WOOD,
		Material = Enum.Material.Wood,
	}
	local extra: { [string]: any } = props or {}
	for key, value in extra do
		properties[key] = value
	end
	local part = Build.part(properties)
	part.Parent = parent
	return part
end

-- A closed house with a peaked roof. The roof is a block turned 45 degrees,
-- so its lower half hides inside the walls. Level 2 adds a porch and a
-- chimney; level 3 adds a second story.
function HomeBuilder.buildHouse(parent: Instance, plotOrigin: CFrame, level: number, roofColor: Color3): Model
	local origin = plotOrigin * HomeBuilder.HOUSE_OFFSET
	local house = Instance.new("Model")
	house.Name = "House"
	local width, depth = 22, 18
	local height = if level >= 3 then 22 else 12

	block(house, origin, "Walls", Vector3.new(width, height, depth), CFrame.new(0, GROUND_TOP + height / 2, 0), {
		Color = WALL_COLOR,
		Material = Enum.Material.WoodPlanks,
	})

	local roofSide = (depth + 3) / math.sqrt(2)
	block(
		house,
		origin,
		"Roof",
		Vector3.new(width + 2, roofSide, roofSide),
		CFrame.new(0, GROUND_TOP + height, 0) * CFrame.Angles(math.rad(45), 0, 0),
		{ Color = roofColor, Material = Enum.Material.Slate }
	)

	local front = -depth / 2 - 0.1
	block(house, origin, "Door", Vector3.new(4, 7, 0.4), CFrame.new(0, GROUND_TOP + 3.5, front), { Color = DARK_WOOD })
	local windowRows = if level >= 3 then { 7, 17 } else { 7 }
	for _, y in windowRows do
		for _, x in { -6.5, 6.5 } do
			block(house, origin, "Window", Vector3.new(3.5, 3, 0.4), CFrame.new(x, GROUND_TOP + y, front), {
				Color = Color3.fromRGB(150, 200, 230),
				Material = Enum.Material.Glass,
				Transparency = 0.2,
			})
		end
	end

	if level >= 2 then
		-- Porch: deck, two posts, and a small roof over the door.
		block(house, origin, "PorchDeck", Vector3.new(14, 0.6, 5), CFrame.new(0, GROUND_TOP + 0.3, front - 2.5), {
			Material = Enum.Material.WoodPlanks,
		})
		for _, x in { -6.5, 6.5 } do
			block(house, origin, "PorchPost", Vector3.new(0.8, 8, 0.8), CFrame.new(x, GROUND_TOP + 4, front - 4.6))
		end
		block(house, origin, "PorchRoof", Vector3.new(15, 0.6, 6), CFrame.new(0, GROUND_TOP + 8.3, front - 2.5), {
			Color = roofColor,
			Material = Enum.Material.Slate,
		})
		block(house, origin, "Chimney", Vector3.new(3, 8, 3), CFrame.new(width / 2 - 4, GROUND_TOP + height + 5, 3), {
			Color = STONE,
			Material = Enum.Material.Brick,
		})
	end

	house.Parent = parent
	return house
end

-- Decorations, each built around a build-spot CFrame (on the ground).
local decorBuilders: { [string]: (Model, CFrame) -> () } = {
	Bench = function(model, at)
		block(model, at, "Seat", Vector3.new(6, 0.5, 2), CFrame.new(0, GROUND_TOP + 1.8, 0))
		block(model, at, "Back", Vector3.new(6, 2, 0.4), CFrame.new(0, GROUND_TOP + 3, 0.9))
		for _, x in { -2.6, 2.6 } do
			block(model, at, "Leg", Vector3.new(0.5, 1.6, 1.8), CFrame.new(x, GROUND_TOP + 0.8, 0), { Color = DARK_WOOD })
		end
	end,
	Lantern = function(model, at)
		Build.lamp(model, (at * CFrame.new(0, GROUND_TOP, 0)).Position)
	end,
	FlowerBed = function(model, at)
		block(model, at, "Bed", Vector3.new(8, 1, 4), CFrame.new(0, GROUND_TOP + 0.5, 0), {
			Color = Color3.fromRGB(90, 60, 40),
			Material = Enum.Material.Ground,
		})
		local colors = {
			Color3.fromRGB(240, 90, 120),
			Color3.fromRGB(250, 210, 70),
			Color3.fromRGB(150, 110, 230),
			Color3.fromRGB(255, 255, 255),
		}
		for i = 0, 7 do
			local x = -3 + (i % 4) * 2
			local z = if i < 4 then -1 else 1
			block(model, at, "Flower", Vector3.new(1, 1, 1), CFrame.new(x, GROUND_TOP + 1.6, z), {
				Shape = Enum.PartType.Ball,
				Color = colors[i % #colors + 1],
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
			})
		end
	end,
	Scarecrow = function(model, at)
		block(model, at, "Pole", Vector3.new(0.6, 7, 0.6), CFrame.new(0, GROUND_TOP + 3.5, 0), { Color = DARK_WOOD })
		block(model, at, "Arms", Vector3.new(5, 0.5, 0.5), CFrame.new(0, GROUND_TOP + 5, 0), { Color = DARK_WOOD })
		block(model, at, "Shirt", Vector3.new(2.4, 2.6, 1.2), CFrame.new(0, GROUND_TOP + 4.6, 0), {
			Color = Color3.fromRGB(70, 110, 170),
			Material = Enum.Material.Fabric,
		})
		block(model, at, "Head", Vector3.new(1.8, 1.8, 1.8), CFrame.new(0, GROUND_TOP + 6.9, 0), {
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(230, 190, 110),
			Material = Enum.Material.Fabric,
		})
		block(model, at, "Hat", Vector3.new(2.6, 0.4, 2.6), CFrame.new(0, GROUND_TOP + 7.9, 0), {
			Color = Color3.fromRGB(170, 130, 60),
			Material = Enum.Material.Fabric,
		})
	end,
	Well = function(model, at)
		block(model, at, "Base", Vector3.new(3, 6, 6), CFrame.new(0, GROUND_TOP + 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), {
			Shape = Enum.PartType.Cylinder,
			Color = STONE,
			Material = Enum.Material.Cobblestone,
		})
		block(model, at, "Water", Vector3.new(0.2, 4.6, 4.6), CFrame.new(0, GROUND_TOP + 2.6, 0) * CFrame.Angles(0, 0, math.rad(90)), {
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(70, 150, 220),
			Material = Enum.Material.Glass,
			Transparency = 0.2,
		})
		for _, x in { -2.6, 2.6 } do
			block(model, at, "Post", Vector3.new(0.6, 5, 0.6), CFrame.new(x, GROUND_TOP + 5.5, 0), { Color = DARK_WOOD })
		end
		block(model, at, "Roof", Vector3.new(6.5, 0.5, 4), CFrame.new(0, GROUND_TOP + 8.2, 0), { Color = DARK_WOOD })
	end,
}

-- Where each decoration's build spot is, relative to the plot origin.
HomeBuilder.DECOR_SPOTS = {
	Bench = CFrame.new(-31, 0, 9),
	Lantern = CFrame.new(-9, 0, 9),
	FlowerBed = CFrame.new(-40, 0, 26) * CFrame.Angles(0, math.rad(90), 0),
	Scarecrow = CFrame.new(-30, 0, -22),
	Well = CFrame.new(-40, 0, 6),
}

function HomeBuilder.buildDecor(parent: Instance, decorId: string, at: CFrame): Model?
	local builder = decorBuilders[decorId]
	if not builder then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = decorId
	builder(model, at)
	model.Parent = parent
	return model
end

return HomeBuilder
