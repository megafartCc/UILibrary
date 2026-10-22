local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local Parts = {}

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

	local switch = { Frame = frame, Knob = knob }

	function switch.Set(on, animate)
		local x = if on then sizes.SwitchWidth - sizes.SwitchHeight + inset else inset
		Motion.Apply(frame, { BackgroundColor3 = if on then colors.Accent else colors.SwitchOff }, animate)
		Motion.Apply(knob, { Position = UDim2.new(0, x, 0.5, 0) }, animate)
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

	local square = { Frame = frame, Icon = image, Scale = scale }

	function square.Press()
		local motion = Theme.Motion
		scale.Scale = motion.PressScale
		frame.BackgroundColor3 = colors.Accent
		image.ImageColor3 = colors.Text
		Motion.Apply(scale, { Scale = 1 }, true, motion.PressDuration, Enum.EasingStyle.Back)
		Motion.Apply(frame, { BackgroundColor3 = colors.Track }, true, motion.PressDuration, Enum.EasingStyle.Quad)
		Motion.Apply(image, { ImageColor3 = colors.Muted }, true, motion.PressDuration, Enum.EasingStyle.Quad)
	end

	return square
end

function Parts.Trailing(kind)
	return if kind then Theme.Sizes.SwitchWidth + 6 else 0
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
