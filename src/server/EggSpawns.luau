-- Pet eggs are found in the wilderness, never dropped by monsters. Each
-- area keeps a few glowing eggs on random spots (clearings, near trees,
-- behind rocks, along paths, hidden areas). Collecting one removes it, and
-- a new egg appears on another spot a little later.
-- Rarity by distance from the area's entrance (proposed values):
--   near entrance      Common
--   forest interior    Common / Uncommon
--   deep wilderness    Uncommon / Rare
--   dangerous frontier Rare / Epic
--   hidden areas       Epic / Special
-- Each egg tier has its own look (see buildEgg).

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Pets = require(ReplicatedStorage.Shared.Pets)
local Build = require(script.Parent.Build)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)

local EGGS_PER_AREA = 8
local RESPAWN_MIN = 60
local RESPAWN_MAX = 120

-- Bands are fractions of the distance from the entrance to the far side.
local BANDS = {
	{ upTo = 0.25, eggs = { CommonEgg = 100 } },
	{ upTo = 0.5, eggs = { CommonEgg = 60, UncommonEgg = 40 } },
	{ upTo = 0.75, eggs = { UncommonEgg = 60, RareEgg = 40 } },
	{ upTo = math.huge, eggs = { RareEgg = 65, EpicEgg = 35 } },
}
local HIDDEN = { EpicEgg = 75, SpecialEgg = 25 }

export type Spot = { position: Vector3, hidden: boolean }

type Area = {
	name: string,
	folder: Folder,
	entrance: Vector3,
	reach: number,
	spots: { Spot },
	taken: { [Spot]: boolean },
}

local EggSpawns = {}

local areas: { Area } = {}

local function pick(weights: { [string]: number }): string
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = math.random() * total
	for egg, weight in weights do
		roll -= weight
		if roll <= 0 then
			return egg
		end
	end
	return "CommonEgg"
end

local function eggFor(area: Area, spot: Spot): string
	if spot.hidden then
		return pick(HIDDEN)
	end
	local distance = (Vector3.new(spot.position.X, 0, spot.position.Z) - Vector3.new(area.entrance.X, 0, area.entrance.Z)).Magnitude
	local fraction = distance / area.reach
	for _, band in BANDS do
		if fraction <= band.upTo then
			return pick(band.eggs)
		end
	end
	return "CommonEgg"
end

-- Builds an egg model on the ground at `position`, styled by tier, with a
-- little grass tuft underneath. Returns the model and its main egg part.
local function buildEgg(eggId: string, position: Vector3): (Model, BasePart)
	local model = Instance.new("Model")
	model.Name = "WildEgg"
	model:SetAttribute("EggId", eggId)
	local center = position + Vector3.new(0, 1.35, 0)
	local radius = Vector3.new(0.9, 1.15, 0.9)
	local random = Random.new()

	local function add(props: { [string]: any }): Part
		props.CanCollide = false
		local part = Build.part(props)
		part.Parent = model
		return part
	end
	-- A point on the egg's surface in direction `direction`.
	local function surface(direction: Vector3): Vector3
		local unit = direction.Unit
		return center + Vector3.new(unit.X * radius.X, unit.Y * radius.Y, unit.Z * radius.Z)
	end

	-- Grass tuft.
	add({
		Name = "Tuft",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 3.2, 3.2),
		CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(80, 160, 60),
		Material = Enum.Material.Grass,
	})
	for i = 1, 6 do
		local angle = i * math.pi / 3
		add({
			Name = "Leaf",
			Size = Vector3.new(0.3, 0.9, 0.6),
			CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * 1.3, 0.45, math.sin(angle) * 1.3))
				* CFrame.Angles(0, -angle, math.rad(25)),
			Color = Color3.fromRGB(70, 150, 55),
			Material = Enum.Material.Grass,
		})
	end

	local item = Items[eggId]
	local shell = add({
		Name = "Egg",
		Shape = Enum.PartType.Ball,
		Size = radius * 2,
		CFrame = CFrame.new(center),
		Color = item.color,
		Material = Enum.Material.SmoothPlastic,
	})

	if eggId == "CommonEgg" then
		-- Green spots.
		for i = 1, 9 do
			local direction = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-0.7, 0.9), random:NextNumber(-1, 1))
			add({
				Name = "Spot",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.55, 0.55, 0.55),
				CFrame = CFrame.new(surface(direction)),
				Color = Color3.fromRGB(110, 190, 80),
			})
		end
	elseif eggId == "UncommonEgg" then
		-- A white swirl spiraling around the shell.
		for i = 0, 13 do
			local angle = i * 0.75
			local height = -0.7 + i * 0.11
			add({
				Name = "Swirl",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.4, 0.4, 0.4),
				CFrame = CFrame.new(surface(Vector3.new(math.cos(angle), height, math.sin(angle)))),
				Color = Color3.fromRGB(235, 245, 255),
			})
		end
	elseif eggId == "RareEgg" then
		-- Glassy purple with gold bands and crystals around the base.
		shell.Material = Enum.Material.Glass
		for _, y in { -0.35, 0.25 } do
			add({
				Name = "GoldBand",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.18, radius.X * 2 * math.sqrt(1 - y * y) + 0.06, radius.X * 2 * math.sqrt(1 - y * y) + 0.06),
				CFrame = CFrame.new(center + Vector3.new(0, y * radius.Y, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(230, 180, 60),
				Material = Enum.Material.Metal,
			})
		end
		for i = 1, 5 do
			local angle = i * math.pi * 2 / 5
			add({
				Name = "Crystal",
				Size = Vector3.new(0.4, random:NextNumber(1, 1.8), 0.4),
				CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * 1.4, 0.6, math.sin(angle) * 1.4))
					* CFrame.Angles(math.rad(random:NextNumber(-25, 25)), angle, math.rad(random:NextNumber(-25, 25))),
				Color = Color3.fromRGB(170, 100, 255),
				Material = Enum.Material.Neon,
			})
		end
	elseif eggId == "EpicEgg" then
		-- Cracked lava rock: dark shell with glowing orange cracks.
		shell.Material = Enum.Material.Basalt
		for i = 1, 8 do
			local angle = i * math.pi / 4
			add({
				Name = "Crack",
				Size = Vector3.new(0.12, random:NextNumber(0.6, 1.2), 0.12),
				CFrame = CFrame.lookAt(surface(Vector3.new(math.cos(angle), random:NextNumber(-0.5, 0.6), math.sin(angle))), center)
					* CFrame.Angles(0, 0, math.rad(random:NextNumber(-40, 40))),
				Color = Color3.fromRGB(255, 140, 30),
				Material = Enum.Material.Neon,
			})
		end
		for i = 1, 4 do
			local angle = i * math.pi / 2 + 0.4
			add({
				Name = "Rock",
				Size = Vector3.new(0.9, 0.7, 0.8),
				CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * 1.3, 0.35, math.sin(angle) * 1.3))
					* CFrame.Angles(0, angle, math.rad(15)),
				Color = Color3.fromRGB(50, 40, 38),
				Material = Enum.Material.Basalt,
			})
		end
	elseif eggId == "SpecialEgg" then
		-- Iridescent shell with a ring of pastel crystals.
		shell.Material = Enum.Material.Glass
		shell.Transparency = 0.1
		local pastels = {
			Color3.fromRGB(255, 170, 200),
			Color3.fromRGB(170, 220, 255),
			Color3.fromRGB(200, 170, 255),
			Color3.fromRGB(170, 255, 210),
			Color3.fromRGB(255, 240, 170),
			Color3.fromRGB(150, 190, 255),
		}
		for i, color in pastels do
			local angle = i * math.pi * 2 / #pastels
			add({
				Name = "Crystal",
				Size = Vector3.new(0.45, 2, 0.45),
				CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * 1.5, 0.9, math.sin(angle) * 1.5))
					* CFrame.Angles(math.rad(math.cos(angle) * 25), 0, math.rad(-math.sin(angle) * 25)),
				Color = color,
				Material = Enum.Material.Neon,
				Transparency = 0.15,
			})
		end
	end

	local glowColor = Pets.eggGlow[eggId] or Color3.new(1, 1, 1)
	local light = Instance.new("PointLight")
	light.Color = glowColor
	light.Range = if eggId == "CommonEgg" then 8 else 12
	light.Brightness = if eggId == "CommonEgg" then 1 else 2
	light.Parent = shell
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = if eggId == "SpecialEgg"
		then ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 200)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 220, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 150)),
		})
		else ColorSequence.new(glowColor)
	sparkles.LightEmission = 1
	sparkles.Rate = if eggId == "CommonEgg" then 2 else 5
	sparkles.Lifetime = NumberRange.new(1, 1.5)
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.Size = NumberSequence.new(0.25)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = shell

	return model, shell
end

local function spawnEgg(area: Area)
	local free = {}
	for _, spot in area.spots do
		if not area.taken[spot] then
			table.insert(free, spot)
		end
	end
	if #free == 0 then
		return
	end
	local spot = free[math.random(1, #free)]
	area.taken[spot] = true
	local eggId = eggFor(area, spot)
	local model, shell = buildEgg(eggId, spot.position)

	local prompt = Build.prompt(shell, "Collect", Items[eggId].displayName)
	prompt.Name = "CollectEgg"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 8

	model.Destroying:Connect(function()
		area.taken[spot] = nil
	end)
	model.Parent = area.folder
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	if prompt.Name ~= "CollectEgg" or not PlayerData.isLoaded(player) then
		return
	end
	local shell = prompt.Parent
	local model = shell and shell.Parent
	local eggId = model and model:GetAttribute("EggId")
	if not model or type(eggId) ~= "string" or not Items[eggId] then
		return
	end
	for _, area in areas do
		if model.Parent == area.folder then
			model:Destroy()
			PlayerData.addItem(player, eggId, 1)
			Notify.send(player, `You found a {Items[eggId].displayName}! Hatch it from your Bag.`, "success")
			task.delay(math.random(RESPAWN_MIN, RESPAWN_MAX), spawnEgg, area)
			return
		end
	end
end

-- reach: distance from the entrance to the far side of the area.
function EggSpawns.registerArea(name: string, parent: Instance, entrance: Vector3, reach: number, spots: { Spot })
	local folder = Instance.new("Folder")
	folder.Name = name .. "Eggs"
	folder.Parent = parent
	local area: Area = {
		name = name,
		folder = folder,
		entrance = entrance,
		reach = reach,
		spots = spots,
		taken = {},
	}
	table.insert(areas, area)
	for _ = 1, EGGS_PER_AREA do
		spawnEgg(area)
	end
end

function EggSpawns.start()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
end

return EggSpawns
