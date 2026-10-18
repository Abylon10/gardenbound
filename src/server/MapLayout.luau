-- Where everything sits on the server map, in studs. The Central Plaza is
-- centered on the world origin, the player islands form a ring around it,
-- and the Dungeon Portal and Wilderness Gate islands sit to the north.
-- Angles are degrees clockwise from north (-Z), so 90 is east (+X).
-- See docs/map-design.md.

export type Island = {
	name: string,
	angle: number,
	radius: number,
	islandRadius: number,
}

local MapLayout = {
	-- Sea: terrain water from SEA_FLOOR up to WATER_LEVEL, MAP_EXTENT studs
	-- out from the origin in every direction.
	WATER_LEVEL = -3,
	SEA_FLOOR = -30,
	MAP_EXTENT = 700,
	-- Top of the grass on every island.
	GROUND_TOP = 1,

	PLAZA_RADIUS = 100,
	PLAZA_ISLAND_RADIUS = 110,
	-- Top of the plaza floor; the default SpawnLocation sits just below it.
	PLAZA_TOP = 1.2,

	-- The four shops stand on the plaza's outer ring, facing the center.
	SHOP_RING_RADIUS = 82,
	SHOP_ANGLES = {
		SeedShop = 45,
		SellShop = 135,
		GearShop = 225,
		BlueprintShop = 315,
	},

	PLOT_RING_RADIUS = 280,
	PLOT_SIZE = 130,
	PLOT_ISLAND_RADIUS = 95,
	PLOT_ANGLES = { 70, 114, 158, 202, 246, 290 },

	LANDMARKS = {
		DungeonPortal = { angle = 0, radius = 280, islandRadius = 60 },
		WildernessGate = { angle = 30, radius = 280, islandRadius = 60 },
	},

	-- Wilderness zones, reached through the Wilderness Gate (same angle,
	-- further out). Not connected to the plaza directly.
	ZONES = {
		Meadow = { angle = 30, radius = 550, islandRadius = 150 },
	},
}

function MapLayout.pointAt(angle: number, radius: number): Vector3
	local radians = math.rad(angle)
	return Vector3.new(math.sin(radians) * radius, 0, -math.cos(radians) * radius)
end

-- A CFrame at that point whose front (-Z) faces the plaza center.
function MapLayout.facingCenter(angle: number, radius: number): CFrame
	local position = MapLayout.pointAt(angle, radius)
	return CFrame.lookAt(position, Vector3.zero)
end

-- Every island except the plaza: player plots first, then landmarks.
function MapLayout.islands(): { Island }
	local islands: { Island } = {}
	for i, angle in MapLayout.PLOT_ANGLES do
		table.insert(islands, {
			name = "Plot" .. i,
			angle = angle,
			radius = MapLayout.PLOT_RING_RADIUS,
			islandRadius = MapLayout.PLOT_ISLAND_RADIUS,
		})
	end
	for name, landmark in MapLayout.LANDMARKS do
		table.insert(islands, {
			name = name,
			angle = landmark.angle,
			radius = landmark.radius,
			islandRadius = landmark.islandRadius,
		})
	end
	return islands
end

-- Wilderness zone islands (see ZONES).
function MapLayout.zones(): { Island }
	local zones: { Island } = {}
	for name, zone in MapLayout.ZONES do
		table.insert(zones, {
			name = name,
			angle = zone.angle,
			radius = zone.radius,
			islandRadius = zone.islandRadius,
		})
	end
	return zones
end

return MapLayout
