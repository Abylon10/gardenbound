-- Small helpers for building anchored parts, prompts, signs, and simple
-- props (trees, lamps, fences) from code. Shared by the map modules.

local Build = {}

function Build.part(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

function Build.prompt(parent: Instance, actionText: string, objectText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- Adds a BillboardGui named "Sign" to parent, with a "Title" label and an
-- optional smaller "Subtitle" label underneath.
function Build.sign(parent: BasePart, title: string, subtitle: string?, offsetY: number): BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Sign"
	billboard.Size = UDim2.fromOffset(300, if subtitle then 80 else 50)
	billboard.StudsOffset = Vector3.new(0, offsetY, 0)
	billboard.MaxDistance = 200
	billboard.Parent = parent

	local function addLabel(name: string, text: string, y: number, height: number)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Position = UDim2.fromScale(0, y)
		label.Size = UDim2.fromScale(1, height)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		label.Text = text
		label.Parent = billboard
	end

	if subtitle then
		addLabel("Title", title, 0, 0.6)
		addLabel("Subtitle", subtitle, 0.6, 0.4)
	else
		addLabel("Title", title, 0, 1)
	end
	return billboard
end

local WOOD = Color3.fromRGB(150, 105, 65)
local TRUNK = Color3.fromRGB(110, 75, 45)
local LEAVES = Color3.fromRGB(70, 150, 60)

-- A round-canopy tree standing on the ground at position.
function Build.tree(parent: Instance, position: Vector3, scale: number?, leafColor: Color3?): Model
	local s = scale or 1
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	local trunkHeight = 10 * s
	Build.part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(trunkHeight, 2 * s, 2 * s),
		CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = TRUNK,
		Material = Enum.Material.Wood,
	}).Parent = tree
	local leaves = {
		{ Vector3.new(0, trunkHeight + 2 * s, 0), 10 },
		{ Vector3.new(3 * s, trunkHeight - 1 * s, 1 * s), 7 },
		{ Vector3.new(-2.5 * s, trunkHeight - 0.5 * s, -2 * s), 7 },
	}
	for _, leaf in leaves do
		local size = leaf[2] * s
		Build.part({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			CFrame = CFrame.new(position + leaf[1]),
			Color = leafColor or LEAVES,
			Material = Enum.Material.Grass,
			CanCollide = false,
		}).Parent = tree
	end
	tree.Parent = parent
	return tree
end

-- A cone-shaped pine tree standing on the ground at position.
function Build.pineTree(parent: Instance, position: Vector3, scale: number?): Model
	local s = scale or 1
	local tree = Instance.new("Model")
	tree.Name = "PineTree"
	Build.part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(5 * s, 1.6 * s, 1.6 * s),
		CFrame = CFrame.new(position + Vector3.new(0, 2.5 * s, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = TRUNK,
		Material = Enum.Material.Wood,
	}).Parent = tree
	-- Stacked, shrinking layers of needles.
	for i = 0, 3 do
		local width = (9 - i * 2) * s
		Build.part({
			Name = "Needles",
			Size = Vector3.new(width, 3 * s, width),
			CFrame = CFrame.new(position + Vector3.new(0, (4.5 + i * 2.6) * s, 0)) * CFrame.Angles(0, math.rad(45 * i), 0),
			Color = Color3.fromRGB(40, 110, 60),
			Material = Enum.Material.Grass,
			CanCollide = false,
		}).Parent = tree
	end
	tree.Parent = parent
	return tree
end

-- A pole with a hanging cloth banner and a gold stripe, standing on the
-- ground at position, the banner facing `facing` (a direction).
function Build.banner(parent: Instance, position: Vector3, facing: Vector3, color: Color3): Model
	local banner = Instance.new("Model")
	banner.Name = "Banner"
	local flat = Vector3.new(facing.X, 0, facing.Z)
	local frame = CFrame.lookAt(position, position + (if flat.Magnitude > 0 then flat.Unit else Vector3.new(0, 0, -1)))
	Build.part({
		Name = "Pole",
		Size = Vector3.new(0.6, 14, 0.6),
		CFrame = frame * CFrame.new(0, 7, 0),
		Color = Color3.fromRGB(60, 45, 35),
		Material = Enum.Material.Wood,
	}).Parent = banner
	Build.part({
		Name = "Crossbar",
		Size = Vector3.new(3.6, 0.3, 0.3),
		CFrame = frame * CFrame.new(0, 13.3, -0.4),
		Color = Color3.fromRGB(200, 170, 70),
		Material = Enum.Material.Metal,
	}).Parent = banner
	Build.part({
		Name = "Cloth",
		Size = Vector3.new(3.2, 6, 0.15),
		CFrame = frame * CFrame.new(0, 10, -0.5),
		Color = color,
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}).Parent = banner
	Build.part({
		Name = "Stripe",
		Size = Vector3.new(3.2, 0.4, 0.2),
		CFrame = frame * CFrame.new(0, 8, -0.5),
		Color = Color3.fromRGB(230, 190, 70),
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}).Parent = banner
	banner.Parent = parent
	return banner
end

-- Stairs down an island cliff to a wooden dock at the water. The landing
-- starts on the grass at `bearing` (degrees) from the island center and
-- the stairs run along the outside of the cliff (`side` picks which way).
function Build.dock(
	parent: Instance,
	name: string,
	center: Vector3,
	islandRadius: number,
	bearing: number,
	side: number,
	groundTop: number,
	waterLevel: number
): Model
	local dock = Instance.new("Model")
	dock.Name = name
	local radians = math.rad(bearing)
	local out = Vector3.new(math.sin(radians), 0, -math.cos(radians))
	local along = Vector3.new(-out.Z, 0, out.X) * side
	local base = Vector3.new(center.X, 0, center.Z)
	-- The cliff rock reaches islandRadius + 5; stairs run just outside it.
	local stairLine = islandRadius + 9
	local width = 8
	local deckTop = waterLevel + 1.5
	local stone = Color3.fromRGB(150, 140, 125)

	local function block(partName: string, size: Vector3, position: Vector3, forward: Vector3, color: Color3, material: Enum.Material)
		Build.part({
			Name = partName,
			Size = size,
			CFrame = CFrame.lookAt(position, position + forward),
			Color = color,
			Material = material,
		}).Parent = dock
	end

	-- Landing from the grass out over the cliff edge.
	local landingStart = islandRadius - 4
	local landingEnd = stairLine + width / 2
	local landingLength = landingEnd - landingStart
	block(
		"Landing",
		Vector3.new(width, 1, landingLength),
		base + out * (landingStart + landingLength / 2) + Vector3.new(0, groundTop - 0.5, 0),
		out,
		stone,
		Enum.Material.Cobblestone
	)

	-- Solid steps down to the dock.
	local height = groundTop - deckTop
	local steps = math.ceil(height)
	local rise = height / steps
	local run = 1.6
	for i = 1, steps do
		local top = groundTop - i * rise
		local bottom = deckTop - 3
		local offset = width / 2 + (i - 0.5) * run
		block(
			"Step",
			Vector3.new(width, top - bottom, run + 0.1),
			base + out * stairLine + along * offset + Vector3.new(0, (top + bottom) / 2, 0),
			along,
			stone,
			Enum.Material.Cobblestone
		)
	end

	-- Wooden dock at the bottom, and a pier out over the water.
	local stairEnd = width / 2 + steps * run
	local wood = Color3.fromRGB(140, 95, 60)
	block(
		"Deck",
		Vector3.new(width + 4, 1, 12),
		base + out * stairLine + along * (stairEnd + 6) + Vector3.new(0, deckTop - 0.5, 0),
		along,
		wood,
		Enum.Material.WoodPlanks
	)
	local pierStart = base + out * (stairLine + width / 2 + 2) + along * (stairEnd + 6)
	block("Pier", Vector3.new(6, 1, 18), pierStart + out * 9 + Vector3.new(0, deckTop - 0.5, 0), out, wood, Enum.Material.WoodPlanks)
	for _, distance in { 4, 10, 16 } do
		for _, sideOffset in { -2.7, 2.7 } do
			local post = pierStart + out * distance + along * sideOffset
			block(
				"Post",
				Vector3.new(0.8, 6, 0.8),
				post + Vector3.new(0, deckTop - 2.5, 0),
				out,
				Color3.fromRGB(100, 70, 45),
				Enum.Material.Wood
			)
		end
	end

	dock.Parent = parent
	return dock
end

-- A lamp post standing on the ground at position, with a warm light.
function Build.lamp(parent: Instance, position: Vector3): Model
	local lamp = Instance.new("Model")
	lamp.Name = "Lamp"
	Build.part({
		Name = "Post",
		Size = Vector3.new(0.8, 12, 0.8),
		CFrame = CFrame.new(position + Vector3.new(0, 6, 0)),
		Color = Color3.fromRGB(50, 50, 55),
		Material = Enum.Material.Metal,
	}).Parent = lamp
	local lantern = Build.part({
		Name = "Lantern",
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(position + Vector3.new(0, 13, 0)),
		Color = Color3.fromRGB(255, 210, 130),
		Material = Enum.Material.Neon,
	})
	local light = Instance.new("PointLight")
	light.Range = 24
	light.Brightness = 1.5
	light.Color = Color3.fromRGB(255, 200, 140)
	light.Parent = lantern
	lantern.Parent = lamp
	lamp.Parent = parent
	return lamp
end

-- A wooden fence between two points given in origin's local space (Y is
-- ignored; the fence stands on groundTop).
function Build.fence(parent: Instance, origin: CFrame, from: Vector3, to: Vector3, groundTop: number)
	local a = Vector3.new(from.X, 0, from.Z)
	local b = Vector3.new(to.X, 0, to.Z)
	local delta = b - a
	local length = delta.Magnitude
	local frame = origin * CFrame.lookAt((a + b) / 2, b)
	for _, height in { 1.5, 3 } do
		Build.part({
			Name = "Rail",
			Size = Vector3.new(0.4, 0.4, length),
			CFrame = frame + Vector3.new(0, groundTop + height, 0),
			Color = WOOD,
			Material = Enum.Material.Wood,
		}).Parent = parent
	end
	local posts = math.max(1, math.floor(length / 6))
	for i = 0, posts do
		local point = origin * (a + delta * (i / posts))
		Build.part({
			Name = "Post",
			Size = Vector3.new(0.8, 4, 0.8),
			CFrame = CFrame.new(point + Vector3.new(0, groundTop + 2, 0)),
			Color = WOOD,
			Material = Enum.Material.Wood,
		}).Parent = parent
	end
end

-- A wooden bridge with railings from one point to another (Y ignored;
-- the deck top sits at deckTop).
function Build.bridge(parent: Instance, name: string, from: Vector3, to: Vector3, deckTop: number): Model
	local bridge = Instance.new("Model")
	bridge.Name = name
	local a = Vector3.new(from.X, 0, from.Z)
	local b = Vector3.new(to.X, 0, to.Z)
	local length = (b - a).Magnitude
	local frame = CFrame.lookAt((a + b) / 2, b)
	local width = 10

	Build.part({
		Name = "Deck",
		Size = Vector3.new(width, 1, length),
		CFrame = frame * CFrame.new(0, deckTop - 0.5, 0),
		Color = WOOD,
		Material = Enum.Material.WoodPlanks,
	}).Parent = bridge

	for _, x in { -width / 2 + 0.3, width / 2 - 0.3 } do
		Build.part({
			Name = "Rail",
			Size = Vector3.new(0.5, 0.5, length),
			CFrame = frame * CFrame.new(x, deckTop + 3, 0),
			Color = WOOD,
			Material = Enum.Material.Wood,
		}).Parent = bridge
		local posts = math.max(1, math.floor(length / 8))
		for i = 0, posts do
			local z = -length / 2 + length * (i / posts)
			Build.part({
				Name = "Post",
				Size = Vector3.new(0.8, 4, 0.8),
				CFrame = frame * CFrame.new(x, deckTop + 1.5, z),
				Color = WOOD,
				Material = Enum.Material.Wood,
			}).Parent = bridge
		end
	end

	bridge.Parent = parent
	return bridge
end

-- A small wooden sign post with a colored board and a floating label.
function Build.signPost(parent: Instance, position: Vector3, text: string, color: Color3)
	local post = Build.part({
		Name = "SignPost",
		Size = Vector3.new(0.6, 5, 0.6),
		CFrame = CFrame.new(position + Vector3.new(0, 2.5, 0)),
		Color = WOOD,
		Material = Enum.Material.Wood,
	})
	post.Parent = parent
	local board = Build.part({
		Name = "SignBoard",
		Size = Vector3.new(4, 1.6, 0.4),
		CFrame = CFrame.new(position + Vector3.new(0, 5, 0)),
		Color = color,
		Material = Enum.Material.SmoothPlastic,
	})
	board.Parent = parent
	local sign = Build.sign(board, text, nil, 2.5)
	sign.Size = UDim2.fromOffset(200, 36)
	sign.MaxDistance = 80
end

return Build
