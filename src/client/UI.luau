-- Small helpers so every menu looks the same: rounded panels, buttons,
-- labels, and a scrolling list.

local UI = {}

UI.colors = {
	panel = Color3.fromRGB(30, 45, 38),
	row = Color3.fromRGB(45, 65, 55),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(190, 210, 195),
	green = Color3.fromRGB(80, 170, 90),
	gold = Color3.fromRGB(245, 200, 60),
	red = Color3.fromRGB(200, 70, 60),
	gray = Color3.fromRGB(90, 95, 92),
}

local function corner(parent: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

function UI.screen(name: string, displayOrder: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = displayOrder or 0
	return gui
end

function UI.panel(parent: Instance, size: UDim2, position: UDim2, anchor: Vector2?): Frame
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = UI.colors.panel
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	corner(frame, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = UI.colors.gold
	stroke.Thickness = 2
	stroke.Transparency = 0.4
	stroke.Parent = frame
	frame.Parent = parent
	return frame
end

function UI.label(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number?, color: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color or UI.colors.text
	label.TextSize = textSize or 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = parent
	return label
end

function UI.button(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3?): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color or UI.colors.green
	button.BorderSizePixel = 0
	button.Font = Enum.Font.FredokaOne
	button.Text = text
	button.TextColor3 = UI.colors.text
	button.TextSize = 16
	button.AutoButtonColor = true
	corner(button, 8)
	button.Parent = parent
	return button
end

-- A vertical scrolling list; add rows as children.
function UI.list(parent: Instance, size: UDim2, position: UDim2): ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = size
	scroll.Position = position
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	scroll.Parent = parent
	return scroll
end

-- One row in a list: a color swatch, a title, a subtitle, and room on the
-- right for a button (returned as the row frame).
function UI.row(list: Instance, order: number, title: string, subtitle: string, swatch: Color3?): Frame
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -10, 0, 58)
	row.BackgroundColor3 = UI.colors.row
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	corner(row, 8)
	local left = 10
	if swatch then
		local box = Instance.new("Frame")
		box.Size = UDim2.fromOffset(34, 34)
		box.Position = UDim2.fromOffset(10, 12)
		box.BackgroundColor3 = swatch
		box.BorderSizePixel = 0
		corner(box, 8)
		box.Parent = row
		left = 54
	end
	UI.label(row, title, UDim2.new(1, -left - 120, 0, 22), UDim2.fromOffset(left, 6), 17).Name = "Title"
	UI.label(row, subtitle, UDim2.new(1, -left - 120, 0, 26), UDim2.fromOffset(left, 28), 13, UI.colors.muted).Name = "Subtitle"
	row.Parent = list
	return row
end

-- Title bar with a close button. Returns the close button.
function UI.header(panel: Frame, title: string): TextButton
	UI.label(panel, title, UDim2.new(1, -60, 0, 36), UDim2.fromOffset(16, 8), 24, UI.colors.gold)
	return UI.button(panel, "X", UDim2.fromOffset(36, 32), UDim2.new(1, -46, 0, 10), UI.colors.red)
end

return UI
