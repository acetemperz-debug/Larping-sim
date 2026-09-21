--!strict
--[[
	Feed.lua

	The social feed. Every post you make appears here as a fake social card:
	caption, location, follower gain, and the occasional viral banner.

	Posts made by a hired social media manager are marked, because at some
	point in this game you stop being the person making the content.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Theme)

local Feed = {}

local container: Frame
local MAX_POSTS = 4

function Feed.build(screen: ScreenGui)
	container = Theme.frame({
		parent = screen,
		size = UDim2.new(0, 330, 0, 420),
		position = UDim2.new(0, 16, 1, -60),
		anchor = Vector2.new(0, 1),
		transparency = 1,
		radius = 0,
		name = "Feed",
	})
	local layout = Theme.list(container, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
end

function Feed.post(post)
	if not container then
		return
	end

	local cards = {}
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(cards, child)
		end
	end
	if #cards >= MAX_POSTS then
		cards[1]:Destroy()
	end

	local accent = post.viral and Theme.Colour.viral or Theme.Colour.followers

	local card = Theme.frame({
		parent = container,
		size = UDim2.new(1, 0, 0, 0),
		colour = Theme.Colour.card,
		transparency = 0.05,
		radius = 12,
		name = "Post",
		order = math.floor(os.clock() * 1000),
	})
	card.AutomaticSize = Enum.AutomaticSize.Y
	Theme.stroke(card, accent, post.viral and 2 or 1, post.viral and 0 or 0.5)
	Theme.padding(card, 12)
	Theme.list(card, 6)

	if post.viral and post.banner then
		local banner = Theme.frame({
			parent = card,
			size = UDim2.new(1, 0, 0, 24),
			colour = Theme.Colour.viral,
			radius = 6,
			order = 1,
			name = "Banner",
		})
		Theme.label({
			parent = banner,
			text = "🔥 " .. post.banner,
			font = Theme.Font.heavy,
			textSize = 13,
			textColour = Color3.fromRGB(20, 12, 30),
			align = Enum.TextXAlignment.Center,
		})
	end

	-- Header: fake handle row.
	local header = Theme.frame({
		parent = card,
		size = UDim2.new(1, 0, 0, 18),
		transparency = 1,
		radius = 0,
		order = 2,
		name = "Header",
	})
	Theme.label({
		parent = header,
		size = UDim2.new(0.6, 0, 1, 0),
		text = post.auto and "@you (posted by your SMM)" or "@you",
		font = Theme.Font.heavy,
		textSize = 12,
		textColour = Theme.Colour.dim,
	})
	Theme.label({
		parent = header,
		size = UDim2.new(0.4, 0, 1, 0),
		position = UDim2.new(0.6, 0, 0, 0),
		text = "📍 " .. post.location,
		font = Theme.Font.medium,
		textSize = 11,
		textColour = Theme.Colour.dim,
		align = Enum.TextXAlignment.Right,
		truncate = Enum.TextTruncate.AtEnd,
	})

	Theme.label({
		parent = card,
		size = UDim2.new(1, 0, 0, 0),
		text = post.caption,
		font = Theme.Font.medium,
		textSize = 15,
		textColour = Theme.Colour.text,
		wrap = true,
		autoSize = Enum.AutomaticSize.Y,
		order = 3,
	})

	if post.propName then
		Theme.label({
			parent = card,
			size = UDim2.new(1, 0, 0, 14),
			text = "featuring: " .. post.propName,
			font = Theme.Font.book,
			textSize = 11,
			textColour = Theme.Colour.dim,
			order = 4,
		})
	end

	local footer = Theme.frame({
		parent = card,
		size = UDim2.new(1, 0, 0, 20),
		transparency = 1,
		radius = 0,
		order = 5,
		name = "Footer",
	})
	Theme.label({
		parent = footer,
		size = UDim2.new(0.6, 0, 1, 0),
		text = "+" .. Format.short(post.followers) .. " followers",
		font = Theme.Font.heavy,
		textSize = 15,
		textColour = accent,
	})
	if post.stale then
		Theme.label({
			parent = footer,
			size = UDim2.new(0.4, 0, 1, 0),
			position = UDim2.new(0.6, 0, 0, 0),
			text = "seen this already",
			font = Theme.Font.book,
			textSize = 11,
			textColour = Theme.Colour.suspicion,
			align = Enum.TextXAlignment.Right,
		})
	end

	card.BackgroundTransparency = 1
	card.Position = UDim2.new(-0.1, 0, 0, 0)
	Theme.tween(card, 0.2, { BackgroundTransparency = 0.05, Position = UDim2.new(0, 0, 0, 0) })

	task.delay(14, function()
		if card.Parent then
			local fade = TweenService:Create(card, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			card:Destroy()
		end
	end)
end

return Feed
