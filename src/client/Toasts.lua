--!strict
--[[
	Toasts.lua

	Notifications, milestone cards and server-wide announcements.

	Milestones take over the screen for three seconds because that is exactly
	what a follower milestone deserves and exactly how seriously these people
	take them.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local Toasts = {}

local stack: Frame
local overlay: Frame
local broadcastBar: Frame
local broadcastLabel: TextLabel

local MAX_TOASTS = 5

function Toasts.build(screen: ScreenGui)
	stack = Theme.frame({
		parent = screen,
		size = UDim2.new(0, 320, 0, 500),
		position = UDim2.new(0, 16, 0, 16),
		transparency = 1,
		radius = 0,
		name = "Toasts",
	})
	local layout = Theme.list(stack, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top

	overlay = Theme.frame({
		parent = screen,
		size = UDim2.fromScale(1, 1),
		colour = Theme.Colour.bg,
		transparency = 1,
		radius = 0,
		name = "MilestoneOverlay",
	})
	overlay.Visible = false
	overlay.ZIndex = 50

	broadcastBar = Theme.frame({
		parent = screen,
		size = UDim2.new(0, 560, 0, 34),
		position = UDim2.new(0.5, 0, 1, -18),
		anchor = Vector2.new(0.5, 1),
		colour = Theme.Colour.card,
		transparency = 0.1,
		radius = 10,
		name = "Broadcast",
	})
	Theme.stroke(broadcastBar, Theme.Colour.viral, 1, 0.4)
	broadcastBar.Visible = false

	broadcastLabel = Theme.label({
		parent = broadcastBar,
		text = "",
		font = Theme.Font.medium,
		textSize = 13,
		textColour = Theme.Colour.muted,
		align = Enum.TextXAlignment.Center,
	})
end

--- kind: "good" | "bad" | "info" | "money" | "sus"
function Toasts.notify(payload)
	if not stack then
		return
	end

	local accent = Theme.Kind[payload.kind] or Theme.Colour.followers

	-- Oldest toast falls off the bottom of the stack.
	local existing = {}
	for _, child in ipairs(stack:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(existing, child)
		end
	end
	if #existing >= MAX_TOASTS then
		existing[1]:Destroy()
	end

	local card = Theme.frame({
		parent = stack,
		size = UDim2.new(1, 0, 0, 0),
		colour = Theme.Colour.card,
		transparency = 0.06,
		radius = 12,
		name = "Toast",
		order = math.floor(os.clock() * 1000),
	})
	card.AutomaticSize = Enum.AutomaticSize.Y
	Theme.stroke(card, accent, 1, 0.35)
	Theme.padding(card, 12)
	Theme.list(card, 4)

	Theme.frame({
		parent = card,
		size = UDim2.new(0, 42, 0, 3),
		colour = accent,
		radius = 2,
		order = 1,
		name = "Accent",
	})

	Theme.label({
		parent = card,
		size = UDim2.new(1, 0, 0, 0),
		text = payload.title,
		font = Theme.Font.heavy,
		textSize = 15,
		textColour = accent,
		wrap = true,
		autoSize = Enum.AutomaticSize.Y,
		order = 2,
	})

	if payload.text and payload.text ~= "" then
		Theme.label({
			parent = card,
			size = UDim2.new(1, 0, 0, 0),
			text = payload.text,
			font = Theme.Font.book,
			textSize = 13,
			textColour = Theme.Colour.muted,
			wrap = true,
			autoSize = Enum.AutomaticSize.Y,
			order = 3,
		})
	end

	card.BackgroundTransparency = 1
	card.Position = UDim2.new(-0.15, 0, 0, 0)
	Theme.tween(card, 0.22, { BackgroundTransparency = 0.06, Position = UDim2.new(0, 0, 0, 0) })

	task.delay(payload.kind == "sus" and 8 or 6, function()
		if card.Parent then
			local fade = TweenService:Create(
				card,
				TweenInfo.new(0.3),
				{ BackgroundTransparency = 1, Position = UDim2.new(-0.2, 0, 0, 0) }
			)
			fade:Play()
			fade.Completed:Wait()
			card:Destroy()
		end
	end)
end

function Toasts.milestone(milestone)
	if not overlay then
		return
	end

	for _, child in ipairs(overlay:GetChildren()) do
		child:Destroy()
	end

	overlay.Visible = true
	overlay.BackgroundTransparency = 1
	Theme.tween(overlay, 0.25, { BackgroundTransparency = 0.35 })

	local card = Theme.frame({
		parent = overlay,
		size = UDim2.new(0, 560, 0, 190),
		position = UDim2.fromScale(0.5, 0.42),
		anchor = Vector2.new(0.5, 0.5),
		colour = Theme.Colour.panel,
		radius = 20,
		name = "MilestoneCard",
	})
	card.ZIndex = 51
	Theme.stroke(card, Theme.Colour.clout, 2)
	Theme.padding(card, 24)
	Theme.list(card, 10)

	Theme.label({
		parent = card,
		size = UDim2.new(1, 0, 0, 20),
		text = "FOLLOWER MILESTONE",
		font = Theme.Font.heavy,
		textSize = 13,
		textColour = Theme.Colour.dim,
		align = Enum.TextXAlignment.Center,
		order = 1,
	}).ZIndex = 52

	Theme.label({
		parent = card,
		size = UDim2.new(1, 0, 0, 54),
		text = milestone.title,
		font = Theme.Font.heavy,
		textSize = 46,
		textColour = Theme.Colour.clout,
		align = Enum.TextXAlignment.Center,
		order = 2,
	}).ZIndex = 52

	Theme.label({
		parent = card,
		size = UDim2.new(1, 0, 0, 0),
		text = milestone.text,
		font = Theme.Font.book,
		textSize = 16,
		textColour = Theme.Colour.text,
		align = Enum.TextXAlignment.Center,
		wrap = true,
		autoSize = Enum.AutomaticSize.Y,
		order = 3,
	}).ZIndex = 52

	card.Size = UDim2.new(0, 480, 0, 190)
	Theme.tween(card, 0.35, { Size = UDim2.new(0, 560, 0, 190) }, Enum.EasingStyle.Back)

	task.delay(3.4, function()
		if overlay.Visible then
			local fade = TweenService:Create(overlay, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			overlay.Visible = false
			for _, child in ipairs(overlay:GetChildren()) do
				child:Destroy()
			end
		end
	end)
end

function Toasts.broadcast(payload)
	if not broadcastBar then
		return
	end

	broadcastLabel.Text = payload.title .. " — " .. payload.text
	broadcastBar.Visible = true
	broadcastBar.BackgroundTransparency = 1
	Theme.tween(broadcastBar, 0.25, { BackgroundTransparency = 0.1 })

	task.delay(7, function()
		if broadcastBar.Visible then
			local fade = TweenService:Create(broadcastBar, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			broadcastBar.Visible = false
		end
	end)
end

return Toasts
