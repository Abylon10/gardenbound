-- Client entry point. Each UI/system is a ModuleScript next to this one.

local BrewMenu = require(script.BrewMenu)
local ForgeMenu = require(script.ForgeMenu)
local GearUI = require(script.GearUI)
local Inventory = require(script.Inventory)
local PetsUI = require(script.PetsUI)
local PlotPrompts = require(script.PlotPrompts)
local SeedBar = require(script.SeedBar)
local ShopMenu = require(script.ShopMenu)
local Toasts = require(script.Toasts)
local TravelButtons = require(script.TravelButtons)

for _, system in { Toasts, PlotPrompts, SeedBar, ShopMenu, Inventory, PetsUI, GearUI, ForgeMenu, BrewMenu, TravelButtons } do
	task.spawn(system.start)
end

print("Gardenbound client started")
