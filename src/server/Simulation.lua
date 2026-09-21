--!strict
--[[
	Simulation.lua

	The single heartbeat. Running everything off one loop keeps the per-player
	timers in one place and avoids a dozen competing task.wait schedules.

	Every second, for each player:
		* expire rentals and buffs (and tell them what they just lost)
		* let hired social media managers post
		* decay suspicion, apply downline heat, check for exposure
		* every CourseTickInterval, sell courses
		* roll random and suspicion events on their own timers
		* push a fresh snapshot
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Items = require(Shared.Items)

local PlayerData = require(script.Parent.PlayerData)
local State = require(script.Parent.State)
local Content = require(script.Parent.Content)
local CourseService = require(script.Parent.CourseService)
local Suspicion = require(script.Parent.Suspicion)
local RandomEvents = require(script.Parent.RandomEvents)
local Feedback = require(script.Parent.Feedback)

local Simulation = {}

local timers: { [number]: any } = {}

function Simulation.track(player: Player)
	timers[player.UserId] = {
		sale = 0,
		random = Balance.RandomEventInterval * 0.5,
		suspicion = Balance.SuspicionEventInterval * 0.5,
	}
end

function Simulation.forget(player: Player)
	timers[player.UserId] = nil
end

local function reportLapsed(player: Player, lapsed: { string })
	if #lapsed == 0 then
		return
	end

	local names = {}
	for _, itemId in ipairs(lapsed) do
		local item = Items.get(itemId)
		if item then
			table.insert(names, item.name)
		end
	end
	if #names == 0 then
		return
	end

	local headline = #names == 1 and names[1] .. " has gone back."
		or (#names .. " rentals have gone back.")

	Feedback.notify(player, "bad", "RENTAL EXPIRED", headline .. " Your clout just evaporated with it.")
end

local function step(player: Player, dt: number)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end

	local clock = timers[player.UserId]
	if not clock then
		Simulation.track(player)
		clock = timers[player.UserId]
	end

	reportLapsed(player, State.expire(profile))

	Suspicion.decay(profile, dt)
	Suspicion.downlineDrip(profile, dt)

	Content.autoPost(player, profile)

	clock.sale += dt
	if clock.sale >= Balance.CourseTickInterval then
		clock.sale -= Balance.CourseTickInterval
		CourseService.tick(player, profile)
	end

	clock.random += dt
	if clock.random >= Balance.RandomEventInterval then
		clock.random = 0
		RandomEvents.roll(player, profile)
	end

	clock.suspicion += dt
	if clock.suspicion >= Balance.SuspicionEventInterval then
		clock.suspicion = 0
		Suspicion.rollEvent(player, profile)
	end

	Suspicion.check(player, profile)

	-- leaderstats mirror, so the Roblox player list is useful at a glance.
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local derived = State.compute(profile)
		local followers = stats:FindFirstChild("Followers")
		local cash = stats:FindFirstChild("Cash")
		if followers then
			(followers :: IntValue).Value = math.min(profile.followers, 2 ^ 31 - 1)
		end
		if cash then
			(cash :: IntValue).Value = math.min(math.floor(profile.cash), 2 ^ 31 - 1)
		end
		State.push(player, profile, derived)
	else
		State.push(player, profile)
	end
end

function Simulation.start()
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(1)
			local now = os.clock()
			local dt = now - last
			last = now

			for _, player in ipairs(Players:GetPlayers()) do
				local success, err = pcall(step, player, dt)
				if not success then
					warn("[LARP] simulation step failed for " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end)
end

return Simulation
