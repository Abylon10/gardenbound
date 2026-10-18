-- Creates and returns RemoteEvents in ReplicatedStorage.Remotes. Every
-- system gets its remotes here so the folder is made once.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		return existing :: Folder
	end
	local created = Instance.new("Folder")
	created.Name = "Remotes"
	created.Parent = ReplicatedStorage
	return created
end

function Remotes.event(name: string): RemoteEvent
	local parent = folder()
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing :: RemoteEvent
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

return Remotes
