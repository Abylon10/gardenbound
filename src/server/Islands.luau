-- Shapes the world with terrain: a sea of water, a sandy sea floor, and a
-- rocky island with a grass top for the plaza and for every other island
-- in MapLayout. Removes the template Baseplate, which would sit above the
-- water. Must run before anything is built on the islands.

local MapLayout = require(script.Parent.MapLayout)

local Islands = {}

local function fillIsland(terrain: Terrain, center: Vector3, radius: number)
	local groundTop = MapLayout.GROUND_TOP
	local rockTop = groundTop - 2
	local rockHeight = rockTop - MapLayout.SEA_FLOOR
	-- A wider rock base leaves a cliff ledge just above the water.
	terrain:FillCylinder(
		CFrame.new(center.X, MapLayout.SEA_FLOOR + rockHeight / 2, center.Z),
		rockHeight,
		radius + 5,
		Enum.Material.Rock
	)
	terrain:FillCylinder(CFrame.new(center.X, groundTop - 2.5, center.Z), 5, radius, Enum.Material.Grass)
end

function Islands.start()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	local terrain = workspace.Terrain
	local extent = MapLayout.MAP_EXTENT * 2
	local depth = MapLayout.WATER_LEVEL - MapLayout.SEA_FLOOR

	terrain:FillBlock(
		CFrame.new(0, MapLayout.SEA_FLOOR - 2, 0),
		Vector3.new(extent, 4, extent),
		Enum.Material.Sand
	)
	terrain:FillBlock(
		CFrame.new(0, MapLayout.SEA_FLOOR + depth / 2, 0),
		Vector3.new(extent, depth, extent),
		Enum.Material.Water
	)

	fillIsland(terrain, Vector3.zero, MapLayout.PLAZA_ISLAND_RADIUS)
	for _, island in MapLayout.islands() do
		fillIsland(terrain, MapLayout.pointAt(island.angle, island.radius), island.islandRadius)
	end
end

return Islands
