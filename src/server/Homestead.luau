-- House upgrades and decorations on each player's plot.
--   * The "Upgrade house" prompt by the door builds the next house level
--     (needs that level's blueprint from the Blueprint Shop, plus wood).
--   * Each build spot builds its decoration (needs the blueprint + wood).
--   * Parts with a "RequiredLevel" attribute (extra tiles and tree spots)
--     are locked until the house reaches that level.
-- Publishes HouseLevel, Blueprints (JSON), and Decor (JSON) attributes.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blueprints = require(ReplicatedStorage.Shared.Blueprints)
local HomeBuilder = require(script.Parent.HomeBuilder)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)

local MAX_LEVEL = 3

local Homestead = {}

local function houseBlueprintFor(level: number): string
	return "HouseLevel" .. level
end

-- Locks or unlocks every part on the plot that needs a house level.
local function applyLocks(plot: Model, level: number)
	for _, part in plot:GetDescendants() do
		local required = part:GetAttribute("RequiredLevel")
		if part:IsA("BasePart") and type(required) == "number" then
			local locked = level < required
			part:SetAttribute("Locked", locked)
			part.Transparency = if locked then 1 else 0
			local prompt = part:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt:SetAttribute("Hidden", locked)
			end
		end
	end
end

local function updateUpgradePrompt(plot: Model, level: number)
	local prompt = (plot :: any).HouseUpgrade:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	local nextBlueprint = Blueprints[houseBlueprintFor(level + 1)]
	if level >= MAX_LEVEL or not nextBlueprint then
		prompt:SetAttribute("Hidden", true)
		return
	end
	prompt:SetAttribute("Hidden", false)
	prompt.ActionText = "Upgrade house"
	prompt.ObjectText = `Level {level} → {level + 1}: {nextBlueprint.wood} wood`
end

local function rebuildHouse(plot: Model, level: number)
	local old = plot:FindFirstChild("House")
	if old then
		old:Destroy()
	end
	HomeBuilder.buildHouse(plot, Plots.origin(plot), level, Plots.roofColor(plot))
end

local function setLevel(plot: Model, level: number)
	rebuildHouse(plot, level)
	applyLocks(plot, level)
	updateUpgradePrompt(plot, level)
end

local function decorFolder(plot: Model): Folder
	local folder = plot:FindFirstChild("Built")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Built"
		folder.Parent = plot
	end
	return folder :: Folder
end

local function buildDecor(plot: Model, decorId: string)
	local folder = decorFolder(plot)
	if folder:FindFirstChild(decorId) then
		return
	end
	local offset = HomeBuilder.DECOR_SPOTS[decorId]
	if offset then
		HomeBuilder.buildDecor(folder, decorId, Plots.origin(plot) * offset)
	end
	local pad = (plot :: any).BuildSpots:FindFirstChild(decorId) :: BasePart?
	if pad then
		pad.Transparency = 1
		local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt:SetAttribute("Hidden", true)
		end
	end
end

local function resetPlot(plot: Model)
	decorFolder(plot):ClearAllChildren()
	for _, pad in (plot :: any).BuildSpots:GetChildren() do
		pad.Transparency = 0.6
		local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt:SetAttribute("Hidden", false)
		end
	end
	setLevel(plot, 1)
end

local function applyPlayer(player: Player)
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
	setLevel(plot, data.houseLevel)
	for decorId in data.decor do
		buildDecor(plot, decorId)
	end
end

local function upgradeHouse(player: Player, plot: Model)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local nextLevel = data.houseLevel + 1
	local blueprintId = houseBlueprintFor(nextLevel)
	local blueprint = Blueprints[blueprintId]
	if not blueprint then
		Notify.send(player, "Your house is fully upgraded", "info")
		return
	end
	if not data.blueprints[blueprintId] then
		Notify.send(player, `Buy the {blueprint.displayName} blueprint at the Blueprint Shop first`, "error")
		return
	end
	if not PlayerData.pay(player, { items = { Wood = blueprint.wood } }) then
		Notify.send(player, `Need {blueprint.wood} wood (you have {PlayerData.getItem(player, "Wood")})`, "error")
		return
	end
	data.houseLevel = nextLevel
	PlayerData.changed(player)
	setLevel(plot, nextLevel)
	Notify.send(player, `House upgraded to level {nextLevel}!`, "success")
end

local function buildDecorFor(player: Player, plot: Model, decorId: string)
	local data = PlayerData.get(player)
	local blueprint = Blueprints[decorId]
	if not data or not blueprint or data.decor[decorId] then
		return
	end
	if not data.blueprints[decorId] then
		Notify.send(player, `Buy the {blueprint.displayName} blueprint at the Blueprint Shop first`, "error")
		return
	end
	if not PlayerData.pay(player, { items = { Wood = blueprint.wood } }) then
		Notify.send(player, `Need {blueprint.wood} wood (you have {PlayerData.getItem(player, "Wood")})`, "error")
		return
	end
	data.decor[decorId] = true
	PlayerData.changed(player)
	buildDecor(plot, decorId)
	Notify.send(player, `Built {blueprint.displayName}!`, "success")
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local plot = Plots.findPlot(prompt)
	if not plot or Plots.getOwner(plot) ~= player or not PlayerData.isLoaded(player) then
		return
	end
	local parent = prompt.Parent
	if not parent then
		return
	end
	if parent.Name == "HouseUpgrade" then
		upgradeHouse(player, plot)
	elseif parent.Parent and parent.Parent.Name == "BuildSpots" then
		buildDecorFor(player, plot, parent.Name)
	end
end

local function publish(player: Player, data: PlayerData.Data)
	player:SetAttribute("HouseLevel", data.houseLevel)
	local owned = {}
	for blueprintId in data.blueprints do
		table.insert(owned, blueprintId)
	end
	player:SetAttribute("Blueprints", HttpService:JSONEncode(owned))
	local built = {}
	for decorId in data.decor do
		table.insert(built, decorId)
	end
	player:SetAttribute("Decor", HttpService:JSONEncode(built))
end

function Homestead.start()
	for _, plot in workspace:WaitForChild("Plots"):GetChildren() do
		setLevel(plot :: Model, 1)
	end

	PlayerData.onSync(publish)
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

	Players.PlayerAdded:Connect(applyPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(applyPlayer, player)
	end

	Plots.onRelease(resetPlot)
end

return Homestead
