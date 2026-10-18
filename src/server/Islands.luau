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

-- Distance from a point to a line segment, on the ground plane.
local function distanceToSegment(point: Vector3, a: Vector3, b: Vector3): number
	local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local ap = Vector3.new(point.X - a.X, 0, point.Z - a.Z)
	local t = math.clamp(ap:Dot(ab) / ab:Dot(ab), 0, 1)
	return (ap - ab * t).Magnitude
end

-- Rocks sticking out of the sea around the islands, like the map art.
-- They stay clear of islands (and their docks) and of every bridge.
local function addSeaStacks(terrain: Terrain)
	local islands = { { center = Vector3.zero, radius = MapLayout.PLAZA_ISLAND_RADIUS } }
	local bridges = {}
	for _, island in MapLayout.islands() do
		local center = MapLayout.pointAt(island.angle, island.radius)
		table.insert(islands, { center = center, radius = island.islandRadius })
		table.insert(bridges, {
			MapLayout.pointAt(island.angle, MapLayout.PLAZA_STEPS_RADIUS),
			MapLayout.pointAt(island.angle, island.radius - island.islandRadius),
		})
	end
	for _, zone in MapLayout.zones() do
		table.insert(islands, { center = MapLayout.pointAt(zone.angle, zone.radius), radius = zone.islandRadius })
		local gate = MapLayout.LANDMARKS.WildernessGate
		table.insert(bridges, {
			MapLayout.pointAt(gate.angle, gate.radius + gate.islandRadius),
			MapLayout.pointAt(zone.angle, zone.radius - zone.islandRadius),
		})
	end

	local random = Random.new(7)
	local placed = 0
	for _ = 1, 400 do
		if placed >= 45 then
			break
		end
		local angle = random:NextNumber(0, 360)
		local distance = random:NextNumber(150, MapLayout.MAP_EXTENT - 40)
		local position = MapLayout.pointAt(angle, distance)
		local size = random:NextNumber(4, 10)
		local clear = true
		for _, island in islands do
			if (position - island.center).Magnitude < island.radius + 45 + size then
				clear = false
			end
		end
		for _, bridge in bridges do
			if distanceToSegment(position, bridge[1], bridge[2]) < 18 + size then
				clear = false
			end
		end
		if clear then
			placed += 1
			local top = MapLayout.WATER_LEVEL + random:NextNumber(2, 12)
			local height = top - MapLayout.SEA_FLOOR
			terrain:FillCylinder(
				CFrame.new(position.X, MapLayout.SEA_FLOOR + height / 2, position.Z),
				height,
				size,
				Enum.Material.Rock
			)
		end
	end
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
	for _, zone in MapLayout.zones() do
		fillIsland(terrain, MapLayout.pointAt(zone.angle, zone.radius), zone.islandRadius)
	end
	addSeaStacks(terrain)
end

return Islands
