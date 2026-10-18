-- The Bag: a button on the left of the screen that opens your inventory.
-- Tabs are registered with Inventory.addTab so later systems (pets, gear)
-- can add their own pages. Every tab redraws when your data changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Items = require(ReplicatedStorage.Shared.Items)
local UI = require(script.Parent.UI)

local Inventory = {}

type Tab = { name: string, order: number, draw: (list: ScrollingFrame) -> () }

local player = Players.LocalPlayer
local tabs: { Tab } = {}
-- Buttons shown on item rows by item kind, e.g. eggs -> "Hatch".
local itemActions: { [string]: { label: string, run: (itemId: string) -> () } } = {}
local gui: ScreenGui
local panel: Frame?
local currentTab: string = "Items"
local redraw: (() -> ())? = nil

-- draw(list) fills the list with UI.row entries; it's called again
-- whenever the player's data changes while the tab is open.
function Inventory.addTab(name: string, order: number, draw: (list: ScrollingFrame) -> ())
	table.insert(tabs, { name = name, order = order, draw = draw })
	table.sort(tabs, function(a, b)
		return a.order < b.order
	end)
end

-- Adds a button to every item of this kind in the Items tab.
function Inventory.addItemAction(kind: string, label: string, run: (itemId: string) -> ())
	itemActions[kind] = { label = label, run = run }
end

local function close()
	if panel then
		panel:Destroy()
		panel = nil
	end
	redraw = nil
end

local function open()
	close()
	local frame = UI.panel(gui, UDim2.fromOffset(520, 460), UDim2.fromScale(0.5, 0.5))
	panel = frame
	UI.header(frame, "Bag").Activated:Connect(close)

	local list = UI.list(frame, UDim2.new(1, -20, 1, -100), UDim2.fromOffset(10, 92))
	local tabButtons: { [string]: TextButton } = {}

	local function draw()
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for name, button in tabButtons do
			button.BackgroundColor3 = if name == currentTab then UI.colors.green else UI.colors.gray
		end
		for _, tab in tabs do
			if tab.name == currentTab then
				tab.draw(list)
			end
		end
	end

	for i, tab in tabs do
		local button = UI.button(frame, tab.name, UDim2.fromOffset(100, 30), UDim2.fromOffset(16 + (i - 1) * 108, 52))
		button.Activated:Connect(function()
			currentTab = tab.name
			draw()
		end)
		tabButtons[tab.name] = button
	end

	redraw = draw
	draw()
end

local function itemsTab(list: ScrollingFrame)
	local order = 0
	local function add(title: string, subtitle: string, color: Color3)
		order += 1
		UI.row(list, order, title, subtitle, color).Name = "Row" .. order
	end

	local cropNames = {}
	for cropName in Crops do
		table.insert(cropNames, cropName)
	end
	table.sort(cropNames, function(a, b)
		return Crops[a].order < Crops[b].order
	end)
	for _, cropName in cropNames do
		local crop = Crops[cropName]
		local seeds = player:GetAttribute("Seed_" .. cropName) or 0
		local crops = player:GetAttribute("Crop_" .. cropName) or 0
		if seeds > 0 or crops > 0 then
			add(crop.displayName, `Seeds: {seeds}   Harvested: {crops}`, crop.color)
		end
	end

	local itemIds = {}
	for itemId in Items do
		table.insert(itemIds, itemId)
	end
	table.sort(itemIds, function(a, b)
		return Items[a].order < Items[b].order
	end)
	for _, itemId in itemIds do
		local count = player:GetAttribute("Item_" .. itemId) or 0
		if count > 0 then
			local item = Items[itemId]
			add(`{item.displayName} x{count}`, item.description, item.color)
			local action = itemActions[item.kind]
			if action then
				local row = list:FindFirstChild("Row" .. order) :: Frame
				local button = UI.button(row, action.label, UDim2.fromOffset(100, 34), UDim2.new(1, -110, 0, 12))
				button.Activated:Connect(function()
					action.run(itemId)
				end)
			end
		end
	end

	if order == 0 then
		add("Your bag is empty", "Harvest crops and chop trees to fill it.", UI.colors.gray)
	end
end

function Inventory.start()
	gui = UI.screen("Inventory", 10)
	local bagButton = UI.button(gui, "Bag", UDim2.fromOffset(90, 44), UDim2.new(0, 16, 0.5, 0), UI.colors.gold)
	bagButton.AnchorPoint = Vector2.new(0, 0.5)
	bagButton.TextColor3 = Color3.fromRGB(40, 40, 30)
	bagButton.TextSize = 20
	bagButton.Activated:Connect(function()
		if panel then
			close()
		else
			open()
		end
	end)
	gui.Parent = player:WaitForChild("PlayerGui")

	Inventory.addTab("Items", 1, itemsTab)
	player.AttributeChanged:Connect(function()
		if redraw then
			redraw()
		end
	end)
end

return Inventory
