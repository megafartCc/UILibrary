local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local Parts = {}

local marquees = setmetatable({}, { __mode = "k" })

local function wrap(label)
	local clip = Create.new("Frame", {
		Name = label.Name .. "Clip",
		AnchorPoint = label.AnchorPoint,
		Position = label.Position,
		Size = label.Size,
		LayoutOrder = label.LayoutOrder,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = label.Parent,
	})
	label.AnchorPoint = Vector2.zero
	label.Position = UDim2.fromScale(0, 0)
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = clip
	return clip
end

local function reset(label)
	label.AutomaticSize = Enum.AutomaticSize.None
	label.AnchorPoint = Vector2.zero
	label.Position = UDim2.fromScale(0, 0)
	label.Size = UDim2.fromScale(1, 1)
	label.TextTruncate = Enum.TextTruncate.AtEnd
end

local function slide(label, toEnd, duration)
	local t = if toEnd then 1 else 0
	Motion.Apply(label, {
		AnchorPoint = Vector2.new(t, 0),
		Position = UDim2.fromScale(t, 0),
	}, true, duration, Enum.EasingStyle.Sine)
end

function Parts.Marquee(label, active)
	local state = marquees[label]
	if not active then
		if state then
			state.Token += 1
			Motion.Apply(label, { AnchorPoint = Vector2.zero, Position = UDim2.fromScale(0, 0) }, false)
			reset(label)
		end
		return
	end

	if not state then
		state = { Clip = wrap(label), Token = 0 }
		marquees[label] = state
	end
	state.Token += 1
	local token = state.Token
	local clip = state.Clip
	local motion = Theme.Motion

	task.spawn(function()
		task.wait(motion.MarqueeDelay)
		if state.Token ~= token then
			return
		end

		local before = label.AbsoluteSize.X
		label.TextTruncate = Enum.TextTruncate.None
		label.Size = UDim2.fromScale(0, 1)
		label.AutomaticSize = Enum.AutomaticSize.X

		local width = clip.AbsoluteSize.X
		for _ = 1, 30 do
			task.wait()
			if state.Token ~= token then
				return
			end
			if label.AbsoluteSize.X ~= before and label.AbsoluteSize.X > 0 then
				break
			end
		end

		local overflow = label.AbsoluteSize.X - width
		if overflow <= 1 or width <= 0 then
			reset(label)
			return
		end

		local duration = math.max(overflow / motion.MarqueeSpeed, 0.4)
		while state.Token == token do
			slide(label, true, duration)
			task.wait(duration + motion.MarqueePause)
			if state.Token ~= token then
				return
			end
			slide(label, false, duration)
			task.wait(duration + motion.MarqueePause)
		end
	end)
end

function Parts.Switch(parent)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local inset = sizes.KnobInset
	local knobSize = sizes.SwitchHeight - 2 * inset

	local frame = Create.new("Frame", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(sizes.SwitchWidth, sizes.SwitchHeight),
		BackgroundColor3 = colors.SwitchOff,
		BorderSizePixel = 0,
		Parent = parent,
		Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local knob = Create.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, inset, 0.5, 0),
		Size = UDim2.fromOffset(knobSize, knobSize),
		BackgroundColor3 = colors.Knob,
		BorderSizePixel = 0,
		Parent = frame,
		Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local switch = { Frame = frame, Knob = knob, On = false, Hovered = false }

	local function paint(animate)
		local off = if switch.Hovered then colors.SwitchOffHover else colors.SwitchOff
		Motion.Apply(frame, { BackgroundColor3 = if switch.On then colors.Accent else off }, animate)
	end

	function switch.Set(on, animate)
		switch.On = on
		local x = if on then sizes.SwitchWidth - sizes.SwitchHeight + inset else inset
		paint(animate)
		Motion.Apply(knob, { Position = UDim2.new(0, x, 0.5, 0) }, animate)
	end

	function switch.SetHover(hovered)
		switch.Hovered = hovered
		paint(true)
	end

	return switch
end

function Parts.Square(parent, icon)
	local sizes, colors = Theme.Sizes, Theme.Colors

	local frame = Create.new("Frame", {
		Name = "Square",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(sizes.SwitchWidth - sizes.ButtonSize) / 2, 0.5, 0),
		Size = UDim2.fromOffset(sizes.ButtonSize, sizes.ButtonSize),
		BackgroundColor3 = colors.Track,
		BorderSizePixel = 0,
		Parent = parent,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.ButtonRadius) }),
	})
	local scale = Create.new("UIScale", { Parent = frame })

	local image = Create.new("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(sizes.ButtonIconSize, sizes.ButtonIconSize),
		ImageColor3 = colors.Muted,
		Parent = frame,
	})
	Icons.Apply(image, icon or "pointer")

	local square = { Frame = frame, Icon = image, Scale = scale, Hovered = false }

	local function rest()
		return if square.Hovered then colors.TrackHover else colors.Track, if square.Hovered then colors.Text else colors.Muted
	end

	function square.Press()
		local motion = Theme.Motion
		local background, iconColor = rest()
		scale.Scale = motion.PressScale
		frame.BackgroundColor3 = colors.Accent
		image.ImageColor3 = colors.Text
		Motion.Apply(scale, { Scale = 1 }, true, motion.PressDuration, Enum.EasingStyle.Back)
		Motion.Apply(frame, { BackgroundColor3 = background }, true, motion.PressDuration, Enum.EasingStyle.Quad)
		Motion.Apply(image, { ImageColor3 = iconColor }, true, motion.PressDuration, Enum.EasingStyle.Quad)
	end

	function square.SetHover(hovered)
		square.Hovered = hovered
		local background, iconColor = rest()
		Motion.Apply(frame, { BackgroundColor3 = background }, true)
		Motion.Apply(image, { ImageColor3 = iconColor }, true)
	end

	return square
end

function Parts.Hover(element, row, extra)
	local colors = Theme.Colors
	local function set(hovered)
		element.Hovered = hovered
		if element.Label then
			Motion.Apply(element.Label, { TextColor3 = if hovered then colors.ElementTextHover else colors.ElementText }, true)
			Parts.Marquee(element.Label, hovered)
		end
		if type(element.Switch) == "table" then
			element.Switch.SetHover(hovered)
		end
		if type(element.Square) == "table" then
			element.Square.SetHover(hovered)
		end
		if extra then
			extra(hovered)
		end
	end
	row.MouseEnter:Connect(function()
		set(true)
	end)
	row.MouseLeave:Connect(function()
		set(false)
	end)
end

function Parts.Trailing(kind)
	local sizes = Theme.Sizes
	if kind == "Button" then
		return (sizes.SwitchWidth + sizes.ButtonSize) / 2 + sizes.AccessoryGap
	elseif kind then
		return sizes.SwitchWidth + sizes.AccessoryGap
	end
	return 0
end

function Parts.Attach(element, row, options)
	local kind = options.Accessory
	if not kind then
		return
	end
	element.Accessory = kind

	local hit = Create.new("TextButton", {
		Name = "Hit",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(0, Theme.Sizes.SwitchWidth + 4, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = row,
	})

	if kind == "Toggle" then
		element.Switch = Parts.Switch(row)
		element.Enabled = options.Enabled == true
		element.Switch.Set(element.Enabled, false)
		hit.Activated:Connect(function()
			element:SetEnabled(not element.Enabled)
		end)
	elseif kind == "Button" then
		element.Square = Parts.Square(row, options.Icon)
		hit.Activated:Connect(function()
			element.Square.Press()
			if element.Callback then
				task.spawn(element.Callback, element:Get())
			end
		end)
	end
end

function Parts.SetEnabled(element, on)
	element.Enabled = on == true
	element.Switch.Set(element.Enabled, true)
	element:_fire()
end

function Parts.Fire(element, value)
	if not element.Callback or element.Accessory == "Button" then
		return
	end
	if element.Accessory == "Toggle" then
		task.spawn(element.Callback, value, element.Enabled)
	else
		task.spawn(element.Callback, value)
	end
end

return Parts
