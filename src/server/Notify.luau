-- Short messages shown to one player as a toast ("Not enough wood").
-- kind: "info" (default), "success", or "error".

local Remotes = require(script.Parent.Remotes)

local Notify = {}

local remote = Remotes.event("Notify")

function Notify.send(player: Player, message: string, kind: string?)
	remote:FireClient(player, message, kind or "info")
end

return Notify
