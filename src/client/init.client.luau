-- Client entry point. Each UI/system is a ModuleScript next to this one.

local Inventory = require(script.Inventory)
local PlotPrompts = require(script.PlotPrompts)
local SeedBar = require(script.SeedBar)
local ShopMenu = require(script.ShopMenu)
local Toasts = require(script.Toasts)

for _, system in { Toasts, PlotPrompts, SeedBar, ShopMenu, Inventory } do
	task.spawn(system.start)
end

print("Gardenbound client started")
