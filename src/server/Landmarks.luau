-- Builds the shared landmark islands north of the plaza: the Dungeon
-- Portal and the Wilderness Gate. Both are decoration for now; dungeons
-- and the wilderness come in later phases (see docs/ROADMAP.md).

local Build = require(script.Parent.Build)
local MapLayout = require(script.Parent.MapLayout)

local GROUND_TOP = MapLayout.GROUND_TOP
local STONE = Color3.fromRGB(120, 115, 125)
local LOG = Color3.fromRGB(110, 75, 45)

local Landmarks = {}

local function originOf(name: string): CFrame
	local landmark = MapLayout.LANDMARKS[name]
	return MapLayout.facingCenter(landmark.angle, landmark.radius)
end

local function treesAround(parent: Instance, origin: CFrame, spots: { Vector3 })
	for _, spot in spots do
		Build.tree(parent, (origin * CFrame.new(spot.X, GROUND_TOP, spot.Z)).Position, 1)
	end
end

local function torch(parent: Instance, position: Vector3)
	Build.part({
		Name = "TorchPost",
		Size = Vector3.new(0.8, 6, 0.8),
		CFrame = CFrame.new(position + Vector3.new(0, 3, 0)),
		Color = LOG,
		Material = Enum.Material.Wood,
	}).Parent = parent
	local head = Build.part({
		Name = "TorchHead",
		Size = Vector3.new(1.4, 1, 1.4),
		CFrame = CFrame.new(position + Vector3.new(0, 6.5, 0)),
		Color = Color3.fromRGB(60, 50, 45),
		Material = Enum.Material.Metal,
	})
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 6
	fire.Parent = head
	local light = Instance.new("PointLight")
	light.Range = 16
	light.Color = Color3.fromRGB(255, 160, 80)
	light.Parent = head
	head.Parent = parent
end

local function buildDungeonPortal(parent: Instance)
	local origin = originOf("DungeonPortal")
	local portal = Instance.new("Model")
	portal.Name = "DungeonPortal"

	Build.part({
		Name = "Platform",
		Size = Vector3.new(30, 1.5, 20),
		CFrame = origin * CFrame.new(0, GROUND_TOP + 0.75, 5),
		Color = STONE,
		Material = Enum.Material.Slate,
	}).Parent = portal
	for _, x in { -9, 9 } do
		Build.part({
			Name = "Pillar",
			Size = Vector3.new(4, 22, 4),
			CFrame = origin * CFrame.new(x, GROUND_TOP + 1.5 + 11, 5),
			Color = STONE,
			Material = Enum.Material.Slate,
		}).Parent = portal
	end
	local lintel = Build.part({
		Name = "Lintel",
		Size = Vector3.new(24, 4, 5),
		CFrame = origin * CFrame.new(0, GROUND_TOP + 1.5 + 24, 5),
		Color = STONE,
		Material = Enum.Material.Slate,
	})
	lintel.Parent = portal
	Build.sign(lintel, "Dungeon Portal", "Abandoned Mine: ore, monsters, and a Rock Golem", 6)

	local gateway = Build.part({
		Name = "Gateway",
		Size = Vector3.new(14, 20, 0.6),
		CFrame = origin * CFrame.new(0, GROUND_TOP + 1.5 + 11, 5),
		Color = Color3.fromRGB(150, 70, 230),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
	})
	local glow = Instance.new("PointLight")
	glow.Range = 30
	glow.Brightness = 2
	glow.Color = Color3.fromRGB(170, 90, 255)
	glow.Parent = gateway
	gateway.Parent = portal

	for _, x in { -14, 14 } do
		torch(portal, (origin * CFrame.new(x, GROUND_TOP + 1.5, -3)).Position)
	end

	treesAround(portal, origin, {
		Vector3.new(-26, 0, 16),
		Vector3.new(26, 0, 16),
		Vector3.new(0, 0, 30),
		Vector3.new(-30, 0, -10),
		Vector3.new(30, 0, -10),
	})
	portal.Parent = parent
end

local function buildWildernessGate(parent: Instance)
	local origin = originOf("WildernessGate")
	local gate = Instance.new("Model")
	gate.Name = "WildernessGate"

	for _, x in { -8, 8 } do
		Build.part({
			Name = "Log",
			Size = Vector3.new(3, 18, 3),
			CFrame = origin * CFrame.new(x, GROUND_TOP + 9, 0),
			Color = LOG,
			Material = Enum.Material.Wood,
		}).Parent = gate
	end
	local beam = Build.part({
		Name = "Beam",
		Size = Vector3.new(24, 2.5, 3),
		CFrame = origin * CFrame.new(0, GROUND_TOP + 17, 0),
		Color = LOG,
		Material = Enum.Material.Wood,
	})
	beam.Parent = gate
	Build.part({
		Name = "Banner",
		Size = Vector3.new(10, 3, 0.3),
		CFrame = origin * CFrame.new(0, GROUND_TOP + 14.5, -1.7),
		Color = Color3.fromRGB(60, 150, 70),
		Material = Enum.Material.Fabric,
	}).Parent = gate
	Build.sign(beam, "Wilderness Gate", "The Meadow lies beyond. Bring your sword!", 5)

	treesAround(gate, origin, {
		Vector3.new(-20, 0, 10),
		Vector3.new(20, 0, 10),
		Vector3.new(-28, 0, -8),
		Vector3.new(28, 0, -8),
		Vector3.new(-12, 0, 28),
		Vector3.new(12, 0, 28),
	})
	gate.Parent = parent
end

function Landmarks.start()
	local folder = Instance.new("Folder")
	folder.Name = "Landmarks"
	buildDungeonPortal(folder)
	buildWildernessGate(folder)
	folder.Parent = workspace
end

return Landmarks
