--!strict
--[[
	Events.lua

	Data-driven random events. The server reads the `apply` table rather than
	running arbitrary functions, which keeps everything serialisable and makes
	adding an event a one-table job.

	apply fields
	------------
	followers      flat follower change
	followersPct   proportional follower change (0.12 = +12%)
	cash           flat cash change
	cashPct        proportional cash change
	cloutPct       permanent clout bonus, as a proportion of current clout
	suspicion      flat suspicion change
	clearRentals   true -> every active rental ends immediately. Brutal.
	buff           { name, followers, cash, duration }
]]

local Events = {}

Events.Random = {
	{
		id = "ev_algo",
		name = "ALGORITHM BOOST",
		text = "The algorithm has decided you deserve this. It will change its mind shortly.",
		weight = 12,
		good = true,
		apply = { buff = { name = "Algorithm Boost", followers = 1.5, cash = 1, duration = 60 } },
	},
	{
		id = "ev_reel",
		name = "VIRAL REEL",
		text = "A 9-second clip of you pointing at a car has outperformed your entire body of work.",
		weight = 12,
		good = true,
		apply = { followersPct = 0.12 },
	},
	{
		id = "ev_hater",
		name = "HATER REACTION VIDEO",
		text = "Someone made a 40-minute takedown of you. Their audience is now your audience.",
		weight = 10,
		good = true,
		apply = { followersPct = 0.07, suspicion = 9 },
	},
	{
		id = "ev_deposit",
		name = "RENTAL DEPOSIT LOST",
		text = "There is a scuff on the wheel. There was always a scuff on the wheel. You are paying for the scuff.",
		weight = 9,
		good = false,
		apply = { cashPct = -0.12 },
	},
	{
		id = "ev_refund",
		name = "COURSE REFUND WAVE",
		text = "Forty people reached Lesson 5 and discovered it was an advert for Lesson 6.",
		weight = 9,
		good = false,
		apply = { cashPct = -0.1, suspicion = 4 },
	},
	{
		id = "ev_celeb",
		name = "CELEBRITY REPOST",
		text = "Someone genuinely famous reposted you. They have already deleted it, but screenshots exist.",
		weight = 6,
		good = true,
		apply = { cloutPct = 0.08, followersPct = 0.05 },
	},
	{
		id = "ev_podclip",
		name = "PODCAST CLIP GOES VIRAL",
		text = "The clip is you saying 'nobody talks about this'. Everybody talks about this.",
		weight = 8,
		good = true,
		apply = { followersPct = 0.18 },
	},
	{
		id = "ev_expose",
		name = "FAKE GURU EXPOSÉ",
		text = "A documentary channel with 3 million subscribers has started a series. You are episode 2.",
		weight = 7,
		good = false,
		apply = { suspicion = 18 },
	},
	{
		id = "ev_brand",
		name = "BRAND DEAL",
		text = "A questionable energy drink wants 15 seconds of your integrity.",
		weight = 8,
		good = true,
		apply = { cashPerFollower = 0.06 },
	},
	{
		id = "ev_frozen",
		name = "PAYMENT PROCESSOR FREEZE",
		text = "Your payment processor has 'a few questions about the refund rate'.",
		weight = 6,
		good = false,
		apply = { cashPct = -0.2, suspicion = 3 },
	},
	{
		id = "ev_copycat",
		name = "COPYCAT GURU",
		text = "Someone has copied your entire brand, including the typo in your bio.",
		weight = 7,
		good = false,
		apply = { followersPct = -0.03, suspicion = 2 },
	},
	{
		id = "ev_mentee",
		name = "MENTEE SUCCESS STORY",
		text = "One of your students made money. Not from the course. From selling their own course.",
		weight = 7,
		good = true,
		apply = { followersPct = 0.09, suspicion = -7 },
	},
	{
		id = "ev_blacklist",
		name = "BLACKLISTED BY EVERY RENTAL COMPANY",
		text = "They compared notes. Every single thing you are currently renting has been recalled.",
		weight = 3,
		good = false,
		apply = { clearRentals = true, suspicion = 5 },
	},
	{
		id = "ev_riot",
		name = "COMMENT SECTION RIOT",
		text = "The top comment has more likes than the post. It is one word long.",
		weight = 8,
		good = false,
		apply = { suspicion = 10, followersPct = 0.04 },
	},
	{
		id = "ev_motivation",
		name = "MOTIVATIONAL POST PERFORMS",
		text = "You posted a sunrise and the word 'grateful'. It outperformed the Lamborghini.",
		weight = 10,
		good = true,
		apply = { followersPct = 0.06, suspicion = -3 },
	},
}

-- Suspicion-gated exposure events. Only rolled once the player is dirty enough.
Events.Suspicion = {
	{
		id = "sus_investigation",
		name = "COMMENT SECTION INVESTIGATION",
		text = "People have noticed your Lamborghini has appeared in 14 other influencers' videos this month.",
		min = 25,
		apply = { suspicion = 6, followersPct = -0.02 },
	},
	{
		id = "sus_airbnb",
		name = "THE AIRBNB OWNER FOUND YOU",
		text = "They have posted the listing. Nightly rate included. It is not, in fact, your home.",
		min = 40,
		apply = { suspicion = 10, followersPct = -0.04 },
	},
	{
		id = "sus_watch",
		name = "WATCH CHECK FAILED",
		text = "A watch account zoomed in on the bezel alignment. It is over.",
		min = 35,
		apply = { suspicion = 8, followersPct = -0.03 },
	},
	{
		id = "sus_review",
		name = "COURSE REVIEW DRAMA",
		text = "One star. 4,000 words. Screenshots. Timestamps. A table of contents.",
		min = 30,
		apply = { suspicion = 5, cashPct = -0.08 },
	},
	{
		id = "sus_receipts",
		name = "THE RECEIPTS THREAD",
		text = "Someone has made a 47-tweet thread. Slide 12 is your old profile picture.",
		min = 55,
		apply = { suspicion = 12, followersPct = -0.08 },
	},
	{
		id = "sus_doc",
		name = "FULL-LENGTH DOCUMENTARY",
		text = "Ninety minutes. Drone shots of your parents' house. Ominous piano.",
		min = 75,
		apply = { suspicion = 15, followersPct = -0.15, cashPct = -0.2 },
	},
	{
		id = "sus_spotted",
		name = "SPOTTED RETURNING THE RENTAL",
		text = "Filmed handing back the keys, in the rain, holding a bus ticket.",
		min = 45,
		apply = { suspicion = 9, followersPct = -0.05 },
	},
}

Events.ById = {}
for _, list in ipairs({ Events.Random, Events.Suspicion }) do
	for _, event in ipairs(list) do
		Events.ById[event.id] = event
	end
end

Events.TotalRandomWeight = 0
for _, event in ipairs(Events.Random) do
	Events.TotalRandomWeight += event.weight
end

function Events.rollRandom(rng: Random)
	local target = rng:NextNumber() * Events.TotalRandomWeight
	local running = 0
	for _, event in ipairs(Events.Random) do
		running += event.weight
		if target <= running then
			return event
		end
	end
	return Events.Random[#Events.Random]
end

function Events.rollSuspicion(suspicion: number, rng: Random)
	local eligible = {}
	for _, event in ipairs(Events.Suspicion) do
		if suspicion >= event.min then
			table.insert(eligible, event)
		end
	end
	if #eligible == 0 then
		return nil
	end
	return eligible[rng:NextInteger(1, #eligible)]
end

return Events
