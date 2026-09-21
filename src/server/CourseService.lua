--!strict
--[[
	CourseService.lua

	Followers in, money out. Sales happen automatically on a tick; a manual
	"launch" front-loads a chunk of that income and costs you a little
	credibility, because launches are always slightly obnoxious.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Balance)
local Courses = require(Shared.Courses)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local Feedback = require(script.Parent.Feedback)

local CourseService = {}

--- One passive sales tick.
function CourseService.tick(player: Player, profile, derived)
	derived = derived or State.compute(profile)

	local revenue = derived.revenuePerTick + derived.mentorshipPerTick
	if revenue <= 0 then
		return 0
	end

	Effects.addCash(profile, revenue)

	local sales = (profile.followers ^ Balance.RevenueExponent) * derived.course.conversion
	profile.stats.coursesSold += math.max(0, math.floor(sales))

	return revenue
end

--- Manual launch: a burst of income, a burst of irritation.
function CourseService.launch(player: Player, profile)
	local since = os.clock() - profile.lastLaunch
	if since < Balance.LaunchCooldown then
		return { ok = false, err = "Launch cooling down (" .. Format.timer(Balance.LaunchCooldown - since) .. ")" }
	end

	local derived = State.compute(profile)
	local revenue = (derived.revenuePerTick + derived.mentorshipPerTick) * Balance.LaunchMultiplier

	if revenue < 1 then
		return { ok = false, err = "Nobody is buying. Get followers first." }
	end

	profile.lastLaunch = os.clock()
	Effects.addCash(profile, revenue)
	Effects.addSuspicion(profile, 2)
	profile.stats.coursesSold += math.max(
		1,
		math.floor((profile.followers ^ Balance.RevenueExponent) * derived.course.conversion * Balance.LaunchMultiplier)
	)

	Feedback.notify(
		player,
		"money",
		"CART OPEN — " .. derived.course.name,
		"Doors close in 4 hours (they never close). " .. Format.money(revenue) .. " collected."
	)

	State.push(player, profile, derived)
	return { ok = true, revenue = revenue }
end

function CourseService.setCourse(player: Player, profile, courseId: string)
	local course = Courses.ById[courseId]
	if not course then
		return { ok = false, err = "No such course." }
	end

	local derived = State.compute(profile)
	if not Courses.isUnlocked(course, profile.followers, derived.clout) then
		local needs = {}
		if profile.followers < course.req.followers then
			table.insert(needs, Format.short(course.req.followers) .. " followers")
		end
		if derived.clout < course.req.clout then
			table.insert(needs, Format.short(course.req.clout) .. " clout")
		end
		return { ok = false, err = "Needs " .. table.concat(needs, " and ") .. "." }
	end

	profile.courseId = courseId
	Feedback.notify(player, "info", "Now selling: " .. course.name, course.pitch)
	State.push(player, profile)
	return { ok = true }
end

--- Course list for the UI, with unlock state resolved.
function CourseService.catalogue(profile)
	local derived = State.compute(profile)
	local entries = {}

	for _, course in ipairs(Courses.List) do
		local unlocked = Courses.isUnlocked(course, profile.followers, derived.clout)
		table.insert(entries, {
			id = course.id,
			name = course.name,
			price = course.price,
			pitch = course.pitch,
			lessons = course.lessons,
			unlocked = unlocked,
			active = course.id == profile.courseId,
			reqFollowers = course.req.followers,
			reqClout = course.req.clout,
			revenuePerTick = (profile.followers ^ Balance.RevenueExponent)
				* course.conversion
				* course.price
				* derived.cashMult
				* derived.suspicionPenalty,
		})
	end

	return {
		entries = entries,
		mentorship = derived.mentorship,
		mentorshipPerTick = derived.mentorshipPerTick,
		tickInterval = Balance.CourseTickInterval,
	}
end

return CourseService
