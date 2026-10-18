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
	-- Top of the grass on every island: high enough above the water that
	-- players can't jump up the cliffs. Docks with stairs lead up instead.
	GROUND_TOP = 15,

	PLAZA_RADIUS = 100,
	PLAZA_ISLAND_RADIUS = 122,
	-- The plaza floor is raised on a ring of steps above the island grass.
	PLAZA_STEPS = 8,
	PLAZA_STEP_RISE = 0.5,
	PLAZA_STEP_RUN = 1.25,
	-- Top of the plaza floor (set below from GROUND_TOP and the steps).
	PLAZA_TOP = 0,

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

MapLayout.PLAZA_TOP = MapLayout.GROUND_TOP + MapLayout.PLAZA_STEPS * MapLayout.PLAZA_STEP_RISE
-- Outer edge of the bottom plaza step.
MapLayout.PLAZA_STEPS_RADIUS = MapLayout.PLAZA_RADIUS + MapLayout.PLAZA_STEPS * MapLayout.PLAZA_STEP_RUN

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

export type Dock = {
	name: string,
	center: Vector3,
	islandRadius: number,
	bearing: number, -- direction from the island center, degrees
	side: number, -- which way the stairs run along the cliff (1 or -1)
}

-- Docks at water level with stairs up the cliff, so players who fall in
-- can climb back. Positions were checked to clear islands and bridges.
function MapLayout.docks(): { Dock }
	local docks: { Dock } = {}
	local function add(name: string, center: Vector3, islandRadius: number, bearing: number, side: number)
		table.insert(docks, { name = name, center = center, islandRadius = islandRadius, bearing = bearing, side = side })
	end
	add("PlazaEast", Vector3.zero, MapLayout.PLAZA_ISLAND_RADIUS, 92, 1)
	add("PlazaWest", Vector3.zero, MapLayout.PLAZA_ISLAND_RADIUS, 268, -1)
	for i, angle in MapLayout.PLOT_ANGLES do
		-- Behind each plot, facing away from the plaza.
		add("Plot" .. i, MapLayout.pointAt(angle, MapLayout.PLOT_RING_RADIUS), MapLayout.PLOT_ISLAND_RADIUS, angle, 1)
	end
	local portal = MapLayout.LANDMARKS.DungeonPortal
	add("DungeonPortal", MapLayout.pointAt(portal.angle, portal.radius), portal.islandRadius, 0, 1)
	local gate = MapLayout.LANDMARKS.WildernessGate
	add("WildernessGate", MapLayout.pointAt(gate.angle, gate.radius), gate.islandRadius, 330, 1)
	local meadow = MapLayout.ZONES.Meadow
	add("Meadow", MapLayout.pointAt(meadow.angle, meadow.radius), meadow.islandRadius, meadow.angle, 1)
	return docks
end

return MapLayout
