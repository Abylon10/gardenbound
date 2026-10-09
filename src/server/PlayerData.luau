-- Loads, saves, and edits each player's coins, seeds, and harvested crops.
-- Values are mirrored to the client as leaderstats.Coins and player attributes
-- ("Seed_<Crop>", "Crop_<Crop>") so the UI can read them without remotes.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)

local STORE_NAME = "PlayerData_v1"
local STARTING_COINS = 20
local STARTING_SEEDS = { Carrot = 3 }
local AUTOSAVE_INTERVAL = 120

type Data = {
	coins: number,
	seeds: { [string]: number },
	crops: { [string]: number },
}

type Profile = {
	data: Data,
	canSave: boolean,
}

local PlayerData = {}

local profiles: { [Player]: Profile } = {}

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
	}
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
				data.coins = result.coins or data.coins
				data.seeds = result.seeds or data.seeds
				data.crops = result.crops or data.crops
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

function PlayerData.addCrop(player: Player, cropName: string, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.data.crops[cropName] = (profile.data.crops[cropName] or 0) + amount
	sync(player)
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
