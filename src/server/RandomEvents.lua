--!strict
--[[ RandomEvents.lua -- the thing that happens while you are doing something else. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Events = require(Shared.Events)

local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local Feedback = require(script.Parent.Feedback)

local RandomEvents = {}

local rng = Random.new()

function RandomEvents.roll(player: Player, profile)
	if rng:NextNumber() > Balance.RandomEventChance then
		return
	end

	-- A player with no audience has nothing to happen to them.
	if profile.followers < 50 then
		return
	end

	local event = Events.rollRandom(rng)
	local derived = State.compute(profile)
	Effects.apply(player, profile, event, derived)

	Feedback.notify(player, event.good and "good" or "bad", event.name, event.text)
	State.push(player, profile)
end

return RandomEvents
