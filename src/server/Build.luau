-- Small helpers for building anchored parts, prompts, and floating signs
-- from code. Shared by Plots and Plaza.

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

return Build
