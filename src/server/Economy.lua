--!strict
--[[
	Economy.lua

	Buying things. Nearly everything worth buying expires, which is the entire
	economic thesis of the game: your outgoings are permanent, your assets are
	not.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Items = require(Shared.Items)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local Feedback = require(script.Parent.Feedback)

local Economy = {}

local function meetsRequirements(profile, derived, item): (boolean, string?)
	local req = item.req
	if not req then
		return true, nil
	end
	if req.followers and profile.followers < req.followers then
		return false, "Needs " .. Format.short(req.followers) .. " followers"
	end
	if req.clout and derived.clout < req.clout then
		return false, "Needs " .. Format.short(req.clout) .. " clout"
	end
	if req.prestige and profile.prestige < req.prestige then
		return false, "Needs a higher rebrand level"
	end
	return true, nil
end

Economy.meetsRequirements = meetsRequirements

--- Starts (or extends) a rental.
local function startRental(profile, item, duration: number)
	local now = os.time()
	local current = profile.rentals[item.id]
	if current and current > now then
		profile.rentals[item.id] = current + duration
	else
		profile.rentals[item.id] = now + duration
	end
end

function Economy.purchase(player: Player, profile, itemId: string)
	local item = Items.get(itemId)
	if not item then
		return { ok = false, err = "That doesn't exist." }
	end

	local derived = State.compute(profile)

	local allowed, reason = meetsRequirements(profile, derived, item)
	if not allowed then
		return { ok = false, err = reason }
	end

	local permanent = not item.rental and not item.consume
	if permanent and profile.owned[item.id] then
		return { ok = false, err = "You already own this. Owning things is not the point." }
	end

	if profile.cash < item.price then
		return { ok = false, err = "Not enough cash. Sell another course." }
	end

	profile.cash -= item.price
	profile.stats.spentLarping += item.price

	if item.consume then
		-- Damage control: applies once, keeps nothing.
		if item.suspicion then
			Effects.addSuspicion(profile, item.suspicion)
		end
		Feedback.notify(player, "good", item.name, "Suspicion down. Narrative back under control. For now.")
	elseif item.rental then
		startRental(profile, item, item.duration)
		if item.grants then
			for _, grantedId in ipairs(item.grants) do
				local granted = Items.get(grantedId)
				if granted then
					startRental(profile, granted, item.duration)
				end
			end
		end
		Feedback.notify(player, "money", item.name, "Rented for " .. Format.timer(item.duration) .. ". Film fast.")
	else
		profile.owned[item.id] = true
		Feedback.notify(player, "good", item.name, "Unlocked permanently. A rare thing in this game.")
	end

	if item.sus then
		Effects.addSuspicion(profile, item.sus)
	end

	State.push(player, profile)
	return { ok = true, spent = item.price }
end

--- Everything the shop UI needs for one category, including affordability.
function Economy.catalogue(profile, categoryId: string)
	local category = Items.category(categoryId)
	if not category then
		return nil
	end

	local derived = State.compute(profile)
	local now = os.time()
	local entries = {}

	for _, item in ipairs(category.tiers) do
		local allowed, reason = meetsRequirements(profile, derived, item)
		local rentalRemaining = nil
		if profile.rentals[item.id] then
			rentalRemaining = math.max(0, profile.rentals[item.id] - now)
		end

		table.insert(entries, {
			id = item.id,
			name = item.name,
			desc = item.desc,
			price = item.price,
			clout = item.clout,
			rental = item.rental or false,
			duration = item.duration,
			consume = item.consume or false,
			mult = item.mult,
			autoPost = item.autoPost,
			suspicion = item.suspicion,
			sus = item.sus,
			owned = profile.owned[item.id] or false,
			rentalRemaining = rentalRemaining,
			locked = not allowed,
			lockReason = reason,
			affordable = profile.cash >= item.price,
		})
	end

	return {
		id = category.id,
		name = category.name,
		blurb = category.blurb,
		icon = category.icon,
		stacking = category.stacking,
		entries = entries,
	}
end

return Economy
