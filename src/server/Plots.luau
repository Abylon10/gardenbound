-- Builds the homestead plots on the ring of player islands around the
-- Central Plaza and gives each player one. Each plot has:
--   FrontGarden  soil tiles facing the plaza (Tile13-16 need house level 2)
--   TreeSpots    back-garden tree spots (Spot5-6 need house level 3)
--   BuildSpots   one pad per decoration blueprint, next to the house
--   HouseUpgrade invisible part by the door with the upgrade prompt
--   House        rebuilt by Homestead when the level changes
--   Decor        fences, signs, and trees
-- Parts that need a higher house level carry a "RequiredLevel" attribute;
-- Homestead locks and unlocks them.

local Players = game:GetService("Players")

local Blueprints = require(game:GetService("ReplicatedStorage").Shared.Blueprints)
local Build = require(script.Parent.Build)
local HomeBuilder = require(script.Parent.HomeBuilder)
local MapLayout = require(script.Parent.MapLayout)

local PLOT_SIZE = MapLayout.PLOT_SIZE
local TILE_SIZE = 8
local TILE_COLUMNS = { -15, -5, 5, 15 }
-- Negative Z is toward the plaza, so the front garden sits on that side.
local TILE_ROWS = { -30, -20, -10 }
-- Extra row unlocked by house level 2; named Tile13-16 so saved tiles keep
-- their names.
local EXTRA_TILE_ROW = -40
local TREE_SPOTS = {
	{ position = Vector3.new(14, 0, 16), level = 1 },
	{ position = Vector3.new(32, 0, 16), level = 1 },
	{ position = Vector3.new(14, 0, 32), level = 1 },
	{ position = Vector3.new(32, 0, 32), level = 1 },
	{ position = Vector3.new(23, 0, 16), level = 3 },
	{ position = Vector3.new(23, 0, 32), level = 3 },
}
local GROUND_TOP = MapLayout.GROUND_TOP

local FRONT_GARDEN_COLOR = Color3.fromRGB(245, 200, 60)
local BACK_GARDEN_COLOR = Color3.fromRGB(90, 190, 90)
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

local function buildDecor(plot: Model, origin: CFrame)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = plot

	-- Front garden fence, open toward the plaza and toward the house.
	buildFencedArea(decor, origin, -22, -47, 22, -3, { front = true, back = true }, 10)
	Build.signPost(decor, (origin * CFrame.new(-26, GROUND_TOP, -48)).Position, "Front Garden", FRONT_GARDEN_COLOR)

	-- Back garden: fenced, open toward the spawn point.
	buildFencedArea(decor, origin, 6, 8, 40, 40, { left = true }, 8)
	Build.signPost(decor, (origin * CFrame.new(43, GROUND_TOP, 6)).Position, "Back Garden", BACK_GARDEN_COLOR)

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
	local function addTile(x: number, z: number, level: number)
		tileIndex += 1
		local tile = Build.part({
			Name = "Tile" .. tileIndex,
			Size = Vector3.new(TILE_SIZE, 1, TILE_SIZE),
			CFrame = origin * CFrame.new(x, 1.5, z),
			Color = Color3.fromRGB(110, 72, 44),
			Material = Enum.Material.Ground,
		})
		tile:SetAttribute("RequiredLevel", level)
		Build.prompt(tile, "Plant", "Soil")
		tile.Parent = garden
	end
	for _, z in TILE_ROWS do
		for _, x in TILE_COLUMNS do
			addTile(x, z, 1)
		end
	end
	for _, x in TILE_COLUMNS do
		addTile(x, EXTRA_TILE_ROW, 2)
	end

	local treeSpots = Instance.new("Folder")
	treeSpots.Name = "TreeSpots"
	treeSpots.Parent = plot
	for i, spot in TREE_SPOTS do
		local part = Build.part({
			Name = "Spot" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 5, 5),
			CFrame = origin * CFrame.new(spot.position.X, GROUND_TOP + 0.2, spot.position.Z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(100, 68, 42),
			Material = Enum.Material.Ground,
			CanCollide = false,
		})
		part:SetAttribute("RequiredLevel", spot.level)
		Build.prompt(part, "Plant tree", "Empty spot")
		part.Parent = treeSpots
	end

	local buildSpots = Instance.new("Folder")
	buildSpots.Name = "BuildSpots"
	buildSpots.Parent = plot
	for decorId, offset in HomeBuilder.DECOR_SPOTS do
		local blueprint = Blueprints[decorId]
		local pad = Build.part({
			Name = decorId,
			Size = Vector3.new(6, 0.2, 6),
			CFrame = origin * offset * CFrame.new(0, GROUND_TOP + 0.1, 0),
			Color = Color3.fromRGB(245, 200, 60),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.6,
			CanCollide = false,
		})
		Build.prompt(pad, "Build", if blueprint then blueprint.displayName else decorId)
		pad.Parent = buildSpots
	end

	local roofIndex = (index - 1) % #ROOF_COLORS + 1
	plot:SetAttribute("RoofIndex", roofIndex)
	HomeBuilder.buildHouse(plot, origin, 1, ROOF_COLORS[roofIndex])

	-- Cauldron behind the spawn point, between the house and back garden.
	local cauldron = Instance.new("Model")
	cauldron.Name = "Cauldron"
	local potCFrame = origin * CFrame.new(-2, GROUND_TOP + 1.6, 30)
	local pot = Build.part({
		Name = "Pot",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3.2, 4.5, 4.5),
		CFrame = potCFrame * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal,
	})
	pot.Parent = cauldron
	Build.part({
		Name = "Brew",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 3.8, 3.8),
		CFrame = potCFrame * CFrame.new(0, 1.55, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(110, 220, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}).Parent = cauldron
	local brewPrompt = Build.prompt(pot, "Brew potions", "Cauldron")
	brewPrompt.Name = "OpenBrewing"
	cauldron.Parent = plot

	local upgrade = Build.part({
		Name = "HouseUpgrade",
		Size = Vector3.new(4, 6, 1),
		CFrame = origin * HomeBuilder.HOUSE_OFFSET * CFrame.new(0, GROUND_TOP + 3, -13),
		Transparency = 1,
		CanCollide = false,
	})
	Build.prompt(upgrade, "Upgrade house", "House")
	upgrade.Parent = plot

	buildDecor(plot, origin)

	local signAnchor = Build.part({
		Name = "SignAnchor",
		Size = Vector3.new(1, 1, 1),
		CFrame = origin * CFrame.new(0, 8, -54),
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

local releaseCallbacks: { (Model) -> () } = {}

-- Register a function called with the plot right before its owner leaves,
-- so systems (Farming, Forestry, Homestead) can reset it.
function Plots.onRelease(callback: (plot: Model) -> ())
	table.insert(releaseCallbacks, callback)
end

function Plots.roofColor(plot: Model): Color3
	local index = plot:GetAttribute("RoofIndex")
	return ROOF_COLORS[if type(index) == "number" then index else 1]
end

-- The plot's origin: on the ground plane, front (-Z) facing the plaza.
function Plots.origin(plot: Model): CFrame
	return ((plot :: any).Ground :: BasePart).CFrame * CFrame.new(0, -0.5, 0)
end

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
		for _, callback in releaseCallbacks do
			callback(plot)
		end
		setOwner(plot, nil)
		ownerOf[player] = nil
	end)
end

return Plots
