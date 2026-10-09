-- Bottom-of-screen bar: pick which seed to plant, see seed and crop counts.
-- Reads the "Seed_<Crop>", "Crop_<Crop>", and "SelectedSeed" attributes
-- the server keeps on the player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crops = require(ReplicatedStorage.Shared.Crops)

local SELECTED_COLOR = Color3.fromRGB(80, 170, 90)
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
	bar.Size = UDim2.fromOffset(0, 70)
	bar.AutomaticSize = Enum.AutomaticSize.X
	bar.BackgroundTransparency = 1
	bar.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	local buttons: { [string]: TextButton } = {}

	for cropName, crop in Crops do
		local button = Instance.new("TextButton")
		button.Name = cropName
		button.LayoutOrder = crop.order
		button.Size = UDim2.fromOffset(120, 70)
		button.BackgroundColor3 = NORMAL_COLOR
		button.BackgroundTransparency = 0.2
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.FredokaOne
		button.TextSize = 16
		button.AutoButtonColor = true
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button
		button.Parent = bar

		button.Activated:Connect(function()
			selectSeed:FireServer(cropName)
		end)
		buttons[cropName] = button
	end

	local function refresh()
		local selected = player:GetAttribute("SelectedSeed")
		for cropName, button in buttons do
			local seeds = player:GetAttribute("Seed_" .. cropName) or 0
			local crops = player:GetAttribute("Crop_" .. cropName) or 0
			button.Text = `{Crops[cropName].displayName}\nSeeds: {seeds}  Crops: {crops}`
			button.BackgroundColor3 = if cropName == selected then SELECTED_COLOR else NORMAL_COLOR
		end
	end

	player.AttributeChanged:Connect(refresh)
	refresh()

	gui.Parent = player:WaitForChild("PlayerGui")
end

return SeedBar
