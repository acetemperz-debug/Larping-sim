--!strict
--[[
	Actions.lua

	Every client request lands here. One RemoteFunction, one action string, one
	validated handler. Nothing the client sends is trusted beyond an id.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Areas = require(Shared.Areas)
local Balance = require(Shared.Balance)
local Format = require(Shared.Format)

local PlayerData = require(script.Parent.PlayerData)
local State = require(script.Parent.State)
local Economy = require(script.Parent.Economy)
local Content = require(script.Parent.Content)
local CourseService = require(script.Parent.CourseService)
local PodcastService = require(script.Parent.PodcastService)
local Pyramid = require(script.Parent.Pyramid)
local Rebrand = require(script.Parent.Rebrand)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Actions = {}

local handlers = {}

handlers.state = function(player, profile)
	return { ok = true, state = State.snapshot(profile) }
end

handlers.shop = function(player, profile, payload)
	local categoryId = payload and payload.category
	if type(categoryId) ~= "string" then
		return { ok = false, err = "No category." }
	end
	local catalogue = Economy.catalogue(profile, categoryId)
	if not catalogue then
		return { ok = false, err = "No such shop." }
	end
	return { ok = true, catalogue = catalogue }
end

handlers.buy = function(player, profile, payload)
	if type(payload) ~= "table" or type(payload.itemId) ~= "string" then
		return { ok = false, err = "Nothing selected." }
	end
	return Economy.purchase(player, profile, payload.itemId)
end

handlers.content = function(player, profile, payload)
	if type(payload) ~= "table" or type(payload.spotId) ~= "string" then
		return { ok = false, err = "Stand on a content spot." }
	end
	return Content.create(player, profile, payload.spotId)
end

handlers.courses = function(player, profile)
	return { ok = true, catalogue = CourseService.catalogue(profile) }
end

handlers.setCourse = function(player, profile, payload)
	if type(payload) ~= "table" or type(payload.courseId) ~= "string" then
		return { ok = false, err = "No course selected." }
	end
	return CourseService.setCourse(player, profile, payload.courseId)
end

handlers.launch = function(player, profile)
	return CourseService.launch(player, profile)
end

handlers.podcast = function(player, profile)
	return { ok = true, catalogue = PodcastService.catalogue(profile) }
end

handlers.appear = function(player, profile, payload)
	if type(payload) ~= "table" or type(payload.tierId) ~= "string" then
		return { ok = false, err = "Pick a show." }
	end
	return PodcastService.appear(player, profile, payload.tierId)
end

handlers.answer = function(player, profile, payload)
	if type(payload) ~= "table" or type(payload.index) ~= "number" then
		return { ok = false, err = "Pick an answer." }
	end
	return PodcastService.answer(player, profile, payload.index)
end

handlers.pyramid = function(player, profile)
	return { ok = true, info = Pyramid.info(profile) }
end

handlers.recruit = function(player, profile)
	return Pyramid.recruit(player, profile)
end

handlers.rebrand = function(player, profile)
	return { ok = true, info = Rebrand.info(profile) }
end

handlers.doRebrand = function(player, profile)
	return Rebrand.perform(player, profile)
end

handlers.travel = function(player, profile, payload)
	local unlocked = {}
	for _, area in ipairs(Areas.List) do
		table.insert(unlocked, {
			id = area.id,
			name = area.name,
			subtitle = area.subtitle,
			index = area.index,
			unlockFollowers = area.unlockFollowers,
			unlocked = profile.followers >= area.unlockFollowers,
		})
	end

	if not payload or not payload.areaId then
		return { ok = true, areas = unlocked }
	end

	local area = Areas.get(payload.areaId)
	if not area then
		return { ok = false, err = "Nowhere by that name." }
	end
	if profile.followers < area.unlockFollowers then
		return { ok = false, err = area.name .. " opens at " .. Format.short(area.unlockFollowers) .. " followers." }
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return { ok = false, err = "You need a body to travel." }
	end

	(root :: BasePart).CFrame = WorldBuilder.arrivalPoint(area)
	return { ok = true, areas = unlocked, travelled = area.id }
end

--- Static reference data the client caches once on join.
handlers.reference = function(player, profile)
	local areas = {}
	for _, area in ipairs(Areas.List) do
		local spots = {}
		for _, spot in ipairs(area.spots) do
			table.insert(spots, { id = spot.id, name = spot.name, base = spot.base })
		end
		table.insert(areas, {
			id = area.id,
			name = area.name,
			subtitle = area.subtitle,
			index = area.index,
			unlockFollowers = area.unlockFollowers,
			shops = area.shops,
			spots = spots,
		})
	end

	return {
		ok = true,
		areas = areas,
		balance = {
			contentCooldown = Balance.ContentCooldown,
			launchCooldown = Balance.LaunchCooldown,
			tickInterval = Balance.CourseTickInterval,
			suspicionMax = Balance.SuspicionMax,
		},
	}
end

--- Reads are cheap and the UI fires them back-to-back (buy, then refresh), so
--- only state-changing actions are throttled.
local READ_ONLY = {
	state = true,
	reference = true,
	shop = true,
	courses = true,
	podcast = true,
	pyramid = true,
	rebrand = true,
}

--- Rate limiting: stops a spammed RemoteFunction from pinning a core.
local lastCall: { [number]: number } = {}

function Actions.handle(player: Player, action: unknown, payload: unknown)
	if type(action) ~= "string" then
		return { ok = false, err = "Bad request." }
	end

	if not READ_ONLY[action] then
		local now = os.clock()
		local previous = lastCall[player.UserId] or 0
		if now - previous < 0.08 then
			return { ok = false, err = "Slow down." }
		end
		lastCall[player.UserId] = now
	end

	local profile = PlayerData.get(player)
	if not profile then
		return { ok = false, err = "Still loading your empire." }
	end

	local handler = handlers[action]
	if not handler then
		return { ok = false, err = "Unknown action." }
	end

	local success, result = pcall(handler, player, profile, payload)
	if not success then
		warn("[LARP] action '" .. action .. "' failed: " .. tostring(result))
		return { ok = false, err = "Something broke. Post through it." }
	end

	return result
end

function Actions.forget(player: Player)
	lastCall[player.UserId] = nil
end

return Actions
