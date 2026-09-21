--!strict
--[[
	Prestige.lua -- the Rebrand system.

	Rebranding wipes cash, followers, clout bonuses and every owned item, then
	hands back permanent multipliers and a new title. Thematically this is a
	guru deleting every video and reappearing four months later in a different
	country with a different accent.
]]

local Prestige = {}

Prestige.Levels = {
	{ level = 0, title = "Bedroom Guru", requirement = 0, followerMult = 1, cashMult = 1, cloutMult = 1, blurb = "No followers, no credibility, no shame." },
	{ level = 1, title = "Side Hustler", requirement = 250000, followerMult = 1.25, cashMult = 1.25, cloutMult = 1.2, blurb = "Still employed. Does not mention this online." },
	{ level = 2, title = "Entrepreneur", requirement = 2500000, followerMult = 1.6, cashMult = 1.6, cloutMult = 1.45, blurb = "Bio now reads 'Entrepreneur | Investor | Father'. Two of these are false." },
	{ level = 3, title = "CEO", requirement = 25000000, followerMult = 2.1, cashMult = 2.1, cloutMult = 1.8, blurb = "CEO of a company with one employee, who is also the CEO." },
	{ level = 4, title = "Multi-Millionaire", requirement = 250000000, followerMult = 2.8, cashMult = 2.8, cloutMult = 2.3, blurb = "On paper. The paper is a Canva graphic." },
	{ level = 5, title = "Mogul", requirement = 2500000000, followerMult = 3.8, cashMult = 3.8, cloutMult = 3, blurb = "Owns a portfolio. Of rentals. That he rents." },
	{ level = 6, title = "Visionary", requirement = 25000000000, followerMult = 5.2, cashMult = 5.2, cloutMult = 4, blurb = "Has begun speaking exclusively in three-word sentences." },
	{ level = 7, title = "Thought Leader", requirement = 250000000000, followerMult = 7, cashMult = 7, cloutMult = 5.5, blurb = "No longer sells courses. Sells 'frameworks'. Same PDF." },
	{ level = 8, title = "Billionaire Mentor", requirement = 2500000000000, followerMult = 10, cashMult = 10, cloutMult = 8, blurb = "Mentors billionaires. Has never met one. Rents near them." },
}

function Prestige.get(level: number)
	local clamped = math.clamp(level, 0, #Prestige.Levels - 1)
	return Prestige.Levels[clamped + 1]
end

function Prestige.next(level: number)
	return Prestige.Levels[level + 2]
end

function Prestige.isMaxed(level: number): boolean
	return Prestige.next(level) == nil
end

--- Followers required to rebrand from the given level.
function Prestige.requirement(level: number): number?
	local nextLevel = Prestige.next(level)
	return nextLevel and nextLevel.requirement or nil
end

return Prestige
