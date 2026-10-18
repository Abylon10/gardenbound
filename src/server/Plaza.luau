-- Builds the Central Plaza at the world origin: a stone floor with a
-- fountain, lamps and trees, the four shops on its outer ring, and a wooden
-- bridge out to every other island. Handles the Sell Shop prompt. The Seed
-- and Blueprint shops have an "OpenShop" prompt that opens a menu on the
-- client (buying is handled by Shops).

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Build = require(script.Parent.Build)
local MapLayout = require(script.Parent.MapLayout)
local Notify = require(script.Parent.Notify)
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
	{ key = "GearShop", displayName = "Gear Shop", subtitle = "Forge and upgrade gear", color = Color3.fromRGB(60, 100, 200) },
	{ key = "BlueprintShop", displayName = "Blueprint Shop", subtitle = "House upgrades and decorations", color = Color3.fromRGB(130, 80, 190) },
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
		-- Crates of produce on the counter (decoration).
		local names = sortedCropNames()
		for i, cropName in names do
			local x = (i - (#names + 1) / 2) * 3.1
			Build.part({
				Name = "Crate",
				Size = Vector3.new(2.6, 2.2, 2.6),
				CFrame = origin * CFrame.new(x, counterTop + 1.1, -4),
				Color = Crops[cropName].color,
				Material = Enum.Material.WoodPlanks,
			}).Parent = stall
		end
	elseif shop.key == "BlueprintShop" then
		-- Rolled-up blueprints on the counter (decoration).
		for i = -1, 1 do
			Build.part({
				Name = "Scroll",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(4, 1, 1),
				CFrame = origin * CFrame.new(i * 4.5, counterTop + 0.5, -4),
				Color = Color3.fromRGB(110, 150, 220),
				Material = Enum.Material.Fabric,
			}).Parent = stall
		end
	end

	-- Shops with a menu get an "OpenShop" prompt; the client opens the menu.
	-- The Gear Shop opens the Forge menu instead.
	if shop.key == "SellShop" then
		Build.prompt(counter, "Sell all crops", "Sell Shop").Name = "Sell"
	elseif shop.key == "GearShop" then
		Build.prompt(counter, "Forge", "Gear Shop").Name = "OpenForge"
	else
		local prompt = Build.prompt(counter, "Browse", shop.displayName)
		prompt.Name = "OpenShop"
		prompt:SetAttribute("Shop", shop.key)
	end

	return stall
end

local function cylinder(props: { [string]: any }, center: Vector3, height: number, diameter: number): Part
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, diameter, diameter)
	props.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
	return Build.part(props)
end

-- Stone fountain in the middle of the plaza with the plaza's name above it.
local function buildFountain(parent: Instance)
	local fountain = Instance.new("Model")
	fountain.Name = "Fountain"

	cylinder({ Name = "Rim", Color = Color3.fromRGB(150, 145, 135), Material = Enum.Material.Cobblestone }, Vector3.new(0, TOP + 1.25, 0), 2.5, 26).Parent =
		fountain
	cylinder({
		Name = "Water",
		Color = Color3.fromRGB(70, 150, 220),
		Material = Enum.Material.Glass,
		Transparency = 0.25,
	}, Vector3.new(0, TOP + 1.6, 0), 2.2, 22).Parent = fountain
	cylinder({ Name = "Pillar", Color = STONE, Material = Enum.Material.Marble }, Vector3.new(0, TOP + 5, 0), 8, 3).Parent = fountain
	cylinder({ Name = "Bowl", Color = STONE, Material = Enum.Material.Marble }, Vector3.new(0, TOP + 9.5, 0), 1, 9).Parent = fountain
	cylinder({
		Name = "BowlWater",
		Color = Color3.fromRGB(70, 150, 220),
		Material = Enum.Material.Glass,
		Transparency = 0.25,
	}, Vector3.new(0, TOP + 10.1, 0), 0.4, 7.5).Parent = fountain

	local sprout = Build.part({
		Name = "Sprout",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4, 4, 4),
		CFrame = CFrame.new(0, TOP + 12.5, 0),
		Color = Color3.fromRGB(110, 200, 90),
		Material = Enum.Material.Grass,
	})
	sprout.Parent = fountain
	Build.sign(sprout, "Central Plaza", nil, 5)

	fountain.Parent = parent
end

-- Lamps around the plaza edge and trees in round planters, placed between
-- the bridges so walkways stay clear.
local function buildGreenery(parent: Instance)
	local greenery = Instance.new("Folder")
	greenery.Name = "Greenery"
	for _, angle in { 12, 50, 92, 136, 180, 224, 268, 325 } do
		local position = MapLayout.pointAt(angle, MapLayout.PLAZA_RADIUS - 3)
		Build.lamp(greenery, position + Vector3.new(0, TOP, 0))
	end
	for _, angle in { 92, 180, 268 } do
		local position = MapLayout.pointAt(angle, 30)
		cylinder({ Name = "Planter", Color = Color3.fromRGB(150, 145, 135), Material = Enum.Material.Cobblestone }, position + Vector3.new(0, TOP + 0.75, 0), 1.5, 9).Parent =
			greenery
		cylinder({ Name = "Soil", Color = Color3.fromRGB(90, 60, 40), Material = Enum.Material.Ground }, position + Vector3.new(0, TOP + 1.1, 0), 1.5, 7.5).Parent =
			greenery
		Build.tree(greenery, position + Vector3.new(0, TOP + 1.5, 0), 0.8)
	end
	greenery.Parent = parent
end

-- A wooden bridge from the plaza edge onto an island.
local function buildBridge(parent: Instance, island: MapLayout.Island)
	local from = MapLayout.pointAt(island.angle, MapLayout.PLAZA_RADIUS - 2)
	local to = MapLayout.pointAt(island.angle, island.radius - island.islandRadius + 6)
	Build.bridge(parent, "Bridge_" .. island.name, from, to, TOP)
end

local function buildPlaza()
	plaza = Instance.new("Model")
	plaza.Name = "Plaza"
	-- Always loaded on every client, like the plots, so the plaza floor and
	-- bridges are never missing underfoot.
	plaza.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

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

	buildFountain(plaza)
	buildGreenery(plaza)

	local shops = Instance.new("Folder")
	shops.Name = "Shops"
	shops.Parent = plaza
	for _, shop in SHOPS do
		local origin = MapLayout.facingCenter(MapLayout.SHOP_ANGLES[shop.key], MapLayout.SHOP_RING_RADIUS)
		buildStall(shop, origin).Parent = shops
	end

	local bridges = Instance.new("Folder")
	bridges.Name = "Bridges"
	bridges.Parent = plaza
	for _, island in MapLayout.islands() do
		buildBridge(bridges, island)
	end

	plaza.Parent = workspace
end

-- Bonuses (pets) set this; multiplies coins from selling crops.
Plaza.sellMultiplier = function(_player: Player): number
	return 1
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
	total = math.floor(total * Plaza.sellMultiplier(player) + 0.5)
	if total > 0 then
		PlayerData.addCoins(player, total)
		Notify.send(player, `Sold crops for {total} coins`, "success")
	else
		Notify.send(player, "You have no crops to sell. Harvest some first!", "error")
	end
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	if not prompt:IsDescendantOf(plaza) or not PlayerData.isLoaded(player) then
		return
	end
	if prompt.Name == "Sell" then
		sellAll(player)
	end
end

function Plaza.start()
	buildPlaza()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
end

return Plaza
