-- Controls when and where characters spawn. Characters don't auto-load:
-- while the loading screen is up, the server streams the player's home
-- island to them (ReplicationFocus on their spawn point). When the client
-- has ground under its spawn point it fires ClientReady, and only then is
-- the character created and moved home. Respawns after death go home too.

local Players = game:GetService("Players")

local Plots = require(script.Parent.Plots)
local Remotes = require(script.Parent.Remotes)

-- Spawn anyway if a client never reports ready (e.g. a broken loader).
local READY_TIMEOUT = 45
local PLOT_WAIT = 10

local Spawning = {}

local spawned: { [Player]: boolean } = {}

local function spawnCharacter(player: Player)
	if player.Parent == Players then
		player:LoadCharacter()
	end
end

local function spawnOnce(player: Player)
	if spawned[player] then
		return
	end
	spawned[player] = true
	spawnCharacter(player)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid then
		humanoid.Died:Connect(function()
			task.wait(Players.RespawnTime)
			if player.Character == character then
				spawnCharacter(player)
			end
		end)
	end

	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local spawnPoint = Plots.getSpawnPoint(player)
	if root and spawnPoint then
		-- Hold still while moving home so the character can't drop through
		-- ground that hasn't reached the client yet.
		root.Anchored = true
		-- Wait a frame so the default spawn placement doesn't override this.
		task.wait()
		character:PivotTo(spawnPoint.CFrame)
		pcall(function()
			player:RequestStreamAroundAsync(spawnPoint.Position, 10)
		end)
		task.wait(0.3)
		if root.Parent then
			root.Anchored = false
		end
	end
	-- From now on, stream around the character as normal.
	player.ReplicationFocus = nil
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	-- Plots claims a plot on PlayerAdded as well; wait for it.
	local deadline = os.clock() + PLOT_WAIT
	while not Plots.getSpawnPoint(player) and os.clock() < deadline and player.Parent do
		task.wait(0.1)
	end
	local spawnPoint = Plots.getSpawnPoint(player)
	if spawnPoint then
		player.ReplicationFocus = spawnPoint
		player:SetAttribute("HomeSpawn", spawnPoint.Position)
	else
		-- No plot: let the loading screen finish and spawn at the plaza.
		player:SetAttribute("HomeSpawn", Vector3.new(0, 5, 0))
	end

	-- In Studio the player can join before this script runs, in which case
	-- a character was already auto-loaded. Move it home.
	if player.Character then
		spawned[player] = true
		task.spawn(onCharacterAdded, player, player.Character)
	end

	task.delay(READY_TIMEOUT, function()
		spawnOnce(player)
	end)
end

function Spawning.start()
	Players.CharacterAutoLoads = false

	local clientReady = Remotes.event("ClientReady")
	clientReady.OnServerEvent:Connect(spawnOnce)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		spawned[player] = nil
	end)
end

return Spawning
