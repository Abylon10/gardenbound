-- Trees for the back garden. Plant a sapling, wait growTime seconds, then
-- chop it for wood. Saplings are bought at the Seed Shop.

export type Tree = {
	displayName: string,
	sapling: string, -- item id
	saplingPrice: number,
	growTime: number,
	wood: number,
	leafColor: Color3,
	order: number,
}

local Trees: { [string]: Tree } = {
	Oak = {
		displayName = "Oak",
		sapling = "OakSapling",
		saplingPrice = 10,
		growTime = 60,
		wood = 4,
		leafColor = Color3.fromRGB(70, 150, 60),
		order = 1,
	},
	Pine = {
		displayName = "Pine",
		sapling = "PineSapling",
		saplingPrice = 30,
		growTime = 150,
		wood = 10,
		leafColor = Color3.fromRGB(40, 110, 70),
		order = 2,
	},
	Maple = {
		displayName = "Maple",
		sapling = "MapleSapling",
		saplingPrice = 90,
		growTime = 360,
		wood = 30,
		leafColor = Color3.fromRGB(220, 110, 50),
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
