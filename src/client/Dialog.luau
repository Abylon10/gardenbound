-- Talking to townsfolk: the "Talk" prompt (F) on an NPC opens a box at
-- the bottom of the screen with their name, job, and lines from
-- shared/NPCs. Next goes through the lines; it closes at the end, on
-- Bye, or when you walk away.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NPCs = require(ReplicatedStorage.Shared.NPCs)
local UI = require(script.Parent.UI)

local WALK_AWAY_DISTANCE = 22

local Dialog = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local box: Frame?

local function close()
	if box then
		box:Destroy()
		box = nil
	end
end

local function open(id: string, anchor: BasePart?)
	close()
	local npc = NPCs[id]
	if not npc then
		return
	end
	local frame = UI.panel(gui, UDim2.new(0, 620, 0, 150), UDim2.new(0.5, 0, 1, -100), Vector2.new(0.5, 1))
	box = frame
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = npc.color
	end
	UI.label(frame, npc.displayName, UDim2.new(0, 300, 0, 28), UDim2.fromOffset(18, 10), 24, npc.color)
	UI.label(frame, npc.title, UDim2.new(0, 300, 0, 18), UDim2.fromOffset(18, 36), 14, UI.colors.muted)
	local text = UI.label(frame, "", UDim2.new(1, -36, 0, 54), UDim2.fromOffset(18, 58), 18)
	text.TextYAlignment = Enum.TextYAlignment.Top

	local index = 1
	local nextButton = UI.button(frame, "Next", UDim2.fromOffset(90, 30), UDim2.new(1, -200, 1, -40), UI.colors.green)
	local byeButton = UI.button(frame, "Bye", UDim2.fromOffset(90, 30), UDim2.new(1, -102, 1, -40), UI.colors.gray)

	local function show()
		text.Text = npc.lines[index]
		nextButton.Text = if index < #npc.lines then "Next" else "Done"
	end
	nextButton.Activated:Connect(function()
		if index < #npc.lines then
			index += 1
			show()
		else
			close()
		end
	end)
	byeButton.Activated:Connect(close)
	show()

	if anchor then
		task.spawn(function()
			while box == frame do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root or (root.Position - anchor.Position).Magnitude > WALK_AWAY_DISTANCE then
					close()
					return
				end
				task.wait(0.5)
			end
		end)
	end
end

function Dialog.start()
	gui = UI.screen("Dialog", 30)
	gui.Parent = player:WaitForChild("PlayerGui")
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name ~= "TalkNPC" then
			return
		end
		local id = prompt:GetAttribute("NPC")
		if type(id) == "string" then
			open(id, prompt.Parent :: BasePart?)
		end
	end)
end

return Dialog
