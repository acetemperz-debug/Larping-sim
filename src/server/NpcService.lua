--!strict
--[[
	NpcService.lua

	Ambient customers. They wander each island, say the things these people
	actually say, and occasionally one of them graduates into a guru of their
	own once somebody on the server has built a downline.

	Deliberately cheap: no Humanoids, no pathfinding, just tweened blocks with
	speech bubbles. They are set dressing, and so is everything else here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Areas = require(Shared.Areas)
local Npcs = require(Shared.Npcs)

local PlayerData = require(script.Parent.PlayerData)

local NpcService = {}

local NPCS_PER_AREA = 5
local WANDER_RADIUS = 55

local rng = Random.new()
local folder: Folder
local active = {}

local function speechBubble(parent: BasePart, npcType)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 210, 0, 54)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.4, 0)
	gui.MaxDistance = 90
	gui.Parent = parent

	local bubble = Instance.new("TextLabel")
	bubble.Size = UDim2.fromScale(1, 1)
	bubble.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	bubble.BackgroundTransparency = 0.15
	bubble.BorderSizePixel = 0
	bubble.Font = Enum.Font.GothamMedium
	bubble.TextSize = 15
	bubble.TextWrapped = true
	bubble.TextColor3 = Color3.fromRGB(240, 240, 248)
	bubble.Text = npcType.lines[1]
	bubble.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bubble

	local nameTag = Instance.new("TextLabel")
	nameTag.Size = UDim2.new(1, 0, 0, 18)
	nameTag.Position = UDim2.new(0, 0, 0, -20)
	nameTag.BackgroundTransparency = 1
	nameTag.Font = Enum.Font.GothamBold
	nameTag.TextSize = 13
	nameTag.TextColor3 = npcType.colour
	nameTag.TextStrokeTransparency = 0.5
	nameTag.Text = npcType.name
	nameTag.Parent = gui

	return bubble, nameTag
end

local function spawnNpc(area, index: number)
	local npcType = Npcs.pickType(rng, true)

	local model = Instance.new("Model")
	model.Name = "Npc_" .. area.id .. "_" .. index
	model.Parent = folder

	local origin = area.origin + Vector3.new(
		rng:NextNumber(-WANDER_RADIUS, WANDER_RADIUS),
		4.5,
		rng:NextNumber(-WANDER_RADIUS, WANDER_RADIUS)
	)

	local body = Instance.new("Part")
	body.Size = Vector3.new(2, 3, 1)
	body.Position = origin
	body.Anchored = true
	body.CanCollide = false
	body.Color = npcType.colour
	body.Material = Enum.Material.SmoothPlastic
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Name = "Body"
	body.Parent = model

	local head = Instance.new("Part")
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Shape = Enum.PartType.Ball
	head.Position = origin + Vector3.new(0, 2.2, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Color = Color3.fromRGB(226, 190, 160)
	head.Material = Enum.Material.SmoothPlastic
	head.Name = "Head"
	head.Parent = model

	model.PrimaryPart = body

	local bubble, nameTag = speechBubble(head, npcType)

	local record = {
		model = model,
		body = body,
		head = head,
		bubble = bubble,
		nameTag = nameTag,
		type = npcType,
		area = area,
		converted = false,
		nextMove = 0,
		nextLine = 0,
	}

	table.insert(active, record)
	return record
end

--- True if anyone in the server has students beneath them.
local function pyramidExists(): boolean
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.get(player)
		if profile and profile.downline > 0 then
			return true
		end
	end
	return false
end

local function moveNpc(record)
	local target = record.area.origin + Vector3.new(
		rng:NextNumber(-WANDER_RADIUS, WANDER_RADIUS),
		4.5,
		rng:NextNumber(-WANDER_RADIUS, WANDER_RADIUS)
	)

	local distance = (target - record.body.Position).Magnitude
	local duration = math.clamp(distance / 9, 1.5, 9)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)

	local lookAt = CFrame.lookAt(target, target + (target - record.body.Position))
	TweenService:Create(record.body, info, { CFrame = lookAt }):Play()
	TweenService:Create(record.head, info, { Position = target + Vector3.new(0, 2.2, 0) }):Play()

	record.nextMove = os.clock() + duration + rng:NextNumber(1, 4)
end

local function talk(record)
	local lines = record.type.lines
	if record.converted then
		lines = Npcs.DownlineLines
	end
	record.bubble.Text = lines[rng:NextInteger(1, #lines)]
	record.nextLine = os.clock() + rng:NextNumber(6, 14)
end

function NpcService.start()
	folder = Instance.new("Folder")
	folder.Name = "LarpNpcs"
	folder.Parent = Workspace

	for _, area in ipairs(Areas.List) do
		for index = 1, NPCS_PER_AREA do
			spawnNpc(area, index)
		end
	end

	task.spawn(function()
		while true do
			local now = os.clock()
			local pyramid = pyramidExists()

			for _, record in ipairs(active) do
				if now >= record.nextMove then
					moveNpc(record)
				end
				if now >= record.nextLine then
					-- Once a pyramid exists, sceptics gradually stop being sceptics.
					if pyramid and not record.converted and not record.type.hater and rng:NextNumber() < 0.08 then
						record.converted = true
						record.nameTag.Text = record.type.name .. " → Guru"
						record.nameTag.TextColor3 = Color3.fromRGB(255, 214, 110)
					end
					talk(record)
				end
			end

			task.wait(1)
		end
	end)
end

return NpcService
