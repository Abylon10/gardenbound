-- Docks at the water with stairs up the island cliffs (see
-- MapLayout.docks), so players who fall into the sea can climb back.

local Build = require(script.Parent.Build)
local MapLayout = require(script.Parent.MapLayout)

local Coast = {}

function Coast.build()
	local docks = Instance.new("Model")
	docks.Name = "Docks"
	-- Always loaded, so the stairs are there wherever a player swims to.
	docks.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	for _, dock in MapLayout.docks() do
		Build.dock(
			docks,
			dock.name,
			dock.center,
			dock.islandRadius,
			dock.bearing,
			dock.side,
			MapLayout.GROUND_TOP,
			MapLayout.WATER_LEVEL
		)
	end
	docks.Parent = workspace
end

-- Uses the docks saved in the place if there are any.
function Coast.start()
	if not workspace:FindFirstChild("Docks") then
		Coast.build()
	end
end

return Coast
