-- Loads, saves, and edits each player's saved state. Every other system
-- changes saved state only through this module.
--
-- Mirrored to the client so UI can read it without remotes:
--   leaderstats.Coins
--   attributes "Seed_<Crop>", "Crop_<Crop>", "Item_<ItemId>"
--   plus anything systems publish through PlayerData.onSync (for example
--   JSON lists of pets or gear).
--
-- To add a new saved field: add it to Data and defaultData(). Old saves
-- get the default for any field they don't have.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)

local STORE_NAME = "PlayerData_v1"
local STARTING_COINS = 20
local STARTING_SEEDS = { Carrot = 3 }
local AUTOSAVE_INTERVAL = 120

export type GardenEntry = { crop: string, plantedAt: number }
export type TreeEntry = { tree: string, plantedAt: number }
export type Pet = { id: number, kind: string }

export type Data = {
	coins: number,
	seeds: { [string]: number },
	crops: { [string]: number },
	-- Stackable items by id: materials, saplings, eggs, potions.
	items: { [string]: number },
	-- What is growing in each front-garden tile / back-garden spot, by name.
	garden: { [string]: GardenEntry },
	trees: { [string]: TreeEntry },
	houseLevel: number,
	-- Blueprint ids the player has bought, and decorations they've built.
	blueprints: { [string]: boolean },
	decor: { [string]: boolean },
	pets: { Pet },
	nextPetId: number,
	equippedPets: { farm: number?, battle: number? },
	-- Owned gear by id -> enhancement level (0 = +0).
	gear: { [string]: number },
	equippedWeapon: string?,
	equippedArmor: string?,
}

type Profile = {
	data: Data,
	canSave: boolean,
}

local PlayerData = {}

local profiles: { [Player]: Profile } = {}
local syncCallbacks: { (Player, Data) -> () } = {}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStore unavailable, progress will not save:", result)
	end
end

local function defaultData(): Data
	return {
		coins = STARTING_COINS,
		seeds = table.clone(STARTING_SEEDS),
		crops = {},
		items = {},
		garden = {},
		trees = {},
		houseLevel = 1,
		blueprints = {},
		decor = {},
		pets = {},
		nextPetId = 1,
		equippedPets = {},
		gear = { WoodenSword = 0 },
		equippedWeapon = "WoodenSword",
		equippedArmor = nil,
	}
end

-- Renames for items that changed between versions.
local RENAMED_ITEMS = {
	ForestEgg = "UncommonEgg",
	AncientEgg = "RareEgg",
}

local function migrate(data: Data)
	for oldId, newId in RENAMED_ITEMS do
		local count = data.items[oldId]
		if count and count > 0 then
			data.items[newId] = (data.items[newId] or 0) + count
		end
		data.items[oldId] = nil
	end
end

local function sync(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local data = profile.data

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		(leaderstats :: any).Coins.Value = data.coins
	end

	for cropName in Crops do
		player:SetAttribute("Seed_" .. cropName, data.seeds[cropName] or 0)
		player:SetAttribute("Crop_" .. cropName, data.crops[cropName] or 0)
	end
	for itemId, count in data.items do
		player:SetAttribute("Item_" .. itemId, count)
	end

	for _, callback in syncCallbacks do
		task.spawn(callback, player, data)
	end
end

local function load(player: Player)
	local data = defaultData()
	local canSave = store ~= nil

	if store then
		local ok, result = pcall(function()
			return store:GetAsync(tostring(player.UserId))
		end)
		if ok then
			if type(result) == "table" then
				for key, value in result do
					(data :: any)[key] = value
				end
				migrate(data)
			end
		else
			-- Don't overwrite real progress with defaults after a failed load.
			canSave = false
			warn("[PlayerData] Failed to load data for", player.Name, result)
		end
	end

	-- The player may have left while we were waiting on the DataStore.
	if player.Parent ~= Players then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
	leaderstats.Parent = player

	profiles[player] = { data = data, canSave = canSave }
	player:SetAttribute("DataLoaded", true)
	sync(player)
end

local function save(player: Player)
	local profile = profiles[player]
	if not (profile and profile.canSave and store) then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(tostring(player.UserId), profile.data)
	end)
	if not ok then
		warn("[PlayerData] Failed to save data for", player.Name, err)
	end
end

function PlayerData.isLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

-- Yields until the player's data is loaded (or they leave / time runs out).
function PlayerData.waitForLoad(player: Player, timeout: number?): boolean
	local deadline = os.clock() + (timeout or 30)
	while not profiles[player] and player.Parent == Players and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player] ~= nil
end

-- Direct access to a player's data for systems with their own fields.
-- After changing it, call PlayerData.changed(player).
function PlayerData.get(player: Player): Data?
	local profile = profiles[player]
	return if profile then profile.data else nil
end

-- Re-publish the player's data to the client after a direct change.
function PlayerData.changed(player: Player)
	sync(player)
end

-- Register a function that publishes extra state to the client whenever
-- the player's data changes.
function PlayerData.onSync(callback: (Player, Data) -> ())
	table.insert(syncCallbacks, callback)
end

function PlayerData.getCoins(player: Player): number
	local profile = profiles[player]
	return if profile then profile.data.coins else 0
end

function PlayerData.addCoins(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.data.coins += amount
	sync(player)
end

-- Returns false (and changes nothing) if the player can't afford it.
function PlayerData.spendCoins(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or profile.data.coins < amount then
		return false
	end
	profile.data.coins -= amount
	sync(player)
	return true
end

function PlayerData.getSeeds(player: Player, cropName: string): number
	local profile = profiles[player]
	return if profile then profile.data.seeds[cropName] or 0 else 0
end

function PlayerData.addSeeds(player: Player, cropName: string, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.data.seeds[cropName] = (profile.data.seeds[cropName] or 0) + amount
	sync(player)
end

-- Returns false if the player has no seed of that type.
function PlayerData.takeSeed(player: Player, cropName: string): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local count = profile.data.seeds[cropName] or 0
	if count <= 0 then
		return false
	end
	profile.data.seeds[cropName] = count - 1
	sync(player)
	return true
end

function PlayerData.getCrop(player: Player, cropName: string): number
	local profile = profiles[player]
	return if profile then profile.data.crops[cropName] or 0 else 0
end

function PlayerData.addCrop(player: Player, cropName: string, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.data.crops[cropName] = (profile.data.crops[cropName] or 0) + amount
	sync(player)
end

-- Returns false (and changes nothing) if the player has fewer than amount.
function PlayerData.takeCrop(player: Player, cropName: string, amount: number): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local count = profile.data.crops[cropName] or 0
	if count < amount then
		return false
	end
	profile.data.crops[cropName] = count - amount
	sync(player)
	return true
end

-- Removes every harvested crop and returns what was removed.
function PlayerData.takeAllCrops(player: Player): { [string]: number }
	local profile = profiles[player]
	if not profile then
		return {}
	end
	local taken = profile.data.crops
	profile.data.crops = {}
	sync(player)
	return taken
end

function PlayerData.getItem(player: Player, itemId: string): number
	local profile = profiles[player]
	return if profile then profile.data.items[itemId] or 0 else 0
end

function PlayerData.addItem(player: Player, itemId: string, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.data.items[itemId] = (profile.data.items[itemId] or 0) + amount
	sync(player)
end

-- Returns false (and changes nothing) if the player has fewer than amount.
function PlayerData.takeItem(player: Player, itemId: string, amount: number): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local count = profile.data.items[itemId] or 0
	if count < amount then
		return false
	end
	profile.data.items[itemId] = count - amount
	sync(player)
	return true
end

-- Takes every listed cost at once, or nothing if anything is short.
-- costs = { coins = n, items = { [id] = n }, crops = { [crop] = n } }
function PlayerData.pay(
	player: Player,
	costs: { coins: number?, items: { [string]: number }?, crops: { [string]: number }? }
): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local data = profile.data
	local coins = costs.coins or 0
	local items: { [string]: number } = costs.items or {}
	local crops: { [string]: number } = costs.crops or {}
	if coins > data.coins then
		return false
	end
	for itemId, amount in items do
		if (data.items[itemId] or 0) < amount then
			return false
		end
	end
	for cropName, amount in crops do
		if (data.crops[cropName] or 0) < amount then
			return false
		end
	end
	data.coins -= coins
	for itemId, amount in items do
		data.items[itemId] -= amount
	end
	for cropName, amount in crops do
		data.crops[cropName] -= amount
	end
	sync(player)
	return true
end

function PlayerData.start()
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			task.spawn(save, player)
		end
		task.wait(2)
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				task.spawn(save, player)
			end
		end
	end)
end

return PlayerData
