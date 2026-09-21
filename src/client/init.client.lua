--!strict
--[[
	LARPing Simulator -- client entry point.

	Builds the HUD and wires the five server -> client streams to it. All game
	logic lives on the server; this file only draws what it is told and asks
	politely for things.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)

local Request = require(script.Request)
local Hud = require(script.Hud)
local Toasts = require(script.Toasts)
local Feed = require(script.Feed)
local Panels = require(script.Panels)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screen = Instance.new("ScreenGui")
screen.Name = "LarpingSimulator"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

Hud.build(screen)
Toasts.build(screen)
Feed.build(screen)
Panels.build(screen)

-- Server -> client ---------------------------------------------------------

Net.event("State").OnClientEvent:Connect(function(state)
	Hud.update(state)
	Panels.onState(state)
end)

Net.event("Notify").OnClientEvent:Connect(function(payload)
	Toasts.notify(payload)
end)

Net.event("Feed").OnClientEvent:Connect(function(post)
	Feed.post(post)
end)

Net.event("Milestone").OnClientEvent:Connect(function(milestone)
	Toasts.milestone(milestone)
end)

Net.event("Broadcast").OnClientEvent:Connect(function(payload)
	Toasts.broadcast(payload)
end)

Net.event("Question").OnClientEvent:Connect(function(payload)
	Panels.question(payload)
end)

-- A kiosk in the world asked us to open something.
Net.event("OpenUI").OnClientEvent:Connect(function(payload)
	Panels.open(payload.panel, payload.payload)
end)

-- Client -> server ---------------------------------------------------------

Hud.onRail("launch", function()
	Request.spawn("launch", nil, function(response)
		if not response.ok and response.err then
			Toasts.notify({ kind = "bad", title = "Can't launch", text = response.err })
		end
	end)
end)

for _, panel in ipairs({ "courses", "podcast", "pyramid", "travel", "rebrand" }) do
	Hud.onRail(panel, function()
		if Panels.isOpen() then
			Panels.close()
		end
		Panels.open(panel)
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q and Panels.isOpen() then
		Panels.close()
	end
end)

-- Ask for an opening snapshot in case we joined mid-tick.
Request.spawn("state", nil, function(response)
	if response.ok and response.state then
		Hud.update(response.state)
		Panels.onState(response.state)
	end
end)

-- A small nudge for the first thirty seconds, since the whole loop hinges on
-- the player understanding that they are supposed to stand on a glowing pad.
task.delay(6, function()
	Toasts.notify({
		kind = "info",
		title = "HOW THIS WORKS",
		text = "Stand on a glowing pad and press E to post. Posts earn followers. Followers buy courses. Courses pay for rentals. Rentals earn followers. Nobody wins.",
	})
end)

print("[LARP] client ready. Remember: none of it is yours.")
