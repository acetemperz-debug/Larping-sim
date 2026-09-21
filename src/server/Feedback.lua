--!strict
--[[ Feedback.lua -- every server -> client message the UI reacts to. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)

local Feedback = {}

local function remote(name: string): RemoteEvent
	return Net.get():FindFirstChild(name) :: RemoteEvent
end

--- kind: "good" | "bad" | "info" | "money" | "sus"
function Feedback.notify(player: Player, kind: string, title: string, text: string?)
	remote("Notify"):FireClient(player, { kind = kind, title = title, text = text })
end

--- post = { caption, location, followers, viral, banner, itemName }
function Feedback.feed(player: Player, post)
	remote("Feed"):FireClient(player, post)
end

function Feedback.milestone(player: Player, milestone)
	remote("Milestone"):FireClient(player, milestone)
end

function Feedback.question(player: Player, question)
	remote("Question"):FireClient(player, question)
end

function Feedback.broadcast(text: string, title: string?)
	remote("Broadcast"):FireAllClients({ title = title or "MEANWHILE, ELSEWHERE", text = text })
end

return Feedback
