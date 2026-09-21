--!strict
--[[
	WorldBuilder.lua

	Generates the entire map from Shared/Areas.lua at runtime. Nothing here is
	hand-modelled, so adding an area is a data change rather than a building job.

	Each area is a floating island containing:
		* content spots       -- pads you stand on to post
		* shop kiosks         -- one per category the area sells
		* a business corner   -- courses, podcasts, the pyramid, rebranding
		* a travel post       -- the only way between areas

	Kiosks carry an "Action" attribute that the interaction handler reads.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Areas = require(Shared.Areas)
local Items = require(Shared.Items)
local Format = require(Shared.Format)

local Leaderboards = require(script.Parent.Leaderboards)

local WorldBuilder = {}

local worldFolder: Folder

-- Construction helpers -----------------------------------------------------

local function part(props): Part
	local instance = Instance.new("Part")
	instance.Anchored = true
	instance.CanCollide = props.collide ~= false
	instance.Size = props.size or Vector3.new(4, 4, 4)
	instance.CFrame = props.cframe or CFrame.new(props.position or Vector3.zero)
	instance.Color = props.color or Color3.fromRGB(160, 160, 160)
	instance.Material = props.material or Enum.Material.SmoothPlastic
	instance.Transparency = props.transparency or 0
	instance.Name = props.name or "Part"
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth
	if props.shape then
		instance.Shape = props.shape
	end
	instance.Parent = props.parent or worldFolder
	return instance
end

local function billboard(parent: BasePart, title: string, subtitle: string?, height: number?)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 260, 0, 74)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height or 4, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 140
	gui.Parent = parent

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, subtitle and 0.55 or 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextScaled = true
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeTransparency = 0.35
	titleLabel.Text = title
	titleLabel.Parent = gui

	if subtitle then
		local subLabel = Instance.new("TextLabel")
		subLabel.Size = UDim2.new(1, 0, 0.45, 0)
		subLabel.Position = UDim2.new(0, 0, 0.55, 0)
		subLabel.BackgroundTransparency = 1
		subLabel.Font = Enum.Font.GothamMedium
		subLabel.TextScaled = true
		subLabel.TextColor3 = Color3.fromRGB(210, 210, 225)
		subLabel.TextStrokeTransparency = 0.5
		subLabel.Text = subtitle
		subLabel.Parent = gui
	end

	return gui
end

local function prompt(parent: BasePart, actionText: string, objectText: string, distance: number?)
	local promptInstance = Instance.new("ProximityPrompt")
	promptInstance.ActionText = actionText
	promptInstance.ObjectText = objectText
	promptInstance.HoldDuration = 0
	promptInstance.MaxActivationDistance = distance or 12
	promptInstance.RequiresLineOfSight = false
	promptInstance.Parent = parent
	return promptInstance
end

-- Decor primitives ---------------------------------------------------------

local function building(parent: Folder, position: Vector3, size: Vector3, colour: Color3)
	local body = part({
		parent = parent,
		position = position + Vector3.new(0, size.Y / 2, 0),
		size = size,
		color = colour,
		material = Enum.Material.Concrete,
		name = "Building",
	})
	-- Windows: one thin slab on each long face, because it reads from a distance.
	part({
		parent = parent,
		position = position + Vector3.new(0, size.Y / 2, size.Z / 2),
		size = Vector3.new(size.X * 0.8, size.Y * 0.85, 0.4),
		color = Color3.fromRGB(120, 180, 210),
		material = Enum.Material.Glass,
		transparency = 0.25,
		collide = false,
		name = "Glass",
	})
	return body
end

local function car(parent: Folder, position: Vector3, colour: Color3, facing: number?)
	local rotation = CFrame.Angles(0, facing or 0, 0)
	local base = CFrame.new(position) * rotation

	part({
		parent = parent,
		cframe = base * CFrame.new(0, 1.4, 0),
		size = Vector3.new(6, 1.6, 13),
		color = colour,
		material = Enum.Material.Metal,
		name = "CarBody",
	})
	part({
		parent = parent,
		cframe = base * CFrame.new(0, 2.7, -0.5),
		size = Vector3.new(5, 1.2, 6),
		color = Color3.fromRGB(35, 35, 40),
		material = Enum.Material.Glass,
		transparency = 0.25,
		name = "CarCabin",
	})
	for _, offset in ipairs({ Vector3.new(3, 0.9, 4), Vector3.new(-3, 0.9, 4), Vector3.new(3, 0.9, -4), Vector3.new(-3, 0.9, -4) }) do
		part({
			parent = parent,
			cframe = base * CFrame.new(offset),
			size = Vector3.new(1.8, 1.8, 1.8),
			shape = Enum.PartType.Cylinder,
			color = Color3.fromRGB(25, 25, 28),
			name = "Wheel",
		})
	end
end

local function palm(parent: Folder, position: Vector3)
	part({
		parent = parent,
		position = position + Vector3.new(0, 9, 0),
		size = Vector3.new(1.6, 18, 1.6),
		color = Color3.fromRGB(120, 95, 60),
		material = Enum.Material.Wood,
		collide = false,
		name = "PalmTrunk",
	})
	for index = 1, 5 do
		local angle = (index / 5) * math.pi * 2
		part({
			parent = parent,
			cframe = CFrame.new(position + Vector3.new(math.cos(angle) * 4, 18, math.sin(angle) * 4))
				* CFrame.Angles(0, -angle, math.rad(20)),
			size = Vector3.new(9, 0.4, 3),
			color = Color3.fromRGB(70, 150, 80),
			material = Enum.Material.Grass,
			collide = false,
			name = "PalmFrond",
		})
	end
end

local function jet(parent: Folder, position: Vector3)
	part({
		parent = parent,
		cframe = CFrame.new(position + Vector3.new(0, 7, 0)) * CFrame.Angles(0, math.rad(90), 0),
		size = Vector3.new(44, 7, 7),
		shape = Enum.PartType.Cylinder,
		color = Color3.fromRGB(245, 245, 250),
		material = Enum.Material.Metal,
		name = "Fuselage",
	})
	part({
		parent = parent,
		position = position + Vector3.new(0, 6, 0),
		size = Vector3.new(38, 0.8, 9),
		color = Color3.fromRGB(235, 235, 240),
		material = Enum.Material.Metal,
		collide = false,
		name = "Wings",
	})
	part({
		parent = parent,
		position = position + Vector3.new(-18, 11, 0),
		size = Vector3.new(1, 10, 8),
		color = Color3.fromRGB(235, 235, 240),
		material = Enum.Material.Metal,
		collide = false,
		name = "Tail",
	})
	-- The stairs. The most photographed object in the game.
	for step = 1, 6 do
		part({
			parent = parent,
			position = position + Vector3.new(6, step * 0.8, 8 + step * 0.9),
			size = Vector3.new(5, 0.4, 1.6),
			color = Color3.fromRGB(200, 200, 205),
			material = Enum.Material.DiamondPlate,
			name = "Step",
		})
	end
end

local function yacht(parent: Folder, position: Vector3)
	part({
		parent = parent,
		position = position + Vector3.new(0, 3, 0),
		size = Vector3.new(24, 6, 80),
		color = Color3.fromRGB(250, 250, 255),
		material = Enum.Material.SmoothPlastic,
		name = "Hull",
	})
	part({
		parent = parent,
		position = position + Vector3.new(0, 8, -6),
		size = Vector3.new(18, 5, 40),
		color = Color3.fromRGB(240, 240, 248),
		material = Enum.Material.SmoothPlastic,
		name = "Deck2",
	})
	part({
		parent = parent,
		position = position + Vector3.new(0, 12.5, -12),
		size = Vector3.new(13, 4, 22),
		color = Color3.fromRGB(235, 235, 245),
		material = Enum.Material.Glass,
		transparency = 0.2,
		name = "Bridge",
	})
	part({
		parent = parent,
		position = position + Vector3.new(0, 11, 22),
		size = Vector3.new(14, 0.4, 14),
		color = Color3.fromRGB(90, 90, 100),
		material = Enum.Material.Concrete,
		collide = false,
		name = "Helipad",
	})
end

-- Per-area decoration ------------------------------------------------------

local Decor = {}

function Decor.bedroom(folder: Folder, origin: Vector3, area)
	-- Three walls and a ceiling-height suggestion. It is a box room.
	for _, spec in ipairs({
		{ pos = Vector3.new(0, 14, -88), size = Vector3.new(180, 28, 3) },
		{ pos = Vector3.new(-88, 14, 0), size = Vector3.new(3, 28, 180) },
		{ pos = Vector3.new(88, 14, 0), size = Vector3.new(3, 28, 180) },
	}) do
		part({
			parent = folder,
			position = origin + spec.pos,
			size = spec.size,
			color = Color3.fromRGB(198, 186, 170),
			material = Enum.Material.Plaster,
			name = "Wall",
		})
	end

	-- The desk, the chair, the laptop, the poster. The empire.
	part({ parent = folder, position = origin + Vector3.new(-40, 4.6, -30), size = Vector3.new(14, 0.5, 7), color = Color3.fromRGB(150, 120, 90), material = Enum.Material.WoodPlanks, name = "Desk" })
	part({ parent = folder, position = origin + Vector3.new(-45, 3.2, -30), size = Vector3.new(0.5, 5, 6), color = Color3.fromRGB(90, 90, 95), name = "DeskLeg" })
	part({ parent = folder, position = origin + Vector3.new(-35, 3.2, -30), size = Vector3.new(0.5, 5, 6), color = Color3.fromRGB(90, 90, 95), name = "DeskLeg" })
	part({ parent = folder, position = origin + Vector3.new(-40, 5.6, -30), size = Vector3.new(5, 0.3, 3.4), color = Color3.fromRGB(60, 60, 65), material = Enum.Material.Metal, name = "Laptop" })
	part({ parent = folder, cframe = CFrame.new(origin + Vector3.new(-40, 6.8, -31.6)) * CFrame.Angles(math.rad(-15), 0, 0), size = Vector3.new(5, 3.2, 0.3), color = Color3.fromRGB(40, 45, 60), material = Enum.Material.Neon, name = "LaptopScreen" })
	part({ parent = folder, position = origin + Vector3.new(-40, 3, -24), size = Vector3.new(4, 6, 4), color = Color3.fromRGB(50, 50, 58), material = Enum.Material.Fabric, name = "GamingChair" })

	local poster = part({
		parent = folder,
		position = origin + Vector3.new(-40, 16, -86.2),
		size = Vector3.new(16, 10, 0.3),
		color = Color3.fromRGB(30, 40, 70),
		material = Enum.Material.SmoothPlastic,
		collide = false,
		name = "MotivationalPoster",
	})
	local posterGui = Instance.new("SurfaceGui")
	posterGui.Face = Enum.NormalId.Front
	posterGui.CanvasSize = Vector2.new(400, 250)
	posterGui.Parent = poster
	local posterLabel = Instance.new("TextLabel")
	posterLabel.Size = UDim2.fromScale(1, 1)
	posterLabel.BackgroundTransparency = 1
	posterLabel.Font = Enum.Font.GothamBold
	posterLabel.TextScaled = true
	posterLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	posterLabel.Text = "HUSTLE\nUNTIL YOUR\nHATERS ASK\nIF YOU'RE\nHIRING"
	posterLabel.Parent = posterGui

	-- The bed you will film "day in the life" from.
	part({ parent = folder, position = origin + Vector3.new(35, 3.5, -35), size = Vector3.new(14, 3, 20), color = Color3.fromRGB(70, 80, 110), material = Enum.Material.Fabric, name = "Bed" })
	part({ parent = folder, position = origin + Vector3.new(35, 5.4, -43), size = Vector3.new(10, 1.6, 4), color = Color3.fromRGB(230, 230, 240), material = Enum.Material.Fabric, name = "Pillow" })
end

function Decor.city(folder: Folder, origin: Vector3, area)
	local heights = { 46, 62, 38, 74, 52, 66, 44 }
	for index, height in ipairs(heights) do
		local x = -75 + (index - 1) * 25
		building(folder, origin + Vector3.new(x, 2, -80), Vector3.new(20, height, 20), Color3.fromRGB(88, 92, 104))
	end
	for index = 1, 4 do
		part({
			parent = folder,
			position = origin + Vector3.new(-60 + index * 30, 10, 20),
			size = Vector3.new(0.8, 16, 0.8),
			color = Color3.fromRGB(60, 60, 65),
			material = Enum.Material.Metal,
			name = "LampPost",
		})
		part({
			parent = folder,
			position = origin + Vector3.new(-60 + index * 30, 18.4, 20),
			size = Vector3.new(2.4, 0.8, 2.4),
			color = Color3.fromRGB(255, 240, 190),
			material = Enum.Material.Neon,
			collide = false,
			name = "LampHead",
		})
	end
	car(folder, origin + Vector3.new(40, 2, -40), Color3.fromRGB(140, 145, 155))
	car(folder, origin + Vector3.new(55, 2, -40), Color3.fromRGB(90, 95, 105))
end

function Decor.rental(folder: Folder, origin: Vector3, area)
	building(folder, origin + Vector3.new(0, 2, -70), Vector3.new(120, 26, 34), Color3.fromRGB(45, 45, 52))
	local colours = {
		Color3.fromRGB(220, 60, 60),
		Color3.fromRGB(240, 200, 60),
		Color3.fromRGB(60, 120, 230),
		Color3.fromRGB(30, 30, 35),
		Color3.fromRGB(240, 240, 245),
		Color3.fromRGB(110, 220, 140),
	}
	for index, colour in ipairs(colours) do
		car(folder, origin + Vector3.new(-62 + (index - 1) * 25, 2, 10), colour)
	end
end

function Decor.apartment(folder: Folder, origin: Vector3, area)
	-- Glass box in the sky, plus the obligatory balcony rail.
	part({ parent = folder, position = origin + Vector3.new(0, 18, -70), size = Vector3.new(150, 32, 6), color = Color3.fromRGB(150, 190, 215), material = Enum.Material.Glass, transparency = 0.35, name = "GlassWall" })
	part({ parent = folder, position = origin + Vector3.new(0, 5, -62), size = Vector3.new(150, 1, 2), color = Color3.fromRGB(230, 230, 235), material = Enum.Material.Metal, collide = false, name = "BalconyRail" })
	part({ parent = folder, position = origin + Vector3.new(-50, 4.5, 30), size = Vector3.new(20, 5, 8), color = Color3.fromRGB(240, 238, 230), material = Enum.Material.Marble, name = "KitchenIsland" })
	part({ parent = folder, position = origin + Vector3.new(50, 4.5, 30), size = Vector3.new(12, 5, 6), color = Color3.fromRGB(245, 245, 248), material = Enum.Material.Marble, name = "Bathroom" })
	part({ parent = folder, position = origin + Vector3.new(0, 2.3, 0), size = Vector3.new(60, 0.3, 40), color = Color3.fromRGB(205, 195, 180), material = Enum.Material.WoodPlanks, collide = false, name = "Rug" })
end

function Decor.mansion(folder: Folder, origin: Vector3, area)
	building(folder, origin + Vector3.new(0, 2, -68), Vector3.new(110, 36, 30), Color3.fromRGB(238, 234, 222))
	for index = 1, 6 do
		part({
			parent = folder,
			position = origin + Vector3.new(-45 + (index - 1) * 18, 12, -50),
			size = Vector3.new(24, 4, 4),
			shape = Enum.PartType.Cylinder,
			cframe = CFrame.new(origin + Vector3.new(-45 + (index - 1) * 18, 14, -50)) * CFrame.Angles(0, 0, math.rad(90)),
			color = Color3.fromRGB(245, 242, 235),
			material = Enum.Material.Marble,
			name = "Column",
		})
	end
	-- The pool, which exists purely to be filmed from above.
	part({ parent = folder, position = origin + Vector3.new(-50, 1.6, -40), size = Vector3.new(34, 1.4, 26), color = Color3.fromRGB(70, 180, 220), material = Enum.Material.Glass, transparency = 0.35, collide = false, name = "Pool" })
	part({ parent = folder, position = origin + Vector3.new(50, 2.2, -45), size = Vector3.new(40, 0.4, 30), color = Color3.fromRGB(190, 185, 170), material = Enum.Material.Sand, collide = false, name = "GravelDriveway" })
	car(folder, origin + Vector3.new(44, 2, -45), Color3.fromRGB(20, 20, 24))
	car(folder, origin + Vector3.new(58, 2, -45), Color3.fromRGB(240, 240, 245))
end

function Decor.airport(folder: Folder, origin: Vector3, area)
	part({ parent = folder, position = origin + Vector3.new(0, 2.2, 0), size = Vector3.new(170, 0.4, 60), color = Color3.fromRGB(52, 54, 58), material = Enum.Material.Asphalt, collide = false, name = "Apron" })
	for index = 1, 8 do
		part({
			parent = folder,
			position = origin + Vector3.new(-75 + (index - 1) * 21, 2.4, 0),
			size = Vector3.new(10, 0.3, 1.6),
			color = Color3.fromRGB(240, 220, 90),
			material = Enum.Material.Neon,
			collide = false,
			name = "Marking",
		})
	end
	jet(folder, origin + Vector3.new(-20, 2, -45))
	building(folder, origin + Vector3.new(60, 2, 55), Vector3.new(50, 22, 28), Color3.fromRGB(70, 74, 82))
end

function Decor.dubai(folder: Folder, origin: Vector3, area)
	local heights = { 90, 130, 70, 160, 110 }
	for index, height in ipairs(heights) do
		building(folder, origin + Vector3.new(-70 + (index - 1) * 35, 2, -78), Vector3.new(22, height, 22), Color3.fromRGB(215, 195, 155))
	end
	for index = 1, 6 do
		palm(folder, origin + Vector3.new(-70 + (index - 1) * 28, 2, 60))
	end
	car(folder, origin + Vector3.new(-20, 2, 45), Color3.fromRGB(250, 250, 255))
	car(folder, origin + Vector3.new(0, 2, 45), Color3.fromRGB(240, 190, 60))
	car(folder, origin + Vector3.new(20, 2, 45), Color3.fromRGB(30, 30, 35))
end

function Decor.marina(folder: Folder, origin: Vector3, area)
	part({ parent = folder, position = origin + Vector3.new(0, 1, 0), size = Vector3.new(178, 2, 178), color = Color3.fromRGB(60, 120, 160), material = Enum.Material.Glass, transparency = 0.3, collide = false, name = "Water" })
	part({ parent = folder, position = origin + Vector3.new(0, 2.4, 40), size = Vector3.new(160, 0.8, 14), color = Color3.fromRGB(180, 160, 120), material = Enum.Material.WoodPlanks, name = "Jetty" })
	yacht(folder, origin + Vector3.new(-40, 2, -25))
	part({ parent = folder, position = origin + Vector3.new(50, 3.4, -35), size = Vector3.new(4, 2, 10), color = Color3.fromRGB(230, 70, 70), material = Enum.Material.SmoothPlastic, name = "JetSki" })
end

function Decor.island(folder: Folder, origin: Vector3, area)
	part({ parent = folder, position = origin + Vector3.new(0, 1, 0), size = Vector3.new(220, 2, 220), color = Color3.fromRGB(80, 170, 200), material = Enum.Material.Glass, transparency = 0.3, collide = false, name = "Ocean" })
	for index = 1, 8 do
		local angle = (index / 8) * math.pi * 2
		palm(folder, origin + Vector3.new(math.cos(angle) * 66, 2, math.sin(angle) * 66))
	end
	building(folder, origin + Vector3.new(0, 2, -60), Vector3.new(90, 24, 34), Color3.fromRGB(245, 243, 238))
	part({
		parent = folder,
		cframe = CFrame.new(origin + Vector3.new(50, 2.4, -40)) * CFrame.Angles(0, 0, math.rad(90)),
		size = Vector3.new(0.4, 30, 30),
		shape = Enum.PartType.Cylinder,
		color = Color3.fromRGB(70, 70, 78),
		material = Enum.Material.Concrete,
		collide = false,
		name = "Helipad",
	})
	yacht(folder, origin + Vector3.new(-60, 2, 60))
end

-- Area assembly ------------------------------------------------------------

local BUSINESS_KIOSKS = {
	{ action = "courses", title = "COURSE DESK", subtitle = "Turn followers into money", colour = Color3.fromRGB(80, 190, 130) },
	{ action = "podcast", title = "PODCAST BOOTH", subtitle = "Pay to be interviewed", colour = Color3.fromRGB(180, 120, 230) },
	{ action = "pyramid", title = "MENTORSHIP OFFICE", subtitle = "Build your downline", colour = Color3.fromRGB(230, 170, 60) },
	{ action = "rebrand", title = "THE MIRROR", subtitle = "Delete everything, start again", colour = Color3.fromRGB(230, 90, 110) },
}

local function buildKiosk(folder: Folder, position: Vector3, colour: Color3, title: string, subtitle: string, action: string, payload: string?)
	local base = part({
		parent = folder,
		position = position + Vector3.new(0, 0.4, 0),
		size = Vector3.new(7, 0.8, 7),
		color = colour,
		material = Enum.Material.Neon,
		name = "KioskBase",
	})
	local post = part({
		parent = folder,
		position = position + Vector3.new(0, 3.4, 0),
		size = Vector3.new(1.2, 5.2, 1.2),
		color = Color3.fromRGB(45, 45, 52),
		material = Enum.Material.Metal,
		name = "KioskPost",
	})
	billboard(post, title, subtitle, 4)

	post:SetAttribute("Action", action)
	if payload then
		post:SetAttribute("Payload", payload)
	end

	local promptInstance = prompt(post, "Open", title)
	promptInstance.Name = "KioskPrompt"

	return post, base
end

local function buildSpot(folder: Folder, spot, area)
	local pad = part({
		parent = folder,
		position = spot.position + Vector3.new(0, 0.2, 0),
		size = Vector3.new(0.4, 12, 12),
		shape = Enum.PartType.Cylinder,
		cframe = CFrame.new(spot.position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color = area.accent,
		material = Enum.Material.Neon,
		transparency = 0.2,
		collide = false,
		name = "ContentSpot_" .. spot.id,
	})

	billboard(pad, "📸 " .. spot.name, "Base reach: " .. Format.short(spot.base), 6)

	pad:SetAttribute("Action", "content")
	pad:SetAttribute("Payload", spot.id)

	local promptInstance = prompt(pad, "Create Content", spot.name, 16)
	promptInstance.Name = "ContentPrompt"

	return pad
end

local function buildLeaderboards(folder: Folder, origin: Vector3)
	for index, board in ipairs(Leaderboards.Boards) do
		local x = -72 + (index - 1) * 36
		local panel = part({
			parent = folder,
			position = origin + Vector3.new(x, 18, -86),
			size = Vector3.new(32, 30, 1),
			color = Color3.fromRGB(22, 22, 28),
			material = Enum.Material.SmoothPlastic,
			name = "Leaderboard_" .. board.id,
		})

		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back
		gui.CanvasSize = Vector2.new(520, 480)
		gui.LightInfluence = 0
		gui.Parent = panel

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 52)
		title.BackgroundColor3 = index == #Leaderboards.Boards and Color3.fromRGB(230, 170, 60) or Color3.fromRGB(45, 45, 58)
		title.BorderSizePixel = 0
		title.Font = Enum.Font.GothamBold
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Text = board.title
		title.Parent = gui

		local subtitle = Instance.new("TextLabel")
		subtitle.Size = UDim2.new(1, 0, 0, 26)
		subtitle.Position = UDim2.new(0, 0, 0, 52)
		subtitle.BackgroundTransparency = 1
		subtitle.Font = Enum.Font.GothamMedium
		subtitle.TextSize = 16
		subtitle.TextColor3 = Color3.fromRGB(170, 170, 185)
		subtitle.Text = board.subtitle
		subtitle.Parent = gui

		local list = Instance.new("Frame")
		list.Size = UDim2.new(1, -16, 1, -92)
		list.Position = UDim2.new(0, 8, 0, 84)
		list.BackgroundTransparency = 1
		list.Parent = gui

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 2)
		layout.Parent = list

		Leaderboards.register(board.id, list)
	end
end

local function buildArea(area)
	local folder = Instance.new("Folder")
	folder.Name = "Area_" .. area.id
	folder.Parent = worldFolder

	local origin = area.origin

	part({
		parent = folder,
		position = origin,
		size = Areas.PlatformSize,
		color = area.floor,
		material = Enum.Material.Concrete,
		name = "Platform",
	})

	-- Area nameplate, floating above the centre of the island.
	local marker = part({
		parent = folder,
		position = origin + Vector3.new(0, 34, 0),
		size = Vector3.new(2, 2, 2),
		transparency = 1,
		collide = false,
		name = "AreaMarker",
	})
	local nameplate = billboard(marker, area.name, area.subtitle, 0)
	nameplate.Size = UDim2.new(0, 560, 0, 120)
	nameplate.MaxDistance = 600

	local decorate = Decor[area.id]
	if decorate then
		decorate(folder, origin, area)
	end

	for _, spot in ipairs(area.spots) do
		buildSpot(folder, spot, area)
	end

	-- Shops along the far edge.
	local shopCount = #area.shops
	for index, categoryId in ipairs(area.shops) do
		local category = Items.category(categoryId)
		if category then
			local spread = 130
			local x = shopCount > 1 and (-spread / 2 + (index - 1) * (spread / (shopCount - 1))) or 0
			buildKiosk(
				folder,
				origin + Vector3.new(x, 2, 75),
				area.accent,
				(category.icon or "") .. " " .. category.name,
				category.blurb,
				"shop",
				categoryId
			)
		end
	end

	-- Business corner, present in every area so nobody has to walk home.
	for index, kiosk in ipairs(BUSINESS_KIOSKS) do
		buildKiosk(
			folder,
			origin + Vector3.new(-45 + (index - 1) * 30, 2, -75),
			kiosk.colour,
			kiosk.title,
			kiosk.subtitle,
			kiosk.action
		)
	end

	-- Travel post.
	buildKiosk(
		folder,
		origin + Vector3.new(75, 2, 0),
		Color3.fromRGB(90, 160, 230),
		"✈ TRAVEL",
		"Go somewhere more expensive",
		"travel"
	)

	if area.index == 1 then
		buildLeaderboards(folder, origin)

		local spawnPart = part({
			parent = folder,
			position = origin + Vector3.new(0, 2.6, 20),
			size = Vector3.new(12, 1.2, 12),
			color = Color3.fromRGB(120, 200, 140),
			material = Enum.Material.Neon,
			transparency = 0.4,
			collide = false,
			name = "SpawnPad",
		})

		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Size = Vector3.new(12, 1, 12)
		spawnLocation.Position = origin + Vector3.new(0, 3.2, 20)
		spawnLocation.Anchored = true
		spawnLocation.CanCollide = false
		spawnLocation.Transparency = 1
		spawnLocation.Neutral = true
		spawnLocation.Duration = 0
		spawnLocation.Parent = folder
		spawnPart.Name = "SpawnPadVisual"
	end

	return folder
end

--- Where a player should land when travelling to an area.
function WorldBuilder.arrivalPoint(area): CFrame
	return CFrame.new(area.origin + Vector3.new(0, 6, 25))
end

function WorldBuilder.build()
	local existing = Workspace:FindFirstChild("LarpWorld")
	if existing then
		existing:Destroy()
	end

	worldFolder = Instance.new("Folder")
	worldFolder.Name = "LarpWorld"
	worldFolder.Parent = Workspace

	for _, area in ipairs(Areas.List) do
		buildArea(area)
	end

	return worldFolder
end

function WorldBuilder.folder(): Folder
	return worldFolder
end

return WorldBuilder
