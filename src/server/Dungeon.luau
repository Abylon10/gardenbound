-- The Abandoned Mine: a dungeon far below the map, entered through the
-- Dungeon Portal. Four rooms in a row joined by tunnels:
--   Entrance   safe; exit portal back to Spawn Island
--   Tunnels    cave bats, copper veins
--   Diggings   cave bats, skeleton miners, copper and iron veins
--   Golem Hall the Rock Golem boss, skeleton miners, iron veins
-- Ore veins: hold E to mine 1-2 ore; a mined vein regrows after a while.
-- Shared by everyone on the server (not instanced).

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Build = require(script.Parent.Build)
local Enemies = require(script.Parent.Enemies)
local MapLayout = require(script.Parent.MapLayout)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)
local Teleport = require(script.Parent.Teleport)

-- Floor level at the center of the entrance hall. Far from the islands
-- and well above the fall-death height (-500).
local ORIGIN = Vector3.new(1600, -300, 0)
local WALL_HEIGHT = 18
local DOOR_WIDTH = 12
local DOOR_HEIGHT = 12
local VEIN_REGROW = 45

local FLOOR = Color3.fromRGB(70, 65, 60)
local WALL = Color3.fromRGB(105, 85, 65)
local BEAM = Color3.fromRGB(90, 60, 35)

type Room = {
	name: string,
	x: number,
	size: number,
	population: { [string]: number }?,
	veins: { { ore: string, x: number, z: number } },
}

local ROOMS: { Room } = {
	{ name = "Entrance", x = 0, size = 36, population = nil, veins = {} },
	{
		name = "Tunnels",
		x = 64,
		size = 40,
		population = { CaveBat = 4 },
		veins = {
			{ ore = "CopperOre", x = -14, z = 16 },
			{ ore = "CopperOre", x = 10, z = -16 },
			{ ore = "CopperOre", x = 15, z = 15 },
		},
	},
	{
		name = "Diggings",
		x = 132,
		size = 44,
		population = { CaveBat = 2, SkeletonMiner = 3 },
		veins = {
			{ ore = "CopperOre", x = -16, z = -18 },
			{ ore = "CopperOre", x = 16, z = 18 },
			{ ore = "IronOre", x = -16, z = 18 },
			{ ore = "IronOre", x = 17, z = -18 },
		},
	},
	{
		name = "GolemHall",
		x = 214,
		size = 60,
		population = { RockGolem = 1, SkeletonMiner = 2 },
		veins = {
			{ ore = "IronOre", x = -24, z = -26 },
			{ ore = "IronOre", x = -24, z = 26 },
			{ ore = "IronOre", x = 26, z = -26 },
			{ ore = "IronOre", x = 26, z = 26 },
		},
	},
}

local Dungeon = {}

local mine: Model
local entranceCFrame: CFrame

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(ORIGIN + Vector3.new(x, y, z))
end

local function slab(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material)
	Build.part({
		Name = name,
		Size = size,
		CFrame = cframe,
		Color = color,
		Material = material,
	}).Parent = parent
end

local function torch(parent: Instance, position: Vector3)
	local head = Build.part({
		Name = "Torch",
		Size = Vector3.new(0.8, 1.6, 0.8),
		CFrame = CFrame.new(position),
		Color = BEAM,
		Material = Enum.Material.Wood,
	})
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 4
	fire.Parent = head
	local light = Instance.new("PointLight")
	light.Range = 26
	light.Brightness = 1.6
	light.Color = Color3.fromRGB(255, 170, 90)
	light.Parent = head
	head.Parent = parent
end

-- A wall running along X (north/south side) or Z (west/east side), with an
-- optional doorway in the middle.
local function wall(parent: Instance, center: Vector3, length: number, alongX: boolean, door: boolean)
	local thickness = 2
	local function segment(offset: number, segmentLength: number, height: number, y: number)
		local size = if alongX
			then Vector3.new(segmentLength, height, thickness)
			else Vector3.new(thickness, height, segmentLength)
		local position = if alongX then center + Vector3.new(offset, y, 0) else center + Vector3.new(0, y, offset)
		slab(parent, "Wall", size, CFrame.new(position), WALL, Enum.Material.Rock)
	end
	if not door then
		segment(0, length, WALL_HEIGHT, WALL_HEIGHT / 2)
		return
	end
	local side = (length - DOOR_WIDTH) / 2
	segment(-(DOOR_WIDTH / 2 + side / 2), side, WALL_HEIGHT, WALL_HEIGHT / 2)
	segment(DOOR_WIDTH / 2 + side / 2, side, WALL_HEIGHT, WALL_HEIGHT / 2)
	segment(0, DOOR_WIDTH, WALL_HEIGHT - DOOR_HEIGHT, DOOR_HEIGHT + (WALL_HEIGHT - DOOR_HEIGHT) / 2)
end

local function buildVein(parent: Instance, ore: string, position: Vector3)
	local item = Items[ore]
	local vein = Instance.new("Model")
	vein.Name = "Vein"
	local rock = Build.part({
		Name = "Rock",
		Size = Vector3.new(6, 5, 6),
		CFrame = CFrame.new(position + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, math.rad(30), 0),
		Color = Color3.fromRGB(95, 90, 85),
		Material = Enum.Material.Rock,
	})
	rock.Parent = vein
	for i = 1, 4 do
		local angle = i * math.pi / 2
		Build.part({
			Name = "Ore",
			Size = Vector3.new(1.4, 1.4, 1.4),
			CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * 2.8, 2 + (i % 2) * 1.5, math.sin(angle) * 2.8)),
			Color = item.color,
			Material = Enum.Material.Neon,
		}).Parent = vein
	end
	vein:SetAttribute("Ore", ore)
	local prompt = Build.prompt(rock, "Mine", `{item.displayName} vein`)
	prompt.Name = "MineVein"
	prompt.HoldDuration = 1.2
	vein.Parent = parent
end

local function buildRoom(parent: Instance, room: Room, index: number)
	local folder = Instance.new("Folder")
	folder.Name = room.name
	folder.Parent = parent
	local half = room.size / 2
	local cx = room.x

	slab(folder, "Floor", Vector3.new(room.size, 2, room.size), at(cx, -1, 0), FLOOR, Enum.Material.Slate)
	slab(folder, "Ceiling", Vector3.new(room.size, 2, room.size), at(cx, WALL_HEIGHT + 1, 0), WALL, Enum.Material.Rock)
	local center = ORIGIN + Vector3.new(cx, 0, 0)
	wall(folder, center + Vector3.new(0, 0, -half - 1), room.size + 4, true, false)
	wall(folder, center + Vector3.new(0, 0, half + 1), room.size + 4, true, false)
	wall(folder, center + Vector3.new(-half - 1, 0, 0), room.size, false, index > 1)
	wall(folder, center + Vector3.new(half + 1, 0, 0), room.size, false, index < #ROOMS)

	-- Support beams and torches in the corners.
	for _, cornerX in { -1, 1 } do
		for _, cornerZ in { -1, 1 } do
			local x = cx + cornerX * (half - 1.5)
			local z = cornerZ * (half - 1.5)
			slab(folder, "Beam", Vector3.new(1.5, WALL_HEIGHT, 1.5), at(x, WALL_HEIGHT / 2, z), BEAM, Enum.Material.Wood)
			torch(folder, ORIGIN + Vector3.new(x - cornerX * 1.2, 9, z - cornerZ * 1.2))
		end
	end

	for _, vein in room.veins do
		buildVein(folder, vein.ore, ORIGIN + Vector3.new(cx + vein.x, 0, vein.z))
	end

	-- Room name sign over the entry doorway.
	local signAnchor = Build.part({
		Name = "SignAnchor",
		Size = Vector3.new(1, 1, 1),
		CFrame = at(cx - half + 4, 14, 0),
		Transparency = 1,
		CanCollide = false,
	})
	Build.sign(signAnchor, room.name:gsub("(%l)(%u)", "%1 %2"), nil, 0)
	signAnchor.Parent = folder

	if room.population then
		Enemies.registerZone(room.name, ORIGIN + Vector3.new(cx, 0, 0), half - 5, ORIGIN.Y, room.population)
	end
end

local function buildTunnel(parent: Instance, fromX: number, toX: number)
	local length = toX - fromX
	local cx = (fromX + toX) / 2
	local folder = Instance.new("Folder")
	folder.Name = "Tunnel"
	folder.Parent = parent
	slab(folder, "Floor", Vector3.new(length + 2, 2, DOOR_WIDTH + 4), at(cx, -1, 0), FLOOR, Enum.Material.Slate)
	slab(folder, "Ceiling", Vector3.new(length + 2, 2, DOOR_WIDTH + 4), at(cx, DOOR_HEIGHT + 1, 0), WALL, Enum.Material.Rock)
	for _, side in { -1, 1 } do
		slab(
			folder,
			"Wall",
			Vector3.new(length + 2, DOOR_HEIGHT, 2),
			at(cx, DOOR_HEIGHT / 2, side * (DOOR_WIDTH / 2 + 1)),
			WALL,
			Enum.Material.Rock
		)
	end
	torch(folder, ORIGIN + Vector3.new(cx, 8, DOOR_WIDTH / 2 - 0.6))
end

local function buildMine()
	mine = Instance.new("Model")
	mine.Name = "AbandonedMine"
	-- Always loaded, so floors are there the moment a player teleports in.
	mine.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	for i, room in ROOMS do
		buildRoom(mine, room, i)
		local nextRoom = ROOMS[i + 1]
		if nextRoom then
			buildTunnel(mine, room.x + room.size / 2 + 2, nextRoom.x - nextRoom.size / 2 - 2)
		end
	end

	-- Exit portal on the entrance hall's west wall.
	local entrance = ROOMS[1]
	local portal = Build.part({
		Name = "ExitPortal",
		Size = Vector3.new(1, 12, 10),
		CFrame = at(entrance.x - entrance.size / 2 + 0.5, 6, 0),
		Color = Color3.fromRGB(150, 70, 230),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		CanCollide = false,
	})
	local glow = Instance.new("PointLight")
	glow.Range = 24
	glow.Color = Color3.fromRGB(170, 90, 255)
	glow.Parent = portal
	Build.prompt(portal, "Leave the mine", "Exit Portal").Name = "LeaveMine"
	portal.Parent = mine

	-- Players arrive facing into the mine (+X).
	entranceCFrame = CFrame.lookAt(
		ORIGIN + Vector3.new(entrance.x - entrance.size / 2 + 6, 4, 0),
		ORIGIN + Vector3.new(entrance.x + 10, 4, 0)
	)

	mine.Parent = workspace
end

local function mineVein(player: Player, vein: Instance, prompt: ProximityPrompt)
	if vein:GetAttribute("Depleted") then
		return
	end
	local ore = vein:GetAttribute("Ore")
	if type(ore) ~= "string" or not Items[ore] then
		return
	end
	local amount = math.random(1, 2)
	PlayerData.addItem(player, ore, amount)
	Notify.send(player, `+{amount} {Items[ore].displayName}`, "success")

	vein:SetAttribute("Depleted", true)
	prompt.Enabled = false
	for _, part in vein:GetChildren() do
		if part.Name == "Ore" and part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
	task.delay(VEIN_REGROW, function()
		vein:SetAttribute("Depleted", nil)
		prompt.Enabled = true
		for _, part in vein:GetChildren() do
			if part.Name == "Ore" and part:IsA("BasePart") then
				part.Transparency = 0
			end
		end
	end)
end

-- Where players land when they leave: in front of the Dungeon Portal arch,
-- facing the plaza.
local function portalReturnCFrame(): CFrame
	local landmark = MapLayout.LANDMARKS.DungeonPortal
	return MapLayout.facingCenter(landmark.angle, landmark.radius) * CFrame.new(0, MapLayout.GROUND_TOP + 4, -14)
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	if prompt.Name == "EnterMine" then
		Teleport.to(player, entranceCFrame)
		Notify.send(player, "Welcome to the Abandoned Mine. Watch out for the Rock Golem!", "info")
	elseif prompt.Name == "LeaveMine" and prompt:IsDescendantOf(mine) then
		Teleport.to(player, portalReturnCFrame())
	elseif prompt.Name == "MineVein" and prompt:IsDescendantOf(mine) and PlayerData.isLoaded(player) then
		local vein = prompt.Parent and prompt.Parent.Parent
		if vein then
			mineVein(player, vein, prompt)
		end
	end
end

function Dungeon.start()
	buildMine()

	-- Make the Dungeon Portal's gateway an entrance.
	local landmarks = workspace:WaitForChild("Landmarks")
	local gateway = landmarks:WaitForChild("DungeonPortal"):WaitForChild("Gateway") :: BasePart
	local enter = Build.prompt(gateway, "Enter the Abandoned Mine", "Dungeon Portal")
	enter.Name = "EnterMine"
	enter.MaxActivationDistance = 14

	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
end

return Dungeon
