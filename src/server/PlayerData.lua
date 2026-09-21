--!strict
--[[
	PlayerData.lua

	Profile storage. Everything the player owns, owes and has faked lives in a
	plain table so it serialises straight into a DataStore.

	Rental expiries are stored as absolute os.time() values, which means logging
	off while renting a Bugatti does not pause the meter. This is intentional
	and, frankly, realistic.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Balance = require(game:GetService("ReplicatedStorage").Shared.Balance)

local PlayerData = {}

local STORE_NAME = "LarpingSimulator_v1"
local store: DataStore? = nil
local storeOk = false

do
	local success, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if success then
		store = result
		storeOk = true
	else
		warn("[LARP] DataStore unavailable, running in memory only: " .. tostring(result))
	end
end

local profiles: { [number]: any } = {}

local function defaultProfile()
	return {
		version = 1,
		cash = Balance.StartingCash,
		followers = 0,
		cloutBonus = 0,
		suspicion = 0,

		owned = {},    -- [itemId] = true
		rentals = {},  -- [itemId] = absolute os.time() expiry

		courseId = Balance.StartingCourseId,
		prestige = 0,
		downline = 0,

		buffs = {},       -- { { name, followers, cash, expires } }
		recentSpots = {}, -- most recent first

		lastPost = 0,
		lastLaunch = 0,
		lastPodcast = 0,
		autoPostAt = 0,
		pendingQuestion = nil,

		stats = {
			spentLarping = 0,   -- the leaderboard that matters
			coursesSold = 0,
			postsMade = 0,
			lifetimeCash = 0,
			peakFollowers = 0,
			timesExposed = 0,
			rebrands = 0,
			rentalsExpired = 0,
		},
	}
end

PlayerData.defaultProfile = defaultProfile

--- Fills in any field added by a later version of the game.
local function reconcile(profile)
	local template = defaultProfile()
	for key, value in pairs(template) do
		if profile[key] == nil then
			profile[key] = value
		end
	end
	for key, value in pairs(template.stats) do
		if profile.stats[key] == nil then
			profile.stats[key] = value
		end
	end
	return profile
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

function PlayerData.load(player: Player)
	local profile = defaultProfile()

	if storeOk and store and not RunService:IsStudio() then
		local success, result = pcall(function()
			return (store :: DataStore):GetAsync(keyFor(player))
		end)
		if success and type(result) == "table" then
			profile = reconcile(result)
		elseif not success then
			warn("[LARP] load failed for " .. player.Name .. ": " .. tostring(result))
		end
	end

	profiles[player.UserId] = profile
	return profile
end

function PlayerData.get(player: Player)
	return profiles[player.UserId]
end

function PlayerData.save(player: Player)
	local profile = profiles[player.UserId]
	if not profile or not storeOk or not store then
		return false
	end
	if RunService:IsStudio() then
		return false
	end

	local success, err = pcall(function()
		(store :: DataStore):SetAsync(keyFor(player), profile)
	end)
	if not success then
		warn("[LARP] save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return success
end

function PlayerData.release(player: Player)
	PlayerData.save(player)
	profiles[player.UserId] = nil
end

function PlayerData.all()
	return profiles
end

--- Autosave loop plus a best-effort flush when the server shuts down.
function PlayerData.start()
	task.spawn(function()
		while true do
			task.wait(Balance.AutosaveInterval)
			for _, player in ipairs(Players:GetPlayers()) do
				if profiles[player.UserId] then
					PlayerData.save(player)
				end
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerData.save(player)
		end
		if RunService:IsStudio() then
			task.wait(0.5)
		else
			task.wait(2)
		end
	end)
end

return PlayerData
