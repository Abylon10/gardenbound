-- Shows short messages from the server (Notify) at the top of the screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)

local SHOW_SECONDS = 3

local Toasts = {}

local container: Frame

local KIND_COLORS = {
	info = UI.colors.panel,
	success = Color3.fromRGB(45, 120, 60),
	error = Color3.fromRGB(150, 50, 45),
}

function Toasts.show(message: string, kind: string?)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.fromOffset(420, 40)
	toast.BackgroundColor3 = KIND_COLORS[kind or "info"] or UI.colors.panel
	toast.BackgroundTransparency = 0.1
	toast.Font = Enum.Font.FredokaOne
	toast.TextSize = 18
	toast.TextColor3 = UI.colors.text
	toast.Text = message
	toast.TextWrapped = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = toast
	toast.Parent = container

	task.delay(SHOW_SECONDS, function()
		local fade = TweenInfo.new(0.4)
		TweenService:Create(toast, fade, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.4)
		toast:Destroy()
	end)
end

function Toasts.start()
	local gui = UI.screen("Toasts", 50)
	container = Instance.new("Frame")
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.Position = UDim2.new(0.5, 0, 0, 70)
	container.Size = UDim2.fromOffset(420, 300)
	container.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container
	container.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
	remote.OnClientEvent:Connect(function(message, kind)
		if type(message) == "string" then
			Toasts.show(message, if type(kind) == "string" then kind else nil)
		end
	end)
end

return Toasts
