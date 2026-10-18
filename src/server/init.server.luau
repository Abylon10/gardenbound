-- Server entry point. Each system is a ModuleScript next to this one.

local PlayerData = require(script.PlayerData)
local Plots = require(script.Plots)
local Farming = require(script.Farming)
local Plaza = require(script.Plaza)

Farming.start()
PlayerData.start()
Plots.start()
Plaza.start()

print("Gardenbound server started")
