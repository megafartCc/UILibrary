local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local Parts = {}

local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

Parts.Touch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local marquees = setmetatable({}, { __mode = "k" })

function Parts.ClipLabel(label)
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
	marquees[label] = { Clip = clip, Token = 0 }
	return clip
end

local function textWidth(label)
	local ok, bounds = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = label.Text
		params.Font = label.FontFace
		params.Size = label.TextSize
		params.Width = 100000
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and bounds then
		return bounds.X
	end
	ok, bounds = pcall(function()
		return TextService:GetTextSize(label.Text, label.TextSize, Enum.Font.GothamMedium, Vector2.new(100000, 100000))
	end)
	return if ok and bounds then bounds.X else 0
end

local function rest(state, label)
	if state.Ghost then
		state.GhostSync:Disconnect()
		state.Ghost:Destroy()
		state.Ghost = nil
	end
	Motion.Apply(label, { Position = UDim2.fromScale(0, 0) }, false)
	label.Size = UDim2.fromScale(1, 1)
	label.TextTruncate = Enum.TextTruncate.AtEnd
end

local function overflowOf(state, label)
	local clip = state.Clip
	if clip.AbsoluteSize.X <= 0 or clip.AbsoluteSize.Y <= 0 then
		return 0, 0
	end
	local scale = clip.AbsoluteSize.Y / Theme.Sizes.ElementHeight
	local full = textWidth(label)
	return full - clip.AbsoluteSize.X / scale, full
end

local function ghostOf(state, label, offset)
	local ghost = state.Ghost
	if not ghost then
		ghost = label:Clone()
		for _, child in ghost:GetChildren() do
			child:Destroy()
		end
		ghost.Name = "Ghost"
		ghost.Parent = label
		state.Ghost = ghost
		state.GhostSync = label:GetPropertyChangedSignal("TextColor3"):Connect(function()
			ghost.TextColor3 = label.TextColor3
		end)
	end
	ghost.Text = label.Text
	ghost.TextColor3 = label.TextColor3
	ghost.TextTruncate = Enum.TextTruncate.None
	ghost.AnchorPoint = Vector2.zero
	ghost.Position = UDim2.fromOffset(offset, 0)
	ghost.Size = UDim2.fromScale(1, 1)
	return ghost
end

function Parts.Marquee(label, active, persistent)
	local state = marquees[label]
	if not state then
		return
	end
	state.Token += 1
	local token = state.Token
	if not active then
		rest(state, label)
		return
	end

	local motion = Theme.Motion
	local function alive()
		return state.Token == token and label.Parent ~= nil
	end

	task.spawn(function()
		task.wait(motion.MarqueeDelay)
		local lapped = false
		while alive() do
			local overflow, full = overflowOf(state, label)
			if overflow <= 1 then
				rest(state, label)
				if not persistent then
					return
				end
				local key = tostring(state.Clip.AbsoluteSize) .. label.Text
				repeat
					task.wait(1)
				until not alive() or tostring(state.Clip.AbsoluteSize) .. label.Text ~= key
				continue
			end

			local distance = math.ceil(full) + motion.MarqueeGap
			label.TextTruncate = Enum.TextTruncate.None
			label.Size = UDim2.new(0, math.ceil(full) + 2, 1, 0)
			ghostOf(state, label, distance)

			label.Position = UDim2.fromOffset(0, 0)
			if lapped then
				task.wait(motion.MarqueePause)
				if not alive() then
					return
				end
			end
			lapped = true
			local duration = distance / motion.MarqueeSpeed
			Motion.Apply(label, { Position = UDim2.fromOffset(-distance, 0) }, true, duration, Enum.EasingStyle.Linear)
			task.wait(duration)
			if not alive() then
				return
			end
			Motion.Apply(label, { Position = UDim2.fromOffset(0, 0) }, false)
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
			if not Parts.Touch then
				Parts.Marquee(element.Label, hovered)
			end
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
	if Parts.Touch and element.Label then
		Parts.Marquee(element.Label, true, true)
	end
end

function Parts.LockScroll(object, locked)
	local parent = object.Parent
	while parent do
		if parent:IsA("ScrollingFrame") then
			parent.ScrollingEnabled = not locked
		end
		parent = parent.Parent
	end
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
