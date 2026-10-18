-- The menu that opens from a shop's "OpenShop" prompt. Lists the shop's
-- catalog (ShopCatalog) with prices; Buy sends ShopBuy to the server.
-- Closes when you walk away.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local Trees = require(ReplicatedStorage.Shared.Trees)
local UI = require(script.Parent.UI)

local CLOSE_DISTANCE = 45

local ShopMenu = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local panel: Frame?
local refreshers: { () -> () } = {}

-- Extra ways to describe what you own, per entry type (Phase 4 adds gear).
local ownedText: { [string]: (ShopCatalog.Entry) -> string } = {
	seed = function(entry)
		return `Owned: {player:GetAttribute("Seed_" .. entry.id) or 0}`
	end,
	sapling = function(entry)
		local tree = Trees.list[entry.id]
		return `Owned: {if tree then player:GetAttribute("Item_" .. tree.sapling) or 0 else 0}`
	end,
	blueprint = function(entry)
		local ok, owned = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Blueprints") or "[]")
		if ok and table.find(owned, entry.id) then
			return "Owned"
		end
		return ""
	end,
}

function ShopMenu.registerOwnedText(entryType: string, describe: (ShopCatalog.Entry) -> string)
	ownedText[entryType] = describe
end

local function close()
	if panel then
		panel:Destroy()
		panel = nil
	end
	table.clear(refreshers)
end

function ShopMenu.open(shopId: string, title: string, anchor: BasePart?)
	close()
	local catalog = ShopCatalog.get(shopId)
	if not catalog then
		return
	end
	local shopBuy = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShopBuy") :: RemoteEvent

	local frame = UI.panel(gui, UDim2.fromOffset(520, 440), UDim2.fromScale(0.5, 0.5))
	panel = frame
	UI.header(frame, title).Activated:Connect(close)
	local coins = UI.label(frame, "", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(16, 44), 16, UI.colors.gold)
	table.insert(refreshers, function()
		local leaderstats = player:FindFirstChild("leaderstats")
		local value = leaderstats and leaderstats:FindFirstChild("Coins") :: IntValue?
		coins.Text = `Coins: {if value then value.Value else 0}`
	end)

	local list = UI.list(frame, UDim2.new(1, -20, 1, -80), UDim2.fromOffset(10, 72))
	for i, entry in catalog do
		local row = UI.row(list, i, entry.displayName, entry.description, entry.color)
		local buy = UI.button(row, `{entry.price} coins`, UDim2.fromOffset(100, 34), UDim2.new(1, -110, 0, 12))
		buy.Activated:Connect(function()
			shopBuy:FireServer(shopId, entry.id)
		end)
		local owned = UI.label(row, "", UDim2.fromOffset(100, 14), UDim2.new(1, -110, 0, 46), 11, UI.colors.muted)
		owned.TextXAlignment = Enum.TextXAlignment.Center
		table.insert(refreshers, function()
			local describe = ownedText[entry.type]
			owned.Text = if describe then describe(entry) else ""
		end)
	end
	for _, refresh in refreshers do
		refresh()
	end

	if anchor then
		task.spawn(function()
			while panel == frame do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root or (root.Position - anchor.Position).Magnitude > CLOSE_DISTANCE then
					close()
					return
				end
				task.wait(0.5)
			end
		end)
	end
end

function ShopMenu.start()
	gui = UI.screen("ShopMenu", 20)
	gui.Parent = player:WaitForChild("PlayerGui")

	player.AttributeChanged:Connect(function()
		for _, refresh in refreshers do
			refresh()
		end
	end)
	local leaderstats = player:WaitForChild("leaderstats", 30)
	if leaderstats then
		leaderstats:WaitForChild("Coins").Changed:Connect(function()
			for _, refresh in refreshers do
				refresh()
			end
		end)
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name ~= "OpenShop" then
			return
		end
		local shopId = prompt:GetAttribute("Shop")
		if type(shopId) == "string" then
			ShopMenu.open(shopId, prompt.ObjectText, prompt.Parent :: BasePart?)
		end
	end)
end

return ShopMenu
