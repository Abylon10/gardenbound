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
function Build.tree(parent: Instance, position: Vector3, scale: number?): Model
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
			Color = LEAVES,
			Material = Enum.Material.Grass,
			CanCollide = false,
		}).Parent = tree
	end
	tree.Parent = parent
	return tree
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
