-- Pet eggs are found in the wilderness, never dropped by monsters. Each
-- area keeps a few glowing eggs on random spots (beside trees, behind
-- rocks, in clearings). Collecting one removes it, and a new egg appears
-- on another spot a little later.
-- Rarity depends on distance from the area's entrance:
--   near   Common
--   middle Common or Forest
--   far    Common, Forest, or Ancient
-- Hidden spots (behind rocks) count as one band further out.
-- Proposed values for balancing.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Pets = require(ReplicatedStorage.Shared.Pets)
local Build = require(script.Parent.Build)
local Notify = require(script.Parent.Notify)
local PlayerData = require(script.Parent.PlayerData)

local EGGS_PER_AREA = 6
local RESPAWN_MIN = 60
local RESPAWN_MAX = 120

-- Egg weights per band. Bands are fractions of the distance from the
-- entrance to the far side of the area.
local BANDS = {
	{ upTo = 0.3, eggs = { CommonEgg = 100 } },
	{ upTo = 0.65, eggs = { CommonEgg = 60, ForestEgg = 40 } },
	{ upTo = math.huge, eggs = { CommonEgg = 30, ForestEgg = 50, AncientEgg = 20 } },
}
-- Hidden spots past the last band.
local HIDDEN_FAR = { ForestEgg = 50, AncientEgg = 50 }

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
	local distance = (Vector3.new(spot.position.X, 0, spot.position.Z) - Vector3.new(area.entrance.X, 0, area.entrance.Z)).Magnitude
	local fraction = distance / area.reach
	local band = #BANDS
	for i, entry in BANDS do
		if fraction <= entry.upTo then
			band = i
			break
		end
	end
	if spot.hidden then
		if band >= #BANDS then
			return pick(HIDDEN_FAR)
		end
		band += 1
	end
	return pick(BANDS[band].eggs)
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
	local item = Items[eggId]
	local glowColor = Pets.eggGlow[eggId] or Color3.new(1, 1, 1)

	local egg = Build.part({
		Name = "WildEgg",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.8, 2.3, 1.8),
		CFrame = CFrame.new(spot.position + Vector3.new(0, 1.15, 0)),
		Color = item.color,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
	egg:SetAttribute("EggId", eggId)
	local light = Instance.new("PointLight")
	light.Color = glowColor
	light.Range = 10
	light.Brightness = 1.5
	light.Parent = egg
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(glowColor)
	sparkles.LightEmission = 1
	sparkles.Rate = 4
	sparkles.Lifetime = NumberRange.new(1, 1.5)
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.Size = NumberSequence.new(0.25)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = egg

	local prompt = Build.prompt(egg, "Collect", item.displayName)
	prompt.Name = "CollectEgg"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 8

	egg.Destroying:Connect(function()
		area.taken[spot] = nil
	end)
	egg.Parent = area.folder
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	if prompt.Name ~= "CollectEgg" or not PlayerData.isLoaded(player) then
		return
	end
	local egg = prompt.Parent
	local eggId = egg and egg:GetAttribute("EggId")
	if not egg or type(eggId) ~= "string" or not Items[eggId] then
		return
	end
	for _, area in areas do
		if egg.Parent == area.folder then
			egg:Destroy()
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
