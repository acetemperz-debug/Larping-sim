--!strict
--[[
	Rebrand.lua -- prestige.

	Deletes everything you built and hands back a permanent multiplier and a
	more impressive noun. The downline survives, because those people are
	independent operators now and frankly they were never really yours.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Prestige = require(Shared.Prestige)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Feedback = require(script.Parent.Feedback)

local Rebrand = {}

function Rebrand.info(profile)
	local current = Prestige.get(profile.prestige)
	local nextLevel = Prestige.next(profile.prestige)

	return {
		level = profile.prestige,
		title = current.title,
		blurb = current.blurb,
		followerMult = current.followerMult,
		cashMult = current.cashMult,
		cloutMult = current.cloutMult,
		nextTitle = nextLevel and nextLevel.title or nil,
		nextBlurb = nextLevel and nextLevel.blurb or nil,
		nextRequirement = nextLevel and nextLevel.requirement or nil,
		nextFollowerMult = nextLevel and nextLevel.followerMult or nil,
		nextCashMult = nextLevel and nextLevel.cashMult or nil,
		nextCloutMult = nextLevel and nextLevel.cloutMult or nil,
		ready = nextLevel ~= nil and profile.followers >= nextLevel.requirement,
		maxed = nextLevel == nil,
		rebrands = profile.stats.rebrands,
	}
end

function Rebrand.perform(player: Player, profile)
	local nextLevel = Prestige.next(profile.prestige)
	if not nextLevel then
		return { ok = false, err = "There is nothing left to become." }
	end

	if profile.followers < nextLevel.requirement then
		return {
			ok = false,
			err = "Needs " .. Format.short(nextLevel.requirement) .. " followers to credibly reinvent yourself.",
		}
	end

	profile.prestige += 1
	profile.stats.rebrands += 1

	-- Everything the audience could see, gone.
	profile.cash = Balance.StartingCash
	profile.followers = 0
	profile.cloutBonus = 0
	profile.suspicion = 0
	profile.owned = {}
	profile.rentals = {}
	profile.buffs = {}
	profile.recentSpots = {}
	profile.courseId = Balance.StartingCourseId
	profile.pendingQuestion = nil

	Feedback.notify(
		player,
		"good",
		"REBRANDED — " .. nextLevel.title,
		nextLevel.blurb .. " Everything is gone except the multipliers and the confidence."
	)
	Feedback.broadcast(
		player.DisplayName .. " has deleted every video and returned as a " .. nextLevel.title .. ".",
		"REBRAND"
	)

	State.push(player, profile)
	return { ok = true, level = profile.prestige, title = nextLevel.title }
end

return Rebrand
