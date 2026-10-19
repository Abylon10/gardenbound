-- The wilderness zones beyond the Wilderness Gate. For now: the Meadow,
-- a large island reached by a bridge from the gate island, with trees,
-- rocks, a winding path, hidden nooks, slimes and goblins (see Enemies),
-- and pet eggs to find (see EggSpawns): in clearings, near trees, behind
-- rocks, along the path, and in the hidden nooks.

local Build = require(script.Parent.Build)
local EggSpawns = require(script.Parent.EggSpawns)
local Enemies = require(script.Parent.Enemies)
local MapLayout = require(script.Parent.MapLayout)

local GROUND_TOP = MapLayout.GROUND_TOP

local Wilderness = {}

local function buildMeadow(parent: Instance)
	local zone = MapLayout.ZONES.Meadow
	local gate = MapLayout.LANDMARKS.WildernessGate
	local center = MapLayout.pointAt(zone.angle, zone.radius)

	local meadow = Instance.new("Model")
	meadow.Name = "Meadow"
	-- Always loaded, so the bridge and ground are never missing underfoot.
	meadow.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	-- Invisible solid ground at grass level, like the plots.
	local ground = Build.part({
		Name = "Ground",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, zone.islandRadius * 2, zone.islandRadius * 2),
		CFrame = CFrame.new(center.X, GROUND_TOP - 0.5, center.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Transparency = 1,
	})
	ground.Parent = meadow
	meadow.PrimaryPart = ground

	Build.bridge(
		meadow,
		"Bridge",
		MapLayout.pointAt(gate.angle, gate.radius + gate.islandRadius - 6),
		MapLayout.pointAt(zone.angle, zone.radius - zone.islandRadius + 6),
		GROUND_TOP + 0.2
	)

	local entrance = MapLayout.pointAt(zone.angle, zone.radius - zone.islandRadius + 12)
	Build.signPost(meadow, entrance + Vector3.new(8, GROUND_TOP, 0), "The Meadow", Color3.fromRGB(90, 190, 90))

	-- Scattered trees and rocks (same layout every time). Each also gives an
	-- egg spot: beside a tree, or hidden behind a rock (away from the
	-- entrance).
	local random = Random.new(27)
	local spots: { EggSpawns.Spot } = {}
	local function inside(position: Vector3): boolean
		return (Vector3.new(position.X, 0, position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
			< zone.islandRadius - 6
	end
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = meadow
	for i = 1, 80 do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(20, zone.islandRadius - 8)
		local position = center + Vector3.new(math.cos(angle) * distance, GROUND_TOP, math.sin(angle) * distance)
		if i % 4 == 0 then
			local size = random:NextNumber(3, 7)
			-- Egg spot behind the rock (on the side away from the entrance).
			local away = Vector3.new(position.X - entrance.X, 0, position.Z - entrance.Z).Unit
			local behindSpot = position + away * (size * 0.8 + 1.5)
			if inside(behindSpot) then
				table.insert(spots, { position = behindSpot, hidden = false })
			end
			Build.part({
				Name = "Rock",
				Size = Vector3.new(size, size * 0.7, size * 1.2),
				CFrame = CFrame.new(position + Vector3.new(0, size * 0.3, 0)) * CFrame.Angles(0, random:NextNumber(0, 6), 0),
				Color = Color3.fromRGB(130, 130, 125),
				Material = Enum.Material.Rock,
			}).Parent = decor
		else
			if i % 3 == 0 then
				Build.pineTree(decor, position, random:NextNumber(1, 1.5))
			else
				Build.tree(decor, position, random:NextNumber(0.8, 1.3))
			end
			local side = random:NextNumber(0, math.pi * 2)
			local besideSpot = position + Vector3.new(math.cos(side) * 3.5, 0, math.sin(side) * 3.5)
			if inside(besideSpot) then
				table.insert(spots, { position = besideSpot, hidden = false })
			end
		end
	end
	-- Open clearings.
	for _ = 1, 25 do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(10, zone.islandRadius - 10)
		table.insert(spots, {
			position = center + Vector3.new(math.cos(angle) * distance, GROUND_TOP, math.sin(angle) * distance),
			hidden = false,
		})
	end

	-- A winding dirt path from the entrance across the meadow, with egg
	-- spots along it.
	local inward = Vector3.new(center.X - entrance.X, 0, center.Z - entrance.Z).Unit
	local across = Vector3.new(-inward.Z, 0, inward.X)
	local length = zone.islandRadius * 2 - 30
	local previous: Vector3? = nil
	for i = 0, 24 do
		local t = i / 24
		local point = entrance + inward * (t * length) + across * (math.sin(t * math.pi * 2.5) * 30)
		point = Vector3.new(point.X, GROUND_TOP, point.Z)
		if previous then
			local segment = point - previous
			Build.part({
				Name = "Path",
				Size = Vector3.new(6, 0.2, segment.Magnitude + 1),
				CFrame = CFrame.lookAt((previous + point) / 2, point) + Vector3.new(0, 0.05, 0),
				Color = Color3.fromRGB(150, 115, 75),
				Material = Enum.Material.Ground,
				CanCollide = false,
			}).Parent = decor
			if i % 2 == 0 and inside(point + across * 5) then
				table.insert(spots, { position = point + across * (if i % 4 == 0 then 5 else -5), hidden = false })
			end
		end
		previous = point
	end

	-- Hidden nooks near the far edge: a ring of boulders around a few
	-- glowing mushrooms. Their spots hold Epic and Special eggs.
	for _, turn in { -55, 0, 55 } do
		local radians = math.rad(turn)
		local direction = inward * math.cos(radians) + across * math.sin(radians)
		local nook = center + direction * (zone.islandRadius - 22)
		nook = Vector3.new(nook.X, GROUND_TOP, nook.Z)
		for j = 1, 7 do
			-- Leave a narrow gap facing the meadow center.
			local angle = math.atan2(-direction.Z, -direction.X) + j * (math.pi * 2 / 8)
			local size = random:NextNumber(4, 6)
			Build.part({
				Name = "NookRock",
				Size = Vector3.new(size, size * 1.1, size),
				CFrame = CFrame.new(nook + Vector3.new(math.cos(angle) * 7, size * 0.45, math.sin(angle) * 7))
					* CFrame.Angles(0, random:NextNumber(0, 6), 0),
				Color = Color3.fromRGB(110, 110, 105),
				Material = Enum.Material.Rock,
			}).Parent = decor
		end
		for j = 1, 3 do
			local offset = Vector3.new(math.cos(j * 2.1) * 3.5, 0, math.sin(j * 2.1) * 3.5)
			local cap = Build.part({
				Name = "Mushroom",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.4, 0.8, 1.4),
				CFrame = CFrame.new(nook + offset + Vector3.new(0, 1, 0)),
				Color = Color3.fromRGB(150, 90, 255),
				Material = Enum.Material.Neon,
				CanCollide = false,
			})
			cap.Parent = decor
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(170, 110, 255)
			light.Range = 8
			light.Parent = cap
		end
		table.insert(spots, { position = nook, hidden = true })
	end

	meadow.Parent = parent
	Enemies.registerZone("Meadow", center, zone.islandRadius - 12, GROUND_TOP, {
		Slime = 12,
		Goblin = 6,
	})
	EggSpawns.registerArea("Meadow", meadow, entrance, zone.islandRadius * 2, spots)
end

function Wilderness.start()
	local folder = Instance.new("Folder")
	folder.Name = "Wilderness"
	folder.Parent = workspace
	buildMeadow(folder)
end

return Wilderness
