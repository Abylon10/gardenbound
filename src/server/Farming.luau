-- Planting, growing, and harvesting on each player's front garden.
-- Driven by the soil-tile ProximityPrompts built in Plots, so the client
-- only needs one remote: choosing which seed to plant. Buying and selling
-- happen at the plaza shops (see Plaza).
--
-- Growth is based on real time: each planted tile is saved in PlayerData
-- (garden[tileName] = { crop, plantedAt }), so crops keep growing while
-- the player is away and are restored when they rejoin.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Remotes = require(script.Parent.Remotes)

local MIN_CROP_SIZE = 1
local MAX_CROP_SIZE = 5
local SPROUT_COLOR = Color3.fromRGB(90, 200, 90)

local Farming = {}

-- Systems that change growth speed (pets, potions) set this. Returns a
-- multiplier on grow time; 1 means normal speed.
Farming.growthMultiplier = function(_player: Player): number
	return 1
end
-- Systems that can give extra crops on harvest (pets) set this.
Farming.harvestAmount = function(_player: Player, _cropName: string): number
	return 1
end

local nextPlantId = 0

local function getPrompt(tile: BasePart): ProximityPrompt
	return tile:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
end

local function clearTile(tile: BasePart)
	local cropPart = tile:FindFirstChild("Crop")
	if cropPart then
		cropPart:Destroy()
	end
	tile:SetAttribute("Crop", nil)
	tile:SetAttribute("PlantId", nil)
	tile:SetAttribute("Ready", nil)
	local prompt = getPrompt(tile)
	prompt.ActionText = "Plant"
	prompt.ObjectText = "Soil"
end

local function setCropSize(tile: BasePart, cropPart: BasePart, progress: number)
	local size = MIN_CROP_SIZE + (MAX_CROP_SIZE - MIN_CROP_SIZE) * progress
	cropPart.Size = Vector3.new(size, size, size)
	cropPart.CFrame = tile.CFrame * CFrame.new(0, tile.Size.Y / 2 + size / 2, 0)
end

-- Shows a crop on the tile and grows it until ready. plantedAt is os.time().
local function startGrowing(owner: Player, tile: BasePart, cropName: string, plantedAt: number)
	local crop = Crops[cropName]
	nextPlantId += 1
	local plantId = nextPlantId
	tile:SetAttribute("Crop", cropName)
	tile:SetAttribute("PlantId", plantId)
	tile:SetAttribute("Ready", nil)

	local cropPart = Instance.new("Part")
	cropPart.Name = "Crop"
	cropPart.Shape = Enum.PartType.Ball
	cropPart.Anchored = true
	cropPart.CanCollide = false
	cropPart.Color = SPROUT_COLOR
	cropPart.Material = Enum.Material.SmoothPlastic
	setCropSize(tile, cropPart, 0)
	cropPart.Parent = tile

	local prompt = getPrompt(tile)
	prompt.ActionText = "Growing..."
	prompt.ObjectText = crop.displayName

	-- Stop if the tile was cleared or replanted meanwhile.
	task.spawn(function()
		while tile:GetAttribute("PlantId") == plantId do
			local growTime = crop.growTime * Farming.growthMultiplier(owner)
			local progress = math.clamp((os.time() - plantedAt) / growTime, 0, 1)
			setCropSize(tile, cropPart, progress)
			if progress >= 1 then
				cropPart.Color = crop.color
				tile:SetAttribute("Ready", true)
				prompt.ActionText = "Harvest"
				return
			end
			prompt.ActionText = `Growing... {math.ceil(growTime * (1 - progress))}s`
			task.wait(1)
		end
	end)
end

local function plant(player: Player, tile: BasePart)
	local cropName = player:GetAttribute("SelectedSeed")
	if type(cropName) ~= "string" or not Crops[cropName] then
		return
	end
	local data = PlayerData.get(player)
	if not data or not PlayerData.takeSeed(player, cropName) then
		return
	end
	local plantedAt = os.time()
	data.garden[tile.Name] = { crop = cropName, plantedAt = plantedAt }
	startGrowing(player, tile, cropName, plantedAt)
end

local function harvest(player: Player, tile: BasePart)
	local cropName = tile:GetAttribute("Crop")
	local data = PlayerData.get(player)
	if type(cropName) ~= "string" or not data then
		return
	end
	data.garden[tile.Name] = nil
	PlayerData.addCrop(player, cropName, Farming.harvestAmount(player, cropName))
	clearTile(tile)
end

local function onTilePrompt(player: Player, tile: BasePart)
	if tile:GetAttribute("Locked") then
		return
	end
	if tile:GetAttribute("Ready") then
		harvest(player, tile)
	elseif not tile:GetAttribute("Crop") then
		plant(player, tile)
	end
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local plot = Plots.findPlot(prompt)
	if not plot or Plots.getOwner(plot) ~= player then
		return
	end
	if not PlayerData.isLoaded(player) then
		return
	end

	local parent = prompt.Parent
	if parent and parent.Parent and parent.Parent.Name == "FrontGarden" then
		onTilePrompt(player, parent :: BasePart)
	end
end

-- How many crops are planted and not yet ready.
function Farming.growingCount(player: Player): number
	local plot = Plots.getPlot(player)
	local data = PlayerData.get(player)
	if not plot or not data then
		return 0
	end
	local count = 0
	for tileName in data.garden do
		local tile = (plot :: any).FrontGarden:FindFirstChild(tileName)
		if tile and not tile:GetAttribute("Ready") then
			count += 1
		end
	end
	return count
end

-- Finishes every crop growing in the player's front garden (Growth
-- Potion). Returns how many crops it finished.
function Farming.growAll(player: Player): number
	local plot = Plots.getPlot(player)
	local data = PlayerData.get(player)
	if not plot or not data then
		return 0
	end
	local count = 0
	for tileName, entry in data.garden do
		local tile = (plot :: any).FrontGarden:FindFirstChild(tileName) :: BasePart?
		local crop = Crops[entry.crop]
		if tile and crop and not tile:GetAttribute("Ready") then
			local old = tile:FindFirstChild("Crop")
			if old then
				old:Destroy()
			end
			entry.plantedAt = os.time() - math.ceil(crop.growTime * Farming.growthMultiplier(player)) - 1
			startGrowing(player, tile, entry.crop, entry.plantedAt)
			count += 1
		end
	end
	return count
end

-- Puts the player's saved crops back on their plot once both are ready.
local function restoreGarden(player: Player)
	if not PlayerData.waitForLoad(player) then
		return
	end
	local deadline = os.clock() + 10
	while not Plots.getPlot(player) and player.Parent == Players and os.clock() < deadline do
		task.wait(0.1)
	end
	local plot = Plots.getPlot(player)
	local data = PlayerData.get(player)
	if not plot or not data then
		return
	end
	local garden = (plot :: any).FrontGarden :: Folder
	for tileName, entry in data.garden do
		local tile = garden:FindFirstChild(tileName) :: BasePart?
		if tile and Crops[entry.crop] then
			startGrowing(player, tile, entry.crop, entry.plantedAt)
		else
			data.garden[tileName] = nil
		end
	end
end

function Farming.start()
	local selectSeed = Remotes.event("SelectSeed")

	-- Selects a crop seed for the front garden or a sapling for the back.
	selectSeed.OnServerEvent:Connect(function(player, id)
		if type(id) ~= "string" then
			return
		end
		if Crops[id] then
			player:SetAttribute("SelectedSeed", id)
		elseif Items[id] and Items[id].kind == "sapling" then
			player:SetAttribute("SelectedSapling", id)
		end
	end)

	local function onPlayerAdded(player: Player)
		if player:GetAttribute("SelectedSeed") == nil then
			player:SetAttribute("SelectedSeed", "Carrot")
		end
		restoreGarden(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

	Plots.onRelease(function(plot)
		for _, tile in (plot :: any).FrontGarden:GetChildren() do
			clearTile(tile)
		end
	end)
end

return Farming
