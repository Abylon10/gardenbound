-- Planting, growing, harvesting, buying seeds, and selling crops.
-- Everything is driven by ProximityPrompts built in Plots, so the client
-- only needs one remote: choosing which seed to plant.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)

local GROWTH_STAGES = 4
local MIN_CROP_SIZE = 1
local MAX_CROP_SIZE = 5

local Farming = {}

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

local function plant(player: Player, tile: BasePart)
	local cropName = player:GetAttribute("SelectedSeed")
	local crop = if type(cropName) == "string" then Crops[cropName] else nil
	if not crop then
		return
	end
	if not PlayerData.takeSeed(player, cropName) then
		return
	end

	nextPlantId += 1
	local plantId = nextPlantId
	tile:SetAttribute("Crop", cropName)
	tile:SetAttribute("PlantId", plantId)

	local cropPart = Instance.new("Part")
	cropPart.Name = "Crop"
	cropPart.Shape = Enum.PartType.Ball
	cropPart.Anchored = true
	cropPart.CanCollide = false
	cropPart.Color = Color3.fromRGB(90, 200, 90)
	cropPart.Material = Enum.Material.SmoothPlastic
	setCropSize(tile, cropPart, 0)
	cropPart.Parent = tile

	local prompt = getPrompt(tile)
	prompt.ActionText = "Growing..."
	prompt.ObjectText = crop.displayName

	-- Grow in stages; stop if the tile was cleared or replanted meanwhile.
	task.spawn(function()
		for stage = 1, GROWTH_STAGES do
			task.wait(crop.growTime / GROWTH_STAGES)
			if tile:GetAttribute("PlantId") ~= plantId then
				return
			end
			setCropSize(tile, cropPart, stage / GROWTH_STAGES)
		end
		cropPart.Color = crop.color
		tile:SetAttribute("Ready", true)
		prompt.ActionText = "Harvest"
	end)
end

local function harvest(player: Player, tile: BasePart)
	local cropName = tile:GetAttribute("Crop")
	if type(cropName) ~= "string" then
		return
	end
	PlayerData.addCrop(player, cropName, 1)
	clearTile(tile)
end

local function onTilePrompt(player: Player, tile: BasePart)
	if tile:GetAttribute("Ready") then
		harvest(player, tile)
	elseif not tile:GetAttribute("Crop") then
		plant(player, tile)
	end
end

local function onBuyPrompt(player: Player, crate: Instance)
	local cropName = string.match(crate.Name, "^Buy_(.+)$")
	local crop = if cropName then Crops[cropName] else nil
	if not crop then
		return
	end
	if PlayerData.spendCoins(player, crop.seedPrice) then
		PlayerData.addSeeds(player, cropName :: string, 1)
	end
end

local function onSellPrompt(player: Player)
	local sold = PlayerData.takeAllCrops(player)
	local total = 0
	for cropName, count in sold do
		local crop = Crops[cropName]
		if crop then
			total += crop.sellPrice * count
		end
	end
	if total > 0 then
		PlayerData.addCoins(player, total)
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
	if not parent then
		return
	end
	if parent.Parent and parent.Parent.Name == "FrontGarden" then
		onTilePrompt(player, parent :: BasePart)
	elseif parent.Parent and parent.Parent.Name == "SeedShop" then
		onBuyPrompt(player, parent)
	elseif parent.Name == "SellStand" then
		onSellPrompt(player)
	end
end

function Farming.start()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	local selectSeed = Instance.new("RemoteEvent")
	selectSeed.Name = "SelectSeed"
	selectSeed.Parent = remotes
	remotes.Parent = ReplicatedStorage

	selectSeed.OnServerEvent:Connect(function(player, cropName)
		if type(cropName) == "string" and Crops[cropName] then
			player:SetAttribute("SelectedSeed", cropName)
		end
	end)

	local function setDefaultSeed(player: Player)
		if player:GetAttribute("SelectedSeed") == nil then
			player:SetAttribute("SelectedSeed", "Carrot")
		end
	end
	Players.PlayerAdded:Connect(setDefaultSeed)
	for _, player in Players:GetPlayers() do
		setDefaultSeed(player)
	end

	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

	Plots.onPlotReleased = function(plot)
		for _, tile in (plot :: any).FrontGarden:GetChildren() do
			clearTile(tile)
		end
	end
end

return Farming
