-- Trees for the back garden. Plant a sapling, wait growTime seconds, then
-- chop it for wood (Apple and Coconut trees also drop fruit). Saplings are
-- bought at the Seed Shop.

export type Tree = {
	displayName: string,
	sapling: string, -- item id
	saplingPrice: number,
	growTime: number,
	wood: number,
	fruit: { item: string, amount: number }?, -- extra drop when chopped
	leafColor: Color3,
	order: number,
}

local Trees: { [string]: Tree } = {
	Birch = {
		displayName = "Birch",
		sapling = "BirchSapling",
		saplingPrice = 10,
		growTime = 60,
		wood = 5,
		leafColor = Color3.fromRGB(150, 200, 80),
		order = 1,
	},
	Apple = {
		displayName = "Apple",
		sapling = "AppleSapling",
		saplingPrice = 35,
		growTime = 150,
		wood = 12,
		fruit = { item = "Apple", amount = 3 },
		leafColor = Color3.fromRGB(70, 150, 60),
		order = 2,
	},
	Coconut = {
		displayName = "Coconut",
		sapling = "CoconutSapling",
		saplingPrice = 90,
		growTime = 360,
		wood = 30,
		fruit = { item = "Coconut", amount = 2 },
		leafColor = Color3.fromRGB(110, 170, 50),
		order = 3,
	},
}

-- Which tree a sapling item grows into.
local function treeForSapling(itemId: string): string?
	for treeName, tree in Trees do
		if tree.sapling == itemId then
			return treeName
		end
	end
	return nil
end

return {
	list = Trees,
	treeForSapling = treeForSapling,
}
