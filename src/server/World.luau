-- Bakes the static world into the place file, so it can be seen and
-- edited in Studio without pressing Play.
--
-- In Studio (edit mode, not playing), open View > Command Bar and run:
--   require(game.ServerScriptService.Server.World).bake()
-- then save the place (File > Save to Roblox). After that the game uses
-- the saved map: terrain, lighting, plaza, plots, docks, landmarks, the
-- Meadow (with its EggSpot markers), the mine, and the NPCs. Anything you
-- delete is rebuilt by code when the game starts.
--
-- To start over from the code's version:
--   require(game.ServerScriptService.Server.World).clear()
-- This also erases ALL terrain.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Atmosphere = require(script.Parent.Atmosphere)
local Coast = require(script.Parent.Coast)
local Dungeon = require(script.Parent.Dungeon)
local Islands = require(script.Parent.Islands)
local Landmarks = require(script.Parent.Landmarks)
local NPCs = require(script.Parent.NPCs)
local Plaza = require(script.Parent.Plaza)
local Plots = require(script.Parent.Plots)
local Wilderness = require(script.Parent.Wilderness)

local BAKED_ATTRIBUTE = "GardenboundBaked"
local BAKED_MODELS = { "Docks", "Plots", "Plaza", "Landmarks", "AbandonedMine", "Wilderness", "NPCs" }

local World = {}

function World.isBaked(): boolean
	return workspace:GetAttribute(BAKED_ATTRIBUTE) == true
end

-- Removes the baked map and all terrain.
function World.clear()
	assert(not RunService:IsRunning(), "Stop the game first. World.clear runs in edit mode.")
	for _, name in BAKED_MODELS do
		local existing = workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
	workspace.Terrain:Clear()
	workspace:SetAttribute(BAKED_ATTRIBUTE, nil)
	print("[World] Cleared the baked map.")
end

-- Builds the whole static world into the place. Replaces any earlier bake.
function World.bake()
	assert(not RunService:IsRunning(), "Stop the game first. World.bake runs in edit mode.")
	-- Requiring the game modules may create the Remotes folder; it's made at
	-- runtime anyway, so don't leave one saved in the place.
	local hadRemotes = ReplicatedStorage:FindFirstChild("Remotes") ~= nil

	World.clear()
	Atmosphere.build()
	Islands.build()
	Coast.build()
	Plots.build()
	Plaza.build()
	Landmarks.build()
	Dungeon.build()
	Wilderness.build()
	NPCs.build()
	workspace:SetAttribute(BAKED_ATTRIBUTE, true)

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes and not hadRemotes then
		remotes:Destroy()
	end
	print("[World] Map baked. Save the place now (File > Save to Roblox).")
end

return World
