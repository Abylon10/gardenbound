-- Builds the Central Plaza at the world origin: a stone floor, the four
-- shops on its outer ring, and paths out to each player plot. Also handles
-- the shop prompts. Seed and Sell shops work; Gear and Blueprint are
-- placeholders until equipment and building exist.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Build = require(script.Parent.Build)
local MapLayout = require(script.Parent.MapLayout)
local PlayerData = require(script.Parent.PlayerData)

local TOP = MapLayout.PLAZA_TOP
local STONE = Color3.fromRGB(196, 188, 170)
local WOOD = Color3.fromRGB(150, 105, 65)

type ShopInfo = {
	key: string,
	displayName: string,
	subtitle: string,
	color: Color3,
}

local SHOPS: { ShopInfo } = {
	{ key = "SeedShop", displayName = "Seed Shop", subtitle = "Seeds for your garden", color = Color3.fromRGB(70, 160, 80) },
	{ key = "SellShop", displayName = "Sell Shop", subtitle = "Sell your crops", color = Color3.fromRGB(200, 60, 50) },
	{ key = "GearShop", displayName = "Gear Shop", subtitle = "Coming soon", color = Color3.fromRGB(60, 100, 200) },
	{ key = "BlueprintShop", displayName = "Blueprint Shop", subtitle = "Coming soon", color = Color3.fromRGB(130, 80, 190) },
}

local Plaza = {}

local plaza: Model

local function sortedCropNames(): { string }
	local names = {}
	for cropName in Crops do
		table.insert(names, cropName)
	end
	table.sort(names, function(a, b)
		return Crops[a].order < Crops[b].order
	end)
	return names
end

-- A market stall. Its front (-Z) faces the plaza center.
local function buildStall(shop: ShopInfo, origin: CFrame): Model
	local stall = Instance.new("Model")
	stall.Name = shop.key

	Build.part({
		Name = "Floor",
		Size = Vector3.new(18, 0.6, 12),
		CFrame = origin * CFrame.new(0, TOP + 0.3, 0),
		Color = WOOD,
		Material = Enum.Material.WoodPlanks,
	}).Parent = stall

	local counter = Build.part({
		Name = "Counter",
		Size = Vector3.new(16, 3.5, 2),
		CFrame = origin * CFrame.new(0, TOP + 0.6 + 1.75, -4),
		Color = WOOD,
		Material = Enum.Material.Wood,
	})
	counter.Parent = stall

	Build.part({
		Name = "BackWall",
		Size = Vector3.new(18, 10, 1),
		CFrame = origin * CFrame.new(0, TOP + 5, 5.5),
		Color = shop.color,
		Material = Enum.Material.SmoothPlastic,
	}).Parent = stall

	for _, x in { -8.5, 8.5 } do
		Build.part({
			Name = "Post",
			Size = Vector3.new(1, 10, 1),
			CFrame = origin * CFrame.new(x, TOP + 5, -5.5),
			Color = WOOD,
			Material = Enum.Material.Wood,
		}).Parent = stall
	end

	local awning = Build.part({
		Name = "Awning",
		Size = Vector3.new(20, 0.6, 14),
		CFrame = origin * CFrame.new(0, TOP + 10.5, 0) * CFrame.Angles(math.rad(-10), 0, 0),
		Color = shop.color,
		Material = Enum.Material.Fabric,
	})
	awning.Parent = stall
	Build.sign(awning, shop.displayName, shop.subtitle, 5)

	local counterTop = TOP + 0.6 + 3.5
	if shop.key == "SeedShop" then
		-- One crate per crop on the counter, each with its own prompt.
		local names = sortedCropNames()
		for i, cropName in names do
			local crop = Crops[cropName]
			local x = (i - (#names + 1) / 2) * 4.5
			local crate = Build.part({
				Name = "Buy_" .. cropName,
				Size = Vector3.new(3, 2.5, 3),
				CFrame = origin * CFrame.new(x, counterTop + 1.25, -4),
				Color = crop.color,
				Material = Enum.Material.WoodPlanks,
			})
			Build.prompt(crate, `Buy seed ({crop.seedPrice} coins)`, crop.displayName)
			crate.Parent = stall
		end
	elseif shop.key == "SellShop" then
		Build.prompt(counter, "Sell all crops", "Sell Shop").Name = "Sell"
	end

	return stall
end

local function buildPlaza()
	plaza = Instance.new("Model")
	plaza.Name = "Plaza"

	local radius = MapLayout.PLAZA_RADIUS
	local floor = Build.part({
		Name = "Floor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(TOP, radius * 2, radius * 2),
		CFrame = CFrame.new(0, TOP / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = STONE,
		Material = Enum.Material.Cobblestone,
	})
	floor.Parent = plaza
	plaza.PrimaryPart = floor

	local emblem = Build.part({
		Name = "Emblem",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 28, 28),
		CFrame = CFrame.new(0, TOP + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(120, 170, 110),
		Material = Enum.Material.Slate,
		CanCollide = false,
	})
	emblem.Parent = plaza
	Build.sign(emblem, "Central Plaza", nil, 14)

	local shops = Instance.new("Folder")
	shops.Name = "Shops"
	shops.Parent = plaza
	for _, shop in SHOPS do
		local origin = MapLayout.facingCenter(MapLayout.SHOP_ANGLES[shop.key], MapLayout.SHOP_RING_RADIUS)
		buildStall(shop, origin).Parent = shops
	end

	-- Stone paths from the plaza edge to the front of each plot.
	local paths = Instance.new("Folder")
	paths.Name = "Paths"
	paths.Parent = plaza
	local pathStart = radius - 2
	local pathEnd = MapLayout.PLOT_RING_RADIUS - MapLayout.PLOT_SIZE / 2 + 2
	for i, angle in MapLayout.PLOT_ANGLES do
		local middle = MapLayout.pointAt(angle, (pathStart + pathEnd) / 2)
		Build.part({
			Name = "Path" .. i,
			Size = Vector3.new(10, 1, pathEnd - pathStart),
			CFrame = CFrame.lookAt(middle, Vector3.zero) * CFrame.new(0, 0.6, 0),
			Color = STONE,
			Material = Enum.Material.Cobblestone,
		}).Parent = paths
	end

	plaza.Parent = workspace
end

local function buySeed(player: Player, crate: Instance)
	local cropName = string.match(crate.Name, "^Buy_(.+)$")
	local crop = if cropName then Crops[cropName] else nil
	if not crop then
		return
	end
	if PlayerData.spendCoins(player, crop.seedPrice) then
		PlayerData.addSeeds(player, cropName :: string, 1)
	end
end

local function sellAll(player: Player)
	local sold = PlayerData.takeAllCrops(player)
	local total = 0
	for cropName, count in sold do
		local crop = Crops[cropName]
		if crop then
			total += crop.sellPrice * count
		end
	end
	if total > 0 then
		PlayerData.addCoins(player, total)
	end
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	if not prompt:IsDescendantOf(plaza) or not PlayerData.isLoaded(player) then
		return
	end
	local parent = prompt.Parent
	if prompt.Name == "Sell" then
		sellAll(player)
	elseif parent and string.match(parent.Name, "^Buy_") then
		buySeed(player, parent)
	end
end

function Plaza.start()
	buildPlaza()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
end

return Plaza
