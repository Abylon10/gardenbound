-- The Forge (Gear Shop): craft weapons and armor from materials, upgrade
-- them +1..+10, and equip them. Remotes:
--   ForgeCraft(gearId), ForgeUpgrade(gearId)  -- must be at the Gear Shop
--   EquipGear(gearId)                         -- anywhere
-- Equipped armor adds max health and defense through Bonuses. Publishes
-- "Gear" (JSON id -> level), "EquippedWeapon", "EquippedArmor".

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gear = require(ReplicatedStorage.Shared.Gear)
local Bonuses = require(script.Parent.Bonuses)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)

local MAX_FORGE_DISTANCE = 40

local Forge = {}

local function atForge(player: Player): boolean
	local plaza = workspace:FindFirstChild("Plaza")
	local shops = plaza and plaza:FindFirstChild("Shops")
	local stall = shops and shops:FindFirstChild("GearShop")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (stall and root) then
		return false
	end
	local center = (stall :: Model):GetBoundingBox()
	return (root.Position - center.Position).Magnitude <= MAX_FORGE_DISTANCE
end

local function craft(player: Player, gearId: unknown)
	if type(gearId) ~= "string" then
		return
	end
	local item = Gear.list[gearId]
	local data = PlayerData.get(player)
	if not item or not item.craft or not data then
		return
	end
	if not atForge(player) then
		Notify.send(player, "Go to the Forge (Gear Shop) to craft", "error")
		return
	end
	if data.gear[gearId] ~= nil then
		Notify.send(player, `You already have a {item.displayName}`, "error")
		return
	end
	if not PlayerData.pay(player, { coins = item.craft.coins, items = item.craft.items }) then
		Notify.send(player, "Not enough coins or materials", "error")
		return
	end
	data.gear[gearId] = 0
	PlayerData.changed(player)
	Notify.send(player, `Forged a {item.displayName}! Equip it from the Gear tab in your Bag.`, "success")
end

local function upgrade(player: Player, gearId: unknown)
	if type(gearId) ~= "string" then
		return
	end
	local item = Gear.list[gearId]
	local data = PlayerData.get(player)
	local level = if data then data.gear[gearId] else nil
	if not item or not data or level == nil then
		return
	end
	if not atForge(player) then
		Notify.send(player, "Go to the Forge (Gear Shop) to upgrade", "error")
		return
	end
	if level >= Gear.MAX_LEVEL then
		Notify.send(player, `{item.displayName} is already +{Gear.MAX_LEVEL}`, "info")
		return
	end
	local cost = Gear.upgradeCost(gearId, level)
	if not PlayerData.pay(player, { coins = cost.coins, items = cost.items }) then
		Notify.send(player, "Not enough coins or materials", "error")
		return
	end
	data.gear[gearId] = level + 1
	PlayerData.changed(player)
	Notify.send(player, `{item.displayName} upgraded to +{level + 1}!`, "success")
end

local function equip(player: Player, gearId: unknown)
	if type(gearId) ~= "string" then
		return
	end
	local item = Gear.list[gearId]
	local data = PlayerData.get(player)
	if not item or not data or data.gear[gearId] == nil then
		return
	end
	if item.slot == "weapon" then
		data.equippedWeapon = gearId
	elseif data.equippedArmor == gearId then
		data.equippedArmor = nil
	else
		data.equippedArmor = gearId
	end
	PlayerData.changed(player)
end

local function armorBonuses(player: Player): { [string]: number }
	local data = PlayerData.get(player)
	local armorId = data and data.equippedArmor
	local item = if armorId then Gear.list[armorId] else nil
	if not data or not armorId or not item then
		return {}
	end
	return {
		maxHealth = Gear.statFor(armorId, data.gear[armorId] or 0),
		defense = item.defense or 0,
	}
end

local function publish(player: Player, data: PlayerData.Data)
	player:SetAttribute("Gear", HttpService:JSONEncode(data.gear))
	player:SetAttribute("EquippedWeapon", data.equippedWeapon or "")
	player:SetAttribute("EquippedArmor", data.equippedArmor or "")
end

function Forge.start()
	Remotes.event("ForgeCraft").OnServerEvent:Connect(craft)
	Remotes.event("ForgeUpgrade").OnServerEvent:Connect(upgrade)
	Remotes.event("EquipGear").OnServerEvent:Connect(equip)
	Bonuses.addSource(armorBonuses)
	PlayerData.onSync(publish)
end

return Forge
