-- Potions: brew them at the cauldron by your house, use them from the
-- Bag. Remotes: Brew(potionId) (at your own cauldron), UsePotion(potionId).
-- Each potion has a cooldown before it can be used again. Buffs last a set
-- time (not saved), count as a Bonuses source, and may multiply running
-- speed. Publishes "Buffs" (JSON potionId -> end time, in
-- workspace:GetServerTimeNow() seconds) for the client buff list.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Potions = require(ReplicatedStorage.Shared.Potions)
local Bonuses = require(script.Parent.Bonuses)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Remotes = require(script.Parent.Remotes)

local BASE_WALK_SPEED = 16
local MAX_CAULDRON_DISTANCE = 20

local Alchemy = {}

-- Active buffs per player: potionId -> end time.
local buffs: { [Player]: { [string]: number } } = {}
-- When each potion can next be used, per player.
local cooldowns: { [Player]: { [string]: number } } = {}

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
	local multiplier = 1
	local active: { [string]: number } = buffs[player] or {}
	for potionId in active do
		multiplier *= Potions[potionId].effect.speedMultiplier or 1
	end
	humanoid.WalkSpeed = BASE_WALK_SPEED * multiplier
end

local function buffBonuses(player: Player): { [string]: number }
	local combined: { [string]: number } = {}
	local active: { [string]: number } = buffs[player] or {}
	for potionId in active do
		local bonus: { [string]: number } = Potions[potionId].effect.bonus or {}
		for key, value in bonus do
			if Bonuses.isMultiplier(key) then
				combined[key] = (combined[key] or 1) * value
			else
				combined[key] = (combined[key] or 0) + value
			end
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
	local readyAt = (cooldowns[player] or {})[potionId] or 0
	if now() < readyAt then
		Notify.send(player, `{Items[potionId].displayName} ready in {math.ceil(readyAt - now())}s`, "info")
		return
	end
	local effect = potion.effect
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if effect.type == "heal" then
		if humanoid.Health >= humanoid.MaxHealth then
			Notify.send(player, "You're already at full health", "info")
			return
		end
		if not PlayerData.takeItem(player, potionId, 1) then
			return
		end
		local amount = humanoid.MaxHealth * (effect.healFraction or 0)
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)
		Notify.send(player, `Healed {math.floor(amount + 0.5)} health!`, "success")
	elseif effect.type == "buff" then
		if not PlayerData.takeItem(player, potionId, 1) then
			return
		end
		local active = buffs[player] or {}
		buffs[player] = active
		active[potionId] = now() + (effect.duration or 10)
		applyWalkSpeed(player)
		publishBuffs(player)
		Notify.send(player, `{Items[potionId].displayName} active for {effect.duration}s`, "success")
	else
		return
	end

	local playerCooldowns = cooldowns[player] or {}
	cooldowns[player] = playerCooldowns
	playerCooldowns[potionId] = now() + potion.cooldown
end

local function expireLoop()
	while true do
		task.wait(0.5)
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
		cooldowns[player] = nil
	end)
	task.spawn(expireLoop)
end

return Alchemy
