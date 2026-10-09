-- Builds the homestead plots at runtime and gives each player one.
-- For now a plot is grass, a front garden of soil tiles, a seed shop,
-- a sell stand, and a name sign. House and back garden come later.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)

local PLOT_COUNT = 6
local PLOT_SPACING = 110
local PLOT_SIZE = 90
local PLOT_ROW_Z = 150
local TILE_SIZE = 8
local TILE_COLUMNS = { -15, -5, 5, 15 }
local TILE_ROWS = { 10, 20, 30 }

local Plots = {}

local plotsFolder: Folder
local ownerOf: { [Player]: Model } = {}

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local function makePrompt(parent: Instance, actionText: string, objectText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local function buildPlot(index: number, origin: CFrame): Model
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index

	local ground = makePart({
		Name = "Ground",
		Size = Vector3.new(PLOT_SIZE, 1, PLOT_SIZE),
		CFrame = origin * CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(106, 170, 72),
		Material = Enum.Material.Grass,
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
			local tile = makePart({
				Name = "Tile" .. tileIndex,
				Size = Vector3.new(TILE_SIZE, 1, TILE_SIZE),
				CFrame = origin * CFrame.new(x, 1.5, z),
				Color = Color3.fromRGB(110, 72, 44),
				Material = Enum.Material.Ground,
			})
			makePrompt(tile, "Plant", "Soil")
			tile.Parent = garden
		end
	end

	-- One seed crate per crop, side by side, each with a single prompt.
	local shop = Instance.new("Folder")
	shop.Name = "SeedShop"
	local sortedCrops = {}
	for cropName in Crops do
		table.insert(sortedCrops, cropName)
	end
	table.sort(sortedCrops, function(a, b)
		return Crops[a].order < Crops[b].order
	end)
	for i, cropName in sortedCrops do
		local crop = Crops[cropName]
		local crate = makePart({
			Name = "Buy_" .. cropName,
			Size = Vector3.new(4, 4, 4),
			CFrame = origin * CFrame.new(-40 + (i - 1) * 6, 3, 38),
			Color = crop.color,
			Material = Enum.Material.WoodPlanks,
		})
		makePrompt(crate, `Buy seed ({crop.seedPrice} coins)`, crop.displayName)
		crate.Parent = shop
	end
	shop.Parent = plot

	local sellStand = makePart({
		Name = "SellStand",
		Size = Vector3.new(6, 6, 4),
		CFrame = origin * CFrame.new(32, 4, 38),
		Color = Color3.fromRGB(180, 130, 70),
		Material = Enum.Material.Wood,
	})
	makePrompt(sellStand, "Sell all crops", "Sell Stand").Name = "Sell"
	sellStand.Parent = plot

	local signAnchor = makePart({
		Name = "Sign",
		Size = Vector3.new(1, 1, 1),
		CFrame = origin * CFrame.new(0, 12, 44),
		Transparency = 1,
		CanCollide = false,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(300, 50)
	billboard.MaxDistance = 150
	billboard.Parent = signAnchor
	local label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = "Empty plot"
	label.Parent = billboard
	signAnchor.Parent = plot

	local spawnPoint = makePart({
		Name = "SpawnPoint",
		Size = Vector3.new(1, 1, 1),
		CFrame = origin * CFrame.new(0, 4, 0),
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
	local label = (plot :: any).Sign.BillboardGui.OwnerLabel :: TextLabel
	label.Text = if player then `{player.DisplayName}'s Homestead` else "Empty plot"
end

local function teleportHome(player: Player, character: Model)
	local plot = ownerOf[player]
	if not plot then
		return
	end
	if not character:WaitForChild("HumanoidRootPart", 5) then
		return
	end
	-- Wait a frame so the default spawn placement doesn't override this.
	task.wait()
	character:PivotTo(((plot :: any).SpawnPoint :: BasePart).CFrame)
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
		return
	end

	player.CharacterAdded:Connect(function(character)
		teleportHome(player, character)
	end)
	if player.Character then
		teleportHome(player, player.Character)
	end
end

-- Called with the plot right before its owner leaves, so other systems
-- (e.g. Farming) can clear it.
Plots.onPlotReleased = nil :: ((plot: Model) -> ())?

function Plots.getPlot(player: Player): Model?
	return ownerOf[player]
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

	for i = 1, PLOT_COUNT do
		local x = (i - (PLOT_COUNT + 1) / 2) * PLOT_SPACING
		buildPlot(i, CFrame.new(x, 0, PLOT_ROW_Z))
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
