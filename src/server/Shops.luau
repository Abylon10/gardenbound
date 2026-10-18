-- Buying from the plaza shop menus. The client opens a menu from a shop's
-- "OpenShop" prompt and sends ShopBuy(shopId, entryId); the server checks
-- the player is at that shop, takes the coins, and gives the goods.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blueprints = require(ReplicatedStorage.Shared.Blueprints)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local Trees = require(ReplicatedStorage.Shared.Trees)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)

-- How close (studs) the player must be to the shop stall to buy.
local MAX_SHOP_DISTANCE = 40

local Shops = {}

-- Extra entry types other systems can register (e.g. gear in Phase 4).
-- handler(player, entry) -> (ok, message)
local handlers: { [string]: (Player, ShopCatalog.Entry) -> (boolean, string?) } = {}

function Shops.registerType(entryType: string, handler: (Player, ShopCatalog.Entry) -> (boolean, string?))
	handlers[entryType] = handler
end

local function nearShop(player: Player, shopId: string): boolean
	local plaza = workspace:FindFirstChild("Plaza")
	local shops = plaza and plaza:FindFirstChild("Shops")
	local stall = shops and shops:FindFirstChild(shopId)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (stall and root) then
		return false
	end
	local center = (stall :: Model):GetBoundingBox()
	return (root.Position - center.Position).Magnitude <= MAX_SHOP_DISTANCE
end

local function buy(player: Player, entry: ShopCatalog.Entry): (boolean, string?)
	if entry.type == "seed" then
		if not PlayerData.spendCoins(player, entry.price) then
			return false, "Not enough coins"
		end
		PlayerData.addSeeds(player, entry.id, 1)
		return true, `Bought {entry.displayName}`
	elseif entry.type == "sapling" then
		local tree = Trees.list[entry.id]
		if not tree or not PlayerData.spendCoins(player, entry.price) then
			return false, "Not enough coins"
		end
		PlayerData.addItem(player, tree.sapling, 1)
		return true, `Bought {entry.displayName}`
	elseif entry.type == "blueprint" then
		local data = PlayerData.get(player)
		if not data or not Blueprints[entry.id] then
			return false, nil
		end
		if data.blueprints[entry.id] then
			return false, "You already have this blueprint"
		end
		if not PlayerData.spendCoins(player, entry.price) then
			return false, "Not enough coins"
		end
		data.blueprints[entry.id] = true
		PlayerData.changed(player)
		return true, `Unlocked {entry.displayName}! Build it at your homestead.`
	end
	local handler = handlers[entry.type]
	if handler then
		return handler(player, entry)
	end
	return false, nil
end

function Shops.start()
	local shopBuy = Remotes.event("ShopBuy")
	shopBuy.OnServerEvent:Connect(function(player, shopId, entryId)
		if type(shopId) ~= "string" or type(entryId) ~= "string" then
			return
		end
		local entry = ShopCatalog.find(shopId, entryId)
		if not entry or not PlayerData.isLoaded(player) then
			return
		end
		if not nearShop(player, shopId) then
			Notify.send(player, "Walk up to the shop to buy", "error")
			return
		end
		local ok, message = buy(player, entry)
		if message then
			Notify.send(player, message, if ok then "success" else "error")
		end
	end)
end

return Shops
