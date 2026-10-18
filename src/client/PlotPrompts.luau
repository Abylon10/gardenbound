-- Hides the prompts on other players' plots, so you only see "Plant",
-- "Harvest", and so on at your own homestead. The server checks ownership
-- anyway; this is just to keep the screen clean.

local Players = game:GetService("Players")

local PlotPrompts = {}

function PlotPrompts.start()
	local player = Players.LocalPlayer
	local plots = workspace:WaitForChild("Plots")

	local function isMine(plot: Instance): boolean
		return plot:GetAttribute("OwnerId") == player.UserId
	end

	local function refresh(plot: Instance)
		local mine = isMine(plot)
		for _, descendant in plot:GetDescendants() do
			if descendant:IsA("ProximityPrompt") then
				descendant.Enabled = mine
			end
		end
	end

	local function watch(plot: Instance)
		refresh(plot)
		plot:GetAttributeChangedSignal("OwnerId"):Connect(function()
			refresh(plot)
		end)
		plot.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("ProximityPrompt") then
				descendant.Enabled = isMine(plot)
			end
		end)
	end

	for _, plot in plots:GetChildren() do
		watch(plot)
	end
	plots.ChildAdded:Connect(watch)
end

return PlotPrompts
