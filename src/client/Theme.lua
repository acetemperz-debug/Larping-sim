--!strict
--[[
	Theme.lua

	One design system for the whole HUD: a parody of every modern
	creator-economy dashboard. Dark panels, tight radii, one accent colour per
	meaning, and numbers that are always slightly too large.
]]

local TweenService = game:GetService("TweenService")

local Theme = {}

Theme.Colour = {
	bg = Color3.fromRGB(16, 16, 22),
	panel = Color3.fromRGB(24, 24, 32),
	card = Color3.fromRGB(33, 33, 43),
	cardHover = Color3.fromRGB(42, 42, 55),
	line = Color3.fromRGB(52, 52, 66),

	text = Color3.fromRGB(240, 240, 248),
	muted = Color3.fromRGB(148, 148, 166),
	dim = Color3.fromRGB(98, 98, 116),

	cash = Color3.fromRGB(96, 224, 158),
	followers = Color3.fromRGB(110, 170, 255),
	clout = Color3.fromRGB(245, 200, 92),
	suspicion = Color3.fromRGB(240, 96, 110),
	viral = Color3.fromRGB(190, 130, 255),
	locked = Color3.fromRGB(70, 70, 86),
}

Theme.Kind = {
	good = Theme.Colour.cash,
	bad = Theme.Colour.suspicion,
	money = Theme.Colour.clout,
	info = Theme.Colour.followers,
	sus = Theme.Colour.suspicion,
}

Theme.Font = {
	heavy = Enum.Font.GothamBold,
	medium = Enum.Font.GothamMedium,
	book = Enum.Font.Gotham,
}

-- Element helpers ----------------------------------------------------------

function Theme.corner(parent: Instance, radius: number?): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

function Theme.stroke(parent: Instance, colour: Color3?, thickness: number?, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = colour or Theme.Colour.line
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function Theme.padding(parent: Instance, all: number?, extra: any?): UIPadding
	local padding = Instance.new("UIPadding")
	local value = UDim.new(0, all or 10)
	padding.PaddingTop = (extra and extra.top) and UDim.new(0, extra.top) or value
	padding.PaddingBottom = (extra and extra.bottom) and UDim.new(0, extra.bottom) or value
	padding.PaddingLeft = (extra and extra.left) and UDim.new(0, extra.left) or value
	padding.PaddingRight = (extra and extra.right) and UDim.new(0, extra.right) or value
	padding.Parent = parent
	return padding
end

function Theme.list(parent: Instance, spacing: number?, direction: Enum.FillDirection?): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, spacing or 8)
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

function Theme.frame(props): Frame
	local frame = Instance.new("Frame")
	frame.Size = props.size or UDim2.fromScale(1, 1)
	frame.Position = props.position or UDim2.fromScale(0, 0)
	frame.AnchorPoint = props.anchor or Vector2.zero
	frame.BackgroundColor3 = props.colour or Theme.Colour.panel
	frame.BackgroundTransparency = props.transparency or 0
	frame.BorderSizePixel = 0
	frame.Name = props.name or "Frame"
	frame.LayoutOrder = props.order or 0
	frame.Visible = props.visible ~= false
	frame.ClipsDescendants = props.clip or false
	frame.Parent = props.parent
	if props.radius ~= 0 then
		Theme.corner(frame, props.radius)
	end
	return frame
end

function Theme.label(props): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = props.size or UDim2.fromScale(1, 1)
	label.Position = props.position or UDim2.fromScale(0, 0)
	label.AnchorPoint = props.anchor or Vector2.zero
	label.BackgroundTransparency = props.bgTransparency or 1
	label.BackgroundColor3 = props.colour or Theme.Colour.card
	label.BorderSizePixel = 0
	label.Font = props.font or Theme.Font.medium
	label.TextColor3 = props.textColour or Theme.Colour.text
	label.TextSize = props.textSize or 16
	label.Text = props.text or ""
	label.TextXAlignment = props.align or Enum.TextXAlignment.Left
	label.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
	label.TextWrapped = props.wrap or false
	label.TextTruncate = props.truncate or Enum.TextTruncate.None
	label.RichText = props.rich or false
	label.LayoutOrder = props.order or 0
	label.Name = props.name or "Label"
	label.AutomaticSize = props.autoSize or Enum.AutomaticSize.None
	label.Parent = props.parent
	return label
end

function Theme.button(props): TextButton
	local button = Instance.new("TextButton")
	button.Size = props.size or UDim2.new(1, 0, 0, 36)
	button.Position = props.position or UDim2.fromScale(0, 0)
	button.AnchorPoint = props.anchor or Vector2.zero
	button.BackgroundColor3 = props.colour or Theme.Colour.card
	button.BackgroundTransparency = props.transparency or 0
	button.BorderSizePixel = 0
	button.AutoButtonColor = props.autoColour ~= false
	button.Font = props.font or Theme.Font.heavy
	button.TextColor3 = props.textColour or Theme.Colour.text
	button.TextSize = props.textSize or 15
	button.Text = props.text or ""
	button.LayoutOrder = props.order or 0
	button.Name = props.name or "Button"
	button.Parent = props.parent
	Theme.corner(button, props.radius or 8)
	return button
end

function Theme.tween(instance: Instance, duration: number, goal, style: Enum.EasingStyle?)
	local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(instance, info, goal)
	tween:Play()
	return tween
end

--- A thin progress bar, used for suspicion and unlock progress.
function Theme.meter(parent: Instance, colour: Color3): (Frame, Frame)
	local track = Theme.frame({
		parent = parent,
		size = UDim2.new(1, 0, 0, 6),
		colour = Theme.Colour.line,
		radius = 3,
		name = "MeterTrack",
	})
	local fill = Theme.frame({
		parent = track,
		size = UDim2.fromScale(0, 1),
		colour = colour,
		radius = 3,
		name = "MeterFill",
	})
	return track, fill
end

return Theme
