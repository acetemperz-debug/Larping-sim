--!strict
--[[
	Suspicion.lua

	Suspicion decays slowly on its own, spikes when you cut corners, and at 100
	the internet finally does the one thing it is genuinely good at.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Events = require(Shared.Events)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local Feedback = require(script.Parent.Feedback)

local Suspicion = {}

local rng = Random.new()

function Suspicion.decay(profile, dt: number)
	if profile.suspicion <= 0 then
		return
	end
	profile.suspicion = math.max(0, profile.suspicion - Balance.SuspicionDecayPerSecond * dt)
end

--- Students who are now running their own operations generate heat for you.
function Suspicion.downlineDrip(profile, dt: number)
	if profile.downline <= 0 then
		return
	end
	Effects.addSuspicion(profile, profile.downline * Balance.DownlineSuspicionDrip * dt)
end

--- The full unravelling.
function Suspicion.expose(player: Player, profile)
	local lostFollowers = math.floor(profile.followers * Balance.ExposeFollowerLoss)
	local lostCash = profile.cash * Balance.ExposeCashLoss

	profile.followers = math.max(0, profile.followers - lostFollowers)
	profile.cash = math.max(0, profile.cash - lostCash)

	local rentalsLost = 0
	for itemId in pairs(profile.rentals) do
		profile.rentals[itemId] = nil
		rentalsLost += 1
	end
	profile.stats.rentalsExpired += rentalsLost
	profile.stats.timesExposed += 1
	profile.suspicion = 35

	Feedback.notify(
		player,
		"sus",
		"YOU HAVE BEEN EXPOSED",
		("-%s followers, -%s, and every rental recalled. Time for a heartfelt apology video.")
			:format(Format.short(lostFollowers), Format.money(lostCash))
	)
	Feedback.broadcast(player.DisplayName .. " has been exposed. The comments are merciless.", "EXPOSÉ")

	State.push(player, profile)
end

--- Rolls a suspicion event if the player is dirty enough to deserve one.
function Suspicion.rollEvent(player: Player, profile)
	if profile.suspicion < 25 then
		return
	end

	local chance = (profile.suspicion / Balance.SuspicionMax) * Balance.SuspicionEventChanceAt100
	if rng:NextNumber() > chance then
		return
	end

	local event = Events.rollSuspicion(profile.suspicion, rng)
	if not event then
		return
	end

	local derived = State.compute(profile)
	Effects.apply(player, profile, event, derived)
	Feedback.notify(player, "sus", event.name, event.text)
	State.push(player, profile)
end

--- Called every heartbeat; handles the 100% case.
function Suspicion.check(player: Player, profile)
	if profile.suspicion >= Balance.ExposeThreshold then
		Suspicion.expose(player, profile)
	end
end

return Suspicion
