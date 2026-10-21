-- The look of Spawn Island: a bright sunny afternoon, light haze, vivid
-- colors, turquoise water, lush grass, and grey cliffs. Based on the map
-- art.

local Lighting = game:GetService("Lighting")

local Atmosphere = {}

local function replace(className: string, name: string): Instance
	for _, child in Lighting:GetChildren() do
		if child.ClassName == className then
			child:Destroy()
		end
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = Lighting
	return instance
end

function Atmosphere.build()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(95, 100, 115)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 215)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true

	local air = replace("Atmosphere", "IslandAir") :: Atmosphere
	air.Density = 0.25
	air.Offset = 0.15
	air.Color = Color3.fromRGB(200, 225, 240)
	air.Decay = Color3.fromRGB(110, 150, 185)
	air.Glare = 0.25
	air.Haze = 1.1

	local sky = replace("Sky", "IslandSky") :: Sky
	sky.SunAngularSize = 14
	sky.MoonAngularSize = 8

	local color = replace("ColorCorrectionEffect", "IslandColor") :: ColorCorrectionEffect
	color.Saturation = 0.2
	color.Contrast = 0.08
	color.Brightness = 0.02
	color.TintColor = Color3.fromRGB(255, 250, 240)

	local bloom = replace("BloomEffect", "IslandBloom") :: BloomEffect
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.7

	local rays = replace("SunRaysEffect", "IslandSunRays") :: SunRaysEffect
	rays.Intensity = 0.05
	rays.Spread = 0.6

	local terrain = workspace.Terrain
	terrain.WaterColor = Color3.fromRGB(35, 165, 195)
	terrain.WaterTransparency = 0.45
	terrain.WaterReflectance = 0.35
	terrain.WaterWaveSize = 0.15
	terrain.WaterWaveSpeed = 8
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(95, 175, 65))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(125, 122, 118))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(225, 205, 155))
	-- Grass blade length can't be set from a script; it's a Studio setting
	-- on Terrain (Decoration / grass length). See README.
end

-- Skipped when the map was baked (World.bake), so lighting changes made
-- in Studio are kept.
function Atmosphere.start()
	if workspace:GetAttribute("GardenboundBaked") ~= true then
		Atmosphere.build()
	end
end

return Atmosphere
