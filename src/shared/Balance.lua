--!strict
--[[
	Balance.lua

	Every tunable number in LARPing Simulator lives here.

	The design target: a player who has just cashed out a big course launch
	should be able to spend ~90% of it on rentals that expire. The fun is the
	treadmill, not the bank balance.

	Verified against an offline simulation of a greedy playthrough. Holding
	roughly 5-15% of everything you have ever spent is the intended steady
	state:

		 100K followers   cash £18.5K    spent LARPing £521K
		   1M followers   cash £271K     spent LARPing £4.5M
		  10M followers   cash £7.8M     spent LARPing £49.3M

	Pacing for a player who never stops posting: ~14 minutes to 100K, first
	rebrand around 16 minutes, 1M by ~34 minutes, 10M by ~an hour. A run is
	designed to top out around 10M followers, after which rebranding is
	strictly better than continuing -- past that point income outgrows the
	fixed rental prices and the treadmill stops biting. The escalating cost of
	your downline is the intended sink for anyone who stays anyway.

	If you change CloutBase, RevenueExponent or any content spot's `base`,
	re-check the whole curve rather than one tier: they multiply together.
]]

local Balance = {}

-- Starting state -----------------------------------------------------------
Balance.StartingCash = 50
Balance.StartingCourseId = "course_success"

-- Content posting ----------------------------------------------------------
Balance.ContentCooldown = 2.5          -- seconds between manual posts

--[[
	Clout's effect on reach: 1 + (clout / CloutBase) ^ CloutExponent.

	Deliberately shallow. Clout is the *within-area* progression lever, worth
	roughly 1.7x when you start and 9x when you own everything. Moving to a
	richer area is what actually multiplies your reach, so the map stays the
	backbone of progression instead of the shop.
]]
Balance.CloutExponent = 0.22
Balance.CloutBase = 300
Balance.RecentPostMemory = 6           -- how many posts we remember for repetition
Balance.RepeatPenalty = 0.3            -- multiplier when you spam the same spot
Balance.RepeatSuspicion = 1.5          -- suspicion added for lazy reposting

Balance.ViralChance = 0.05
Balance.ViralMultiplierMin = 5
Balance.ViralMultiplierMax = 25

-- Courses ------------------------------------------------------------------
Balance.CourseTickInterval = 5         -- seconds between passive sales ticks

--[[
	Revenue scales with followers ^ RevenueExponent, not with followers.

	This is the single most important number in the game. Rental prices are
	fixed, so if income grew linearly with audience then by the mid-game every
	rental would be pocket change and the joke would die. At 0.82 the cost of
	maintaining the illusion grows almost exactly as fast as the income from
	selling it, and the player stays permanently, hilariously broke.
]]
Balance.RevenueExponent = 0.82
Balance.LaunchCooldown = 45            -- seconds between manual course launches
Balance.LaunchMultiplier = 14          -- a launch is worth this many passive ticks
Balance.SuspicionRevenuePenalty = 0.75 -- at 100% suspicion you keep 25% of revenue

-- Mentorship (passive, unlocked by followers) -------------------------------
Balance.MentorshipUnlockFollowers = 25000
Balance.MentorshipRatePerFollower = 0.00035

-- Suspicion ----------------------------------------------------------------
Balance.SuspicionMax = 100
Balance.SuspicionDecayPerSecond = 0.06 -- the internet has a short memory
Balance.ExposeThreshold = 100
Balance.ExposeFollowerLoss = 0.35      -- lose 35% of followers when fully exposed
Balance.ExposeCashLoss = 0.25
Balance.SuspicionEventInterval = 55    -- seconds between suspicion event rolls
Balance.SuspicionEventChanceAt100 = 0.9

-- Random events ------------------------------------------------------------
Balance.RandomEventInterval = 75
Balance.RandomEventChance = 0.55

-- The pyramid --------------------------------------------------------------
-- Students who buy your course and start LARPing themselves. They kick a cut
-- upstairs forever, which is the single most accurate mechanic in this game.
Balance.DownlineUnlockFollowers = 100000
Balance.DownlineCostBase = 20000
Balance.DownlineCostGrowth = 1.55
Balance.DownlineCutPerStudent = 0.04   -- +4% course revenue each
Balance.DownlineSuspicionDrip = 0.015  -- per second, per student
Balance.DownlineMax = 40

-- Prestige -----------------------------------------------------------------
Balance.RebrandBaseRequirement = 250000 -- followers needed for first rebrand
Balance.RebrandRequirementGrowth = 9

-- Automation ---------------------------------------------------------------
Balance.AutoPostQualityFloor = 0.6     -- bots post slightly worse content than you

-- Data ---------------------------------------------------------------------
Balance.AutosaveInterval = 60
Balance.LeaderboardRefresh = 90

return Balance
