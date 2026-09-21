--!strict
--[[
	Podcasts.lua

	You pay to appear on podcasts. This is not a joke the game invented.

	Each appearance costs cash, grants a flat + percentage follower bump, then
	asks you one question. Your answer decides the bonus.
]]

local Podcasts = {}

Podcasts.Cooldown = 120

Podcasts.Tiers = {
	{ id = "pod_alone", name = "Record A Podcast Alone", desc = "Two microphones. One chair. Zero guests.", cost = 0, flat = 15, pct = 0.01, req = 0 },
	{ id = "pod_friend", name = "Your Friend's Podcast", desc = "He has 31 listeners and 30 of them are him.", cost = 50, flat = 120, pct = 0.02, req = 200 },
	{ id = "pod_thirty", name = "Podcast With 30 Subscribers", desc = "They call it 'the show'. It is a garage.", cost = 300, flat = 900, pct = 0.03, req = 2000 },
	{ id = "pod_business", name = "Regional Business Podcast", desc = "Sponsored by a local window company. Genuinely.", cost = 3000, flat = 9000, pct = 0.05, req = 15000 },
	{ id = "pod_viral", name = "The Clips Podcast", desc = "Ninety minutes recorded. Four seconds used. Those four seconds ruin you.", cost = 30000, flat = 120000, pct = 0.08, req = 120000 },
	{ id = "pod_massive", name = "Massive Entrepreneur Podcast", desc = "You paid £400,000 to sit in a chair and say 'value'.", cost = 400000, flat = 2000000, pct = 0.12, req = 1500000 },
	{ id = "pod_legend", name = "The Biggest Podcast On Earth", desc = "Three hours. No questions. Total agreement throughout.", cost = 5000000, flat = 30000000, pct = 0.18, req = 20000000 },
}

Podcasts.ById = {}
for index, tier in ipairs(Podcasts.Tiers) do
	tier.index = index
	Podcasts.ById[tier.id] = tier
end

--[[
	Questions. Each answer carries:
		mult  -- multiplier applied to the appearance's follower gain
		clout -- flat permanent clout bonus
		sus   -- suspicion change
]]
Podcasts.Questions = {
	{
		prompt = "What advice would you give your younger self?",
		answers = {
			{ text = "Wake up at 4AM", mult = 1.25, clout = 40, sus = 0, reply = "The host nods for eleven seconds straight." },
			{ text = "Stop being lazy", mult = 1.1, clout = 20, sus = 3, reply = "Half the comments agree. The other half have jobs." },
			{ text = "Buy my course", mult = 0.8, clout = 10, sus = 12, reply = "The clip is used against you for years." },
			{ text = "Network harder", mult = 1.15, clout = 30, sus = 1, reply = "Someone stitches this with a photo of your spare room." },
			{ text = "Escape the matrix", mult = 1.4, clout = 60, sus = 8, reply = "This becomes the thumbnail. Obviously." },
		},
	},
	{
		prompt = "What's the biggest misconception about your journey?",
		answers = {
			{ text = "People think it was luck", mult = 1.2, clout = 35, sus = 2, reply = "It was mostly luck." },
			{ text = "People think I started with money", mult = 1.3, clout = 45, sus = 6, reply = "You started with money." },
			{ text = "People think I sleep", mult = 1.15, clout = 25, sus = 1, reply = "You sleep nine hours." },
			{ text = "Honestly, no misconceptions", mult = 0.9, clout = 5, sus = -4, reply = "Refreshingly honest. Commercially catastrophic." },
		},
	},
	{
		prompt = "Walk us through a typical day.",
		answers = {
			{ text = "4AM, cold plunge, 400 emails", mult = 1.35, clout = 50, sus = 7, reply = "You have never received 400 emails." },
			{ text = "I don't do typical days", mult = 1.2, clout = 30, sus = 3, reply = "Vague. Powerful. Meaningless." },
			{ text = "Gym, deals, gym again", mult = 1.15, clout = 25, sus = 2, reply = "The 'deals' section is load-bearing." },
			{ text = "I film myself doing this", mult = 1.0, clout = 15, sus = -8, reply = "The host laughs. The audience does not." },
		},
	},
	{
		prompt = "What would you say to the people calling you a fraud?",
		answers = {
			{ text = "Broke people always talk", mult = 1.3, clout = 55, sus = 14, reply = "This ages like milk in a sauna." },
			{ text = "I welcome the scrutiny", mult = 1.1, clout = 20, sus = -12, reply = "Nobody scrutinises you. You are slightly disappointed." },
			{ text = "Check my results", mult = 1.25, clout = 40, sus = 10, reply = "They check. It does not go well." },
			{ text = "They're not wrong", mult = 0.7, clout = 80, sus = -30, reply = "Astonishing honesty. Your engagement triples. Your revenue halves." },
		},
	},
}

function Podcasts.bestAvailable(followers: number)
	local best = Podcasts.Tiers[1]
	for _, tier in ipairs(Podcasts.Tiers) do
		if followers >= tier.req then
			best = tier
		end
	end
	return best
end

function Podcasts.randomQuestion(rng: Random)
	return Podcasts.Questions[rng:NextInteger(1, #Podcasts.Questions)]
end

return Podcasts
