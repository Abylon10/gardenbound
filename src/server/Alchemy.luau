-- Potions: brew them at the cauldron by your house, use them from the
-- Bag. Remotes: Brew(potionId) (at your own cauldron), UsePotion(potionId).
-- Buffs last a set time (not saved), count as a Bonuses source, and may
-- add running speed. Publishes "Buffs" (JSON potionId -> end time, in
-- workspace:GetServerTimeNow() seconds) for the client buff bar.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Potions = require(ReplicatedStorage.Shared.Potions)
local Bonuses = require(script.Parent.Bonuses)
local Farming = require(script.Parent.Farming)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Remotes = require(script.Parent.Remotes)

local BASE_WALK_SPEED = 16
local MAX_CAULDRON_DISTANCE = 20

local Alchemy = {}

-- Active buffs per player: potionId -> end time.
local buffs: { [Player]: { [string]: number } } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function publishBuffs(player: Player)
	player:SetAttribute("Buffs", HttpService:JSONEncode(buffs[player] or {}))
end

local function applyWalkSpeed(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local extra = 0
	local active: { [string]: number } = buffs[player] or {}
	for potionId in active do
		extra += Potions[potionId].effect.walkSpeed or 0
	end
	humanoid.WalkSpeed = BASE_WALK_SPEED + extra
end

local function buffBonuses(player: Player): { [string]: number }
	local combined: { [string]: number } = {}
	local active: { [string]: number } = buffs[player] or {}
	for potionId in active do
		local bonus: { [string]: number } = Potions[potionId].effect.bonus or {}
		for key, value in bonus do
			combined[key] = (combined[key] or 0) + value
		end
	end
	return combined
end

local function atOwnCauldron(player: Player): boolean
	local plot = Plots.getPlot(player)
	local cauldron = plot and plot:FindFirstChild("Cauldron")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (cauldron and root) then
		return false
	end
	local center = (cauldron :: Model):GetBoundingBox()
	return (root.Position - center.Position).Magnitude <= MAX_CAULDRON_DISTANCE
end

local function brew(player: Player, potionId: unknown)
	if type(potionId) ~= "string" then
		return
	end
	local potion = Potions[potionId]
	if not potion or not PlayerData.isLoaded(player) then
		return
	end
	if not atOwnCauldron(player) then
		Notify.send(player, "Brew at the cauldron by your house", "error")
		return
	end
	if not PlayerData.pay(player, potion.recipe) then
		Notify.send(player, "Missing ingredients", "error")
		return
	end
	PlayerData.addItem(player, potionId, 1)
	Notify.send(player, `Brewed a {Items[potionId].displayName}!`, "success")
end

local function use(player: Player, potionId: unknown)
	if type(potionId) ~= "string" then
		return
	end
	local potion = Potions[potionId]
	if not potion or not PlayerData.isLoaded(player) then
		return
	end
	local effect = potion.effect
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if effect.type == "heal" then
		if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
			Notify.send(player, "You're already at full health", "info")
			return
		end
		if not PlayerData.takeItem(player, potionId, 1) then
			return
		end
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (effect.amount or 0))
		Notify.send(player, "Healed!", "success")
	elseif effect.type == "buff" then
		if not PlayerData.takeItem(player, potionId, 1) then
			return
		end
		local active = buffs[player] or {}
		buffs[player] = active
		active[potionId] = now() + (effect.duration or 60)
		applyWalkSpeed(player)
		publishBuffs(player)
		PlayerData.changed(player) -- refresh max health / weapon from new bonuses
		Notify.send(player, `{Items[potionId].displayName} active for {effect.duration}s`, "success")
	elseif effect.type == "growAll" then
		if Farming.growingCount(player) == 0 then
			Notify.send(player, "Nothing is growing in your front garden", "info")
			return
		end
		if not PlayerData.takeItem(player, potionId, 1) then
			return
		end
		local count = Farming.growAll(player)
		Notify.send(player, `{count} crops finished growing!`, "success")
	end
end

local function expireLoop()
	while true do
		task.wait(1)
		local time = now()
		for player, active in buffs do
			local changed = false
			for potionId, endTime in active do
				if time >= endTime then
					active[potionId] = nil
					changed = true
					Notify.send(player, `{Items[potionId].displayName} wore off`, "info")
				end
			end
			if changed then
				applyWalkSpeed(player)
				publishBuffs(player)
				PlayerData.changed(player)
			end
		end
	end
end

function Alchemy.start()
	Remotes.event("Brew").OnServerEvent:Connect(brew)
	Remotes.event("UsePotion").OnServerEvent:Connect(use)
	Bonuses.addSource(buffBonuses)

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 10)
			applyWalkSpeed(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		buffs[player] = nil
	end)
	task.spawn(expireLoop)
end

return Alchemy
