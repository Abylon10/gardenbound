-- Server entry point. Each system is a ModuleScript next to this one.

local PlayerData = require(script.PlayerData)
local Plots = require(script.Plots)
local Farming = require(script.Farming)

Farming.start()
PlayerData.start()
Plots.start()

print("Gardenbound server started")
