-- Hatching eggs, equipping pets, and the pets that follow you around.
-- Remotes: HatchEgg(eggItemId), EquipPet(petId) (toggles; one farm pet
-- and one battle pet at a time). Publishes the "Pets" and "EquippedPets"
-- attributes as JSON for the client Bag.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Pets = require(ReplicatedStorage.Shared.Pets)
local PetModels = require(script.Parent.PetModels)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)

local FOLLOW_OFFSETS = {
	farm = Vector3.new(-3.5, 1.5, 2.5),
	battle = Vector3.new(3.5, 1.5, 2.5),
}

local PetSystem = {}

local hatchedRemote = Remotes.event("Hatched")

local function rollPet(eggId: string): string?
	local weights = Pets.eggs[eggId]
	if not weights then
		return nil
	end
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = math.random() * total
	for kind, weight in weights do
		roll -= weight
		if roll <= 0 then
			return kind
		end
	end
	return nil
end

local function findPet(data: PlayerData.Data, petId: number): PlayerData.Pet?
	for _, pet in data.pets do
		if pet.id == petId then
			return pet
		end
	end
	return nil
end

local function buildFollower(character: Model, kind: string, slot: string)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local def = Pets.list[kind]
	if not root or not def then
		return
	end
	local folder = character:FindFirstChild("Pets")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Pets"
		folder.Parent = character
	end

	-- Invisible root that the align constraints move; the visible parts
	-- are welded to it (see PetModels).
	local body = Instance.new("Part")
	body.Name = "Pet_" .. slot
	body.Size = Vector3.new(1, 1, 1)
	body.Transparency = 1
	body.CanCollide = false
	body.CanQuery = false
	body.Massless = true
	local offset = FOLLOW_OFFSETS[slot] + Vector3.new(0, PetModels.HEIGHT[kind] or 0, 0)
	body.CFrame = root.CFrame * CFrame.new(offset)
	PetModels.build(body, kind, def.color)

	local petAttachment = Instance.new("Attachment")
	petAttachment.Parent = body
	local anchorName = `PetSlot_{slot}_{kind}`
	local anchor = root:FindFirstChild(anchorName) :: Attachment?
	if not anchor then
		local created = Instance.new("Attachment")
		created.Name = anchorName
		created.Position = offset
		created.Parent = root
		anchor = created
	end
	local align = Instance.new("AlignPosition")
	align.Attachment0 = petAttachment
	align.Attachment1 = anchor
	align.Responsiveness = 15
	align.MaxForce = 100000
	align.Parent = body
	local orient = Instance.new("AlignOrientation")
	orient.Attachment0 = petAttachment
	orient.Attachment1 = anchor
	orient.Responsiveness = 15
	orient.MaxTorque = 100000
	orient.Parent = body

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(90, 20)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.MaxDistance = 50
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Pets.rarityColors[def.rarity] or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = def.displayName
	label.Parent = billboard
	billboard.Parent = body

	body.Parent = folder
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		pcall(function()
			body:SetNetworkOwner(player)
		end)
	end
end

local function refreshFollowers(player: Player)
	local character = player.Character
	local data = PlayerData.get(player)
	if not character or not data then
		return
	end
	local folder = character:FindFirstChild("Pets")
	if folder then
		folder:ClearAllChildren()
	end
	for slot, petId in { farm = data.equippedPets.farm, battle = data.equippedPets.battle } do
		local pet = if petId then findPet(data, petId) else nil
		if pet then
			buildFollower(character, pet.kind, slot)
		end
	end
end

local function hatch(player: Player, eggId: unknown)
	if type(eggId) ~= "string" then
		return
	end
	local item = Items[eggId]
	local data = PlayerData.get(player)
	if not item or item.kind ~= "egg" or not data then
		return
	end
	local kind = rollPet(eggId)
	if not kind or not PlayerData.takeItem(player, eggId, 1) then
		return
	end
	table.insert(data.pets, { id = data.nextPetId, kind = kind })
	data.nextPetId += 1
	PlayerData.changed(player)
	-- The client plays the hatch reveal and says what came out.
	hatchedRemote:FireClient(player, eggId, kind)
end

local function equip(player: Player, petId: unknown)
	local data = PlayerData.get(player)
	if type(petId) ~= "number" or not data then
		return
	end
	local pet = findPet(data, petId)
	local def = if pet then Pets.list[pet.kind] else nil
	if not pet or not def then
		return
	end
	local slot = def.type :: "farm" | "battle"
	if data.equippedPets[slot] == petId then
		data.equippedPets[slot] = nil
	else
		data.equippedPets[slot] = petId
	end
	PlayerData.changed(player)
	refreshFollowers(player)
end

local function publish(player: Player, data: PlayerData.Data)
	player:SetAttribute("Pets", HttpService:JSONEncode(data.pets))
	player:SetAttribute(
		"EquippedPets",
		HttpService:JSONEncode({ farm = data.equippedPets.farm or 0, battle = data.equippedPets.battle or 0 })
	)
end

function PetSystem.start()
	Remotes.event("HatchEgg").OnServerEvent:Connect(hatch)
	Remotes.event("EquipPet").OnServerEvent:Connect(equip)
	PlayerData.onSync(publish)

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			refreshFollowers(player)
		end)
		if player.Character then
			task.spawn(refreshFollowers, player)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return PetSystem
