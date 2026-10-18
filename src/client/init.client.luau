-- Client entry point. Each UI/system is a ModuleScript next to this one.

local PlotPrompts = require(script.PlotPrompts)
local SeedBar = require(script.SeedBar)

task.spawn(PlotPrompts.start)
SeedBar.start()

print("Gardenbound client started")
