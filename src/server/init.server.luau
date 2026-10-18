-- Server entry point. Each system is a ModuleScript next to this one.

local Islands = require(script.Islands)
local PlayerData = require(script.PlayerData)
local Plots = require(script.Plots)
local Farming = require(script.Farming)
local Plaza = require(script.Plaza)
local Landmarks = require(script.Landmarks)
local Spawning = require(script.Spawning)
local Shops = require(script.Shops)
local Homestead = require(script.Homestead)
local Forestry = require(script.Forestry)

-- Terrain first, so everything else is built on finished islands.
Islands.start()
Farming.start()
PlayerData.start()
Plots.start()
Plaza.start()
Landmarks.start()
Shops.start()
Homestead.start()
Forestry.start()
-- Last: characters only spawn once the map and plots exist.
Spawning.start()

print("Gardenbound server started")
