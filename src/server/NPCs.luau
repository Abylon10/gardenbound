-- Builds the townsfolk (see shared/NPCs for names and dialogue) and puts
-- them at their posts: a shopkeeper behind each plaza stall, two scouts at
-- the Wilderness Gate, and two knights at the Dungeon Portal.
-- Each is a standard R15 body made from a HumanoidDescription (skin and
-- clothing colors), plus code-built accessories: hair, hats, aprons,
-- armor, and whatever they hold. Everything is anchored; they stand still.
-- If the R15 body can't be created, a simple blocky body is used instead.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NPCDefs = require(ReplicatedStorage.Shared.NPCs)
local Build = require(script.Parent.Build)
local MapLayout = require(script.Parent.MapLayout)

local NPCs = {}

type Look = {
	skin: Color3,
	shirt: Color3,
	pants: Color3,
	dress: (Model) -> (),
}

local SKIN_LIGHT = Color3.fromRGB(245, 205, 170)
local SKIN_MEDIUM = Color3.fromRGB(210, 160, 120)
local SKIN_TAN = Color3.fromRGB(180, 130, 95)
local METAL = Color3.fromRGB(185, 190, 200)
local DARK_METAL = Color3.fromRGB(80, 80, 90)
local WOOD = Color3.fromRGB(120, 80, 45)
local GOLD = Color3.fromRGB(230, 190, 70)

-- Adds an anchored part placed relative to one of the model's body parts.
local function attach(model: Model, bodyPartName: string, name: string, size: Vector3, offset: CFrame, props: { [string]: any }?): BasePart?
	local bodyPart = model:FindFirstChild(bodyPartName) :: BasePart?
	if not bodyPart then
		return nil
	end
	local properties: { [string]: any } = {
		Name = name,
		Size = size,
		CFrame = bodyPart.CFrame * offset,
		CanCollide = false,
		CanQuery = false,
		Material = Enum.Material.SmoothPlastic,
	}
	local extra: { [string]: any } = props or {}
	for key, value in extra do
		properties[key] = value
	end
	local part = Build.part(properties)
	part.Parent = model
	return part
end

local function headSize(model: Model): Vector3
	local head = model:FindFirstChild("Head") :: BasePart?
	return if head then head.Size else Vector3.new(1.2, 1.2, 1.2)
end

local function torsoSize(model: Model): Vector3
	local torso = model:FindFirstChild("UpperTorso") :: BasePart?
	return if torso then torso.Size else Vector3.new(2, 1.6, 1)
end

-- Hair and headwear ------------------------------------------------------

local function hairCap(model: Model, color: Color3)
	local h = headSize(model)
	attach(model, "Head", "Hair", Vector3.new(h.X * 1.1, h.Y * 0.5, h.Z * 1.12), CFrame.new(0, h.Y * 0.32, 0.05), {
		Color = color,
		Material = Enum.Material.Fabric,
	})
end

local function longHair(model: Model, color: Color3)
	hairCap(model, color)
	local h = headSize(model)
	attach(model, "Head", "HairBack", Vector3.new(h.X * 1.05, h.Y * 1.5, 0.35), CFrame.new(0, -h.Y * 0.25, h.Z * 0.5), {
		Color = color,
		Material = Enum.Material.Fabric,
	})
end

local function bun(model: Model, color: Color3)
	hairCap(model, color)
	local h = headSize(model)
	attach(model, "Head", "Bun", Vector3.new(0.8, 0.8, 0.8), CFrame.new(0, h.Y * 0.5, h.Z * 0.5), {
		Shape = Enum.PartType.Ball,
		Color = color,
		Material = Enum.Material.Fabric,
	})
end

local function messyHair(model: Model, color: Color3)
	hairCap(model, color)
	local h = headSize(model)
	for i, x in { -0.3, 0, 0.3 } do
		attach(model, "Head", "Tuft", Vector3.new(0.35, 0.3, 0.35), CFrame.new(x * h.X, h.Y * 0.6, (i - 2) * 0.15) * CFrame.Angles(0, 0, math.rad(x * 60)), {
			Color = color,
			Material = Enum.Material.Fabric,
		})
	end
end

local function flowerCrown(model: Model)
	local h = headSize(model)
	local colors = { Color3.fromRGB(250, 120, 160), Color3.fromRGB(255, 220, 90), Color3.fromRGB(170, 130, 240), Color3.fromRGB(255, 255, 255) }
	for i = 0, 7 do
		local angle = i * math.pi / 4
		attach(model, "Head", "Flower", Vector3.new(0.3, 0.3, 0.3), CFrame.new(math.cos(angle) * h.X * 0.55, h.Y * 0.55, math.sin(angle) * h.Z * 0.55), {
			Shape = Enum.PartType.Ball,
			Color = colors[i % #colors + 1],
		})
	end
end

local function glasses(model: Model)
	local h = headSize(model)
	for _, x in { -0.21, 0.21 } do
		attach(model, "Head", "Lens", Vector3.new(h.X * 0.3, h.Y * 0.2, 0.06), CFrame.new(x * h.X, h.Y * 0.08, -h.Z * 0.53), {
			Color = Color3.fromRGB(30, 30, 35),
			Transparency = 0.25,
		})
	end
	attach(model, "Head", "GlassesBridge", Vector3.new(h.X * 0.15, 0.06, 0.06), CFrame.new(0, h.Y * 0.1, -h.Z * 0.53), {
		Color = Color3.fromRGB(30, 30, 35),
	})
end

local function beard(model: Model, color: Color3)
	local h = headSize(model)
	attach(model, "Head", "Beard", Vector3.new(h.X * 0.85, h.Y * 0.45, 0.35), CFrame.new(0, -h.Y * 0.35, -h.Z * 0.42), {
		Color = color,
		Material = Enum.Material.Fabric,
	})
end

local function hood(model: Model, color: Color3)
	local h = headSize(model)
	attach(model, "Head", "Hood", Vector3.new(h.X * 1.2, h.Y * 0.65, h.Z * 1.25), CFrame.new(0, h.Y * 0.3, 0.1), {
		Color = color,
		Material = Enum.Material.Fabric,
	})
	attach(model, "Head", "HoodBack", Vector3.new(h.X * 1.15, h.Y * 1.1, 0.3), CFrame.new(0, -h.Y * 0.1, h.Z * 0.55), {
		Color = color,
		Material = Enum.Material.Fabric,
	})
end

local function helmet(model: Model, plume: Color3)
	local h = headSize(model)
	attach(model, "Head", "Helmet", Vector3.new(h.X * 1.15, h.Y * 0.6, h.Z * 1.18), CFrame.new(0, h.Y * 0.3, 0.02), {
		Color = METAL,
		Material = Enum.Material.Metal,
	})
	attach(model, "Head", "NoseGuard", Vector3.new(0.15, h.Y * 0.45, 0.12), CFrame.new(0, h.Y * 0.05, -h.Z * 0.6), {
		Color = METAL,
		Material = Enum.Material.Metal,
	})
	attach(model, "Head", "Plume", Vector3.new(0.3, 0.7, h.Z * 1.1), CFrame.new(0, h.Y * 0.8, 0.1), {
		Color = plume,
		Material = Enum.Material.Fabric,
	})
end

-- Clothing ----------------------------------------------------------------

local function apron(model: Model, color: Color3)
	local t = torsoSize(model)
	attach(model, "UpperTorso", "Apron", Vector3.new(t.X * 0.75, t.Y * 0.9, 0.1), CFrame.new(0, -t.Y * 0.05, -t.Z / 2 - 0.06), {
		Color = color,
		Material = Enum.Material.Fabric,
	})
	attach(model, "LowerTorso", "ApronSkirt", Vector3.new(t.X * 0.8, 2, 0.1), CFrame.new(0, -0.7, -t.Z / 2 - 0.06), {
		Color = color,
		Material = Enum.Material.Fabric,
	})
end

local function vest(model: Model, color: Color3)
	local t = torsoSize(model)
	for _, x in { -0.3, 0.3 } do
		attach(model, "UpperTorso", "Vest", Vector3.new(t.X * 0.38, t.Y * 0.95, t.Z * 1.08), CFrame.new(x * t.X, 0, 0), {
			Color = color,
			Material = Enum.Material.Fabric,
		})
	end
end

local function necklace(model: Model)
	local t = torsoSize(model)
	attach(model, "UpperTorso", "Necklace", Vector3.new(t.X * 0.4, 0.1, 0.06), CFrame.new(0, t.Y * 0.38, -t.Z / 2 - 0.04), {
		Color = GOLD,
		Material = Enum.Material.Metal,
	})
	attach(model, "UpperTorso", "Pendant", Vector3.new(0.25, 0.25, 0.25), CFrame.new(0, t.Y * 0.25, -t.Z / 2 - 0.08), {
		Shape = Enum.PartType.Ball,
		Color = Color3.fromRGB(150, 40, 70),
		Material = Enum.Material.Glass,
	})
end

local function cape(model: Model, color: Color3)
	local t = torsoSize(model)
	attach(model, "UpperTorso", "Cape", Vector3.new(t.X * 1.05, 3.8, 0.12), CFrame.new(0, -t.Y * 0.55, t.Z / 2 + 0.1), {
		Color = color,
		Material = Enum.Material.Fabric,
	})
end

local function armor(model: Model)
	local t = torsoSize(model)
	attach(model, "UpperTorso", "Chestplate", Vector3.new(t.X * 1.08, t.Y * 1.02, t.Z * 1.15), CFrame.new(), {
		Color = METAL,
		Material = Enum.Material.Metal,
	})
	for _, x in { -1, 1 } do
		attach(model, "UpperTorso", "Pauldron", Vector3.new(1.1, 0.5, 1.2), CFrame.new(x * t.X * 0.6, t.Y * 0.42, 0), {
			Color = METAL,
			Material = Enum.Material.Metal,
		})
	end
	attach(model, "LowerTorso", "Belt", Vector3.new(t.X * 1.05, 0.3, t.Z * 1.12), CFrame.new(0, 0.1, 0), {
		Color = Color3.fromRGB(70, 45, 30),
		Material = Enum.Material.Fabric,
	})
end

-- Held items --------------------------------------------------------------

local function spear(model: Model)
	attach(model, "RightHand", "SpearShaft", Vector3.new(0.25, 8, 0.25), CFrame.new(0, 2.6, 0), { Color = WOOD, Material = Enum.Material.Wood })
	attach(model, "RightHand", "SpearTip", Vector3.new(0.12, 1.3, 0.5), CFrame.new(0, 7.2, 0), { Color = METAL, Material = Enum.Material.Metal })
end

local function dagger(model: Model)
	attach(model, "RightHand", "DaggerBlade", Vector3.new(0.12, 1.2, 0.35), CFrame.new(0, -0.8, -0.1), { Color = METAL, Material = Enum.Material.Metal })
	attach(model, "RightHand", "DaggerGuard", Vector3.new(0.2, 0.12, 0.7), CFrame.new(0, -0.2, -0.1), { Color = GOLD, Material = Enum.Material.Metal })
end

local function spyglass(model: Model)
	attach(model, "LeftHand", "Spyglass", Vector3.new(1.8, 0.35, 0.35), CFrame.new(0, 0.1, -0.5) * CFrame.Angles(0, math.rad(90), 0), {
		Shape = Enum.PartType.Cylinder,
		Color = Color3.fromRGB(190, 150, 60),
		Material = Enum.Material.Metal,
	})
end

local function sword(model: Model)
	attach(model, "RightHand", "SwordBlade", Vector3.new(0.18, 3.4, 0.55), CFrame.new(0, 1.9, -0.1), { Color = METAL, Material = Enum.Material.Metal })
	attach(model, "RightHand", "SwordGuard", Vector3.new(0.25, 0.2, 1.4), CFrame.new(0, 0.15, -0.1), { Color = GOLD, Material = Enum.Material.Metal })
end

local function shield(model: Model, color: Color3)
	attach(model, "LeftHand", "Shield", Vector3.new(0.3, 2.8, 2.8), CFrame.new(-0.35, 0.4, 0), {
		Shape = Enum.PartType.Cylinder,
		Color = color,
		Material = Enum.Material.Metal,
	})
	attach(model, "LeftHand", "ShieldBoss", Vector3.new(0.4, 0.8, 0.8), CFrame.new(-0.55, 0.4, 0), {
		Shape = Enum.PartType.Cylinder,
		Color = GOLD,
		Material = Enum.Material.Metal,
	})
end

local function hammer(model: Model)
	attach(model, "RightHand", "HammerHandle", Vector3.new(0.25, 2, 0.25), CFrame.new(0, -0.6, 0), { Color = WOOD, Material = Enum.Material.Wood })
	attach(model, "RightHand", "HammerHead", Vector3.new(0.6, 0.6, 1.3), CFrame.new(0, -1.6, 0), { Color = DARK_METAL, Material = Enum.Material.Metal })
end

local function blueprint(model: Model)
	attach(model, "LeftHand", "Blueprint", Vector3.new(1.7, 0.05, 1.2), CFrame.new(0.3, 0.3, -0.7) * CFrame.Angles(math.rad(-55), 0, 0), {
		Color = Color3.fromRGB(50, 100, 200),
	})
	attach(model, "LeftHand", "BlueprintLines", Vector3.new(1.2, 0.06, 0.06), CFrame.new(0.3, 0.33, -0.7) * CFrame.Angles(math.rad(-55), 0, 0), {
		Color = Color3.fromRGB(230, 240, 255),
	})
	attach(model, "RightHand", "BlueprintRoll", Vector3.new(2, 0.35, 0.35), CFrame.new(0, -0.2, -0.2) * CFrame.Angles(0, math.rad(90), 0), {
		Shape = Enum.PartType.Cylinder,
		Color = Color3.fromRGB(70, 120, 210),
	})
end

local function bouquet(model: Model)
	attach(model, "LeftHand", "Stems", Vector3.new(0.9, 0.2, 0.2), CFrame.new(0, 0.3, -0.3) * CFrame.Angles(0, 0, math.rad(90)), {
		Shape = Enum.PartType.Cylinder,
		Color = Color3.fromRGB(70, 150, 60),
	})
	for i, color in { Color3.fromRGB(250, 120, 160), Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 130, 240) } do
		local angle = i * math.pi / 2
		attach(model, "LeftHand", "Bloom", Vector3.new(0.4, 0.4, 0.4), CFrame.new(math.cos(angle) * 0.2, 0.85, -0.3 + math.sin(angle) * 0.2), {
			Shape = Enum.PartType.Ball,
			Color = color,
		})
	end
end

local function coinPouch(model: Model)
	attach(model, "LeftHand", "Pouch", Vector3.new(0.8, 0.8, 0.8), CFrame.new(0, -0.5, 0), {
		Shape = Enum.PartType.Ball,
		Color = Color3.fromRGB(120, 60, 50),
		Material = Enum.Material.Fabric,
	})
	attach(model, "LeftHand", "Coin", Vector3.new(0.1, 0.4, 0.4), CFrame.new(0, -0.05, -0.3) * CFrame.Angles(0, math.rad(90), 0), {
		Shape = Enum.PartType.Cylinder,
		Color = GOLD,
		Material = Enum.Material.Metal,
	})
end

-- Who looks like what -------------------------------------------------------

local LOOKS: { [string]: Look } = {
	-- Teenage florist: flower crown, long hair, green apron, bouquet.
	Louisa = {
		skin = SKIN_LIGHT,
		shirt = Color3.fromRGB(250, 190, 210),
		pants = Color3.fromRGB(240, 235, 220),
		dress = function(m)
			longHair(m, Color3.fromRGB(150, 95, 55))
			flowerCrown(m)
			apron(m, Color3.fromRGB(110, 170, 90))
			bouquet(m)
		end,
	},
	-- Sophisticated merchant in her 30s: hair bun, burgundy outfit, gold
	-- necklace, coin pouch.
	Diane = {
		skin = SKIN_MEDIUM,
		shirt = Color3.fromRGB(130, 30, 55),
		pants = Color3.fromRGB(40, 35, 45),
		dress = function(m)
			bun(m, Color3.fromRGB(45, 30, 25))
			necklace(m)
			coinPouch(m)
		end,
	},
	-- Blacksmith in his 40s: beard, short hair, leather apron, hammer.
	Arthur = {
		skin = SKIN_TAN,
		shirt = Color3.fromRGB(110, 100, 90),
		pants = Color3.fromRGB(60, 50, 45),
		dress = function(m)
			hairCap(m, Color3.fromRGB(70, 50, 40))
			beard(m, Color3.fromRGB(70, 50, 40))
			apron(m, Color3.fromRGB(80, 50, 30))
			hammer(m)
		end,
	},
	-- Architect around 25: messy hair, glasses, blue shirt, blueprints.
	Gary = {
		skin = SKIN_LIGHT,
		shirt = Color3.fromRGB(90, 140, 210),
		pants = Color3.fromRGB(70, 70, 80),
		dress = function(m)
			messyHair(m, Color3.fromRGB(120, 85, 50))
			glasses(m)
			blueprint(m)
		end,
	},
	-- Scout with a dagger and a spyglass.
	Kevin = {
		skin = SKIN_MEDIUM,
		shirt = Color3.fromRGB(75, 110, 60),
		pants = Color3.fromRGB(90, 70, 50),
		dress = function(m)
			hood(m, Color3.fromRGB(60, 95, 50))
			vest(m, Color3.fromRGB(110, 80, 50))
			cape(m, Color3.fromRGB(60, 95, 50))
			dagger(m)
			spyglass(m)
		end,
	},
	-- Scout with a spear.
	Josh = {
		skin = SKIN_TAN,
		shirt = Color3.fromRGB(95, 120, 60),
		pants = Color3.fromRGB(80, 65, 45),
		dress = function(m)
			hairCap(m, Color3.fromRGB(35, 25, 20))
			vest(m, Color3.fromRGB(120, 85, 55))
			cape(m, Color3.fromRGB(70, 110, 55))
			spear(m)
		end,
	},
	-- Knight (blue plume), sword and shield.
	Alfred = {
		skin = SKIN_LIGHT,
		shirt = METAL,
		pants = DARK_METAL,
		dress = function(m)
			helmet(m, Color3.fromRGB(50, 80, 180))
			armor(m)
			cape(m, Color3.fromRGB(50, 80, 180))
			sword(m)
			shield(m, Color3.fromRGB(50, 80, 180))
		end,
	},
	-- Knight (red plume, long hair), spear and shield.
	Susan = {
		skin = SKIN_MEDIUM,
		shirt = METAL,
		pants = DARK_METAL,
		dress = function(m)
			longHair(m, Color3.fromRGB(110, 60, 35))
			helmet(m, Color3.fromRGB(180, 40, 50))
			armor(m)
			cape(m, Color3.fromRGB(180, 40, 50))
			spear(m)
			shield(m, Color3.fromRGB(180, 40, 50))
		end,
	},
}

-- A simple blocky body with the same part names, used if the R15 body
-- can't be created. Returns the model and its root height above ground.
local function blockyBody(look: Look): (Model, number)
	local model = Instance.new("Model")
	local function add(name: string, size: Vector3, position: Vector3, color: Color3, shape: Enum.PartType?)
		local part = Build.part({
			Name = name,
			Size = size,
			CFrame = CFrame.new(position),
			Color = color,
			Shape = shape or Enum.PartType.Block,
		})
		part.Parent = model
		return part
	end
	local root = add("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), look.shirt)
	root.Transparency = 1
	add("LowerTorso", Vector3.new(2, 0.8, 1), Vector3.new(0, 2.4, 0), look.pants)
	add("UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 3.6, 0), look.shirt)
	add("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 5, 0), look.skin, Enum.PartType.Ball)
	for _, x in { -1, 1 } do
		add(if x < 0 then "LeftUpperArm" else "RightUpperArm", Vector3.new(0.8, 1.8, 0.8), Vector3.new(x * 1.4, 3.5, 0), look.shirt)
		add(if x < 0 then "LeftHand" else "RightHand", Vector3.new(0.8, 0.6, 0.8), Vector3.new(x * 1.4, 2.3, 0), look.skin)
		add(if x < 0 then "LeftLeg" else "RightLeg", Vector3.new(0.9, 2, 0.9), Vector3.new(x * 0.5, 1, 0), look.pants)
	end
	model.PrimaryPart = root
	return model, 3
end

-- An R15 body colored from the look, or the blocky fallback.
local function body(look: Look): (Model, number)
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = look.skin
	description.TorsoColor = look.shirt
	description.LeftArmColor = look.shirt
	description.RightArmColor = look.shirt
	description.LeftLegColor = look.pants
	description.RightLegColor = look.pants
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not result then
		warn("[NPCs] Using blocky bodies:", result)
		return blockyBody(look)
	end
	local model = result :: Model
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		model:Destroy()
		return blockyBody(look)
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	return model, humanoid.HipHeight + root.Size.Y / 2
end

-- Builds one NPC standing on `ground` (a CFrame on the floor, facing the
-- way the NPC should look).
local function spawnNPC(parent: Instance, id: string, ground: CFrame)
	local def = NPCDefs[id]
	local look = LOOKS[id]
	if not def or not look then
		return
	end
	local model, rootHeight = body(look)
	model.Name = id
	model:PivotTo(ground * CFrame.new(0, rootHeight, 0))
	look.dress(model)

	local head = model:FindFirstChild("Head") :: BasePart?
	if head then
		local sign = Build.sign(head, def.displayName, def.title, 2.6)
		sign.MaxDistance = 60
		sign.Size = UDim2.fromOffset(200, 50)
	end

	local root = model.PrimaryPart
	if root then
		local prompt = Build.prompt(root, "Talk", def.displayName)
		prompt.Name = "TalkNPC"
		prompt.KeyboardKeyCode = Enum.KeyCode.F
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
		prompt.MaxActivationDistance = 14
		prompt.UIOffset = Vector2.new(0, 60)
		prompt:SetAttribute("NPC", id)
	end
	model.Parent = parent
end

function NPCs.start()
	local folder = Instance.new("Model")
	folder.Name = "NPCs"
	folder.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	folder.Parent = workspace

	-- Shopkeepers stand behind their counters, facing the plaza center.
	local floorTop = MapLayout.PLAZA_TOP + 0.6
	local shopkeepers = { SeedShop = "Louisa", SellShop = "Diane", GearShop = "Arthur", BlueprintShop = "Gary" }
	for shop, id in shopkeepers do
		local origin = MapLayout.facingCenter(MapLayout.SHOP_ANGLES[shop], MapLayout.SHOP_RING_RADIUS)
		task.spawn(spawnNPC, folder, id, origin * CFrame.new(0, floorTop, 1.5))
	end

	-- Scouts in front of the Wilderness Gate, knights on the portal steps.
	local gate = MapLayout.LANDMARKS.WildernessGate
	local gateOrigin = MapLayout.facingCenter(gate.angle, gate.radius)
	task.spawn(spawnNPC, folder, "Kevin", gateOrigin * CFrame.new(-12, MapLayout.GROUND_TOP, -5))
	task.spawn(spawnNPC, folder, "Josh", gateOrigin * CFrame.new(12, MapLayout.GROUND_TOP, -5))

	local portal = MapLayout.LANDMARKS.DungeonPortal
	local portalOrigin = MapLayout.facingCenter(portal.angle, portal.radius)
	task.spawn(spawnNPC, folder, "Alfred", portalOrigin * CFrame.new(-11.5, MapLayout.GROUND_TOP + 1.5, -2))
	task.spawn(spawnNPC, folder, "Susan", portalOrigin * CFrame.new(11.5, MapLayout.GROUND_TOP + 1.5, -2))
end

return NPCs
