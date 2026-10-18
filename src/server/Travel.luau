-- Teleport buttons. TravelTo("Plaza") puts you on the plaza at the start
-- of your garden's bridge; TravelTo("Garden") puts you at the island end of
-- that bridge. Works from anywhere (including the mine), with a short
-- cooldown.

local MapLayout = require(script.Parent.MapLayout)
local Plots = require(script.Parent.Plots)
local Remotes = require(script.Parent.Remotes)
local Teleport = require(script.Parent.Teleport)

local COOLDOWN = 3

local Travel = {}

local lastTravel: { [Player]: number } = {}

local function destination(player: Player, place: string): CFrame?
	local plot = Plots.getPlot(player)
	local angle = if plot then Plots.angle(plot) else 180
	if place == "Plaza" then
		-- Just inside the plaza edge, facing the fountain.
		local position = MapLayout.pointAt(angle, MapLayout.PLAZA_RADIUS - 8) + Vector3.new(0, MapLayout.PLAZA_TOP + 3, 0)
		return CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
	elseif place == "Garden" and plot then
		-- The island end of the bridge, facing the island.
		local islandCenter = MapLayout.pointAt(angle, MapLayout.PLOT_RING_RADIUS)
		local position = MapLayout.pointAt(angle, MapLayout.PLOT_RING_RADIUS - MapLayout.PLOT_ISLAND_RADIUS + 10)
			+ Vector3.new(0, MapLayout.GROUND_TOP + 3, 0)
		return CFrame.lookAt(position, Vector3.new(islandCenter.X, position.Y, islandCenter.Z))
	end
	return nil
end

function Travel.start()
	Remotes.event("TravelTo").OnServerEvent:Connect(function(player, place)
		if type(place) ~= "string" then
			return
		end
		local now = os.clock()
		if (lastTravel[player] or 0) + COOLDOWN > now then
			return
		end
		local target = destination(player, place)
		if target then
			lastTravel[player] = now
			Teleport.to(player, target)
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastTravel[player] = nil
	end)
end

return Travel
