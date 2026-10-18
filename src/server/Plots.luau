-- Builds the homestead plots in a ring around the Central Plaza and gives
-- each player one. For now a plot is grass, a front garden of soil tiles
-- facing the plaza, and a name sign. House and back garden come later.

local Players = game:GetService("Players")

local Build = require(script.Parent.Build)
local MapLayout = require(script.Parent.MapLayout)

local PLOT_SIZE = MapLayout.PLOT_SIZE
local TILE_SIZE = 8
local TILE_COLUMNS = { -15, -5, 5, 15 }
-- Negative Z is toward the plaza, so the front garden sits on that side.
local TILE_ROWS = { -30, -20, -10 }

local Plots = {}

local plotsFolder: Folder
local ownerOf: { [Player]: Model } = {}

local function buildPlot(index: number, origin: CFrame): Model
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index

	local ground = Build.part({
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
