--!strict
--[[
	Content.lua

	Making a post. The single most important formula in the game:

		followers = spotBase
		          * cloutFactor(clout)
		          * followerMultipliers
		          * repetitionPenalty
		          * viralMultiplier

	Suspicion is generated here in proportion to how much of your apparent
	wealth is rented rather than owned. Post from a Lamborghini you are renting
	by the minute and people start asking questions. Post from a watch you
	actually bought and they don't.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Areas = require(Shared.Areas)
local Items = require(Shared.Items)
local Captions = require(Shared.Captions)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local Feedback = require(script.Parent.Feedback)

local Content = {}

local rng = Random.new()

--- How repetitive the last few posts have been. 1 = fresh, RepeatPenalty = stale.
local function repetitionPenalty(profile, spotId: string): (number, boolean)
	local repeats = 0
	for _, recent in ipairs(profile.recentSpots) do
		if recent == spotId then
			repeats += 1
		end
	end
	if repeats == 0 then
		return 1, false
	end
	local penalty = math.max(Balance.RepeatPenalty, 1 - repeats * 0.22)
	return penalty, repeats >= 3
end

local function rememberSpot(profile, spotId: string)
	table.insert(profile.recentSpots, 1, spotId)
	while #profile.recentSpots > Balance.RecentPostMemory do
		table.remove(profile.recentSpots)
	end
end

--- The most impressive thing currently propping you up, and how much of your
--- clout is borrowed.
local function bestProp(profile, derived)
	local bestId, bestClout = nil, 0
	local rentedClout, totalClout = 0, 0

	for itemId, item in pairs(derived.active) do
		local clout = item.clout or 0
		totalClout += clout
		if profile.rentals[itemId] then
			rentedClout += clout
		end
		if clout > bestClout then
			bestClout = clout
			bestId = itemId
		end
	end

	local rentedShare = 0
	if totalClout > 0 then
		rentedShare = rentedClout / totalClout
	end

	return bestId, rentedShare
end

--[[
	Creates one post.

	`auto` marks posts made by a hired social media manager: slightly worse
	output, no cooldown, no repetition memory. You are paying for volume.
]]
function Content.create(player: Player, profile, spotId: string, auto: boolean?)
	local spot = Areas.spot(spotId)
	if not spot then
		return { ok = false, err = "There's nothing to film here." }
	end

	local area = Areas.get(spot.areaId)
	if profile.followers < area.unlockFollowers then
		return { ok = false, err = area.name .. " needs " .. Format.short(area.unlockFollowers) .. " followers." }
	end

	if not auto then
		local since = os.clock() - profile.lastPost
		if since < Balance.ContentCooldown then
			return { ok = false, err = "Let the last one breathe." }
		end
		profile.lastPost = os.clock()
	end

	local derived = State.compute(profile)
	local propId, rentedShare = bestProp(profile, derived)

	local penalty, stale = 1, false
	if not auto then
		penalty, stale = repetitionPenalty(profile, spotId)
	end

	local quality = auto and Balance.AutoPostQualityFloor or 1

	local gain = spot.base
		* State.cloutFactor(derived.clout)
		* derived.followerMult
		* penalty
		* quality

	-- Virality. Rare, enormous, and the reason anyone keeps posting.
	local viral = false
	local banner = nil
	if rng:NextNumber() < Balance.ViralChance then
		local multiplier = rng:NextNumber(Balance.ViralMultiplierMin, Balance.ViralMultiplierMax)
		gain *= multiplier
		viral = true
		banner = Captions.viralBanner(rng)
	end

	local delta = Effects.addFollowers(player, profile, gain)
	profile.stats.postsMade += 1

	-- Renting your entire personality is noticed eventually.
	local suspicionGain = rentedShare * 0.8
	if stale then
		suspicionGain += Balance.RepeatSuspicion
	end
	Effects.addSuspicion(profile, suspicionGain)

	if not auto then
		rememberSpot(profile, spotId)
	end

	local item = propId and Items.get(propId) or nil
	local post = {
		caption = Captions.pick(spot.caption, propId, rng),
		location = spot.name,
		areaName = area.name,
		followers = delta,
		viral = viral,
		banner = banner,
		propName = item and item.name or nil,
		auto = auto or false,
		stale = stale,
	}

	Feedback.feed(player, post)
	State.push(player, profile, derived)

	return { ok = true, post = post }
end

--[[
	Social media manager tick. Picks the best spot the player has unlocked and
	posts from it, whether or not they are anywhere near it. Nobody checks.
]]
function Content.autoPost(player: Player, profile)
	local derived = State.compute(profile)
	if not derived.autoPostInterval then
		return
	end

	local now = os.clock()
	if now < profile.autoPostAt then
		return
	end
	profile.autoPostAt = now + derived.autoPostInterval

	local bestSpot = nil
	for index = derived.areaIndex, 1, -1 do
		local area = Areas.List[index]
		for _, spot in ipairs(area.spots) do
			if not bestSpot or spot.base > bestSpot.base then
				bestSpot = spot
			end
		end
		if bestSpot then
			break
		end
	end

	if bestSpot then
		Content.create(player, profile, bestSpot.id, true)
	end
end

return Content
