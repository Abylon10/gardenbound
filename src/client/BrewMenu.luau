-- Brewing menu (from your cauldron's "OpenBrewing" prompt), the "Use"
-- button on potions in the Bag, and a small list of active potion effects
-- under the Bag button (from the "Buffs" JSON attribute).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Potions = require(ReplicatedStorage.Shared.Potions)
local Costs = require(script.Parent.Costs)
local Inventory = require(script.Parent.Inventory)
local UI = require(script.Parent.UI)

local CLOSE_DISTANCE = 25

local BrewMenu = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local panel: Frame?
local redraw: (() -> ())? = nil

local function close()
	if panel then
		panel:Destroy()
		panel = nil
	end
	redraw = nil
end

local function open(anchor: BasePart?)
	close()
	local brewRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Brew") :: RemoteEvent
	local frame = UI.panel(gui, UDim2.fromOffset(540, 440), UDim2.fromScale(0.5, 0.5))
	panel = frame
	UI.header(frame, "Cauldron").Activated:Connect(close)
	UI.label(frame, "Brew potions from crops and monster materials.", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(16, 44), 14, UI.colors.muted)
	local list = UI.list(frame, UDim2.new(1, -20, 1, -80), UDim2.fromOffset(10, 72))

	local ids = {}
	for id in Potions do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return Potions[a].order < Potions[b].order
	end)

	local function draw()
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for i, id in ids do
			local item = Items[id]
			local recipe = Potions[id].recipe
			local owned = player:GetAttribute("Item_" .. id) or 0
			local row = UI.row(list, i, `{item.displayName} (have {owned})`, `{item.description} Needs: {Costs.describe(recipe)}`, item.color)
			row.Size = UDim2.new(1, -10, 0, 70)
			local button = UI.button(
				row,
				"Brew",
				UDim2.fromOffset(100, 34),
				UDim2.new(1, -110, 0, 18),
				if Costs.canAfford(recipe) then UI.colors.green else UI.colors.gray
			)
			button.Activated:Connect(function()
				brewRemote:FireServer(id)
			end)
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

local function startBuffBar()
	local bar = Instance.new("Frame")
	bar.Name = "Buffs"
	bar.AnchorPoint = Vector2.new(0, 0)
	bar.Position = UDim2.new(0, 16, 0.5, 30)
	bar.Size = UDim2.fromOffset(220, 0)
	bar.AutomaticSize = Enum.AutomaticSize.Y
	bar.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = bar
	bar.Parent = gui

	while true do
		for _, child in bar:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local ok, active = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Buffs") or "{}")
		if ok and type(active) == "table" then
			local now = workspace:GetServerTimeNow()
			for potionId, endTime in active do
				local item = Items[potionId]
				local left = math.max(0, math.ceil(endTime - now))
				if item and left > 0 then
					local label = UI.label(bar, `{item.displayName}: {left}s`, UDim2.fromOffset(220, 22), UDim2.new(), 15, item.color)
					label.TextStrokeTransparency = 0.4
				end
			end
		end
		task.wait(1)
	end
end

function BrewMenu.start()
	gui = UI.screen("BrewMenu", 20)
	gui.Parent = player:WaitForChild("PlayerGui")

	local useRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UsePotion") :: RemoteEvent
	Inventory.addItemAction("potion", "Use", function(itemId)
		useRemote:FireServer(itemId)
	end)

	player.AttributeChanged:Connect(function()
		if redraw then
			redraw()
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "OpenBrewing" then
			open(prompt.Parent :: BasePart?)
		end
	end)
	task.spawn(startBuffBar)
end

return BrewMenu
