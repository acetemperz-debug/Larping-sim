--!strict
--[[
	Panels.lua

	Every modal in the game: shops, courses, podcasts, the downline, rebranding
	and travel. One container, one renderer per panel type.

	Cards register an `update` callback so affordability restyles live off the
	state stream without rebuilding the list and throwing away the scroll
	position.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Format = require(Shared.Format)

local Theme = require(script.Parent.Theme)
local Request = require(script.Parent.Request)

local Panels = {}

local root: Frame
local titleLabel: TextLabel
local blurbLabel: TextLabel
local body: ScrollingFrame
local questionModal: Frame

local current = { panel = nil :: string?, payload = nil :: string? }
local liveCards: { (any) -> () } = {}
local latestState: any = nil

-- Shared card furniture ----------------------------------------------------

local function clearBody()
	liveCards = {}
	for _, child in ipairs(body:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function emptyMessage(text: string)
	Theme.label({
		parent = body,
		size = UDim2.new(1, 0, 0, 60),
		text = text,
		font = Theme.Font.medium,
		textSize = 14,
		textColour = Theme.Colour.dim,
		align = Enum.TextXAlignment.Center,
		wrap = true,
	})
end

--- The standard row: title, description, meta line, action button.
local function card(props)
	local frame = Theme.frame({
		parent = body,
		size = UDim2.new(1, 0, 0, 0),
		colour = props.highlight and Theme.Colour.cardHover or Theme.Colour.card,
		radius = 12,
		order = props.order,
		name = "Card",
	})
	frame.AutomaticSize = Enum.AutomaticSize.Y
	Theme.stroke(frame, props.accent or Theme.Colour.line, props.highlight and 2 or 1, props.highlight and 0 or 0.4)
	Theme.padding(frame, 14)

	local textColumn = Theme.frame({
		parent = frame,
		size = UDim2.new(1, -140, 0, 0),
		transparency = 1,
		radius = 0,
		name = "Text",
	})
	textColumn.AutomaticSize = Enum.AutomaticSize.Y
	Theme.list(textColumn, 4)

	Theme.label({
		parent = textColumn,
		size = UDim2.new(1, 0, 0, 0),
		text = props.title,
		font = Theme.Font.heavy,
		textSize = 16,
		textColour = props.locked and Theme.Colour.dim or Theme.Colour.text,
		wrap = true,
		autoSize = Enum.AutomaticSize.Y,
		order = 1,
	})

	if props.desc then
		Theme.label({
			parent = textColumn,
			size = UDim2.new(1, 0, 0, 0),
			text = props.desc,
			font = Theme.Font.book,
			textSize = 13,
			textColour = Theme.Colour.muted,
			wrap = true,
			autoSize = Enum.AutomaticSize.Y,
			order = 2,
		})
	end

	if props.meta then
		Theme.label({
			parent = textColumn,
			size = UDim2.new(1, 0, 0, 0),
			text = props.meta,
			font = Theme.Font.medium,
			textSize = 12,
			textColour = props.metaColour or Theme.Colour.dim,
			wrap = true,
			rich = true,
			autoSize = Enum.AutomaticSize.Y,
			order = 3,
		})
	end

	local button = Theme.button({
		parent = frame,
		size = UDim2.new(0, 124, 0, 42),
		position = UDim2.new(1, 0, 0, 0),
		anchor = Vector2.new(1, 0),
		text = props.buttonText,
		textSize = 14,
		colour = props.buttonColour or Theme.Colour.cash,
		textColour = props.buttonTextColour or Color3.fromRGB(12, 16, 14),
		name = "Action",
	})

	if props.onClick then
		button.Activated:Connect(props.onClick)
	end

	return frame, button
end

local function disableButton(button: TextButton, text: string)
	button.Text = text
	button.BackgroundColor3 = Theme.Colour.locked
	button.TextColor3 = Theme.Colour.dim
	button.AutoButtonColor = false
	button.Active = false
end

local function enableButton(button: TextButton, text: string, colour: Color3, textColour: Color3?)
	button.Text = text
	button.BackgroundColor3 = colour
	button.TextColor3 = textColour or Color3.fromRGB(12, 16, 14)
	button.AutoButtonColor = true
	button.Active = true
end

-- Renderers ----------------------------------------------------------------

local function renderShop(result)
	local catalogue = result.catalogue
	titleLabel.Text = (catalogue.icon or "") .. "  " .. catalogue.name
	blurbLabel.Text = catalogue.blurb

	for index, entry in ipairs(catalogue.entries) do
		local meta = { "<font color='#F5C85C'>+" .. Format.short(entry.clout) .. " clout</font>" }

		if entry.rental then
			table.insert(meta, "⏱ expires after " .. Format.timer(entry.duration))
		elseif entry.consume then
			table.insert(meta, "one use")
		else
			table.insert(meta, "permanent")
		end

		if entry.mult then
			if entry.mult.followers then
				table.insert(meta, string.format("×%.2f followers", entry.mult.followers))
			end
			if entry.mult.cash then
				table.insert(meta, string.format("×%.2f revenue", entry.mult.cash))
			end
		end
		if entry.autoPost then
			table.insert(meta, "auto-posts every " .. entry.autoPost .. "s")
		end
		if entry.suspicion and entry.suspicion < 0 then
			table.insert(meta, "<font color='#60E09E'>" .. entry.suspicion .. " suspicion</font>")
		end
		if entry.sus and entry.sus > 0 then
			table.insert(meta, "<font color='#F0606E'>+" .. entry.sus .. " suspicion</font>")
		end
		if entry.rentalRemaining and entry.rentalRemaining > 0 then
			table.insert(meta, "<font color='#60E09E'>ACTIVE — " .. Format.timer(entry.rentalRemaining) .. " left</font>")
		end

		local accent = Theme.Colour.line
		if entry.owned or (entry.rentalRemaining and entry.rentalRemaining > 0) then
			accent = Theme.Colour.cash
		end

		local _, button = card({
			order = index,
			title = entry.name,
			desc = entry.desc,
			meta = table.concat(meta, "   ·   "),
			locked = entry.locked,
			accent = accent,
			buttonText = Format.money(entry.price),
			onClick = function()
				Request.spawn("buy", { itemId = entry.id }, function(response)
					if response.ok then
						Panels.refresh()
					elseif response.err then
						Panels.flash(response.err)
					end
				end)
			end,
		})

		-- Live affordability, driven by the state stream.
		local function update(state)
			if entry.locked then
				disableButton(button, entry.lockReason or "Locked")
			elseif entry.owned then
				disableButton(button, "OWNED")
			elseif state and state.cash < entry.price then
				disableButton(button, Format.money(entry.price))
			else
				local label = entry.rental and ("RENT " .. Format.money(entry.price))
					or ("BUY " .. Format.money(entry.price))
				enableButton(button, label, entry.rental and Theme.Colour.clout or Theme.Colour.cash)
			end
		end

		update(latestState)
		table.insert(liveCards, update)
	end
end

local function renderCourses(result)
	local catalogue = result.catalogue
	titleLabel.Text = "💼  COURSE DESK"
	blurbLabel.Text = "Your followers are the product. The course is the receipt."

	local launchFrame = Theme.frame({
		parent = body,
		size = UDim2.new(1, 0, 0, 62),
		colour = Theme.Colour.cash,
		radius = 12,
		order = 0,
		name = "Launch",
	})
	Theme.padding(launchFrame, 12)
	Theme.label({
		parent = launchFrame,
		size = UDim2.new(1, -140, 1, 0),
		text = "LAUNCH NOW\nCart open. Doors close in 4 hours (they never close).",
		font = Theme.Font.heavy,
		textSize = 14,
		textColour = Color3.fromRGB(10, 26, 18),
		wrap = true,
	})
	local launchButton = Theme.button({
		parent = launchFrame,
		size = UDim2.new(0, 124, 0, 38),
		position = UDim2.new(1, 0, 0.5, 0),
		anchor = Vector2.new(1, 0.5),
		text = "🚀 LAUNCH",
		colour = Color3.fromRGB(12, 30, 22),
		textColour = Theme.Colour.cash,
	})
	launchButton.Activated:Connect(function()
		Request.spawn("launch", nil, function(response)
			if not response.ok and response.err then
				Panels.flash(response.err)
			end
		end)
	end)

	if catalogue.mentorship then
		Theme.label({
			parent = body,
			size = UDim2.new(1, 0, 0, 28),
			text = "Mentorship running passively: "
				.. catalogue.mentorship.name
				.. " · "
				.. Format.money(catalogue.mentorshipPerTick)
				.. " per tick",
			font = Theme.Font.medium,
			textSize = 12,
			textColour = Theme.Colour.viral,
			order = 1,
		})
	end

	for index, entry in ipairs(catalogue.entries) do
		local meta
		if entry.unlocked then
			meta = string.format(
				"<font color='#60E09E'>%s / %ss</font>   ·   %s per sale",
				Format.money(entry.revenuePerTick),
				tostring(catalogue.tickInterval),
				Format.money(entry.price)
			)
		else
			meta = string.format(
				"Needs %s followers and %s clout",
				Format.short(entry.reqFollowers),
				Format.short(entry.reqClout)
			)
		end

		local lessons = table.concat(entry.lessons, "  ·  ")

		local _, button = card({
			order = index + 1,
			title = entry.name .. "  —  " .. Format.money(entry.price),
			desc = entry.pitch,
			meta = meta .. "\n<font color='#6A6A74'>" .. lessons .. "</font>",
			locked = not entry.unlocked,
			highlight = entry.active,
			accent = entry.active and Theme.Colour.cash or Theme.Colour.line,
			buttonText = "SELL THIS",
			onClick = function()
				Request.spawn("setCourse", { courseId = entry.id }, function(response)
					if response.ok then
						Panels.refresh()
					elseif response.err then
						Panels.flash(response.err)
					end
				end)
			end,
		})

		if entry.active then
			disableButton(button, "SELLING")
			button.BackgroundColor3 = Theme.Colour.cash
			button.TextColor3 = Color3.fromRGB(12, 26, 18)
		elseif not entry.unlocked then
			disableButton(button, "LOCKED")
		end
	end
end

local function renderPodcast(result)
	local catalogue = result.catalogue
	titleLabel.Text = "🎙  PODCAST BOOTH"
	blurbLabel.Text = "You pay them. That is genuinely how this works."

	if catalogue.cooldownRemaining > 1 then
		Theme.label({
			parent = body,
			size = UDim2.new(1, 0, 0, 26),
			text = "Next booking available in " .. Format.timer(catalogue.cooldownRemaining),
			font = Theme.Font.medium,
			textSize = 13,
			textColour = Theme.Colour.suspicion,
			order = 0,
		})
	end

	for index, entry in ipairs(catalogue.entries) do
		local meta = entry.unlocked
				and ("est. +" .. Format.short(entry.estimate) .. " followers")
			or ("Needs " .. Format.short(entry.req) .. " followers")

		local _, button = card({
			order = index,
			title = entry.name,
			desc = entry.desc,
			meta = meta,
			locked = not entry.unlocked,
			accent = Theme.Colour.viral,
			buttonText = Format.money(entry.cost),
			buttonColour = Theme.Colour.viral,
			buttonTextColour = Color3.fromRGB(16, 10, 26),
			onClick = function()
				Request.spawn("appear", { tierId = entry.id }, function(response)
					if response.ok then
						Panels.close()
					elseif response.err then
						Panels.flash(response.err)
					end
				end)
			end,
		})

		if not entry.unlocked then
			disableButton(button, "LOCKED")
		elseif not entry.affordable then
			disableButton(button, Format.money(entry.cost))
		end
	end
end

local function renderPyramid(result)
	local info = result.info
	titleLabel.Text = "🔺  MENTORSHIP OFFICE"
	blurbLabel.Text = "Teach them everything you know. They will do the same to someone else."

	local summary = Theme.frame({
		parent = body,
		size = UDim2.new(1, 0, 0, 92),
		colour = Theme.Colour.card,
		radius = 12,
		order = 0,
		name = "Summary",
	})
	Theme.stroke(summary, Theme.Colour.clout, 1, 0.4)
	Theme.padding(summary, 14)
	Theme.label({
		parent = summary,
		size = UDim2.new(1, 0, 0, 30),
		text = info.downline .. " / " .. info.max .. " GURUS BENEATH YOU",
		font = Theme.Font.heavy,
		textSize = 22,
		textColour = Theme.Colour.clout,
	})
	Theme.label({
		parent = summary,
		size = UDim2.new(1, 0, 0, 36),
		position = UDim2.new(0, 0, 0, 30),
		text = string.format(
			"Each graduate sends %.0f%% of their course revenue upward, forever. You currently take +%.0f%%.\nThey also generate suspicion, because they are all using your slides.",
			info.perStudentPercent,
			info.cutPercent
		),
		font = Theme.Font.book,
		textSize = 12,
		textColour = Theme.Colour.muted,
		wrap = true,
	})

	if not info.unlocked then
		emptyMessage(
			"Nobody copies a nobody.\nReach "
				.. Format.short(info.unlockFollowers)
				.. " followers and they will start reaching out to you."
		)
		return
	end

	local _, button = card({
		order = 1,
		title = "Onboard Your Next Guru",
		desc = "They buy the mentorship, rebrand themselves, and start selling a slightly more expensive version of your course.",
		meta = string.format("Cost rises %.0f%% with every graduate.", info.growthPercent),
		accent = Theme.Colour.clout,
		buttonText = Format.money(info.cost),
		buttonColour = Theme.Colour.clout,
		onClick = function()
			Request.spawn("recruit", nil, function(response)
				if response.ok then
					Panels.refresh()
				elseif response.err then
					Panels.flash(response.err)
				end
			end)
		end,
	})

	if info.downline >= info.max then
		disableButton(button, "SATURATED")
	else
		local function update(state)
			if state and state.cash < info.cost then
				disableButton(button, Format.money(info.cost))
			else
				enableButton(button, "RECRUIT " .. Format.money(info.cost), Theme.Colour.clout)
			end
		end
		update(latestState)
		table.insert(liveCards, update)
	end
end

local function renderRebrand(result)
	local info = result.info
	titleLabel.Text = "🪞  THE MIRROR"
	blurbLabel.Text = "Delete every video. Move country. Come back with a new accent."

	local summary = Theme.frame({
		parent = body,
		size = UDim2.new(1, 0, 0, 0),
		colour = Theme.Colour.card,
		radius = 12,
		order = 0,
		name = "Current",
	})
	summary.AutomaticSize = Enum.AutomaticSize.Y
	Theme.stroke(summary, Theme.Colour.suspicion, 1, 0.4)
	Theme.padding(summary, 14)
	Theme.list(summary, 6)

	Theme.label({
		parent = summary,
		size = UDim2.new(1, 0, 0, 24),
		text = "CURRENTLY: " .. info.title:upper(),
		font = Theme.Font.heavy,
		textSize = 19,
		textColour = Theme.Colour.suspicion,
		order = 1,
	})
	Theme.label({
		parent = summary,
		size = UDim2.new(1, 0, 0, 0),
		text = info.blurb,
		font = Theme.Font.book,
		textSize = 13,
		textColour = Theme.Colour.muted,
		wrap = true,
		autoSize = Enum.AutomaticSize.Y,
		order = 2,
	})
	Theme.label({
		parent = summary,
		size = UDim2.new(1, 0, 0, 18),
		text = string.format(
			"×%.2f followers   ·   ×%.2f revenue   ·   ×%.2f clout   ·   %d rebrands",
			info.followerMult,
			info.cashMult,
			info.cloutMult,
			info.rebrands
		),
		font = Theme.Font.medium,
		textSize = 12,
		textColour = Theme.Colour.clout,
		order = 3,
	})

	if info.maxed then
		emptyMessage("You have become everything there is to become.\nThere is no higher noun.")
		return
	end

	local progress = math.clamp((latestState and latestState.followers or 0) / info.nextRequirement, 0, 1)

	local _, button = card({
		order = 1,
		title = "Become: " .. info.nextTitle,
		desc = info.nextBlurb,
		meta = string.format(
			"Resets cash, followers, clout and every item you own.\nKeeps your downline.\nGrants ×%.2f followers · ×%.2f revenue · ×%.2f clout, permanently.\nProgress: %s / %s (%s)",
			info.nextFollowerMult,
			info.nextCashMult,
			info.nextCloutMult,
			Format.short(latestState and latestState.followers or 0),
			Format.short(info.nextRequirement),
			Format.percent(progress * 100)
		),
		accent = Theme.Colour.suspicion,
		buttonText = "REBRAND",
		buttonColour = Theme.Colour.suspicion,
		buttonTextColour = Color3.fromRGB(26, 10, 14),
		onClick = function()
			Request.spawn("doRebrand", nil, function(response)
				if response.ok then
					Panels.close()
				elseif response.err then
					Panels.flash(response.err)
				end
			end)
		end,
	})

	if not info.ready then
		disableButton(button, Format.percent(progress * 100))
	end
end

local function renderTravel(result)
	titleLabel.Text = "✈  TRAVEL"
	blurbLabel.Text = "Every destination is more expensive and less real than the last."

	for index, area in ipairs(result.areas) do
		local _, button = card({
			order = index,
			title = area.index .. ". " .. area.name,
			desc = area.subtitle,
			meta = area.unlocked and "Open" or ("Opens at " .. Format.short(area.unlockFollowers) .. " followers"),
			locked = not area.unlocked,
			accent = area.unlocked and Theme.Colour.followers or Theme.Colour.line,
			buttonText = "GO",
			buttonColour = Theme.Colour.followers,
			buttonTextColour = Color3.fromRGB(8, 14, 26),
			onClick = function()
				Request.spawn("travel", { areaId = area.id }, function(response)
					if response.ok then
						Panels.close()
					elseif response.err then
						Panels.flash(response.err)
					end
				end)
			end,
		})

		if not area.unlocked then
			disableButton(button, "LOCKED")
		end
	end
end

local RENDERERS = {
	shop = renderShop,
	courses = renderCourses,
	podcast = renderPodcast,
	pyramid = renderPyramid,
	rebrand = renderRebrand,
	travel = renderTravel,
}

-- Public surface -----------------------------------------------------------

function Panels.build(screen: ScreenGui)
	root = Theme.frame({
		parent = screen,
		size = UDim2.new(0, 640, 0, 560),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		colour = Theme.Colour.panel,
		radius = 18,
		name = "Panel",
	})
	root.Visible = false
	root.ZIndex = 20
	Theme.stroke(root, Theme.Colour.line, 1)

	local header = Theme.frame({
		parent = root,
		size = UDim2.new(1, 0, 0, 78),
		colour = Theme.Colour.bg,
		radius = 18,
		name = "Header",
	})
	Theme.padding(header, 18, { bottom = 12 })

	titleLabel = Theme.label({
		parent = header,
		size = UDim2.new(1, -60, 0, 26),
		text = "",
		font = Theme.Font.heavy,
		textSize = 22,
	})
	blurbLabel = Theme.label({
		parent = header,
		size = UDim2.new(1, -60, 0, 20),
		position = UDim2.new(0, 0, 0, 28),
		text = "",
		font = Theme.Font.book,
		textSize = 13,
		textColour = Theme.Colour.muted,
		wrap = true,
	})

	local close = Theme.button({
		parent = header,
		size = UDim2.new(0, 34, 0, 34),
		position = UDim2.new(1, 0, 0, 0),
		anchor = Vector2.new(1, 0),
		text = "✕",
		textSize = 18,
		colour = Theme.Colour.card,
		textColour = Theme.Colour.muted,
		radius = 10,
	})
	close.Activated:Connect(function()
		Panels.close()
	end)

	body = Instance.new("ScrollingFrame")
	body.Size = UDim2.new(1, -24, 1, -92)
	body.Position = UDim2.new(0, 12, 0, 84)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ScrollBarThickness = 4
	body.ScrollBarImageColor3 = Theme.Colour.line
	body.CanvasSize = UDim2.new()
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.Name = "Body"
	body.Parent = root
	Theme.list(body, 10)
	Theme.padding(body, 4, { right = 10 })

	-- Podcast question modal, deliberately un-closeable.
	questionModal = Theme.frame({
		parent = screen,
		size = UDim2.new(0, 560, 0, 0),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		colour = Theme.Colour.panel,
		radius = 18,
		name = "Question",
	})
	questionModal.AutomaticSize = Enum.AutomaticSize.Y
	questionModal.Visible = false
	questionModal.ZIndex = 40
	Theme.stroke(questionModal, Theme.Colour.viral, 2)
	Theme.padding(questionModal, 22)
	Theme.list(questionModal, 10)
end

function Panels.open(panel: string, payload: string?)
	local renderer = RENDERERS[panel]
	if not renderer then
		return
	end

	current.panel = panel
	current.payload = payload

	local action = panel
	local requestPayload = nil
	if panel == "shop" then
		requestPayload = { category = payload }
	end

	Request.spawn(action, requestPayload, function(result)
		if not result.ok then
			Panels.flash(result.err or "That's closed.")
			return
		end

		clearBody()
		renderer(result)

		root.Visible = true
		root.Size = UDim2.new(0, 600, 0, 560)
		Theme.tween(root, 0.18, { Size = UDim2.new(0, 640, 0, 560) }, Enum.EasingStyle.Back)
	end)
end

function Panels.refresh()
	if current.panel then
		Panels.open(current.panel, current.payload)
	end
end

function Panels.close()
	if root then
		root.Visible = false
	end
	current.panel = nil
	current.payload = nil
	liveCards = {}
end

function Panels.isOpen(): boolean
	return root ~= nil and root.Visible
end

--- Error text, shown on the panel header so it can't be missed.
function Panels.flash(message: string)
	if not blurbLabel then
		return
	end
	local previous = blurbLabel.Text
	blurbLabel.Text = "⚠ " .. message
	blurbLabel.TextColor3 = Theme.Colour.suspicion
	task.delay(2.5, function()
		if blurbLabel.Text == "⚠ " .. message then
			blurbLabel.Text = previous
			blurbLabel.TextColor3 = Theme.Colour.muted
		end
	end)
end

function Panels.onState(state)
	latestState = state
	for _, update in ipairs(liveCards) do
		update(state)
	end
end

--- The podcast question. No close button: you agreed to be here.
function Panels.question(payload)
	for _, child in ipairs(questionModal:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end

	Theme.label({
		parent = questionModal,
		size = UDim2.new(1, 0, 0, 18),
		text = "LIVE ON: " .. payload.show:upper(),
		font = Theme.Font.heavy,
		textSize = 12,
		textColour = Theme.Colour.viral,
		order = 1,
	}).ZIndex = 41

	Theme.label({
		parent = questionModal,
		size = UDim2.new(1, 0, 0, 0),
		text = '"' .. payload.prompt .. '"',
		font = Theme.Font.heavy,
		textSize = 24,
		textColour = Theme.Colour.text,
		wrap = true,
		autoSize = Enum.AutomaticSize.Y,
		order = 2,
	}).ZIndex = 41

	for _, answer in ipairs(payload.answers) do
		local button = Theme.button({
			parent = questionModal,
			size = UDim2.new(1, 0, 0, 44),
			text = answer.text,
			textSize = 16,
			colour = Theme.Colour.card,
			textColour = Theme.Colour.text,
			order = 2 + answer.index,
			name = "Answer" .. answer.index,
		})
		button.ZIndex = 41
		Theme.stroke(button, Theme.Colour.viral, 1, 0.6)

		button.Activated:Connect(function()
			questionModal.Visible = false
			Request.spawn("answer", { index = answer.index })
		end)
	end

	questionModal.Visible = true
end

return Panels
