-- The Forge menu, opened from the Gear Shop's "OpenForge" prompt. Lists
-- every weapon and armor: Craft if you don't have it, Upgrade (+N) if you
-- do. Reads the "Gear" JSON attribute; sends ForgeCraft / ForgeUpgrade.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gear = require(ReplicatedStorage.Shared.Gear)
local Costs = require(script.Parent.Costs)
local UI = require(script.Parent.UI)

local CLOSE_DISTANCE = 45

local ForgeMenu = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local panel: Frame?
local redraw: (() -> ())? = nil

local function ownedGear(): { [string]: number }
	local ok, value = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Gear") or "{}")
	return if ok and type(value) == "table" then value else {}
end

local function close()
	if panel then
		panel:Destroy()
		panel = nil
	end
	redraw = nil
end

local function statText(id: string, level: number): string
	local item = Gear.list[id]
	if item.slot == "weapon" then
		return `{Gear.statFor(id, level)} damage`
	end
	return `+{Gear.statFor(id, level)} health, {math.floor((item.defense or 0) * 100)}% defense`
end

local function open(anchor: BasePart?)
	close()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local craftRemote = remotes:WaitForChild("ForgeCraft") :: RemoteEvent
	local upgradeRemote = remotes:WaitForChild("ForgeUpgrade") :: RemoteEvent

	local frame = UI.panel(gui, UDim2.fromOffset(560, 480), UDim2.fromScale(0.5, 0.5))
	panel = frame
	UI.header(frame, "Forge").Activated:Connect(close)
	local coins = UI.label(frame, "", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(16, 44), 16, UI.colors.gold)
	local list = UI.list(frame, UDim2.new(1, -20, 1, -80), UDim2.fromOffset(10, 72))

	local ids = {}
	for id in Gear.list do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return Gear.list[a].order < Gear.list[b].order
	end)

	local function draw()
		coins.Text = `Coins: {Costs.coins()}`
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local owned = ownedGear()
		for i, id in ids do
			local item = Gear.list[id]
			local level = owned[id]
			local title: string
			local subtitle: string
			local buttonText: string
			local cost: Costs.Cost?
			local onClick: (() -> ())?
			if level == nil then
				if not item.craft then
					continue
				end
				title = `{item.displayName} ({item.tier})`
				cost = { coins = item.craft.coins, items = item.craft.items }
				subtitle = `{statText(id, 0)}. Craft: {Costs.describe(cost :: Costs.Cost)}`
				buttonText = "Craft"
				onClick = function()
					craftRemote:FireServer(id)
				end
			elseif level >= Gear.MAX_LEVEL then
				title = `{item.displayName} +{level}`
				subtitle = `{statText(id, level)}. Fully upgraded!`
				buttonText = "Max"
			else
				local upgrade = Gear.upgradeCost(id, level)
				cost = { coins = upgrade.coins, items = upgrade.items }
				title = `{item.displayName} +{level}`
				subtitle = `{statText(id, level)} → {statText(id, level + 1)}. Cost: {Costs.describe(cost :: Costs.Cost)}`
				buttonText = `Upgrade to +{level + 1}`
				onClick = function()
					upgradeRemote:FireServer(id)
				end
			end
			local row = UI.row(list, i, title, subtitle, item.color)
			row.Size = UDim2.new(1, -10, 0, 70)
			local affordable = cost == nil or Costs.canAfford(cost)
			local button = UI.button(
				row,
				buttonText,
				UDim2.fromOffset(110, 34),
				UDim2.new(1, -118, 0, 18),
				if onClick and affordable then UI.colors.green else UI.colors.gray
			)
			button.TextSize = 13
			if onClick then
				button.Activated:Connect(onClick)
			end
		end
	end
	redraw = draw
	draw()

	if anchor then
		task.spawn(function()
			while panel == frame do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root or (root.Position - anchor.Position).Magnitude > CLOSE_DISTANCE then
					close()
					return
				end
				task.wait(0.5)
			end
		end)
	end
end

function ForgeMenu.start()
	gui = UI.screen("ForgeMenu", 20)
	gui.Parent = player:WaitForChild("PlayerGui")
	player.AttributeChanged:Connect(function()
		if redraw then
			redraw()
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "OpenForge" then
			open(prompt.Parent :: BasePart?)
		end
	end)
end

return ForgeMenu
