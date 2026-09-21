--!strict
--[[
	Captions.lua

	Every generated social post pulls from here. Context is decided by the
	content spot the player is standing on, then flavoured by whatever they
	happen to be renting at the time.
]]

local Captions = {}

Captions.Sets = {
	bedroom = {
		"How I made my first £10,000 online.",
		"Most people will never understand this room.",
		"3 years ago I was nobody. I am still nobody, but louder.",
		"Day 412 of building in public. Public has not noticed.",
		"This desk cost £22. The mindset is priceless.",
		"Your excuses are why you're still scrolling.",
		"Nobody is coming to save you. Not even my course. Especially not my course.",
		"Built this from a box room. Still in the box room.",
		"While you slept, I refreshed my analytics.",
		"Poor mindset: rent. Rich mindset: also rent, but filmed.",
	},
	city = {
		"Walking to a meeting. There is no meeting.",
		"They laughed when I moved to the city. They still are.",
		"Every building here was built by someone who started with nothing. And a large inheritance.",
		"You can't out-earn a broken routine. I have tried.",
		"The 9-5 is a cage. I'm in a slightly larger cage with worse hours.",
		"Chose myself. Nobody else was available.",
		"Filmed this walking past a shop I cannot afford to enter.",
		"Cities don't sleep. Neither do people with unsustainable business models.",
	},
	car = {
		"Nobody believed in me 3 years ago.",
		"Bought this with money I made from my phone. Renting this with money I made from my phone. Same thing.",
		"Your dream car is a decision away. And a £4,000 deposit away.",
		"Poor people buy liabilities. I lease them hourly.",
		"If this doesn't motivate you, nothing will.",
		"12 minutes in this car. 6 months of content. That's leverage.",
		"Comment 'DRIVEN' and I'll DM you the blueprint.",
		"Some of you will never feel this. Because it costs £5,000 an hour.",
		"Doors go up. Standards go up. Balance goes down.",
	},
	property = {
		"POV: you stopped making excuses.",
		"Checkout is at 11am but the legend is forever.",
		"This is what discipline looks like. Discipline, and a 48-hour booking.",
		"Everyone said I'd never make it. My host has said nothing, because they don't know.",
		"View from the office today. Office is an Airbnb. Today is one day.",
		"You're one decision away from a completely different life, and a cleaning fee.",
		"Woke up here. Leaving here. Never mentioning the leaving part.",
		"Location independent. Also deposit dependent.",
	},
	jet = {
		"Your network is your net worth.",
		"Time is the only currency. This jet costs £150,000 and does not move.",
		"Flying private isn't about luxury. It's about the thumbnail.",
		"Most people fly economy because they think small. I fly nowhere, because I think bigger.",
		"Filmed on the stairs. Never filmed inside. Never ask why.",
		"If you're reading this, you're still boarding by group number.",
		"Wheels up. (Wheels are, technically, down.)",
	},
	yacht = {
		"Saltwater and no small talk.",
		"This boat costs more per hour than most people earn per year. Mine included.",
		"They said I was delusional. The marina says I'm booked until 4pm.",
		"Sea days over work days. Also sea days ARE work days.",
		"Nothing out here but ambition and a charter agreement.",
		"Captain thinks I'm a client. He is correct.",
	},
	island = {
		"There is no ceiling. There is only a booking window.",
		"I rented an island to tell you money doesn't matter.",
		"This is what happens when you take yourself seriously for 5 years.",
		"Bought an island. Well. Not bought. Not really an island. But look at it.",
		"You were sold a lie. Here is a different, more expensive lie.",
		"This is the level. Very few of you will reach it. Fewer will finance it.",
	},
	business = {
		"Systems over motivation.",
		"Revenue update: up. Source: unverifiable.",
		"Fired myself from the day-to-day. There was no day-to-day.",
		"Scaling. Scaling what, exactly, is between me and my accountant.",
		"7 figures isn't a number, it's an identity. Also it isn't my number.",
		"Team meeting this morning. The team are actors. The meeting was filmed.",
	},
	generic = {
		"Stay dangerous.",
		"Escape the matrix.",
		"Most of you will screenshot this and do nothing.",
		"I don't have motivation. I have obligations and a rental agreement.",
		"If you want it, you'd have it. Unless it requires capital, which it does.",
		"Two types of people: those who post this, and those who believe it.",
		"Discipline is choosing between what you want now and what you want to film.",
		"Comment 'READY' and I'll send you nothing.",
		"They don't hate you. They've just seen your bank statement.",
		"Your comfort zone is beautifully decorated. Mine is rented.",
	},
}

-- Prop-specific lines, keyed by item id. Used when the player's best active
-- prop is notable enough to deserve its own joke.
Captions.ForItem = {
	watch_fake = { "Poor people buy liabilities.", "Don't check the watch. Check the mindset." },
	watch_grail = { "This watch costs more than a house. It goes back in four minutes." },
	set_screenshot = { "Another day, another five figures. (Inspect element is free.)" },
	set_dashboard = { "Numbers don't lie. This screensaver, however, does." },
	set_heli = { "Landed, stepped out, left. Nine seconds. Worth every penny." },
	set_magcover = { "Honoured to be featured. Invoice paid in full." },
	ext_crowd = { "Sold out room tonight. Everyone here is on a day rate." },
	ext_queue = { "The love is unreal. £12 an hour of unreal love." },
	award_30under30 = { "Humbled to be recognised. Entry fee: £50,000." },
	end_lifestyle = { "This is the life. For the next ten minutes, this is literally the life." },
	buff_4am = { "4AM. Nobody made me do this. That's the problem." },
	buff_monk = { "Going silent for 90 days. Here is day 1 of 90 daily updates." },
}

Captions.ViralBanners = {
	"POST WENT VIRAL!",
	"THE ALGORITHM CHOSE YOU",
	"EXPLODING ON THE FOR-YOU PAGE",
	"THIS ONE HIT DIFFERENT",
	"SHARED BY A BIGGER GURU",
}

local function pickFrom(list, rng: Random): string
	return list[rng:NextInteger(1, #list)]
end

--- Returns a caption for a post.
--- @param context the content spot's caption key ("car", "jet", ...)
--- @param itemId  the player's best active prop, may be nil
function Captions.pick(context: string, itemId: string?, rng: Random): string
	if itemId then
		local specific = Captions.ForItem[itemId]
		if specific and rng:NextNumber() < 0.35 then
			return pickFrom(specific, rng)
		end
	end

	local set = Captions.Sets[context] or Captions.Sets.generic
	if rng:NextNumber() < 0.25 then
		set = Captions.Sets.generic
	end
	return pickFrom(set, rng)
end

function Captions.viralBanner(rng: Random): string
	return pickFrom(Captions.ViralBanners, rng)
end

return Captions
