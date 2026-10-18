-- Hides the prompts on other players' plots, so you only see "Plant",
-- "Harvest", and so on at your own homestead, and hides any prompt the
-- server marks with a "Hidden" attribute (locked or finished things).
-- The server checks everything anyway; this keeps the screen clean.

local Players = game:GetService("Players")

local PlotPrompts = {}

function PlotPrompts.start()
	local player = Players.LocalPlayer
	local plots = workspace:WaitForChild("Plots")

	local function isMine(plot: Instance): boolean
		return plot:GetAttribute("OwnerId") == player.UserId
	end

	local function apply(plot: Instance, prompt: ProximityPrompt)
		prompt.Enabled = isMine(plot) and prompt:GetAttribute("Hidden") ~= true
	end

	local function track(plot: Instance, prompt: ProximityPrompt)
		apply(plot, prompt)
		prompt:GetAttributeChangedSignal("Hidden"):Connect(function()
			apply(plot, prompt)
		end)
	end

	local function refresh(plot: Instance)
		for _, descendant in plot:GetDescendants() do
			if descendant:IsA("ProximityPrompt") then
				apply(plot, descendant)
			end
		end
	end

	local function watch(plot: Instance)
		for _, descendant in plot:GetDescendants() do
			if descendant:IsA("ProximityPrompt") then
				track(plot, descendant)
			end
		end
		plot:GetAttributeChangedSignal("OwnerId"):Connect(function()
			refresh(plot)
		end)
		plot.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("ProximityPrompt") then
				track(plot, descendant)
			end
		end)
	end

	for _, plot in plots:GetChildren() do
		watch(plot)
	end
	plots.ChildAdded:Connect(watch)
end

return PlotPrompts
