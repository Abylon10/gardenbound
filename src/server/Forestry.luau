-- Back-garden trees. Plant the selected sapling on a tree spot, wait for
-- it to grow (real time, saved per spot like crops), then chop it for
-- wood (plus apples or coconuts from fruit trees). Spots locked by house
-- level are skipped.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Trees = require(ReplicatedStorage.Shared.Trees)
local Build = require(script.Parent.Build)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)

local MIN_SCALE = 0.15
local MAX_SCALE = 0.85
local STAGES = 10

local Forestry = {}

-- Bonuses (pets, potions) can change these.
Forestry.growthMultiplier = function(_player: Player): number
	return 1
end
Forestry.woodAmount = function(_player: Player, baseWood: number): number
	return baseWood
end

local nextPlantId = 0

local function getPrompt(spot: BasePart): ProximityPrompt
	return spot:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
end

local function groundPosition(spot: BasePart): Vector3
	-- The spot is a flat cylinder lying on the ground.
	return spot.Position - Vector3.new(0, spot.Size.X / 2, 0)
end

local function clearSpot(spot: BasePart)
	local tree = spot:FindFirstChild("Tree")
	if tree then
		tree:Destroy()
	end
	spot:SetAttribute("Tree", nil)
	spot:SetAttribute("PlantId", nil)
	spot:SetAttribute("Ready", nil)
	local prompt = getPrompt(spot)
	prompt.ActionText = "Plant tree"
	prompt.ObjectText = "Empty spot"
end

local function showTree(spot: BasePart, treeName: string, stage: number)
	local old = spot:FindFirstChild("Tree")
	if old then
		old:Destroy()
	end
	local tree = Trees.list[treeName]
	local scale = MIN_SCALE + (MAX_SCALE - MIN_SCALE) * (stage / STAGES)
	Build.tree(spot, groundPosition(spot), scale, tree.leafColor)
end

local function startGrowing(owner: Player, spot: BasePart, treeName: string, plantedAt: number)
	local tree = Trees.list[treeName]
	nextPlantId += 1
	local plantId = nextPlantId
	spot:SetAttribute("Tree", treeName)
	spot:SetAttribute("PlantId", plantId)
	spot:SetAttribute("Ready", nil)

	local prompt = getPrompt(spot)
	prompt.ObjectText = tree.displayName

	task.spawn(function()
		local shownStage = -1
		while spot:GetAttribute("PlantId") == plantId do
			local growTime = tree.growTime * Forestry.growthMultiplier(owner)
			local progress = math.clamp((os.time() - plantedAt) / growTime, 0, 1)
			local stage = math.floor(progress * STAGES)
			if stage ~= shownStage then
				shownStage = stage
				showTree(spot, treeName, stage)
			end
			if progress >= 1 then
				spot:SetAttribute("Ready", true)
				prompt.ActionText = "Chop"
				prompt.HoldDuration = 1
				return
			end
			prompt.ActionText = `Growing... {math.ceil(growTime * (1 - progress))}s`
			task.wait(1)
		end
	end)
end

-- The sapling to plant: the selected one if the player has it, otherwise
-- the first sapling they own.
local function chooseSapling(player: Player): string?
	local selected = player:GetAttribute("SelectedSapling")
	if type(selected) == "string" and PlayerData.getItem(player, selected) > 0 then
		return selected
	end
	for itemId, item in Items do
		if item.kind == "sapling" and PlayerData.getItem(player, itemId) > 0 then
			return itemId
		end
	end
	return nil
end

local function plant(player: Player, spot: BasePart)
	local data = PlayerData.get(player)
	local sapling = chooseSapling(player)
	local treeName = if sapling then Trees.treeForSapling(sapling) else nil
	if not data or not sapling or not treeName then
		Notify.send(player, "You need a sapling. Buy one at the Seed Shop.", "error")
		return
	end
	if not PlayerData.takeItem(player, sapling, 1) then
		return
	end
	local plantedAt = os.time()
	data.trees[spot.Name] = { tree = treeName, plantedAt = plantedAt }
	startGrowing(player, spot, treeName, plantedAt)
end

local function chop(player: Player, spot: BasePart)
	local treeName = spot:GetAttribute("Tree")
	local data = PlayerData.get(player)
	local tree = if type(treeName) == "string" then Trees.list[treeName] else nil
	if not data or not tree then
		return
	end
	data.trees[spot.Name] = nil
	local wood = Forestry.woodAmount(player, tree.wood)
	PlayerData.addItem(player, "Wood", wood)
	local message = `+{wood} wood`
	if tree.fruit and Items[tree.fruit.item] then
		PlayerData.addItem(player, tree.fruit.item, tree.fruit.amount)
		message ..= `, +{tree.fruit.amount} {Items[tree.fruit.item].displayName}`
	end
	getPrompt(spot).HoldDuration = 0
	clearSpot(spot)
	Notify.send(player, message, "success")
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local plot = Plots.findPlot(prompt)
	if not plot or Plots.getOwner(plot) ~= player or not PlayerData.isLoaded(player) then
		return
	end
	local spot = prompt.Parent
	if not (spot and spot.Parent and spot.Parent.Name == "TreeSpots") then
		return
	end
	if spot:GetAttribute("Locked") then
		return
	end
	if spot:GetAttribute("Ready") then
		chop(player, spot :: BasePart)
	elseif not spot:GetAttribute("Tree") then
		plant(player, spot :: BasePart)
	end
end

local function restoreTrees(player: Player)
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
	local spots = (plot :: any).TreeSpots :: Folder
	for spotName, entry in data.trees do
		local spot = spots:FindFirstChild(spotName) :: BasePart?
		if spot and Trees.list[entry.tree] then
			startGrowing(player, spot, entry.tree, entry.plantedAt)
		else
			data.trees[spotName] = nil
		end
	end
end

function Forestry.start()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
	Players.PlayerAdded:Connect(restoreTrees)
	for _, player in Players:GetPlayers() do
		task.spawn(restoreTrees, player)
	end
	Plots.onRelease(function(plot)
		for _, spot in (plot :: any).TreeSpots:GetChildren() do
			getPrompt(spot).HoldDuration = 0
			clearSpot(spot)
		end
	end)
end

return Forestry
