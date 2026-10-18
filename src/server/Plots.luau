-- Builds the homestead plots on the ring of player islands around the
-- Central Plaza and gives each player one. Each plot has a fenced front
-- garden of soil tiles facing the plaza, a house, a fenced back garden
-- (decoration until trees are added), trees, and a name sign.

local Players = game:GetService("Players")

local Build = require(script.Parent.Build)
local MapLayout = require(script.Parent.MapLayout)

local PLOT_SIZE = MapLayout.PLOT_SIZE
local TILE_SIZE = 8
local TILE_COLUMNS = { -15, -5, 5, 15 }
-- Negative Z is toward the plaza, so the front garden sits on that side.
local TILE_ROWS = { -30, -20, -10 }
local GROUND_TOP = MapLayout.GROUND_TOP

local FRONT_GARDEN_COLOR = Color3.fromRGB(245, 200, 60)
local BACK_GARDEN_COLOR = Color3.fromRGB(90, 190, 90)
local WALL_COLOR = Color3.fromRGB(235, 215, 180)
local ROOF_COLORS = {
	Color3.fromRGB(215, 90, 120),
	Color3.fromRGB(60, 150, 160),
	Color3.fromRGB(120, 80, 180),
	Color3.fromRGB(70, 110, 200),
	Color3.fromRGB(90, 160, 80),
	Color3.fromRGB(200, 80, 60),
}

local Plots = {}

local plotsFolder: Folder
local ownerOf: { [Player]: Model } = {}

-- A closed house with a peaked roof. The roof is a block turned 45 degrees,
-- so its lower half hides inside the walls.
local function buildHouse(parent: Instance, origin: CFrame, roofColor: Color3)
	local house = Instance.new("Model")
	house.Name = "House"
	local width, depth, height = 22, 18, 12

	Build.part({
		Name = "Walls",
		Size = Vector3.new(width, height, depth),
		CFrame = origin * CFrame.new(0, GROUND_TOP + height / 2, 0),
		Color = WALL_COLOR,
		Material = Enum.Material.WoodPlanks,
	}).Parent = house

	local roofSide = (depth + 3) / math.sqrt(2)
	Build.part({
		Name = "Roof",
		Size = Vector3.new(width + 2, roofSide, roofSide),
		CFrame = origin * CFrame.new(0, GROUND_TOP + height, 0) * CFrame.Angles(math.rad(45), 0, 0),
		Color = roofColor,
		Material = Enum.Material.Slate,
	}).Parent = house

	-- Front faces -Z (toward the garden and the plaza).
	local front = -depth / 2 - 0.1
	Build.part({
		Name = "Door",
		Size = Vector3.new(4, 7, 0.4),
		CFrame = origin * CFrame.new(0, GROUND_TOP + 3.5, front),
		Color = Color3.fromRGB(120, 75, 40),
		Material = Enum.Material.Wood,
	}).Parent = house
	for _, x in { -6.5, 6.5 } do
		Build.part({
			Name = "Window",
			Size = Vector3.new(3.5, 3, 0.4),
			CFrame = origin * CFrame.new(x, GROUND_TOP + 7, front),
			Color = Color3.fromRGB(150, 200, 230),
			Material = Enum.Material.Glass,
			Transparency = 0.2,
		}).Parent = house
	end

	house.Parent = parent
end

-- Rectangle of fence from (x1, z1) to (x2, z2) in plot space, with a gap
-- of gapWidth centered on each side listed in gaps ("front" is -Z,
-- "back" is +Z, "left" is -X, "right" is +X).
local function buildFencedArea(parent: Instance, origin: CFrame, x1: number, z1: number, x2: number, z2: number, gaps: { [string]: boolean }, gapWidth: number)
	local function side(name: string, from: Vector3, to: Vector3)
		if not gaps[name] then
			Build.fence(parent, origin, from, to, GROUND_TOP)
			return
		end
		local middle = (from + to) / 2
		local direction = (to - from).Unit
		Build.fence(parent, origin, from, middle - direction * (gapWidth / 2), GROUND_TOP)
		Build.fence(parent, origin, middle + direction * (gapWidth / 2), to, GROUND_TOP)
	end
	side("front", Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z1))
	side("right", Vector3.new(x2, 0, z1), Vector3.new(x2, 0, z2))
	side("back", Vector3.new(x2, 0, z2), Vector3.new(x1, 0, z2))
	side("left", Vector3.new(x1, 0, z2), Vector3.new(x1, 0, z1))
end

local function buildDecor(plot: Model, index: number, origin: CFrame)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = plot

	-- Front garden fence, open toward the plaza and toward the house.
	buildFencedArea(decor, origin, -22, -37, 22, -3, { front = true, back = true }, 10)
	Build.signPost(decor, (origin * CFrame.new(-26, GROUND_TOP, -38)).Position, "Front Garden", FRONT_GARDEN_COLOR)

	buildHouse(decor, origin * CFrame.new(-20, 0, 26), ROOF_COLORS[(index - 1) % #ROOF_COLORS + 1])

	-- Back garden: fenced, open toward the spawn point, with saplings.
	buildFencedArea(decor, origin, 8, 8, 38, 40, { left = true }, 8)
	Build.signPost(decor, (origin * CFrame.new(41, GROUND_TOP, 6)).Position, "Back Garden", BACK_GARDEN_COLOR)
	for _, spot in { Vector3.new(16, 0, 16), Vector3.new(30, 0, 16), Vector3.new(16, 0, 32), Vector3.new(30, 0, 32) } do
		Build.tree(decor, (origin * CFrame.new(spot.X, GROUND_TOP, spot.Z)).Position, 0.35)
	end

	for _, spot in {
		Vector3.new(-42, 0, -25),
		Vector3.new(42, 0, -25),
		Vector3.new(-55, 0, 0),
		Vector3.new(55, 0, 0),
		Vector3.new(-45, 0, 48),
		Vector3.new(0, 0, 55),
		Vector3.new(42, 0, 47),
	} do
		Build.tree(decor, (origin * CFrame.new(spot.X, GROUND_TOP, spot.Z)).Position, 1)
	end
end

local function buildPlot(index: number, origin: CFrame): Model
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	-- Always sent to every client and never streamed out, so the ground and
	-- garden are there as soon as a player joins.
	plot.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local ground = Build.part({
		Name = "Ground",
		Size = Vector3.new(PLOT_SIZE, 1, PLOT_SIZE),
		CFrame = origin * CFrame.new(0, 0.5, 0),
		-- The island terrain is the visible ground. This invisible part sits
		-- exactly at grass level so there is always solid ground, even before
		-- the terrain has streamed in on the client.
		Transparency = 1,
	})
	ground.Parent = plot
	plot.PrimaryPart = ground

	local garden = Instance.new("Folder")
	garden.Name = "FrontGarden"
	garden.Parent = plot
	local tileIndex = 0
	for _, z in TILE_ROWS do
		for _, x in TILE_COLUMNS do
			tileIndex += 1
			local tile = Build.part({
				Name = "Tile" .. tileIndex,
				Size = Vector3.new(TILE_SIZE, 1, TILE_SIZE),
				CFrame = origin * CFrame.new(x, 1.5, z),
				Color = Color3.fromRGB(110, 72, 44),
				Material = Enum.Material.Ground,
			})
			Build.prompt(tile, "Plant", "Soil")
			tile.Parent = garden
		end
	end

	buildDecor(plot, index, origin)

	local signAnchor = Build.part({
		Name = "SignAnchor",
		Size = Vector3.new(1, 1, 1),
		CFrame = origin * CFrame.new(0, 8, -PLOT_SIZE / 2 + 2),
		Transparency = 1,
		CanCollide = false,
	})
	Build.sign(signAnchor, "Empty plot", nil, 4)
	signAnchor.Parent = plot

	local spawnPoint = Build.part({
		Name = "SpawnPoint",
		Size = Vector3.new(1, 1, 1),
		CFrame = origin * CFrame.new(0, 4, 15),
		Transparency = 1,
		CanCollide = false,
	})
	spawnPoint.Parent = plot

	plot:SetAttribute("OwnerId", 0)
	plot.Parent = plotsFolder
	return plot
end

local function setOwner(plot: Model, player: Player?)
	plot:SetAttribute("OwnerId", if player then player.UserId else 0)
	local label = (plot :: any).SignAnchor.Sign.Title :: TextLabel
	label.Text = if player then `{player.DisplayName}'s Homestead` else "Empty plot"
end

local function claimPlot(player: Player)
	for _, plot in plotsFolder:GetChildren() do
		if plot:GetAttribute("OwnerId") == 0 then
			ownerOf[player] = plot :: Model
			setOwner(plot :: Model, player)
			break
		end
	end
	if not ownerOf[player] then
		warn("[Plots] No free plot for", player.Name)
	end
end

-- Called with the plot right before its owner leaves, so other systems
-- (e.g. Farming) can clear it.
Plots.onPlotReleased = nil :: ((plot: Model) -> ())?

function Plots.getPlot(player: Player): Model?
	return ownerOf[player]
end

-- Where the player's character should stand when it spawns.
function Plots.getSpawnPoint(player: Player): BasePart?
	local plot = ownerOf[player]
	return if plot then (plot :: any).SpawnPoint :: BasePart else nil
end

function Plots.getOwner(plot: Instance): Player?
	local ownerId = plot:GetAttribute("OwnerId")
	if not ownerId or ownerId == 0 then
		return nil
	end
	return Players:GetPlayerByUserId(ownerId)
end

-- Returns the plot model that contains this instance, if any.
function Plots.findPlot(instance: Instance): Model?
	local current: Instance? = instance
	while current and current.Parent ~= plotsFolder do
		current = current.Parent
	end
	return current :: Model?
end

function Plots.start()
	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = workspace

	for i, angle in MapLayout.PLOT_ANGLES do
		buildPlot(i, MapLayout.facingCenter(angle, MapLayout.PLOT_RING_RADIUS))
	end

	Players.PlayerAdded:Connect(claimPlot)
	for _, player in Players:GetPlayers() do
		task.spawn(claimPlot, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local plot = ownerOf[player]
		if not plot then
			return
		end
		if Plots.onPlotReleased then
			Plots.onPlotReleased(plot)
		end
		setOwner(plot, nil)
		ownerOf[player] = nil
	end)
end

return Plots
