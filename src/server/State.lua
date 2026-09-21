--!strict
--[[
	State.lua

	Turns a raw profile into the numbers the rest of the game actually uses,
	and pushes snapshots down to the client.

	Clout rules
	-----------
	* Non-stacking category: only your single best owned/active item counts.
	  You are upgrading a costume, not hoarding one.
	* Stacking category: everything counts. Accessories, awards and rented
	  humans all pile on top of each other.
	* The total is scaled by your prestige clout multiplier, then event and
	  milestone bonuses are added on top.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Items = require(Shared.Items)
local Courses = require(Shared.Courses)
local Prestige = require(Shared.Prestige)
local Podcasts = require(Shared.Podcasts)
local Areas = require(Shared.Areas)
local Net = require(Shared.Net)

local PlayerData = require(script.Parent.PlayerData)

local State = {}

--- Removes expired rentals and buffs. Returns the list of rental ids that just
--- lapsed so callers can tell the player their Lamborghini has gone home.
function State.expire(profile): { string }
	local now = os.time()
	local lapsed = {}

	for itemId, expiry in pairs(profile.rentals) do
		if now >= expiry then
			profile.rentals[itemId] = nil
			profile.stats.rentalsExpired += 1
			table.insert(lapsed, itemId)
		end
	end

	for index = #profile.buffs, 1, -1 do
		if now >= profile.buffs[index].expires then
			table.remove(profile.buffs, index)
		end
	end

	return lapsed
end

--- Every item currently contributing to the player's numbers.
local function activeItems(profile)
	local active = {}
	for itemId in pairs(profile.owned) do
		local item = Items.get(itemId)
		if item then
			active[itemId] = item
		end
	end
	for itemId in pairs(profile.rentals) do
		local item = Items.get(itemId)
		if item then
			active[itemId] = item
		end
	end
	return active
end

State.activeItems = activeItems

--- The full derived view of a profile.
function State.compute(profile)
	local active = activeItems(profile)
	local prestigeLevel = Prestige.get(profile.prestige)

	--[[
		Work out which items actually count before reading anything off them.

		In a non-stacking category only the single best item contributes, and
		that applies to its multipliers and automation too, not just its clout.
		Otherwise every buff you had ever rented would multiply together and a
		player could be simultaneously in monk mode, mid cold-plunge and awake
		at 4AM for a combined 11x, which broke the whole economy in testing.
	]]
	local bestInCategory: { [string]: any } = {}
	local contributing = {}

	for _, item in pairs(active) do
		local category = Items.category(item.category)
		if category and category.stacking then
			table.insert(contributing, item)
		else
			local incumbent = bestInCategory[item.category]
			if not incumbent or (item.clout or 0) > (incumbent.clout or 0) then
				bestInCategory[item.category] = item
			end
		end
	end

	for _, item in pairs(bestInCategory) do
		table.insert(contributing, item)
	end

	local rawClout = 0
	local followerMult = 1
	local cashMult = 1
	local autoPostInterval = nil

	for _, item in ipairs(contributing) do
		rawClout += item.clout or 0

		if item.mult then
			followerMult *= item.mult.followers or 1
			cashMult *= item.mult.cash or 1
		end

		if item.autoPost then
			autoPostInterval = math.min(autoPostInterval or math.huge, item.autoPost)
		end
	end

	local clout = rawClout * prestigeLevel.cloutMult + profile.cloutBonus

	-- Buffs stack multiplicatively on top of everything else.
	for _, buff in ipairs(profile.buffs) do
		followerMult *= buff.followers or 1
		cashMult *= buff.cash or 1
	end

	followerMult *= prestigeLevel.followerMult
	cashMult *= prestigeLevel.cashMult

	-- The pyramid takes its cut upward, forever.
	local downlineCut = 1 + profile.downline * Balance.DownlineCutPerStudent
	cashMult *= downlineCut

	-- Suspicion strangles revenue but never follower growth. People love a mess.
	local suspicionPenalty = 1 - (profile.suspicion / Balance.SuspicionMax) * Balance.SuspicionRevenuePenalty

	local course = Courses.ById[profile.courseId] or Courses.List[1]
	if not Courses.isUnlocked(course, profile.followers, clout) then
		course = Courses.bestAvailable(profile.followers, clout)
		profile.courseId = course.id
	end

	-- Audience is monetised sub-linearly; see Balance.RevenueExponent.
	local monetisable = profile.followers ^ Balance.RevenueExponent

	local revenuePerTick = monetisable
		* course.conversion
		* course.price
		* cashMult
		* suspicionPenalty

	local mentorship = Courses.bestMentorship(profile.followers)
	local mentorshipPerTick = 0
	if mentorship then
		mentorshipPerTick = monetisable * mentorship.rate * mentorship.price * cashMult * suspicionPenalty
	end

	return {
		clout = clout,
		rawClout = rawClout,
		followerMult = followerMult,
		cashMult = cashMult,
		suspicionPenalty = suspicionPenalty,
		autoPostInterval = autoPostInterval,
		course = course,
		revenuePerTick = revenuePerTick,
		mentorship = mentorship,
		mentorshipPerTick = mentorshipPerTick,
		prestigeLevel = prestigeLevel,
		areaIndex = Areas.highestUnlocked(profile.followers),
		active = active,
		contributing = contributing,
	}
end

--- Clout's contribution to follower yield. Deliberately shallow so that a
--- player cannot simply buy their way past the content loop: roughly 1.7x
--- when you own a fake watch, roughly 9x when you own everything.
function State.cloutFactor(clout: number): number
	if clout <= 0 then
		return 1
	end
	return 1 + (clout / Balance.CloutBase) ^ Balance.CloutExponent
end

-- Replication --------------------------------------------------------------

local stateEvent: RemoteEvent? = nil

local function getStateEvent(): RemoteEvent
	if not stateEvent then
		stateEvent = Net.get():FindFirstChild("State") :: RemoteEvent
	end
	return stateEvent :: RemoteEvent
end

function State.snapshot(profile, derived)
	derived = derived or State.compute(profile)
	local now = os.time()

	local rentals = {}
	for itemId, expiry in pairs(profile.rentals) do
		rentals[itemId] = math.max(0, expiry - now)
	end

	local buffs = {}
	for _, buff in ipairs(profile.buffs) do
		table.insert(buffs, {
			name = buff.name,
			followers = buff.followers,
			cash = buff.cash,
			remaining = math.max(0, buff.expires - now),
		})
	end

	local owned = {}
	for itemId in pairs(profile.owned) do
		owned[itemId] = true
	end

	return {
		cash = profile.cash,
		followers = profile.followers,
		clout = derived.clout,
		suspicion = profile.suspicion,

		owned = owned,
		rentals = rentals,
		buffs = buffs,

		courseId = derived.course.id,
		coursePrice = derived.course.price,
		courseName = derived.course.name,
		revenuePerTick = derived.revenuePerTick + derived.mentorshipPerTick,
		tickInterval = Balance.CourseTickInterval,

		followerMult = derived.followerMult,
		cashMult = derived.cashMult,
		autoPostInterval = derived.autoPostInterval,

		prestige = profile.prestige,
		prestigeTitle = derived.prestigeLevel.title,
		prestigeNext = Prestige.requirement(profile.prestige),

		downline = profile.downline,
		areaIndex = derived.areaIndex,
		stats = profile.stats,
		pendingQuestion = profile.pendingQuestion,

		postReady = os.clock() - profile.lastPost >= Balance.ContentCooldown,
		launchIn = math.max(0, Balance.LaunchCooldown - (os.clock() - profile.lastLaunch)),
		podcastIn = math.max(0, Podcasts.Cooldown - (os.clock() - profile.lastPodcast)),
	}
end

--- Pushes a fresh snapshot to one player.
function State.push(player: Player, profile: any?, derived: any?)
	profile = profile or PlayerData.get(player)
	if not profile then
		return
	end
	getStateEvent():FireClient(player, State.snapshot(profile, derived))
end

return State
