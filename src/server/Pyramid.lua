--!strict
--[[
	Pyramid.lua

	The endgame mechanic. Your students stop buying courses and start selling
	them, and you take a permanent cut of everything underneath you. They also
	generate suspicion, because forty people running the identical grift with
	the identical slides is, eventually, noticeable.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Feedback = require(script.Parent.Feedback)

local Pyramid = {}

local GRADUATION_LINES = {
	"They have already outsold you in their first week.",
	"Their course is £200 more expensive than yours. You are proud and furious.",
	"They have started calling you 'my mentor' in videos you are not in.",
	"They rented the same Lamborghini. On the same day. Two hours after you.",
	"Their first student has just recruited three more. It is spreading.",
}

function Pyramid.cost(profile): number
	return math.floor(Balance.DownlineCostBase * Balance.DownlineCostGrowth ^ profile.downline)
end

function Pyramid.recruit(player: Player, profile)
	if profile.followers < Balance.DownlineUnlockFollowers then
		return {
			ok = false,
			err = "Needs " .. Format.short(Balance.DownlineUnlockFollowers) .. " followers before anyone will copy you.",
		}
	end

	if profile.downline >= Balance.DownlineMax then
		return { ok = false, err = "Your downline is full. The market is saturated. By you." }
	end

	local cost = Pyramid.cost(profile)
	if profile.cash < cost then
		return { ok = false, err = "Onboarding costs " .. Format.money(cost) .. "." }
	end

	profile.cash -= cost
	profile.stats.spentLarping += cost
	profile.downline += 1

	local cut = math.floor(profile.downline * Balance.DownlineCutPerStudent * 100)
	Feedback.notify(
		player,
		"good",
		"NEW GURU GRADUATED (" .. profile.downline .. ")",
		GRADUATION_LINES[math.random(1, #GRADUATION_LINES)] .. " You now take +" .. cut .. "% of all course revenue."
	)

	State.push(player, profile)
	return { ok = true, downline = profile.downline }
end

function Pyramid.info(profile)
	return {
		downline = profile.downline,
		max = Balance.DownlineMax,
		cost = Pyramid.cost(profile),
		cutPercent = profile.downline * Balance.DownlineCutPerStudent * 100,
		perStudentPercent = Balance.DownlineCutPerStudent * 100,
		growthPercent = (Balance.DownlineCostGrowth - 1) * 100,
		unlockFollowers = Balance.DownlineUnlockFollowers,
		unlocked = profile.followers >= Balance.DownlineUnlockFollowers,
	}
end

return Pyramid
