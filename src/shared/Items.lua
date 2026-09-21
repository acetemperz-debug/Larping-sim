--!strict
--[[
	Items.lua

	The full LARP catalogue. Every purchasable thing in the game is defined here
	and nowhere else -- the shops, the clout maths and the content generator all
	read from this table.

	Item fields
	-----------
	id        unique string key
	name      display name
	desc      the joke. Non-optional.
	price     cost in pounds
	clout     clout granted while owned / active
	rental    true  -> expires after `duration` seconds (the whole point)
	          false -> permanent unlock
	duration  seconds, rentals only
	consume   true  -> applies its effect once and is not retained (PR items)
	sus       suspicion added at point of purchase
	susRate   suspicion added per second while active
	req       { followers = n, clout = n, prestige = n } gate
	mult      { followers = n, cash = n } multiplicative bonuses while active
	grants    { itemId, ... } activates other rentals for the same duration
	autoPost  seconds between automated posts (social media manager)

	Category fields
	---------------
	stacking  true  -> every owned/active item in the category contributes clout
	          false -> only the single best one counts (you are upgrading, not hoarding)
]]

local Items = {}

Items.Categories = {
	--------------------------------------------------------------------------
	{
		id = "cars",
		name = "Vehicle LARPing",
		blurb = "You will not own any of these. You will be photographed with all of them.",
		icon = "🏎️",
		stacking = false,
		tiers = {
			{ id = "car_parked", name = "Photo Next To A Parked Car", desc = "It isn't yours. It isn't even running. The angle is doing all the work.", price = 5, clout = 4, rental = true, duration = 180, sus = 0.5 },
			{ id = "car_hatch", name = "Loud Hatchback Rental", desc = "Aftermarket exhaust. Zero horsepower. Sounds expensive in a reel.", price = 75, clout = 30, rental = true, duration = 240, sus = 0.5 },
			{ id = "car_sports", name = "Sports Car — 10 Minutes", desc = "Ten minutes. Six months of content. Do the maths.", price = 350, clout = 85, rental = true, duration = 600, sus = 1 },
			{ id = "car_bmw", name = "BMW-Style Saloon Rental", desc = "Indicators sold separately.", price = 900, clout = 180, rental = true, duration = 300, sus = 1 },
			{ id = "car_merc", name = "Mercedes-Style Rental", desc = "The car your audience believes is the ceiling. You will not correct them.", price = 1800, clout = 320, rental = true, duration = 300, sus = 1.5, req = { followers = 500 } },
			{ id = "car_porsche", name = "Porsche-Style Rental", desc = "Filmed exclusively from the front three-quarter, because you scuffed the rear.", price = 3000, clout = 600, rental = true, duration = 300, sus = 2, req = { followers = 1500 } },
			{ id = "car_lambo", name = "Lamborghini Rental", desc = "Drive it for 12 minutes. Film content for the next six months.", price = 5000, clout = 1100, rental = true, duration = 720, sus = 3, req = { followers = 4000 } },
			{ id = "car_ferrari", name = "Ferrari-Style Rental", desc = "Doors go up. Deposit goes down. Never leaves the car park.", price = 9000, clout = 1900, rental = true, duration = 300, sus = 3.5, req = { followers = 10000 } },
			{ id = "car_rolls", name = "Rolls-Royce-Style Rental", desc = "You are pictured getting IN. You are never pictured getting out at your mum's.", price = 16000, clout = 3200, rental = true, duration = 300, sus = 4, req = { followers = 25000 } },
			{ id = "car_mclaren", name = "McLaren-Style Rental", desc = "The rental company has filmed 40 other gurus in this exact car this week.", price = 28000, clout = 5400, rental = true, duration = 300, sus = 5, req = { followers = 60000 } },
			{ id = "car_hyper", name = "Hypercar Rental", desc = "£28 a second. You will talk about discipline while standing next to it.", price = 60000, clout = 11000, rental = true, duration = 300, sus = 6, req = { followers = 150000 } },
			{ id = "car_plate", name = "Rented Personalised Number Plate", desc = "Your name on a plate on a car you are returning in four minutes.", price = 250000, clout = 45000, rental = true, duration = 600, sus = 7, req = { followers = 400000 } },
			{ id = "car_convoy", name = "Supercar Convoy Rental", desc = "Six cars. Six drivers on minimum wage. One roundabout, filmed nine times.", price = 900000, clout = 150000, rental = true, duration = 300, sus = 8, req = { followers = 1000000 } },
			{ id = "car_showroom", name = "Rent An Entire Exotic Showroom", desc = "For one hour, every car in this building is 'part of the collection'.", price = 4000000, clout = 620000, rental = true, duration = 420, sus = 10, req = { followers = 4000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "property",
		name = "Property LARPing",
		blurb = "Check-in at 3pm. Film everything by 3:20pm. Claim you live here.",
		icon = "🏠",
		stacking = false,
		tiers = {
			{ id = "prop_outside", name = "Photo Outside A Nice House", desc = "Stand at the gate. Do not make eye contact with the owner.", price = 10, clout = 6, rental = true, duration = 180, sus = 0.5 },
			{ id = "prop_hotel", name = "Hotel Lobby Access", desc = "You bought a £4 coffee. You now have a marble backdrop.", price = 250, clout = 60, rental = true, duration = 300, sus = 1 },
			{ id = "prop_airbnb", name = "Airbnb Apartment", desc = "One night. Forty-one pieces of content. Cleaning fee: brutal.", price = 1200, clout = 260, rental = true, duration = 300, sus = 1.5 },
			{ id = "prop_lux_airbnb", name = "Luxury Airbnb", desc = "There is a bowl of decorative lemons. You will film the lemons.", price = 4000, clout = 800, rental = true, duration = 300, sus = 2, req = { followers = 2500 } },
			{ id = "prop_penthouse", name = "Penthouse Airbnb", desc = "Floor-to-ceiling windows. Floor-to-ceiling debt.", price = 12000, clout = 2400, rental = true, duration = 300, sus = 3, req = { followers = 12000 } },
			{ id = "prop_mansion", name = "Mansion Airbnb", desc = "Eleven bedrooms. You sleep in one. You imply you own all eleven.", price = 40000, clout = 7500, rental = true, duration = 360, sus = 4, req = { followers = 40000 } },
			{ id = "prop_dubai", name = "Dubai-Style Apartment", desc = "Balcony shot, skyline, hands behind head. The genre demands it.", price = 120000, clout = 21000, rental = true, duration = 360, sus = 5, req = { followers = 120000 } },
			{ id = "prop_villa", name = "Beach Villa", desc = "Infinity pool. Finite funds.", price = 400000, clout = 62000, rental = true, duration = 360, sus = 6, req = { followers = 400000 } },
			{ id = "prop_estate", name = "Private Estate", desc = "Gravel driveway. Crunching gravel is the single most monetisable sound in business.", price = 1500000, clout = 200000, rental = true, duration = 420, sus = 7, req = { followers = 1200000 } },
			{ id = "prop_billionaire", name = "Billionaire Mansion (4 Hours)", desc = "The staff have been told to call you 'sir' on camera. They are also renting.", price = 6000000, clout = 750000, rental = true, duration = 420, sus = 9, req = { followers = 5000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "jets",
		name = "Private Jet LARPing",
		blurb = "The aviation industry's most profitable customers are people who never fly.",
		icon = "✈️",
		stacking = false,
		tiers = {
			{ id = "jet_lounge", name = "Airport Lounge Selfie", desc = "Free biscuits. Implied wealth.", price = 150, clout = 45, rental = true, duration = 300, sus = 1 },
			{ id = "jet_business", name = "Business Class Seat", desc = "Filmed the seat. Sat in economy. Nobody checked.", price = 900, clout = 200, rental = true, duration = 300, sus = 1.5, req = { followers = 1000 } },
			{ id = "jet_terminal", name = "Private Terminal Access", desc = "You walked through it. You did not board anything.", price = 3500, clout = 700, rental = true, duration = 300, sus = 2, req = { followers = 6000 } },
			{ id = "jet_studio", name = "Private Jet Photo Studio", desc = "It doesn't fly anywhere, but your followers don't need to know that.", price = 20000, clout = 4200, rental = false, sus = 6, req = { followers = 20000 } },
			{ id = "jet_grounded", name = "Sit Inside A Grounded Jet", desc = "Engines off. Stairs down. Dreams up.", price = 30000, clout = 6000, rental = true, duration = 300, sus = 4, req = { followers = 50000 } },
			{ id = "jet_rental", name = "Private Jet — 10 Minutes On The Tarmac", desc = "You will point at it. You will not get in it.", price = 150000, clout = 26000, rental = true, duration = 300, sus = 5, req = { followers = 300000 } },
			{ id = "jet_flight", name = "Actual Private Jet Flight", desc = "An genuinely real expense. Your accountant is crying.", price = 750000, clout = 120000, rental = true, duration = 420, sus = 3, req = { followers = 1500000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "watches",
		name = "Wrist Credibility",
		blurb = "Nothing says 'trust me with your money' like something on your arm.",
		icon = "⌚",
		stacking = false,
		tiers = {
			{ id = "watch_fake", name = "£15 Fake Watch", desc = "The second hand ticks. Real ones sweep. Your audience does not know this. Yet.", price = 15, clout = 10, rental = false, sus = 3 },
			{ id = "watch_inspired", name = "'Luxury Inspired' Chronograph", desc = "Legally distinct. Visually identical. Morally ambiguous.", price = 180, clout = 60, rental = false, sus = 3 },
			{ id = "watch_entry", name = "Entry Luxury Watch", desc = "Genuinely real! You will never stop mentioning it.", price = 1500, clout = 320, rental = false, sus = 0 },
			{ id = "watch_rolecks", name = "Rolecks Submersible", desc = "Water resistant to 300m. You wear it to the shop.", price = 9000, clout = 1800, rental = false, sus = 1, req = { followers = 15000 } },
			{ id = "watch_royaltree", name = "Royal Tree — Audemars Piguette Style", desc = "Octagonal bezel, octagonal personality.", price = 45000, clout = 8000, rental = false, sus = 1, req = { followers = 80000 } },
			{ id = "watch_millions", name = "Richard Millions RM-LARP", desc = "Skeletonised, like your business model.", price = 250000, clout = 45000, rental = false, sus = 2, req = { followers = 500000 } },
			{ id = "watch_grail", name = "Grail Watch Rental", desc = "Insured for more than everything you have ever earned. Back in five minutes.", price = 1000000, clout = 200000, rental = true, duration = 300, sus = 6, req = { followers = 2000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "clothing",
		name = "Guru Wardrobe",
		blurb = "Dress for the imaginary job you claim to already have.",
		icon = "🕴️",
		stacking = false,
		tiers = {
			{ id = "fit_cheapsuit", name = "Cheap Suit", desc = "Shiny in a way suits should not be.", price = 60, clout = 25, rental = false },
			{ id = "fit_turtleneck", name = "Black Turtleneck", desc = "Implies you have reinvented something.", price = 150, clout = 70, rental = false },
			{ id = "fit_oversized", name = "Oversized Designer-Style Shirt", desc = "Three sizes too big. Deliberately. Allegedly.", price = 500, clout = 160, rental = false },
			{ id = "fit_shades", name = "Indoor Sunglasses", desc = "Worn at night, in a basement, on a podcast.", price = 900, clout = 300, rental = false, sus = 1 },
			{ id = "fit_chain", name = "Gold-Coloured Chain", desc = "Turns your neck green. Turns your engagement gold.", price = 2500, clout = 650, rental = false, sus = 2 },
			{ id = "fit_trainers", name = "Designer-Style Trainers", desc = "Cropped out of every photo from the ankle down, just in case.", price = 7000, clout = 1500, rental = false, sus = 2, req = { followers = 10000 } },
			{ id = "fit_luxsuit", name = "Actual Luxury Suit", desc = "Tailored. Expensive. Worn once, on a rented yacht.", price = 25000, clout = 5000, rental = false, req = { followers = 60000 } },
			{ id = "fit_fur", name = "Fur Coat (Faux, Obviously)", desc = "Worn in August. In Dubai. For the algorithm.", price = 90000, clout = 16000, rental = false, sus = 2, req = { followers = 200000 } },
			{ id = "fit_allwhite", name = "All-White Billionaire Outfit", desc = "Impossible to eat in. Impossible to sit down in. Perfect.", price = 350000, clout = 55000, rental = false, req = { followers = 800000 } },
			{ id = "fit_dubai_guru", name = "The Dubai Guru Fit", desc = "Linen, aviators, and an opinion about taxes.", price = 1200000, clout = 180000, rental = false, req = { followers = 3000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "accessories",
		name = "Props & Accessories",
		blurb = "Small objects that do a disproportionate amount of lying.",
		icon = "💼",
		stacking = true,
		tiers = {
			{ id = "acc_coffee", name = "Coffee Cup (Held, Never Drunk)", desc = "It's empty. It has been empty for two hours.", price = 40, clout = 15, rental = false },
			{ id = "acc_briefcase", name = "Briefcase", desc = "Contains one charger and a banana.", price = 120, clout = 40, rental = false },
			{ id = "acc_cigar", name = "Cigar Prop", desc = "Unlit. You coughed for nine minutes the one time you tried.", price = 600, clout = 130, rental = false, sus = 1 },
			{ id = "acc_headset", name = "Bluetooth Headset", desc = "Not connected to anything. You nod into it regularly.", price = 900, clout = 190, rental = false, sus = 1 },
			{ id = "acc_laptop_open", name = "Laptop, Open, Charts Visible", desc = "The chart is a stock photo. It has been going up since 2011.", price = 1800, clout = 320, rental = false, sus = 2 },
			{ id = "acc_ring", name = "Diamond-Style Ring", desc = "Cubic zirconia. Catches the light. Catches the eye. Catches allegations.", price = 15000, clout = 2600, rental = false, sus = 3, req = { followers = 30000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "office",
		name = "Office LARPing",
		blurb = "A CEO needs somewhere to be filmed walking purposefully.",
		icon = "🏢",
		stacking = false,
		tiers = {
			{ id = "off_desk", name = "Bedroom Desk Setup", desc = "Folding table. Motivational poster. Empire.", price = 25, clout = 12, rental = false },
			{ id = "off_coffeeshop", name = "Coffee Shop Table", desc = "You have been nursing one flat white for five hours. The staff hate you.", price = 90, clout = 45, rental = true, duration = 300 },
			{ id = "off_coworking", name = "Coworking Hot Desk", desc = "Shared with a man building a dog-walking app. You film around him.", price = 700, clout = 190, rental = true, duration = 600 },
			{ id = "off_small", name = "Small Rented Office", desc = "One room. Filmed to look like a floor.", price = 4000, clout = 900, rental = true, duration = 600, sus = 1, req = { followers = 8000 } },
			{ id = "off_glass", name = "Glass Office", desc = "Transparent walls. Opaque revenue.", price = 20000, clout = 4000, rental = true, duration = 600, sus = 2, req = { followers = 35000 } },
			{ id = "off_trading", name = "Fake Trading Floor", desc = "Twelve monitors, all showing the same chart, none of them live.", price = 80000, clout = 15000, rental = true, duration = 600, sus = 6, req = { followers = 150000 } },
			{ id = "off_corporate", name = "Corporate Office Suite", desc = "Reception desk. Nobody at it. Filmed anyway.", price = 300000, clout = 48000, rental = true, duration = 600, sus = 4, req = { followers = 600000 } },
			{ id = "off_floor", name = "An Entire Office Floor", desc = "Rented by the hour. Referred to as 'HQ'.", price = 1000000, clout = 140000, rental = true, duration = 600, sus = 5, req = { followers = 2500000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "extras",
		name = "Rented Humans",
		blurb = "People are the cheapest set dressing available, which is bleak.",
		icon = "🧍",
		stacking = true,
		tiers = {
			{ id = "ext_employees3", name = "Rent 3 Employees", desc = "Actors sit at desks pretending to work. One is actually asleep.", price = 500, clout = 140, rental = true, duration = 300, sus = 2 },
			{ id = "ext_employees20", name = "Rent 20 Employees", desc = "Makes your videos look like you own a huge company. They have never met you.", price = 6000, clout = 1400, rental = true, duration = 300, sus = 4, req = { followers = 15000 } },
			{ id = "ext_crowd", name = "Rent A Seminar Crowd", desc = "200 people paid to nod. Front row paid extra to take notes.", price = 25000, clout = 5200, rental = true, duration = 300, sus = 7, req = { followers = 75000 } },
			{ id = "ext_queue", name = "Paid Autograph Queue", desc = "They queue. You sign. Nobody knows what you do.", price = 60000, clout = 11000, rental = true, duration = 300, sus = 8, req = { followers = 200000 } },
			{ id = "ext_paparazzi", name = "Hired Paparazzi", desc = "You leave a building. Flashes go off. You look annoyed, as instructed.", price = 150000, clout = 24000, rental = true, duration = 300, sus = 9, req = { followers = 700000 } },
			{ id = "ext_ovation", name = "Guaranteed Standing Ovation", desc = "Begins 0.4 seconds after you say 'and that's when everything changed'.", price = 500000, clout = 70000, rental = true, duration = 300, sus = 10, req = { followers = 2000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "staff",
		name = "Personal Staff",
		blurb = "Rented by the hour, introduced as 'my team'.",
		icon = "👥",
		stacking = true,
		tiers = {
			{ id = "staff_photographer", name = "Photographer", desc = "Follows you. Photographs you pointing at things.", price = 2000, clout = 450, rental = true, duration = 420, req = { followers = 10000 } },
			{ id = "staff_videographer", name = "Videographer", desc = "Walks backwards in front of you for a living.", price = 5000, clout = 1000, rental = true, duration = 420, req = { followers = 25000 } },
			{ id = "staff_assistant", name = "Personal Assistant", desc = "Holds your phone. Hands it to you. This is filmed.", price = 12000, clout = 2300, rental = true, duration = 420, req = { followers = 60000 } },
			{ id = "staff_chauffeur", name = "Chauffeur", desc = "Opens a door on a car you rented 20 minutes ago.", price = 30000, clout = 5500, rental = true, duration = 420, sus = 2, req = { followers = 150000 } },
			{ id = "staff_chef", name = "Personal Chef", desc = "Plates something tiny. You film it. You eat a meal deal later.", price = 75000, clout = 12000, rental = true, duration = 420, req = { followers = 400000 } },
			{ id = "staff_partner", name = "Fake Business Partner", desc = "An actor who says 'we're scaling' on camera. Day rate: reasonable.", price = 200000, clout = 30000, rental = true, duration = 420, sus = 8, req = { followers = 1000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "security",
		name = "Security Detail",
		blurb = "Nothing signals importance like being protected from nobody.",
		icon = "🕶️",
		stacking = false,
		tiers = {
			{ id = "sec_one", name = "One Security Guard", desc = "Protects you from a threat that does not exist.", price = 8000, clout = 1600, rental = true, duration = 300, sus = 2, req = { followers = 30000 } },
			{ id = "sec_two", name = "Two Bodyguards", desc = "They walk slightly ahead. Through an empty car park.", price = 20000, clout = 3800, rental = true, duration = 300, sus = 3, req = { followers = 90000 } },
			{ id = "sec_suv", name = "Blacked-Out Security SUV", desc = "Tinted to the legal limit and then a bit past it.", price = 70000, clout = 12000, rental = true, duration = 300, sus = 4, req = { followers = 250000 } },
			{ id = "sec_team", name = "Full Security Team", desc = "Six men with earpieces, shepherding you into a Pret.", price = 250000, clout = 40000, rental = true, duration = 300, sus = 5, req = { followers = 900000 } },
			{ id = "sec_convoy", name = "Presidential-Looking Convoy", desc = "Motorcade outriders. For a man who sells a PDF.", price = 900000, clout = 130000, rental = true, duration = 300, sus = 7, req = { followers = 3000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "yachts",
		name = "Yacht LARPing",
		blurb = "The boat never leaves the marina. Neither does the truth.",
		icon = "🛥️",
		stacking = false,
		tiers = {
			{ id = "yacht_photo", name = "Photo Next To A Yacht", desc = "Someone else's yacht. Someone else's life. Your caption.", price = 2000, clout = 500, rental = true, duration = 300, sus = 2, req = { followers = 20000 } },
			{ id = "yacht_small", name = "Small Yacht Charter", desc = "Moored. Stationary. Filmed as though mid-Atlantic.", price = 50000, clout = 9000, rental = true, duration = 360, sus = 3, req = { followers = 150000 } },
			{ id = "yacht_luxury", name = "Luxury Yacht Charter", desc = "There is a jacuzzi. It is cold. You sit in it regardless.", price = 250000, clout = 40000, rental = true, duration = 360, sus = 4, req = { followers = 600000 } },
			{ id = "yacht_super", name = "Superyacht Charter", desc = "Crew of 14, all of whom have worked out exactly what you do.", price = 1200000, clout = 180000, rental = true, duration = 420, sus = 5, req = { followers = 2500000 } },
			{ id = "yacht_mega", name = "Mega Yacht Charter", desc = "It has a helipad. The helicopter is also rented. Nothing here is yours.", price = 5000000, clout = 700000, rental = true, duration = 420, sus = 6, req = { followers = 8000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "setpieces",
		name = "Set Pieces",
		blurb = "Individually stupid. Collectively, a personal brand.",
		icon = "🎬",
		stacking = true,
		tiers = {
			{ id = "set_screenshot", name = "Fake Revenue Screenshots", desc = "Stripe dashboard, edited in the browser inspector. Classic.", price = 300, clout = 120, rental = true, duration = 600, sus = 8 },
			{ id = "set_dashboard", name = "Fake Revenue Dashboard", desc = "A giant screen of green arrows pointing upward. It is a screensaver.", price = 3000, clout = 700, rental = true, duration = 600, sus = 9, req = { followers = 8000 } },
			{ id = "set_podcast_set", name = "Fake Podcast Set", desc = "Two mics, one guest, zero listeners, infinite clips.", price = 90000, clout = 15000, rental = false, sus = 3, req = { followers = 100000 } },
			{ id = "set_heli", name = "Helicopter Step-Out", desc = "You do not fly anywhere. You step out, you film nine seconds, it leaves.", price = 40000, clout = 8000, rental = true, duration = 120, sus = 6, req = { followers = 120000 } },
			{ id = "set_stage", name = "Rented Keynote Stage", desc = "Arena hired for 40 minutes. Filmed from the front only, always.", price = 120000, clout = 20000, rental = true, duration = 300, sus = 7, req = { followers = 350000 } },
			{ id = "set_magcover", name = "Fake 'Forbz' Magazine Cover", desc = "Printed at a shop that also does personalised mugs. Framed. Hung. Cited.", price = 400000, clout = 65000, rental = false, sus = 12, req = { followers = 1000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "business",
		name = "Business LARPing",
		blurb = "The paperwork of a company that has never invoiced anyone.",
		icon = "📇",
		stacking = true,
		tiers = {
			{ id = "biz_logo", name = "Fake Company Logo", desc = "A lion. In a hexagon. Obviously.", price = 200, clout = 70, rental = false },
			{ id = "biz_cards", name = "Fake Business Cards", desc = "Job title: Founder & CEO. Employees: you, and a cat.", price = 500, clout = 150, rental = false, sus = 1 },
			{ id = "biz_sign", name = "Fake Office Sign", desc = "Vinyl. Removable. Applied to a wall you are renting by the hour.", price = 4000, clout = 800, rental = false, sus = 3, req = { followers = 10000 } },
			{ id = "biz_desk", name = "Fake CEO Desk", desc = "Huge. Empty. One pen. Nothing has ever been decided at it.", price = 12000, clout = 2200, rental = false, sus = 2, req = { followers = 40000 } },
			{ id = "biz_llc", name = "Company Registered Somewhere Warm", desc = "You cannot find it on a map. Neither can the tax authority. That's the feature.", price = 60000, clout = 9000, rental = false, sus = 6, req = { followers = 200000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "awards",
		name = "Fake Awards",
		blurb = "Every single one of these has an entry fee.",
		icon = "🏆",
		stacking = true,
		tiers = {
			{ id = "award_local", name = "'Best New Entrepreneur' (Local)", desc = "Category had one entrant. Entry fee: £2,500.", price = 2500, clout = 600, rental = false, sus = 2, req = { followers = 5000 } },
			{ id = "award_30under30", name = "Top 30 Entrepreneur Under 30", desc = "Paid list. 30 spots. 30 invoices. You are number 29.", price = 50000, clout = 9000, rental = false, sus = 6, req = { followers = 100000 } },
			{ id = "award_globe", name = "Global Visionary Of The Year", desc = "Ceremony held in a hotel function room above a Wetherspoons.", price = 300000, clout = 45000, rental = false, sus = 8, req = { followers = 800000 } },
			{ id = "award_honorary", name = "Honorary Doctorate (Unaccredited)", desc = "You now insist on 'Dr' in your email signature.", price = 2000000, clout = 260000, rental = false, sus = 10, req = { followers = 4000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "studio",
		name = "Course Production",
		blurb = "The course gets no better. It only gets better lit.",
		icon = "🎥",
		stacking = false,
		tiers = {
			{ id = "stu_webcam", name = "Cheap Webcam", desc = "720p. Somehow still an upgrade.", price = 500, clout = 20, rental = false, mult = { cash = 1.15 } },
			{ id = "stu_ringlight", name = "Ring Light", desc = "Two rings in your eyes in every video from now until you die.", price = 2000, clout = 60, rental = false, mult = { cash = 1.25 } },
			{ id = "stu_dslr", name = "DSLR Camera", desc = "Blurry background. Blurry claims.", price = 9000, clout = 200, rental = false, mult = { cash = 1.4 }, req = { followers = 15000 } },
			{ id = "stu_lighting", name = "Studio Lighting Rig", desc = "Three-point lighting on a man reading from a slide.", price = 35000, clout = 600, rental = false, mult = { cash = 1.6 }, req = { followers = 60000 } },
			{ id = "stu_mic", name = "Broadcast Microphone", desc = "Sounds like radio. Says nothing.", price = 120000, clout = 1800, rental = false, mult = { cash = 1.85 }, req = { followers = 200000 } },
			{ id = "stu_studio", name = "Recording Studio", desc = "Acoustic foam, green screen, and 'Lesson 1: Mindset'.", price = 600000, clout = 7000, rental = false, mult = { cash = 2.1 }, req = { followers = 900000 } },
			{ id = "stu_team", name = "Full Production Team", desc = "Nine professionals. One PDF.", price = 3000000, clout = 30000, rental = false, mult = { cash = 2.4 }, req = { followers = 4000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "automation",
		name = "Content Team",
		blurb = "At some point you stop making the content and start managing the lie.",
		icon = "🤖",
		stacking = true,
		tiers = {
			{ id = "auto_smm1", name = "Social Media Manager I", desc = "Posts for you every 60 seconds. Has never met you.", price = 15000, clout = 400, rental = false, autoPost = 60, req = { followers = 30000 } },
			{ id = "auto_smm2", name = "Social Media Manager II", desc = "Posts every 30 seconds. Quietly building their own audience.", price = 120000, clout = 1500, rental = false, autoPost = 30, req = { followers = 150000 } },
			{ id = "auto_smm3", name = "Social Media Manager III", desc = "Posts every 15 seconds. You are now a content farm with a face.", price = 800000, clout = 6000, rental = false, autoPost = 15, req = { followers = 700000 } },
			{ id = "auto_editor", name = "Editor", desc = "Adds zoom-punches and subtitles to the word 'discipline'.", price = 250000, clout = 3000, rental = false, mult = { followers = 1.15 }, req = { followers = 400000 } },
			{ id = "auto_thumbnail", name = "Thumbnail Designer", desc = "Your face, shocked, next to an arrow. Every time.", price = 600000, clout = 5000, rental = false, mult = { followers = 1.2 }, req = { followers = 1000000 } },
			{ id = "auto_copywriter", name = "Copywriter", desc = "Writes your 'unfiltered, raw, personal' captions.", price = 1500000, clout = 12000, rental = false, mult = { followers = 1.25 }, req = { followers = 3000000 } },
			{ id = "auto_producer", name = "Podcast Producer", desc = "Turns 90 minutes of nothing into 40 clips of nothing.", price = 4000000, clout = 25000, rental = false, mult = { followers = 1.3 }, req = { followers = 8000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "buffs",
		name = "Mindset Buffs",
		blurb = "Temporary. Expensive. Announced publicly, always. Only your strongest one counts -- you cannot be in monk mode and on a cold plunge at 4AM simultaneously, however much you post about it.",
		icon = "🧠",
		stacking = false,
		tiers = {
			{ id = "buff_4am", name = "Wake Up At 4AM", desc = "You did not need to. You wanted the content.", price = 500, clout = 100, rental = true, duration = 300, mult = { followers = 1.25, cash = 1.25 } },
			{ id = "buff_cold", name = "Cold Plunge", desc = "Ninety seconds of suffering. Eleven pieces of content.", price = 5000, clout = 600, rental = true, duration = 300, mult = { followers = 1.4, cash = 1.3 }, req = { followers = 20000 } },
			{ id = "buff_monk", name = "Monk Mode (Announced Publicly)", desc = "You have gone silent, and you will be posting about it daily.", price = 50000, clout = 4000, rental = true, duration = 300, mult = { followers = 1.7, cash = 1.4 }, req = { followers = 150000 } },
			{ id = "buff_grindset", name = "Full Grindset Protocol", desc = "Sleep is for people without a personal brand.", price = 500000, clout = 30000, rental = true, duration = 300, mult = { followers = 2, cash = 1.5 }, req = { followers = 1000000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "pr",
		name = "Damage Control",
		blurb = "Suspicion is just unmanaged narrative.",
		icon = "🧯",
		stacking = true,
		tiers = {
			{ id = "pr_delete", name = "Delete The Comments", desc = "Manual. Tedious. Ultimately futile.", price = 250, clout = 0, rental = false, consume = true, suspicion = -6 },
			{ id = "pr_block", name = "Block The Critics", desc = "They screenshot it. It gets worse. But it feels good.", price = 1000, clout = 0, rental = false, consume = true, suspicion = -14 },
			{ id = "pr_moderator", name = "Hire A Moderator", desc = "£3/hour to protect a man claiming £3m/month.", price = 8000, clout = 0, rental = false, consume = true, suspicion = -28 },
			{ id = "pr_response", name = "Motivational Response Video", desc = "'I wasn't going to address this, but...' — 41 minutes.", price = 40000, clout = 500, rental = false, consume = true, suspicion = -48 },
			{ id = "pr_manager", name = "Hire A PR Manager", desc = "They have done this eleven times before. Not for you. For others.", price = 200000, clout = 2000, rental = false, consume = true, suspicion = -75 },
			{ id = "pr_scrub", name = "Full Reputation Scrub", desc = "Every old video, gone. Every old claim, gone. The grift, intact.", price = 1500000, clout = 0, rental = false, consume = true, suspicion = -100, req = { followers = 500000 } },
		},
	},

	--------------------------------------------------------------------------
	{
		id = "endgame",
		name = "The Big One",
		blurb = "The logical conclusion of every decision you have made.",
		icon = "👑",
		stacking = false,
		tiers = {
			{
				id = "end_lifestyle",
				name = "Rent Billionaire Lifestyle — £10,000,000/hour",
				desc = "Mega yacht, private jet, mansion, supercar convoy, full security team and 20 staff. Simultaneously. For ten minutes. Then you go home on the bus.",
				price = 10000000,
				clout = 1500000,
				rental = true,
				duration = 600,
				sus = 15,
				mult = { followers = 1.5, cash = 1.2 },
				req = { followers = 10000000 },
				grants = { "yacht_mega", "jet_flight", "prop_billionaire", "car_convoy", "sec_convoy", "ext_employees20", "staff_partner" },
			},
		},
	},
}

-- Index building -----------------------------------------------------------

Items.ById = {}
Items.CategoryById = {}

for _, category in ipairs(Items.Categories) do
	Items.CategoryById[category.id] = category
	for index, item in ipairs(category.tiers) do
		item.category = category.id
		item.tier = index
		assert(Items.ById[item.id] == nil, "duplicate item id: " .. item.id)
		Items.ById[item.id] = item
	end
end

function Items.get(id: string)
	return Items.ById[id]
end

function Items.category(id: string)
	return Items.CategoryById[id]
end

return Items
