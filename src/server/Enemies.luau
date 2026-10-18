-- Server-side enemies. Each zone (registered with Enemies.registerZone)
-- keeps a population of each enemy type alive inside a circle. Enemies are
-- anchored models moved by the server: they wander, chase the nearest
-- player in range, and attack when close. They never leave their zone.
-- Combat calls Enemies.damage; kills are reported through onKilled.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EnemyTypes = require(ReplicatedStorage.Shared.EnemyTypes)
local Build = require(script.Parent.Build)

local TICK = 1 / 15
local RESPAWN_DELAY = 10
local ATTACK_REACH = 3

export type Zone = {
	name: string,
	center: Vector3,
	radius: number,
	groundY: number,
	population: { [string]: number },
	folder: Folder,
}

export type Enemy = {
	kind: string,
	model: Model,
	health: number,
	maxHealth: number,
	zone: Zone,
	position: Vector3,
	-- Height of the model's pivot (its body center) above the ground.
	pivotHeight: number,
	facing: Vector3,
	wanderTarget: Vector3,
	nextWander: number,
	nextAttack: number,
	dead: boolean,
}

local Enemies = {}

local enemies: { Enemy } = {}
local killedCallbacks: { (Player, string, Vector3) -> () } = {}

-- Hook: how much damage a player actually takes (armor, potions).
Enemies.damageTaken = function(_player: Player, amount: number): number
	return amount
end

function Enemies.onKilled(callback: (killer: Player, kind: string, position: Vector3) -> ())
	table.insert(killedCallbacks, callback)
end

local function randomPointIn(zone: Zone): Vector3
	local angle = math.random() * math.pi * 2
	local distance = math.sqrt(math.random()) * zone.radius * 0.85
	return zone.center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

-- Builds the model at the origin; the server moves it with PivotTo.
local function buildModel(kind: string): Model
	local def = EnemyTypes[kind]
	local model = Instance.new("Model")
	model.Name = kind
	local size = def.size
	local function add(name: string, props: { [string]: any }): Part
		props.Name = name
		props.CanCollide = false
		local part = Build.part(props)
		part.Parent = model
		return part
	end

	local body: Part
	if def.shape == "slime" then
		body = add("Body", {
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size * 0.8, size),
			CFrame = CFrame.new(0, size * 0.4, 0),
			Color = def.color,
			Material = Enum.Material.Glass,
			Transparency = 0.2,
		})
	elseif def.shape == "rabbit" then
		body = add("Body", {
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size * 0.8, size * 0.7, size),
			CFrame = CFrame.new(0, size * 0.35, 0),
			Color = def.color,
			Material = Enum.Material.Fabric,
		})
		for _, x in { -0.25, 0.25 } do
			add("Ear", {
				Size = Vector3.new(size * 0.15, size * 0.5, size * 0.1),
				CFrame = CFrame.new(x * size, size * 0.9, -size * 0.25),
				Color = def.color,
				Material = Enum.Material.Fabric,
			})
		end
	else
		body = add("Body", {
			Size = Vector3.new(size * 0.6, size * 0.6, size * 0.4),
			CFrame = CFrame.new(0, size * 0.45, 0),
			Color = Color3.fromRGB(120, 85, 50),
			Material = Enum.Material.Fabric,
		})
		add("Head", {
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size * 0.45, size * 0.45, size * 0.45),
			CFrame = CFrame.new(0, size * 0.95, 0),
			Color = def.color,
			Material = Enum.Material.SmoothPlastic,
		})
		add("Club", {
			Size = Vector3.new(size * 0.12, size * 0.6, size * 0.12),
			CFrame = CFrame.new(size * 0.4, size * 0.5, -size * 0.15) * CFrame.Angles(math.rad(-30), 0, 0),
			Color = Color3.fromRGB(90, 60, 35),
			Material = Enum.Material.Wood,
		})
	end
	-- Two eyes on the front (-Z).
	for _, x in { -0.18, 0.18 } do
		add("Eye", {
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size * 0.14, size * 0.14, size * 0.14),
			CFrame = CFrame.new(x * size, body.Position.Y + size * 0.1, -body.Size.Z / 2),
			Color = Color3.fromRGB(20, 20, 20),
			Material = Enum.Material.SmoothPlastic,
		})
	end
	-- All parts are anchored; PivotTo moves them together around the body.
	model.PrimaryPart = body

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromOffset(110, 30)
	billboard.StudsOffset = Vector3.new(0, size * 0.8 + 1, 0)
	billboard.MaxDistance = 80
	billboard.Parent = body
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0.55, 0)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.4
	name.Text = def.displayName
	name.Parent = billboard
	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Position = UDim2.fromScale(0, 0.62)
	back.Size = UDim2.fromScale(1, 0.3)
	back.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	back.BorderSizePixel = 0
	back.Parent = billboard
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	fill.BorderSizePixel = 0
	fill.Parent = back

	return model
end

local function placeModel(enemy: Enemy, now: number)
	local def = EnemyTypes[enemy.kind]
	local hop = if def.shape == "slime" or def.shape == "rabbit" then math.abs(math.sin(now * 6)) * def.size * 0.25 else 0
	local position = Vector3.new(enemy.position.X, enemy.zone.groundY + enemy.pivotHeight + hop, enemy.position.Z)
	local facing = Vector3.new(enemy.facing.X, 0, enemy.facing.Z)
	if facing.Magnitude < 0.01 then
		facing = Vector3.new(0, 0, -1)
	end
	enemy.model:PivotTo(CFrame.lookAt(position, position + facing))
end

local function spawnEnemy(zone: Zone, kind: string)
	local def = EnemyTypes[kind]
	local model = buildModel(kind)
	local position = randomPointIn(zone)
	local enemy: Enemy = {
		kind = kind,
		model = model,
		health = def.health,
		maxHealth = def.health,
		zone = zone,
		position = position,
		pivotHeight = (model.PrimaryPart :: BasePart).Position.Y,
		facing = Vector3.new(0, 0, -1),
		wanderTarget = position,
		nextWander = 0,
		nextAttack = 0,
		dead = false,
	}
	placeModel(enemy, os.clock())
	model.Parent = zone.folder
	table.insert(enemies, enemy)
end

local function nearestTarget(enemy: Enemy): (Humanoid?, BasePart?)
	local def = EnemyTypes[enemy.kind]
	local bestDistance = def.aggroRange
	local bestHumanoid, bestRoot = nil, nil
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and root and humanoid.Health > 0 then
			-- Only chase players who are inside this zone.
			local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
			local inZone = (flat - Vector3.new(enemy.zone.center.X, 0, enemy.zone.center.Z)).Magnitude <= enemy.zone.radius
			local distance = (flat - Vector3.new(enemy.position.X, 0, enemy.position.Z)).Magnitude
			if inZone and distance < bestDistance then
				bestDistance = distance
				bestHumanoid, bestRoot = humanoid, root
			end
		end
	end
	return bestHumanoid, bestRoot
end

local function moveToward(enemy: Enemy, target: Vector3, speed: number, dt: number)
	local flatTarget = Vector3.new(target.X, enemy.position.Y, target.Z)
	local offset = flatTarget - enemy.position
	local distance = offset.Magnitude
	if distance < 0.1 then
		return
	end
	local step = math.min(distance, speed * dt)
	local nextPosition = enemy.position + offset.Unit * step
	-- Stay inside the zone.
	local fromCenter = Vector3.new(nextPosition.X - enemy.zone.center.X, 0, nextPosition.Z - enemy.zone.center.Z)
	if fromCenter.Magnitude > enemy.zone.radius then
		nextPosition = enemy.zone.center + fromCenter.Unit * enemy.zone.radius
		nextPosition = Vector3.new(nextPosition.X, enemy.position.Y, nextPosition.Z)
	end
	enemy.facing = offset.Unit
	enemy.position = nextPosition
end

local function update(dt: number)
	local now = os.clock()
	for _, enemy in enemies do
		if enemy.dead then
			continue
		end
		local def = EnemyTypes[enemy.kind]
		local humanoid, root = nearestTarget(enemy)
		if humanoid and root then
			local distance = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(enemy.position.X, 0, enemy.position.Z)).Magnitude
			local reach = def.size / 2 + ATTACK_REACH
			if distance > reach then
				moveToward(enemy, root.Position, def.speed, dt)
			else
				enemy.facing = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(enemy.position.X, 0, enemy.position.Z)).Unit
				if now >= enemy.nextAttack then
					enemy.nextAttack = now + def.attackCooldown
					local player = Players:GetPlayerFromCharacter(humanoid.Parent)
					local amount = if player then Enemies.damageTaken(player, def.damage) else def.damage
					humanoid:TakeDamage(amount)
				end
			end
		else
			if now >= enemy.nextWander then
				enemy.nextWander = now + 3 + math.random() * 4
				enemy.wanderTarget = randomPointIn(enemy.zone)
			end
			moveToward(enemy, enemy.wanderTarget, def.speed * 0.4, dt)
		end
		placeModel(enemy, now)
	end
end

-- Enemies whose position is within range of a point.
function Enemies.findInRange(position: Vector3, range: number): { Enemy }
	local found = {}
	for _, enemy in enemies do
		if not enemy.dead then
			local flat = Vector3.new(enemy.position.X - position.X, 0, enemy.position.Z - position.Z)
			if flat.Magnitude <= range + EnemyTypes[enemy.kind].size / 2 then
				table.insert(found, enemy)
			end
		end
	end
	return found
end

-- Deals damage. Returns true if this hit killed the enemy.
function Enemies.damage(enemy: Enemy, amount: number, attacker: Player): boolean
	if enemy.dead then
		return false
	end
	enemy.health -= amount
	local body = enemy.model.PrimaryPart
	local bar = body and body:FindFirstChild("HealthBar")
	if bar then
		local fill = (bar :: any).Back.Fill :: Frame
		fill.Size = UDim2.fromScale(math.max(0, enemy.health / enemy.maxHealth), 1)
	end
	if enemy.health > 0 then
		return false
	end

	enemy.dead = true
	local position = enemy.position
	enemy.model:Destroy()
	local index = table.find(enemies, enemy)
	if index then
		table.remove(enemies, index)
	end
	for _, callback in killedCallbacks do
		task.spawn(callback, attacker, enemy.kind, position)
	end
	task.delay(RESPAWN_DELAY, spawnEnemy, enemy.zone, enemy.kind)
	return true
end

function Enemies.registerZone(name: string, center: Vector3, radius: number, groundY: number, population: { [string]: number })
	local folder = Instance.new("Folder")
	folder.Name = name .. "Enemies"
	folder.Parent = workspace
	local zone: Zone = {
		name = name,
		center = Vector3.new(center.X, groundY, center.Z),
		radius = radius,
		groundY = groundY,
		population = population,
		folder = folder,
	}
	for kind, count in population do
		for _ = 1, count do
			spawnEnemy(zone, kind)
		end
	end
end

function Enemies.start()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= TICK then
			update(elapsed)
			elapsed = 0
		end
	end)
end

return Enemies
