-- Two buttons on the left, above the Bag: "Plaza" and "My Garden".
-- They ask the server to teleport you (see server Travel).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent.UI)

local TravelButtons = {}

function TravelButtons.start()
	local travel = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TravelTo") :: RemoteEvent
	local gui = UI.screen("TravelButtons", 10)

	local function button(text: string, offsetY: number, color: Color3, place: string)
		local b = UI.button(gui, text, UDim2.fromOffset(110, 40), UDim2.new(0, 16, 0.5, offsetY), color)
		b.AnchorPoint = Vector2.new(0, 0.5)
		b.TextSize = 17
		b.Activated:Connect(function()
			travel:FireServer(place)
		end)
	end
	-- The Bag button is centered at 0.5; stack these above it.
	button("Plaza", -54, Color3.fromRGB(70, 120, 200), "Plaza")
	button("My Garden", -100, UI.colors.green, "Garden")

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return TravelButtons
