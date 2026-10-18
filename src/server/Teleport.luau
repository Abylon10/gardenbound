-- Moves a character somewhere safely: holds it still while the
-- destination streams in on the client, so it can't fall through floors
-- the client doesn't have yet (StreamingEnabled is on).

local Teleport = {}

function Teleport.to(player: Player, target: CFrame)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root then
		return
	end
	root.Anchored = true
	character:PivotTo(target)
	pcall(function()
		player:RequestStreamAroundAsync(target.Position, 10)
	end)
	task.wait(0.3)
	if root.Parent then
		root.Anchored = false
	end
end

return Teleport
