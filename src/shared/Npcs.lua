--!strict
--[[
	Npcs.lua

	Customer archetypes that wander the map, say things, and buy your course.
	Once you unlock the pyramid, some of them stop buying and start selling.
]]

local Npcs = {}

Npcs.Types = {
	{
		id = "npc_student",
		name = "Broke Student",
		colour = Color3.fromRGB(120, 160, 200),
		wealth = 0.4,
		lines = {
			"Bro what's the secret?",
			"Is the course worth it? I've got £11.",
			"I'll buy it next month I swear.",
			"My mate said you're a scammer but he's broke so",
		},
	},
	{
		id = "npc_trader",
		name = "Aspiring Trader",
		colour = Color3.fromRGB(90, 200, 140),
		wealth = 1.0,
		lines = {
			"What's your win rate?",
			"I blew my account again.",
			"Do you have a signals group?",
			"This is the year. I can feel it.",
		},
	},
	{
		id = "npc_dropshipper",
		name = "Dropshipper",
		colour = Color3.fromRGB(230, 160, 70),
		wealth = 0.9,
		lines = {
			"Can you teach me dropshipping?",
			"My store's had 4,000 visitors and zero sales.",
			"How do I escape the 9-5?",
			"I'm testing 12 products at once.",
		},
	},
	{
		id = "npc_crypto",
		name = "Crypto Guy",
		colour = Color3.fromRGB(240, 200, 60),
		wealth = 1.4,
		lines = {
			"We're still early.",
			"I'm not selling. Ever.",
			"Have you seen this new chain?",
			"I'm down 94% but the tech is sound.",
		},
	},
	{
		id = "npc_gym",
		name = "Gym Bro",
		colour = Color3.fromRGB(220, 120, 120),
		wealth = 1.1,
		lines = {
			"Discipline is everything, brother.",
			"I train fasted at 4AM.",
			"Do you offer mentorship?",
			"Body and business, same thing.",
		},
	},
	{
		id = "npc_corporate",
		name = "Corporate Escapee",
		colour = Color3.fromRGB(150, 150, 170),
		wealth = 2.2,
		lines = {
			"I hate my job. I have a pension though.",
			"How do I escape the 9-5?",
			"I've got savings. Is that enough to start?",
			"My manager doesn't respect me.",
		},
	},
	{
		id = "npc_future",
		name = "Future Millionaire",
		colour = Color3.fromRGB(190, 130, 230),
		wealth = 1.6,
		lines = {
			"I'm going to be rich by 25.",
			"I've read every book you recommended.",
			"I've got 14 business ideas.",
			"I just need one break.",
		},
	},
	{
		id = "npc_serial",
		name = "Serial Course Buyer",
		colour = Color3.fromRGB(240, 100, 180),
		wealth = 4.0,
		lines = {
			"I've bought 31 courses this year.",
			"I haven't finished any of them.",
			"Is there an advanced version?",
			"Take my money. Genuinely. Take it.",
		},
	},
	{
		id = "npc_hater",
		name = "Sceptic",
		colour = Color3.fromRGB(110, 110, 110),
		wealth = 0,
		hater = true,
		lines = {
			"That's a rental mate.",
			"I've seen that car in six other videos.",
			"What's the business? Like, actually?",
			"Post your bank statement then.",
		},
	},
}

Npcs.ById = {}
for _, npcType in ipairs(Npcs.Types) do
	Npcs.ById[npcType.id] = npcType
end

--- Lines used by NPCs you have converted into your own downline of gurus.
Npcs.DownlineLines = {
	"I'm running my own programme now.",
	"Shoutout to my mentor. Link in bio.",
	"Just rented my first Lamborghini.",
	"I teach what he taught me. For more money.",
	"My students are already getting results.",
}

function Npcs.pickType(rng: Random, allowHater: boolean)
	for _ = 1, 12 do
		local candidate = Npcs.Types[rng:NextInteger(1, #Npcs.Types)]
		if allowHater or not candidate.hater then
			return candidate
		end
	end
	return Npcs.Types[1]
end

return Npcs
