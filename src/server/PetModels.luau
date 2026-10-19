-- Builds the follower models for each pet: a small blocky Dog, Cat, Hen,
-- Giant Earthworm, or Butterfly, made of parts welded to an invisible root
-- (which PetSystem moves with AlignPosition/AlignOrientation).
-- Front is -Z.

local PetModels = {}

local BLACK = Color3.fromRGB(20, 20, 20)

-- How high above the follow point each pet floats (butterflies fly,
-- earthworms stay low).
PetModels.HEIGHT = {
	Butterfly = 2.5,
	GiantEarthworm = -1.3,
}

local function addPart(root: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, props: { [string]: any }?)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = true
	part.CFrame = root.CFrame * offset
	local extra: { [string]: any } = props or {}
	for key, value in extra do
		(part :: any)[key] = value
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = root
	return part
end

local function ball(root: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, props: { [string]: any }?)
	local extra: { [string]: any } = props or {}
	extra.Shape = Enum.PartType.Ball
	return addPart(root, name, size, offset, color, extra)
end

local function eyes(root: BasePart, y: number, z: number, spread: number, size: number, color: Color3?, neon: boolean?)
	for _, x in { -spread, spread } do
		ball(root, "Eye", Vector3.new(size, size, size), CFrame.new(x, y, z), color or BLACK, {
			Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic,
		})
	end
end

local builders: { [string]: (BasePart) -> () } = {
	Dog = function(root)
		local brown = Color3.fromRGB(190, 130, 80)
		local white = Color3.fromRGB(245, 240, 230)
		addPart(root, "Body", Vector3.new(1.3, 1, 2), CFrame.new(0, 0, 0.1), brown)
		addPart(root, "Belly", Vector3.new(1.32, 0.5, 1.6), CFrame.new(0, -0.3, 0.1), white)
		addPart(root, "Head", Vector3.new(1.1, 1, 1), CFrame.new(0, 0.6, -1.1), white)
		addPart(root, "Snout", Vector3.new(0.6, 0.45, 0.5), CFrame.new(0, 0.4, -1.7), white)
		ball(root, "Nose", Vector3.new(0.25, 0.25, 0.25), CFrame.new(0, 0.55, -1.95), BLACK)
		for _, x in { -0.45, 0.45 } do
			addPart(root, "Ear", Vector3.new(0.25, 0.6, 0.45), CFrame.new(x, 0.95, -1.05), Color3.fromRGB(120, 70, 40))
		end
		addPart(root, "Bandana", Vector3.new(1.15, 0.25, 1.05), CFrame.new(0, 0.15, -1.05), Color3.fromRGB(50, 110, 220))
		eyes(root, 0.75, -1.61, 0.25, 0.2)
		for _, x in { -0.45, 0.45 } do
			for _, z in { -0.6, 0.8 } do
				addPart(root, "Leg", Vector3.new(0.3, 0.6, 0.3), CFrame.new(x, -0.75, z), brown)
			end
		end
		addPart(root, "Tail", Vector3.new(0.2, 0.7, 0.2), CFrame.new(0, 0.5, 1.2) * CFrame.Angles(math.rad(-30), 0, 0), brown)
	end,
	Cat = function(root)
		local black = Color3.fromRGB(35, 35, 45)
		addPart(root, "Body", Vector3.new(1, 0.9, 1.8), CFrame.new(0, 0, 0.1), black)
		addPart(root, "Head", Vector3.new(1, 0.9, 0.9), CFrame.new(0, 0.55, -1.05), black)
		for _, x in { -0.3, 0.3 } do
			addPart(root, "Ear", Vector3.new(0.3, 0.45, 0.15), CFrame.new(x, 1.15, -1.05) * CFrame.Angles(0, 0, math.rad(x * 40)), black)
		end
		eyes(root, 0.65, -1.5, 0.22, 0.22, Color3.fromRGB(120, 255, 90), true)
		addPart(root, "Collar", Vector3.new(1.02, 0.15, 0.92), CFrame.new(0, 0.15, -1.05), Color3.fromRGB(200, 200, 210), {
			Material = Enum.Material.Metal,
		})
		for _, x in { -0.35, 0.35 } do
			for _, z in { -0.55, 0.75 } do
				addPart(root, "Leg", Vector3.new(0.25, 0.6, 0.25), CFrame.new(x, -0.7, z), black)
			end
		end
		addPart(root, "Tail", Vector3.new(0.18, 1.4, 0.18), CFrame.new(0, 0.6, 1.15) * CFrame.Angles(math.rad(-25), 0, 0), black)
	end,
	Hen = function(root)
		local white = Color3.fromRGB(250, 250, 245)
		local red = Color3.fromRGB(220, 40, 40)
		local orange = Color3.fromRGB(245, 160, 40)
		ball(root, "Body", Vector3.new(1.4, 1.3, 1.7), CFrame.new(0, 0, 0.1), white)
		ball(root, "Head", Vector3.new(0.85, 0.85, 0.85), CFrame.new(0, 0.85, -0.65), white)
		addPart(root, "Comb", Vector3.new(0.15, 0.45, 0.55), CFrame.new(0, 1.35, -0.65), red)
		addPart(root, "Beak", Vector3.new(0.25, 0.2, 0.35), CFrame.new(0, 0.8, -1.15), orange)
		ball(root, "Wattle", Vector3.new(0.2, 0.3, 0.2), CFrame.new(0, 0.55, -1.05), red)
		eyes(root, 0.95, -1.02, 0.22, 0.15)
		addPart(root, "TailFeathers", Vector3.new(0.6, 0.8, 0.3), CFrame.new(0, 0.5, 0.95) * CFrame.Angles(math.rad(-20), 0, 0), white)
		for _, x in { -0.3, 0.3 } do
			addPart(root, "Leg", Vector3.new(0.12, 0.6, 0.12), CFrame.new(x, -0.85, 0), orange)
		end
	end,
	GiantEarthworm = function(root)
		local pink = Color3.fromRGB(230, 140, 140)
		for i = 0, 5 do
			local size = 1 - i * 0.08
			ball(root, "Segment", Vector3.new(size, size, size), CFrame.new(0, math.sin(i * 1.2) * 0.25, -0.9 + i * 0.6), pink)
		end
		addPart(root, "Band", Vector3.new(0.95, 0.95, 0.25), CFrame.new(0, math.sin(1.2) * 0.25, -0.3), Color3.fromRGB(210, 110, 120), {
			Shape = Enum.PartType.Cylinder,
			CFrame = root.CFrame * CFrame.new(0, math.sin(1.2) * 0.25, -0.3) * CFrame.Angles(0, math.rad(90), 0),
		})
		eyes(root, 0.25, -1.3, 0.2, 0.22, Color3.fromRGB(250, 250, 250))
		eyes(root, 0.25, -1.4, 0.2, 0.1)
	end,
	Butterfly = function(root)
		addPart(root, "Body", Vector3.new(0.25, 0.25, 1.3), CFrame.new(), Color3.fromRGB(40, 30, 50))
		ball(root, "Head", Vector3.new(0.35, 0.35, 0.35), CFrame.new(0, 0, -0.75), Color3.fromRGB(40, 30, 50))
		for _, x in { -1, 1 } do
			addPart(root, "UpperWing", Vector3.new(1.4, 0.05, 1.1), CFrame.new(x * 0.8, 0.15, -0.3) * CFrame.Angles(0, 0, math.rad(x * 20)), Color3.fromRGB(70, 150, 240))
			addPart(root, "WingSpot", Vector3.new(0.5, 0.07, 0.4), CFrame.new(x * 1.05, 0.25, -0.4) * CFrame.Angles(0, 0, math.rad(x * 20)), Color3.fromRGB(255, 210, 60))
			addPart(root, "LowerWing", Vector3.new(1, 0.05, 0.8), CFrame.new(x * 0.65, 0.1, 0.45) * CFrame.Angles(0, 0, math.rad(x * 20)), Color3.fromRGB(160, 90, 220))
			addPart(root, "Antenna", Vector3.new(0.05, 0.05, 0.6), CFrame.new(x * 0.12, 0.2, -1.05) * CFrame.Angles(math.rad(30), 0, 0), Color3.fromRGB(40, 30, 50))
		end
	end,
}

-- Fills `root` with the pet's parts. Unknown kinds get a simple ball.
function PetModels.build(root: BasePart, kind: string, color: Color3)
	local builder = builders[kind]
	if builder then
		builder(root)
	else
		ball(root, "Body", Vector3.new(1.6, 1.6, 1.6), CFrame.new(), color)
		eyes(root, 0.25, -0.7, 0.3, 0.3)
	end
end

return PetModels
