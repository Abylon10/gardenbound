-- Where everything sits on the server map, in studs. The Central Plaza is
-- centered on the world origin and the player plots form a ring around it.
-- Angles are degrees clockwise from north (-Z), so 90 is east (+X).
-- North is kept free for the Dungeon Portal and Wilderness Gate.

local MapLayout = {
	PLAZA_RADIUS = 60,
	-- Top of the plaza floor; the default SpawnLocation sits just below it.
	PLAZA_TOP = 1.2,

	-- The four shops stand on the plaza's outer ring, facing the center.
	SHOP_RING_RADIUS = 48,
	SHOP_ANGLES = {
		SeedShop = 45,
		SellShop = 135,
		GearShop = 225,
		BlueprintShop = 315,
	},

	PLOT_RING_RADIUS = 180,
	PLOT_SIZE = 90,
	PLOT_ANGLES = { 70, 114, 158, 202, 246, 290 },
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

return MapLayout
