-- Gardenbound loading screen. Runs first on the client, replaces Roblox's
-- default loader, and stays up until the player's home island has loaded
-- and their character is standing on it. Steps:
--   1. game assets loaded
--   2. the map exists (Plaza, Plots, Landmarks)
--   3. the server told us where home is ("HomeSpawn" attribute)
--   4. there's ground under the home spawn point (streamed in)
--   5. tell the server we're ready, wait for the character to arrive

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GROUND_TIMEOUT = 30
local ARRIVE_TIMEOUT = 15

local player = Players.LocalPlayer

ReplicatedFirst:RemoveDefaultLoadingScreen()

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(40, 110, 70)
background.BorderSizePixel = 0
background.Parent = gui
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Color3.fromRGB(60, 150, 90), Color3.fromRGB(30, 80, 110))
gradient.Rotation = 90
gradient.Parent = background

local function label(text: string, y: number, height: number, size: number, transparency: number): TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.Position = UDim2.fromScale(0.5, y)
	textLabel.Size = UDim2.new(0.8, 0, 0, height)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextSize = size
	textLabel.TextTransparency = transparency
	textLabel.Text = text
	textLabel.Parent = background
	return textLabel
end

label("Gardenbound", 0.38, 80, 72, 0)
label("Grow. Build. Explore. Battle.", 0.46, 30, 24, 0.2)
local status = label("Loading...", 0.62, 24, 20, 0.1)

local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.57)
barBack.Size = UDim2.fromOffset(360, 14)
barBack.BackgroundColor3 = Color3.fromRGB(20, 40, 30)
barBack.BackgroundTransparency = 0.4
barBack.BorderSizePixel = 0
barBack.Parent = background
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBack
local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(245, 200, 60)
barFill.BorderSizePixel = 0
barFill.Parent = barBack
barCorner:Clone().Parent = barFill

gui.Parent = player:WaitForChild("PlayerGui")

local TOTAL_STEPS = 5
local function step(index: number, text: string)
	status.Text = text
	TweenService:Create(barFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(index / TOTAL_STEPS, 1) }):Play()
end

-- 1. Assets
step(0, "Loading game...")
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- 2. Map
step(1, "Building the islands...")
for _, name in { "Plaza", "Plots", "Landmarks" } do
	workspace:WaitForChild(name)
end

-- 3. Home
step(2, "Finding your homestead...")
while player:GetAttribute("HomeSpawn") == nil do
	player:GetAttributeChangedSignal("HomeSpawn"):Wait()
end
local home = player:GetAttribute("HomeSpawn") :: Vector3

-- 4. Ground under home
step(3, "Growing your garden...")
local rayParams = RaycastParams.new()
rayParams.IgnoreWater = true
local started = os.clock()
while not workspace:Raycast(home + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), rayParams) do
	if os.clock() - started > GROUND_TIMEOUT then
		warn("[LoadingScreen] No ground under home spawn after", GROUND_TIMEOUT, "seconds; continuing anyway")
		break
	end
	task.wait(0.2)
end

-- 5. Spawn
step(4, "Entering Gardenbound...")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local clientReady = remotes:WaitForChild("ClientReady") :: RemoteEvent
clientReady:FireServer()

started = os.clock()
while os.clock() - started < ARRIVE_TIMEOUT do
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and (root.Position - home).Magnitude < 30 then
		break
	end
	task.wait(0.1)
end
step(5, "Welcome!")
task.wait(0.4)

-- Fade out, then remove.
local fade = TweenInfo.new(0.6)
TweenService:Create(background, fade, { BackgroundTransparency = 1 }):Play()
for _, child in background:GetDescendants() do
	if child:IsA("TextLabel") then
		TweenService:Create(child, fade, { TextTransparency = 1 }):Play()
	elseif child:IsA("Frame") then
		TweenService:Create(child, fade, { BackgroundTransparency = 1 }):Play()
	end
end
task.wait(0.7)
gui:Destroy()
