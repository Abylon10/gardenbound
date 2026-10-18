-- What each plaza shop sells. Prices come from the item definitions.
-- Entry types:
--   seed      -> Crops[id]          (adds seeds)
--   sapling   -> Trees.list[id]     (adds the sapling item)
--   blueprint -> Blueprints[id]     (unlocks the blueprint)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Blueprints = require(Shared:WaitForChild("Blueprints"))
local Crops = require(Shared:WaitForChild("Crops"))
local Trees = require(Shared:WaitForChild("Trees"))

export type Entry = {
	type: string,
	id: string,
	displayName: string,
	description: string,
	price: number,
	color: Color3,
}

local function sortedKeys(map: { [string]: any }): { string }
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return map[a].order < map[b].order
	end)
	return keys
end

local catalogs: { [string]: { Entry } } = {
	SeedShop = {},
	BlueprintShop = {},
}

for _, cropName in sortedKeys(Crops) do
	local crop = Crops[cropName]
	table.insert(catalogs.SeedShop, {
		type = "seed",
		id = cropName,
		displayName = crop.displayName .. " Seed",
		description = `Grows in {crop.growTime}s. Sells for {crop.sellPrice} coins.`,
		price = crop.seedPrice,
		color = crop.color,
	})
end

for _, treeName in sortedKeys(Trees.list) do
	local tree = Trees.list[treeName]
	table.insert(catalogs.SeedShop, {
		type = "sapling",
		id = treeName,
		displayName = tree.displayName .. " Sapling",
		description = `Back garden tree. Grows in {tree.growTime}s, gives {tree.wood} wood.`,
		price = tree.saplingPrice,
		color = tree.leafColor,
	})
end

for _, blueprintId in sortedKeys(Blueprints) do
	local blueprint = Blueprints[blueprintId]
	table.insert(catalogs.BlueprintShop, {
		type = "blueprint",
		id = blueprintId,
		displayName = blueprint.displayName,
		description = `{blueprint.description} Build cost: {blueprint.wood} wood.`,
		price = blueprint.price,
		color = Color3.fromRGB(130, 80, 190),
	})
end

local ShopCatalog = {}

function ShopCatalog.get(shopId: string): { Entry }?
	return catalogs[shopId]
end

function ShopCatalog.find(shopId: string, entryId: string): Entry?
	local catalog: { Entry } = catalogs[shopId] or {}
	for _, entry in catalog do
		if entry.id == entryId then
			return entry
		end
	end
	return nil
end

return ShopCatalog
