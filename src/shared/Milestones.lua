--!strict
--[[
	Milestones.lua -- dramatic full-screen notifications at follower counts.

	The clout bonus attached to each one is roughly 15% of the clout a player
	is expected to be carrying when they cross it: a real reward that never
	competes with actually buying things.
]]

local Milestones = {}

Milestones.List = {
	{ followers = 100, title = "100 FOLLOWERS", text = "Three of them are your mum on different accounts.", cloutBonus = 15 },
	{ followers = 1000, title = "1,000 FOLLOWERS", text = "You have crossed the threshold where people stop asking what you actually do.", cloutBonus = 60 },
	{ followers = 10000, title = "10,000 FOLLOWERS", text = "You can now say 'my community' without anyone laughing out loud.", cloutBonus = 400 },
	{ followers = 100000, title = "100,000 FOLLOWERS", text = "Brands have started sending you things you would never buy.", cloutBonus = 2500 },
	{ followers = 1000000, title = "1,000,000 FOLLOWERS", text = "You are now qualified to give financial advice despite having no qualifications.", cloutBonus = 15000 },
	{ followers = 10000000, title = "10,000,000 FOLLOWERS", text = "You have not had an original thought since 2019 and it has never mattered less.", cloutBonus = 80000 },
	{ followers = 100000000, title = "100,000,000 FOLLOWERS", text = "Governments have begun quoting you. Incorrectly. It doesn't matter.", cloutBonus = 300000 },
	{ followers = 1000000000, title = "1,000,000,000 FOLLOWERS", text = "One in eight people alive have seen you point at a car.", cloutBonus = 1000000 },
}

--- Returns every milestone crossed by moving from `before` to `after`.
function Milestones.crossed(before: number, after: number)
	local crossed = {}
	for _, milestone in ipairs(Milestones.List) do
		if before < milestone.followers and after >= milestone.followers then
			table.insert(crossed, milestone)
		end
	end
	return crossed
end

return Milestones
