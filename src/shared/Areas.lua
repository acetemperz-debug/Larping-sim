--!strict
--[[
	Areas.lua

	Map layout data. The world is generated procedurally from this table by
	src/server/WorldBuilder.lua, so there is nothing to model by hand.

	Areas are laid out in a straight line along +X. Each has a platform, a
	gate that only opens at the required follower count, a handful of content
	spots and a set of shop kiosks.

	Content spot `base` is the raw follower yield before clout, props,
	multipliers and virality are applied. It is the single biggest lever on
	progression pacing, and it is tuned so that each area takes roughly ten
	minutes to earn its way out of. Clout covers the climb within an area;
	moving to a richer area is what jumps you an order of magnitude.
]]

local Areas = {}

Areas.PlatformSize = Vector3.new(180, 4, 180)
Areas.Spacing = 260

Areas.List = {
	{
		id = "bedroom",
		name = "The Spare Room",
		subtitle = "Your parents call it 'the box room'. You call it 'HQ'.",
		unlockFollowers = 0,
		floor = Color3.fromRGB(94, 78, 66),
		accent = Color3.fromRGB(196, 132, 74),
		skyTint = Color3.fromRGB(120, 110, 100),
		shops = { "watches", "clothing", "accessories", "office", "studio" },
		spots = {
			{ id = "spot_desk", name = "The Folding Desk", base = 3, caption = "bedroom", offset = Vector3.new(-40, 0, -30) },
			{ id = "spot_bed", name = "Unmade Bed", base = 2, caption = "bedroom", offset = Vector3.new(35, 0, -35) },
			{ id = "spot_mirror", name = "Bathroom Mirror", base = 4, caption = "bedroom", offset = Vector3.new(0, 0, 45) },
		},
	},
	{
		id = "city",
		name = "The City",
		subtitle = "Where you film yourself walking with purpose towards nothing.",
		unlockFollowers = 100,
		floor = Color3.fromRGB(78, 78, 82),
		accent = Color3.fromRGB(120, 140, 170),
		skyTint = Color3.fromRGB(150, 155, 165),
		shops = { "clothing", "accessories", "business", "setpieces", "pr" },
		spots = {
			{ id = "spot_street", name = "Busy Street Corner", base = 7, caption = "city", offset = Vector3.new(-45, 0, -25) },
			{ id = "spot_carpark", name = "Multi-Storey Car Park", base = 9, caption = "city", offset = Vector3.new(40, 0, -40) },
			{ id = "spot_window", name = "Designer Shop Window", base = 8, caption = "city", offset = Vector3.new(10, 0, 50) },
		},
	},
	{
		id = "rental",
		name = "Luxury Car Rental",
		subtitle = "Open 24 hours. Every customer is filming.",
		unlockFollowers = 1000,
		floor = Color3.fromRGB(58, 58, 64),
		accent = Color3.fromRGB(220, 60, 60),
		skyTint = Color3.fromRGB(160, 140, 130),
		shops = { "cars", "watches", "clothing", "extras", "pr" },
		spots = {
			{ id = "spot_forecourt", name = "The Forecourt", base = 20, caption = "car", offset = Vector3.new(-45, 0, -30) },
			{ id = "spot_showroom", name = "Showroom Floor", base = 26, caption = "car", offset = Vector3.new(45, 0, 35) },
		},
	},
	{
		id = "apartment",
		name = "Luxury Apartment",
		subtitle = "Booked for one night. Referred to as 'my place' for two years.",
		unlockFollowers = 10000,
		floor = Color3.fromRGB(186, 178, 164),
		accent = Color3.fromRGB(212, 180, 120),
		skyTint = Color3.fromRGB(190, 180, 170),
		shops = { "property", "office", "staff", "business", "studio", "automation" },
		spots = {
			{ id = "spot_balcony", name = "The Balcony", base = 60, caption = "property", offset = Vector3.new(0, 0, -55) },
			{ id = "spot_kitchen", name = "Marble Kitchen", base = 48, caption = "property", offset = Vector3.new(-50, 0, 30) },
			{ id = "spot_bathroom", name = "Enormous Bathroom Mirror", base = 54, caption = "property", offset = Vector3.new(50, 0, 30) },
		},
	},
	{
		id = "mansion",
		name = "Mansion District",
		subtitle = "Eleven bedrooms. You are using one. You imply otherwise.",
		unlockFollowers = 100000,
		floor = Color3.fromRGB(150, 165, 130),
		accent = Color3.fromRGB(240, 235, 220),
		skyTint = Color3.fromRGB(200, 210, 190),
		shops = { "property", "cars", "staff", "security", "awards", "extras" },
		spots = {
			{ id = "spot_pool", name = "The Pool", base = 330, caption = "property", offset = Vector3.new(-50, 0, -40) },
			{ id = "spot_driveway", name = "Gravel Driveway", base = 270, caption = "car", offset = Vector3.new(50, 0, -45) },
			{ id = "spot_cinema", name = "Cinema Room", base = 300, caption = "property", offset = Vector3.new(-45, 0, 45) },
			{ id = "spot_study", name = "The Study", base = 290, caption = "business", offset = Vector3.new(50, 0, 45) },
		},
	},
	{
		id = "airport",
		name = "Private Jet Terminal",
		subtitle = "Nothing here has ever taken off with you on board.",
		unlockFollowers = 1000000,
		floor = Color3.fromRGB(70, 74, 80),
		accent = Color3.fromRGB(240, 200, 60),
		skyTint = Color3.fromRGB(170, 180, 200),
		shops = { "jets", "setpieces", "security", "staff", "buffs" },
		spots = {
			{ id = "spot_tarmac", name = "The Tarmac", base = 780, caption = "jet", offset = Vector3.new(-50, 0, -35) },
			{ id = "spot_stairs", name = "Jet Stairs", base = 900, caption = "jet", offset = Vector3.new(45, 0, -40) },
			{ id = "spot_lounge", name = "Private Lounge", base = 640, caption = "jet", offset = Vector3.new(0, 0, 50) },
		},
	},
	{
		id = "dubai",
		name = "Dubai-Style Luxury District",
		subtitle = "The natural habitat. The final form. The 42°C heat.",
		unlockFollowers = 10000000,
		floor = Color3.fromRGB(216, 190, 140),
		accent = Color3.fromRGB(255, 215, 110),
		skyTint = Color3.fromRGB(240, 210, 160),
		shops = { "property", "cars", "watches", "clothing", "awards", "extras", "buffs" },
		spots = {
			{ id = "spot_skyline", name = "Skyline Balcony", base = 3400, caption = "property", offset = Vector3.new(-50, 0, -40) },
			{ id = "spot_marina", name = "Marina Walk", base = 2800, caption = "property", offset = Vector3.new(50, 0, -40) },
			{ id = "spot_desert", name = "Desert Convoy", base = 3900, caption = "car", offset = Vector3.new(0, 0, 50) },
		},
	},
	{
		id = "marina",
		name = "Superyacht Marina",
		subtitle = "Not one of these boats will leave the harbour today.",
		unlockFollowers = 50000000,
		floor = Color3.fromRGB(96, 130, 150),
		accent = Color3.fromRGB(250, 250, 255),
		skyTint = Color3.fromRGB(170, 200, 220),
		shops = { "yachts", "staff", "security", "setpieces", "buffs" },
		spots = {
			{ id = "spot_deck", name = "Upper Deck", base = 11000, caption = "yacht", offset = Vector3.new(-45, 0, -40) },
			{ id = "spot_jetski", name = "Jet Ski (Stationary)", base = 9500, caption = "yacht", offset = Vector3.new(50, 0, -35) },
			{ id = "spot_helipad", name = "Yacht Helipad", base = 13000, caption = "yacht", offset = Vector3.new(0, 0, 50) },
		},
	},
	{
		id = "island",
		name = "Billionaire Island",
		subtitle = "You rented an island. By the hour. With a payment plan.",
		unlockFollowers = 100000000,
		floor = Color3.fromRGB(226, 212, 170),
		accent = Color3.fromRGB(120, 220, 190),
		skyTint = Color3.fromRGB(190, 230, 235),
		shops = { "endgame", "yachts", "jets", "awards", "buffs", "pr" },
		spots = {
			{ id = "spot_beach", name = "Private Beach", base = 30000, caption = "island", offset = Vector3.new(-50, 0, -40) },
			{ id = "spot_heliport", name = "Island Heliport", base = 34000, caption = "island", offset = Vector3.new(50, 0, -40) },
			{ id = "spot_compound", name = "The Compound", base = 39000, caption = "island", offset = Vector3.new(0, 0, 50) },
		},
	},
}

Areas.ById = {}
Areas.SpotById = {}

for index, area in ipairs(Areas.List) do
	area.index = index
	area.origin = Vector3.new((index - 1) * Areas.Spacing, 0, 0)
	Areas.ById[area.id] = area

	for _, spot in ipairs(area.spots) do
		spot.areaId = area.id
		spot.position = area.origin + spot.offset + Vector3.new(0, Areas.PlatformSize.Y / 2, 0)
		assert(Areas.SpotById[spot.id] == nil, "duplicate spot id: " .. spot.id)
		Areas.SpotById[spot.id] = spot
	end
end

function Areas.get(id: string)
	return Areas.ById[id]
end

function Areas.spot(id: string)
	return Areas.SpotById[id]
end

--- Highest area index the player has unlocked at this follower count.
function Areas.highestUnlocked(followers: number): number
	local highest = 1
	for _, area in ipairs(Areas.List) do
		if followers >= area.unlockFollowers then
			highest = area.index
		end
	end
	return highest
end

return Areas
