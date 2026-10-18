-- Swords and fighting. Every character gets their equipped weapon as a
-- Tool; swinging it (click/tap) hits enemies in a half circle in front of
-- the player. Kills give coins and item drops. Max health comes from the
-- Bonuses "maxHealth" key, and damage taken is reduced by "defense".

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyTypes = require(ReplicatedStorage.Shared.EnemyTypes)
local Gear = require(ReplicatedStorage.Shared.Gear)
local Items = require(ReplicatedStorage.Shared.Items)
local Bonuses = require(script.Parent.Bonuses)
local Enemies = require(script.Parent.Enemies)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)

local SWING_COOLDOWN = 0.55
local SWING_RANGE = 8
local BASE_HEALTH = 100
local MAX_DEFENSE = 0.8

local Combat = {}

local lastSwing: { [Player]: number } = {}
-- The weapon id + level each player is currently holding, so we only
-- rebuild the tool when it changes.
local heldWeapon: { [Player]: string } = {}

local function weaponOf(player: Player): (string, number)
	local data = PlayerData.get(player)
	local id = if data and data.equippedWeapon and Gear.list[data.equippedWeapon] then data.equippedWeapon else "WoodenSword"
	local level = if data then data.gear[id] or 0 else 0
	return id, level
end

-- Damage for one hit, and whether it was a critical hit.
function Combat.rollDamage(player: Player): (number, boolean)
	local id, level = weaponOf(player)
	local damage = (Gear.statFor(id, level) + Bonuses.get(player, "damage")) * Bonuses.get(player, "damageMultiplier")
	local crit = math.random() < Bonuses.get(player, "crit")
	if crit then
		damage *= 2
	end
	return math.floor(damage + 0.5), crit
end

local function buildTool(id: string, level: number): Tool
	local item = Gear.list[id]
	local tool = Instance.new("Tool")
	tool.Name = if level > 0 then `{item.displayName} +{level}` else item.displayName
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.GripPos = Vector3.new(0, -1.6, 0)
	tool:SetAttribute("GearId", id)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 4.6, 0.9)
	handle.Color = item.color
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.5, 0.3, 2)
	guard.Color = Color3.fromRGB(90, 60, 35)
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = handle.CFrame * CFrame.new(0, -1.2, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = guard
	weld.Parent = handle
	guard.Parent = tool
	return tool
end

local function swing(player: Player, tool: Tool)
	local now = os.clock()
	if (lastSwing[player] or 0) + SWING_COOLDOWN > now then
		return
	end
	lastSwing[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or tool.Parent ~= character then
		return
	end

	-- The default Animate script plays a slash when it sees this value.
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	Debris:AddItem(anim, 1)

	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	for _, enemy in Enemies.findInRange(root.Position, SWING_RANGE) do
		local offset = Vector3.new(enemy.position.X - root.Position.X, 0, enemy.position.Z - root.Position.Z)
		if offset.Magnitude < 1 or offset.Unit:Dot(look) > 0 then
			local damage = Combat.rollDamage(player)
			Enemies.damage(enemy, damage, player)
		end
	end
end

function Combat.giveWeapon(player: Player)
	local id, level = weaponOf(player)
	local key = `{id}:{level}`
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	-- Already holding this exact weapon (in hand or in the backpack)?
	local function has(container: Instance?): boolean
		if not container then
			return false
		end
		for _, child in container:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute("GearId") then
				return true
			end
		end
		return false
	end
	if heldWeapon[player] == key and (has(character) or has(backpack)) then
		return
	end
	for _, container in { character, backpack } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("GearId") then
					child:Destroy()
				end
			end
		end
	end
	local tool = buildTool(id, level)
	tool.Activated:Connect(function()
		swing(player, tool)
	end)
	tool.Parent = backpack
	heldWeapon[player] = key
end

function Combat.applyMaxHealth(player: Player, heal: boolean?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local maxHealth = BASE_HEALTH + Bonuses.get(player, "maxHealth")
	if humanoid.MaxHealth ~= maxHealth then
		humanoid.MaxHealth = maxHealth
	end
	if heal or humanoid.Health > maxHealth then
		humanoid.Health = maxHealth
	end
end

local function onKilled(player: Player, kind: string, _position: Vector3)
	local def = EnemyTypes[kind]
	if not def or player.Parent ~= Players then
		return
	end
	local parts = { `+{def.coins} coins` }
	PlayerData.addCoins(player, def.coins)
	for itemId, chance in def.drops do
		if math.random() < chance then
			PlayerData.addItem(player, itemId, 1)
			local item = Items[itemId]
			table.insert(parts, if item then item.displayName else itemId)
		end
	end
	local gearDrops: { [string]: number } = def.gearDrops or {}
	local data = PlayerData.get(player)
	for gearId, chance in gearDrops do
		if data and data.gear[gearId] == nil and Gear.list[gearId] and math.random() < chance then
			data.gear[gearId] = 0
			PlayerData.changed(player)
			table.insert(parts, `a {Gear.list[gearId].displayName}! (Equip it from the Gear tab)`)
		end
	end
	Notify.send(player, `{def.displayName} defeated! ` .. table.concat(parts, ", "), "success")
end

local function onCharacterAdded(player: Player, character: Model)
	character:WaitForChild("Humanoid", 10)
	heldWeapon[player] = nil
	Combat.applyMaxHealth(player, true)
	Combat.giveWeapon(player)
end

function Combat.start()
	Enemies.damageTaken = function(player, amount)
		local defense = math.clamp(Bonuses.get(player, "defense"), 0, MAX_DEFENSE)
		return amount * (1 - defense)
	end
	Enemies.onKilled(onKilled)

	-- Gear or pets changed: update the weapon and max health.
	PlayerData.onSync(function(player)
		if player.Character then
			Combat.giveWeapon(player)
			Combat.applyMaxHealth(player)
		end
	end)

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		heldWeapon[player] = nil
	end)
end

return Combat
