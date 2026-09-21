--!strict
--[[
	Hud.lua

	The top bar. Cash, Followers, Clout, Suspicion -- plus a quiet second line
	of the numbers that actually drive progression, and a rail of buttons for
	the things you shouldn't have to walk to a kiosk for.

	Counters roll rather than snap, because watching a follower count tick
	upwards is the entire emotional payload of this genre.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Format = require(Shared.Format)

local Theme = require(script.Parent.Theme)

local Hud = {}

local displayed = { cash = 0, followers = 0, clout = 0 }
local target = { cash = 0, followers = 0, clout = 0 }
local widgets = {}
local railCallbacks = {}

local RAIL = {
	{ id = "launch", label = "🚀", tooltip = "Launch course", colour = Theme.Colour.cash },
	{ id = "courses", label = "💼", tooltip = "Courses", colour = Theme.Colour.followers },
	{ id = "podcast", label = "🎙", tooltip = "Podcasts", colour = Theme.Colour.viral },
	{ id = "pyramid", label = "🔺", tooltip = "Downline", colour = Theme.Colour.clout },
	{ id = "travel", label = "✈", tooltip = "Travel", colour = Theme.Colour.followers },
	{ id = "rebrand", label = "🪞", tooltip = "Rebrand", colour = Theme.Colour.suspicion },
}

local function statChip(parent: Instance, name: string, icon: string, colour: Color3, order: number)
	local chip = Theme.frame({
		parent = parent,
		size = UDim2.new(0, 168, 1, 0),
		colour = Theme.Colour.card,
		radius = 12,
		order = order,
		name = name,
	})
	Theme.stroke(chip, Theme.Colour.line, 1)
	Theme.padding(chip, 10, { left = 12, right = 12 })

	Theme.label({
		parent = chip,
		size = UDim2.new(1, 0, 0, 14),
		text = icon .. "  " .. name:upper(),
		font = Theme.Font.heavy,
		textSize = 11,
		textColour = Theme.Colour.dim,
	})

	local value = Theme.label({
		parent = chip,
		size = UDim2.new(1, 0, 0, 26),
		position = UDim2.new(0, 0, 0, 15),
		text = "0",
		font = Theme.Font.heavy,
		textSize = 24,
		textColour = colour,
	})

	return chip, value
end

function Hud.build(screen: ScreenGui)
	local bar = Theme.frame({
		parent = screen,
		size = UDim2.new(0, 712, 0, 62),
		position = UDim2.new(0.5, 0, 0, 12),
		anchor = Vector2.new(0.5, 0),
		colour = Theme.Colour.panel,
		transparency = 0.08,
		radius = 16,
		name = "StatBar",
	})
	Theme.stroke(bar, Theme.Colour.line, 1)
	Theme.padding(bar, 6)
	Theme.list(bar, 6, Enum.FillDirection.Horizontal)

	local _, cashValue = statChip(bar, "Cash", "💷", Theme.Colour.cash, 1)
	local _, followerValue = statChip(bar, "Followers", "👥", Theme.Colour.followers, 2)
	local _, cloutValue = statChip(bar, "Clout", "✨", Theme.Colour.clout, 3)

	-- Suspicion gets a meter rather than a number, because a percentage that
	-- creeps upward is more threatening than one that just sits there.
	local susChip = Theme.frame({
		parent = bar,
		size = UDim2.new(0, 168, 1, 0),
		colour = Theme.Colour.card,
		radius = 12,
		order = 4,
		name = "Suspicion",
	})
	Theme.stroke(susChip, Theme.Colour.line, 1)
	Theme.padding(susChip, 10, { left = 12, right = 12 })

	Theme.label({
		parent = susChip,
		size = UDim2.new(1, 0, 0, 14),
		text = "🕵  SUSPICION",
		font = Theme.Font.heavy,
		textSize = 11,
		textColour = Theme.Colour.dim,
	})
	local susValue = Theme.label({
		parent = susChip,
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.new(0, 0, 0, 14),
		text = "0%",
		font = Theme.Font.heavy,
		textSize = 20,
		textColour = Theme.Colour.suspicion,
	})
	local susHolder = Theme.frame({
		parent = susChip,
		size = UDim2.new(1, 0, 0, 6),
		position = UDim2.new(0, 0, 1, -6),
		transparency = 1,
		radius = 0,
		name = "SusMeter",
	})
	local _, susFill = Theme.meter(susHolder, Theme.Colour.suspicion)

	-- Secondary line: the numbers that explain the primary line.
	local sub = Theme.frame({
		parent = screen,
		size = UDim2.new(0, 712, 0, 26),
		position = UDim2.new(0.5, 0, 0, 78),
		anchor = Vector2.new(0.5, 0),
		colour = Theme.Colour.panel,
		transparency = 0.35,
		radius = 8,
		name = "SubBar",
	})
	Theme.padding(sub, 4, { left = 14, right = 14 })
	local subLabel = Theme.label({
		parent = sub,
		text = "",
		font = Theme.Font.medium,
		textSize = 13,
		textColour = Theme.Colour.muted,
		rich = true,
	})

	-- Right-hand button rail.
	local rail = Theme.frame({
		parent = screen,
		size = UDim2.new(0, 56, 0, #RAIL * 56),
		position = UDim2.new(1, -16, 0.5, 0),
		anchor = Vector2.new(1, 0.5),
		transparency = 1,
		radius = 0,
		name = "Rail",
	})
	Theme.list(rail, 8)

	for index, entry in ipairs(RAIL) do
		local button = Theme.button({
			parent = rail,
			size = UDim2.new(0, 48, 0, 48),
			text = entry.label,
			textSize = 22,
			colour = Theme.Colour.card,
			radius = 14,
			order = index,
			name = entry.id,
		})
		Theme.stroke(button, entry.colour, 1, 0.55)

		local tip = Theme.label({
			parent = button,
			size = UDim2.new(0, 120, 0, 24),
			position = UDim2.new(0, -128, 0.5, 0),
			anchor = Vector2.new(0, 0.5),
			text = entry.tooltip,
			font = Theme.Font.heavy,
			textSize = 12,
			textColour = Theme.Colour.text,
			bgTransparency = 0.15,
			colour = Theme.Colour.bg,
			align = Enum.TextXAlignment.Center,
		})
		tip.Visible = false
		Theme.corner(tip, 6)

		button.MouseEnter:Connect(function()
			tip.Visible = true
		end)
		button.MouseLeave:Connect(function()
			tip.Visible = false
		end)
		button.Activated:Connect(function()
			local callback = railCallbacks[entry.id]
			if callback then
				callback()
			end
		end)
	end

	widgets = {
		cash = cashValue,
		followers = followerValue,
		clout = cloutValue,
		suspicion = susValue,
		suspicionFill = susFill,
		sub = subLabel,
	}

	-- Counter roll-up.
	RunService.RenderStepped:Connect(function(dt)
		local alpha = math.clamp(dt * 6, 0, 1)
		for key, goal in pairs(target) do
			local current = displayed[key]
			if math.abs(goal - current) < 1 then
				displayed[key] = goal
			else
				displayed[key] = current + (goal - current) * alpha
			end
		end

		widgets.cash.Text = Format.money(displayed.cash)
		widgets.followers.Text = Format.short(displayed.followers)
		widgets.clout.Text = Format.short(displayed.clout)
	end)
end

function Hud.onRail(id: string, callback: () -> ())
	railCallbacks[id] = callback
end

function Hud.update(state)
	target.cash = state.cash
	target.followers = state.followers
	target.clout = state.clout

	if not widgets.suspicion then
		return
	end

	widgets.suspicion.Text = Format.percent(state.suspicion)
	Theme.tween(widgets.suspicionFill, 0.3, { Size = UDim2.fromScale(state.suspicion / 100, 1) })

	local tint = Theme.Colour.suspicion
	if state.suspicion < 30 then
		tint = Theme.Colour.cash
	elseif state.suspicion < 65 then
		tint = Theme.Colour.clout
	end
	widgets.suspicionFill.BackgroundColor3 = tint
	widgets.suspicion.TextColor3 = tint

	local perSecond = state.revenuePerTick / state.tickInterval
	local parts = {
		string.format('<font color="#60E09E">%s/sec</font> from "%s"', Format.money(perSecond), state.courseName),
		string.format("×%.2f followers", state.followerMult),
		string.format("×%.2f revenue", state.cashMult),
		state.prestigeTitle,
	}
	if state.downline > 0 then
		table.insert(parts, state.downline .. " in your downline")
	end
	if state.autoPostInterval then
		table.insert(parts, "auto-post " .. state.autoPostInterval .. "s")
	end

	widgets.sub.Text = table.concat(parts, "   ·   ")
end

return Hud
