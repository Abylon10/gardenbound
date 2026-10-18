-- Bottom-of-screen bar: pick which crop seed to plant in the front garden
-- and which sapling to plant in the back garden. Shows how many you have.
-- Reads the "Seed_<Crop>", "Crop_<Crop>", "Item_<Sapling>",
-- "SelectedSeed", and "SelectedSapling" attributes on the player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)
local Trees = require(ReplicatedStorage.Shared.Trees)

local SELECTED_SEED_COLOR = Color3.fromRGB(80, 170, 90)
local SELECTED_SAPLING_COLOR = Color3.fromRGB(170, 120, 60)
local NORMAL_COLOR = Color3.fromRGB(40, 40, 40)

local SeedBar = {}

function SeedBar.start()
	local player = Players.LocalPlayer
	local selectSeed = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SelectSeed") :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "SeedBar"
	gui.ResetOnSpawn = false

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -16)
	bar.Size = UDim2.fromOffset(0, 64)
	bar.AutomaticSize = Enum.AutomaticSize.X
	bar.BackgroundTransparency = 1
	bar.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	type Slot = { button: TextButton, refresh: () -> () }
	local slots: { Slot } = {}

	local function makeButton(id: string, order: number): TextButton
		local button = Instance.new("TextButton")
		button.Name = id
		button.LayoutOrder = order
		button.Size = UDim2.fromOffset(96, 64)
		button.BackgroundColor3 = NORMAL_COLOR
		button.BackgroundTransparency = 0.2
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.FredokaOne
		button.TextSize = 13
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button
		button.Parent = bar
		button.Activated:Connect(function()
			selectSeed:FireServer(id)
		end)
		return button
	end

	for cropName, crop in Crops do
		local button = makeButton(cropName, crop.order)
		table.insert(slots, {
			button = button,
			refresh = function()
				local seeds = player:GetAttribute("Seed_" .. cropName) or 0
				local crops = player:GetAttribute("Crop_" .. cropName) or 0
				button.Text = `{crop.displayName}\nSeeds {seeds} · Crops {crops}`
				local selected = player:GetAttribute("SelectedSeed") == cropName
				button.BackgroundColor3 = if selected then SELECTED_SEED_COLOR else NORMAL_COLOR
			end,
		})
	end

	for _, tree in Trees.list do
		local button = makeButton(tree.sapling, 10 + tree.order)
		table.insert(slots, {
			button = button,
			refresh = function()
				local count = player:GetAttribute("Item_" .. tree.sapling) or 0
				button.Text = `{tree.displayName} tree\nSaplings {count}`
				local selected = player:GetAttribute("SelectedSapling") == tree.sapling
				button.BackgroundColor3 = if selected then SELECTED_SAPLING_COLOR else NORMAL_COLOR
				button.Visible = count > 0 or selected
			end,
		})
	end

	local function refresh()
		for _, slot in slots do
			slot.refresh()
		end
	end
	player.AttributeChanged:Connect(refresh)
	refresh()

	gui.Parent = player:WaitForChild("PlayerGui")
end

return SeedBar
