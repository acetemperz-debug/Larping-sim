--!strict
--[[
	LARPing Simulator -- server entry point.

	A satirical tycoon about spending enormous amounts of real money to appear
	to have enormous amounts of money. Earn, spend it all looking rich, gain
	followers, sell a course, repeat at a more expensive tier.

	Boot order matters: Net must exist before any service tries to fire a
	remote, and the world must exist before Interactions can bind to it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)

local PlayerData = require(script.PlayerData)
local State = require(script.State)
local Actions = require(script.Actions)
local Simulation = require(script.Simulation)
local WorldBuilder = require(script.WorldBuilder)
local Interactions = require(script.Interactions)
local Leaderboards = require(script.Leaderboards)
local NpcService = require(script.NpcService)
local Feedback = require(script.Feedback)

-- 1. Remotes first, so nothing fires into the void.
Net.get()

-- 2. The world.
local world = WorldBuilder.build()
Interactions.bind(world)

-- 3. Client requests.
Net.fn("Request").OnServerInvoke = function(player, action, payload)
	return Actions.handle(player, action, payload)
end

-- 4. Players.
local function addLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local followers = Instance.new("IntValue")
	followers.Name = "Followers"
	followers.Parent = stats

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = stats

	stats.Parent = player
end

local function onPlayerAdded(player: Player)
	local profile = PlayerData.load(player)
	addLeaderstats(player)
	Simulation.track(player)

	-- Rentals kept running while they were logged off. Tell them the bad news.
	local lapsed = State.expire(profile)
	if #lapsed > 0 then
		Feedback.notify(
			player,
			"bad",
			"WHILE YOU WERE AWAY",
			#lapsed .. " rental(s) expired and were collected. The meter never stops."
		)
	end

	State.push(player, profile)

	if profile.stats.postsMade == 0 then
		task.delay(2, function()
			if player.Parent then
				Feedback.notify(
					player,
					"info",
					"WELCOME TO THE GRIND",
					"You have £50 and no followers. Stand on a content spot and post something untrue."
				)
			end
		end)
	end
end

local function onPlayerRemoving(player: Player)
	Leaderboards.submit(player)
	Simulation.forget(player)
	Actions.forget(player)
	PlayerData.release(player)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- 5. Loops.
PlayerData.start()
Simulation.start()
Leaderboards.start()
NpcService.start()

print("[LARP] LARPing Simulator server ready. Nothing here is real.")
