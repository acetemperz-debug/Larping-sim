--!strict
--[[
	Effects.lua

	Applies the data-driven `apply` tables defined in Shared/Events.lua. Random
	events, exposure events and anything else that wants to nudge the player's
	numbers all funnel through here so the rules stay in one place.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Milestones = require(Shared.Milestones)

local Feedback = require(script.Parent.Feedback)

local Effects = {}

--- Adds followers, fires any milestone cards crossed on the way up, and keeps
--- the peak-follower stat honest.
function Effects.addFollowers(player: Player, profile, amount: number)
	local before = profile.followers
	profile.followers = math.max(0, math.floor(before + amount))

	if profile.followers > profile.stats.peakFollowers then
		profile.stats.peakFollowers = profile.followers
	end

	for _, milestone in ipairs(Milestones.crossed(before, profile.followers)) do
		profile.cloutBonus += milestone.cloutBonus
		Feedback.milestone(player, milestone)
	end

	return profile.followers - before
end

function Effects.addCash(profile, amount: number)
	profile.cash = math.max(0, profile.cash + amount)
	if amount > 0 then
		profile.stats.lifetimeCash += amount
	end
end

function Effects.addSuspicion(profile, amount: number)
	profile.suspicion = math.clamp(profile.suspicion + amount, 0, Balance.SuspicionMax)
end

--- Runs one event's `apply` table against a player.
function Effects.apply(player: Player, profile, event, derived)
	local apply = event.apply or {}
	local summary = {}

	if apply.followersPct then
		local delta = Effects.addFollowers(player, profile, profile.followers * apply.followersPct)
		table.insert(summary, { kind = "followers", value = delta })
	end
	if apply.followers then
		local delta = Effects.addFollowers(player, profile, apply.followers)
		table.insert(summary, { kind = "followers", value = delta })
	end

	if apply.cashPct then
		local delta = profile.cash * apply.cashPct
		Effects.addCash(profile, delta)
		table.insert(summary, { kind = "cash", value = delta })
	end
	if apply.cash then
		Effects.addCash(profile, apply.cash)
		table.insert(summary, { kind = "cash", value = apply.cash })
	end
	if apply.cashPerFollower then
		local delta = profile.followers * apply.cashPerFollower
		Effects.addCash(profile, delta)
		table.insert(summary, { kind = "cash", value = delta })
	end

	if apply.cloutPct and derived then
		local bonus = derived.clout * apply.cloutPct
		profile.cloutBonus += bonus
		table.insert(summary, { kind = "clout", value = bonus })
	end

	if apply.suspicion then
		Effects.addSuspicion(profile, apply.suspicion)
		table.insert(summary, { kind = "suspicion", value = apply.suspicion })
	end

	if apply.clearRentals then
		local count = 0
		for itemId in pairs(profile.rentals) do
			profile.rentals[itemId] = nil
			count += 1
		end
		profile.stats.rentalsExpired += count
		table.insert(summary, { kind = "rentals", value = -count })
	end

	if apply.buff then
		table.insert(profile.buffs, {
			name = apply.buff.name,
			followers = apply.buff.followers or 1,
			cash = apply.buff.cash or 1,
			expires = os.time() + apply.buff.duration,
		})
	end

	return summary
end

return Effects
