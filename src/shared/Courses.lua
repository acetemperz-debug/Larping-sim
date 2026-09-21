--!strict
--[[
	Courses.lua

	Followers are converted into money here. Revenue per sales tick is roughly:

		followers ^ RevenueExponent * conversion * price
		         * studioMultiplier * prestigeMultiplier
		         * (1 - suspicionPenalty) * (1 + downlineCut)

	Note the exponent: audience is raised to Balance.RevenueExponent before it
	is monetised. Conversion then falls off far faster than price rises, which
	is why a guru with 60 million followers still needs to sell a
	quarter-million-pound "Inner Circle" to keep the yacht rented.

	Each course tier is worth about 6% more per follower than the one below it.
	That is deliberately modest: a steeper ladder compounds with the studio and
	prestige multipliers until the rental bill stops mattering, and the rental
	bill mattering is the entire game.
]]

local Courses = {}

local GENERIC_LESSONS = {
	"Lesson 1: Mindset",
	"Lesson 2: Wake Up Earlier",
	"Lesson 3: Network",
	"Lesson 4: Work Harder",
	"Lesson 5: Buy My Advanced Course",
}

Courses.List = {
	{
		id = "course_success",
		name = "How To Become Successful",
		price = 9,
		conversion = 0.068889,
		req = { followers = 0, clout = 0 },
		pitch = "47 minutes of you saying 'consistency' into a laptop microphone.",
		lessons = GENERIC_LESSONS,
	},
	{
		id = "course_drop",
		name = "Dropshipping Masterclass",
		price = 49,
		conversion = 0.013412,
		req = { followers = 2000, clout = 400 },
		pitch = "Teaches people to sell the same garden hose you failed to sell.",
		lessons = {
			"Lesson 1: Find A Winning Product",
			"Lesson 2: The Product Is Always A Posture Corrector",
			"Lesson 3: Ads",
			"Lesson 4: More Ads",
			"Lesson 5: Sell A Dropshipping Course Instead",
		},
	},
	{
		id = "course_crypto",
		name = "Crypto Masterclass",
		price = 99,
		conversion = 0.0070367,
		req = { followers = 8000, clout = 1500 },
		pitch = "Recorded during a bull run. Sold forever.",
		lessons = {
			"Lesson 1: Do Your Own Research (Do Not Do This)",
			"Lesson 2: Diamond Hands",
			"Lesson 3: My Private Telegram",
			"Lesson 4: Nobody Is Coming To Save You",
			"Lesson 5: Buy My Advanced Course",
		},
	},
	{
		id = "course_trading",
		name = "Trading Masterclass",
		price = 499,
		conversion = 0.0014798,
		req = { followers = 25000, clout = 6000 },
		pitch = "Taught by a man whose only profitable trade was this course.",
		lessons = {
			"Lesson 1: Support And Resistance",
			"Lesson 2: Draw A Line, Then Another Line",
			"Lesson 3: Risk Management (Skipped)",
			"Lesson 4: Screenshot Your Wins Only",
			"Lesson 5: Buy My Advanced Course",
		},
	},
	{
		id = "course_agency",
		name = "Agency Masterclass",
		price = 999,
		conversion = 0.00078352,
		req = { followers = 75000, clout = 18000 },
		pitch = "Start an agency. Serve no clients. Teach agency-starting.",
		lessons = GENERIC_LESSONS,
	},
	{
		id = "course_brand",
		name = "Personal Branding Course",
		price = 2500,
		conversion = 0.00033188,
		req = { followers = 200000, clout = 50000 },
		pitch = "Becoming famous for explaining how to become famous.",
		lessons = {
			"Lesson 1: Pick A Niche",
			"Lesson 2: Your Niche Is You",
			"Lesson 3: Post Daily Forever",
			"Lesson 4: Never Reveal Your Actual Income",
			"Lesson 5: Buy My Advanced Course",
		},
	},
	{
		id = "course_ai",
		name = "AI Money Course",
		price = 5000,
		conversion = 0.0001759,
		req = { followers = 600000, clout = 140000 },
		pitch = "Written by AI. Sold by you. Read by nobody.",
		lessons = {
			"Lesson 1: Prompting",
			"Lesson 2: Prompting, But Louder",
			"Lesson 3: Automate Everything Except This Course",
			"Lesson 4: The Window Is Closing (It Is Not)",
			"Lesson 5: Buy My Advanced Course",
		},
	},
	{
		id = "course_passive",
		name = "Passive Income Blueprint",
		price = 10000,
		conversion = 9.32259e-05,
		req = { followers = 1500000, clout = 400000 },
		pitch = "Requires 90 hours a week of active work to maintain.",
		lessons = GENERIC_LESSONS,
	},
	{
		id = "course_highticket",
		name = "High Ticket Sales Academy",
		price = 25000,
		conversion = 3.95278e-05,
		req = { followers = 4000000, clout = 1200000 },
		pitch = "Learn to sell a £25,000 course on how to sell £25,000 courses.",
		lessons = {
			"Lesson 1: Never Say The Price First",
			"Lesson 2: Silence Is A Closing Technique",
			"Lesson 3: 'What's Stopping You Investing In Yourself?'",
			"Lesson 4: Payment Plans",
			"Lesson 5: Buy My Advanced Course",
		},
	},
	{
		id = "course_elite",
		name = "Elite Mentorship Program",
		price = 50000,
		conversion = 2.09497e-05,
		req = { followers = 10000000, clout = 3000000 },
		pitch = "You will be mentored by someone who was mentored by you.",
		lessons = GENERIC_LESSONS,
	},
	{
		id = "course_mastermind",
		name = "Millionaire Mastermind",
		price = 100000,
		conversion = 1.11034e-05,
		req = { followers = 25000000, clout = 9000000 },
		pitch = "A group chat. A very, very expensive group chat.",
		lessons = GENERIC_LESSONS,
	},
	{
		id = "course_inner",
		name = "Billionaire Inner Circle",
		price = 250000,
		conversion = 4.7078e-06,
		req = { followers = 60000000, clout = 25000000 },
		pitch = "Annual dinner. Everyone there is also renting. Nobody mentions it.",
		lessons = {
			"Lesson 1: Mindset",
			"Lesson 2: You Are Already One Of Us",
			"Lesson 3: Do Not Google Any Of Us",
			"Lesson 4: Recruit",
			"Lesson 5: There Is No Advanced Course. You Are It.",
		},
	},
}

Courses.ById = {}
for index, course in ipairs(Courses.List) do
	course.index = index
	Courses.ById[course.id] = course
end

--- The most expensive course the player currently qualifies for.
function Courses.bestAvailable(followers: number, clout: number)
	local best = Courses.List[1]
	for _, course in ipairs(Courses.List) do
		if followers >= course.req.followers and clout >= course.req.clout then
			best = course
		end
	end
	return best
end

function Courses.isUnlocked(course, followers: number, clout: number): boolean
	return followers >= course.req.followers and clout >= course.req.clout
end

-- Mentorship: pure passive income, gated purely on audience size ------------
Courses.Mentorship = {
	{ id = "ment_15", name = "15-Minute Call", price = 100, followers = 25000, rate = 0.0015 },
	{ id = "ment_30", name = "30-Minute Call", price = 500, followers = 120000, rate = 0.0004 },
	{ id = "ment_hour", name = "1-Hour Strategy Call", price = 2000, followers = 500000, rate = 0.000125 },
	{ id = "ment_elite", name = "Elite Mentorship", price = 10000, followers = 2500000, rate = 3e-05 },
	{ id = "ment_dinner", name = "Mastermind Dinner", price = 25000, followers = 12000000, rate = 1.4e-05 },
}

function Courses.bestMentorship(followers: number)
	local best = nil
	for _, tier in ipairs(Courses.Mentorship) do
		if followers >= tier.followers then
			best = tier
		end
	end
	return best
end

return Courses
