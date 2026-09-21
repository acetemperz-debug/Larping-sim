--!strict
--[[
	PodcastService.lua

	You pay to appear. You answer one question. The answer is the whole
	mechanic: the most viral answers are also the ones that get clipped and
	used against you.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Podcasts = require(Shared.Podcasts)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local Feedback = require(script.Parent.Feedback)

local PodcastService = {}

local rng = Random.new()

function PodcastService.appear(player: Player, profile, tierId: string)
	local tier = Podcasts.ById[tierId]
	if not tier then
		return { ok = false, err = "That show doesn't exist." }
	end

	if profile.pendingQuestion then
		return { ok = false, err = "You're mid-episode. Answer the question." }
	end

	local since = os.clock() - profile.lastPodcast
	if since < Podcasts.Cooldown then
		return { ok = false, err = "Next booking in " .. Format.timer(Podcasts.Cooldown - since) .. "." }
	end

	if profile.followers < tier.req then
		return { ok = false, err = "They won't book you under " .. Format.short(tier.req) .. " followers." }
	end

	if profile.cash < tier.cost then
		return { ok = false, err = "Appearing costs " .. Format.money(tier.cost) .. ". Yes, you pay them." }
	end

	profile.cash -= tier.cost
	profile.stats.spentLarping += tier.cost
	profile.lastPodcast = os.clock()

	local derived = State.compute(profile)
	local baseGain = (tier.flat + profile.followers * tier.pct) * derived.followerMult

	local question = Podcasts.randomQuestion(rng)
	local answers = {}
	for index, answer in ipairs(question.answers) do
		table.insert(answers, { index = index, text = answer.text })
	end

	profile.pendingQuestion = {
		tierId = tier.id,
		prompt = question.prompt,
		answers = answers,
		baseGain = baseGain,
		questionPrompt = question.prompt,
	}

	Feedback.question(player, {
		show = tier.name,
		prompt = question.prompt,
		answers = answers,
	})

	State.push(player, profile, derived)
	return { ok = true }
end

function PodcastService.answer(player: Player, profile, answerIndex: number)
	local pending = profile.pendingQuestion
	if not pending then
		return { ok = false, err = "No question on the table." }
	end

	-- Find the question again by its prompt so the answer effects stay server-side.
	local question = nil
	for _, candidate in ipairs(Podcasts.Questions) do
		if candidate.prompt == pending.questionPrompt then
			question = candidate
			break
		end
	end

	if not question then
		profile.pendingQuestion = nil
		return { ok = false, err = "The episode was never released." }
	end

	local answer = question.answers[answerIndex]
	if not answer then
		return { ok = false, err = "Pick one of the answers." }
	end

	profile.pendingQuestion = nil

	local gained = Effects.addFollowers(player, profile, pending.baseGain * answer.mult)
	profile.cloutBonus += answer.clout
	Effects.addSuspicion(profile, answer.sus)

	local tier = Podcasts.ById[pending.tierId]
	Feedback.notify(
		player,
		answer.sus > 8 and "bad" or "good",
		(tier and tier.name or "The Podcast") .. " — episode live",
		('"' .. answer.text .. '" — ' .. answer.reply .. " +" .. Format.short(gained) .. " followers.")
	)

	State.push(player, profile)
	return { ok = true, followers = gained, reply = answer.reply }
end

function PodcastService.catalogue(profile)
	local entries = {}
	local derived = State.compute(profile)

	for _, tier in ipairs(Podcasts.Tiers) do
		table.insert(entries, {
			id = tier.id,
			name = tier.name,
			desc = tier.desc,
			cost = tier.cost,
			req = tier.req,
			unlocked = profile.followers >= tier.req,
			affordable = profile.cash >= tier.cost,
			estimate = (tier.flat + profile.followers * tier.pct) * derived.followerMult,
		})
	end

	return {
		entries = entries,
		cooldownRemaining = math.max(0, Podcasts.Cooldown - (os.clock() - profile.lastPodcast)),
	}
end

return PodcastService
