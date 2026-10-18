-- The wilderness zones beyond the Wilderness Gate. For now: the Meadow,
-- a large island reached by a bridge from the gate island, with trees,
-- rocks, and slimes, rabbits, and goblins (see Enemies).

local Build = require(script.Parent.Build)
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

	-- Scattered trees and rocks (same layout every time).
	local random = Random.new(27)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = meadow
	for i = 1, 40 do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(20, zone.islandRadius - 8)
		local position = center + Vector3.new(math.cos(angle) * distance, GROUND_TOP, math.sin(angle) * distance)
		if i % 4 == 0 then
			local size = random:NextNumber(3, 7)
			Build.part({
				Name = "Rock",
				Size = Vector3.new(size, size * 0.7, size * 1.2),
				CFrame = CFrame.new(position + Vector3.new(0, size * 0.3, 0)) * CFrame.Angles(0, random:NextNumber(0, 6), 0),
				Color = Color3.fromRGB(130, 130, 125),
				Material = Enum.Material.Rock,
			}).Parent = decor
		else
			Build.tree(decor, position, random:NextNumber(0.8, 1.3))
		end
	end

	meadow.Parent = parent
	Enemies.registerZone("Meadow", center, zone.islandRadius - 12, GROUND_TOP, {
		Slime = 6,
		Rabbit = 5,
		Goblin = 3,
	})
end

function Wilderness.start()
	local folder = Instance.new("Folder")
	folder.Name = "Wilderness"
	folder.Parent = workspace
	buildMeadow(folder)
end

return Wilderness
