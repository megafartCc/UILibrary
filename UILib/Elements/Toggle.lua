local import = ...
local Theme = import("Theme")
local Motion = import("Motion")
local Create = import("Util/Create")

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(group, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local knob = sizes.SwitchHeight - 2 * sizes.KnobInset
	local self = setmetatable({ Name = options.Name }, Toggle)

	self.Frame = Create.new("TextButton", {
		Name = "Toggle_" .. options.Name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, sizes.ElementHeight),
		BackgroundTransparency = 1,
		Parent = group.Body,
	})

	self.Label = Create.new("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -(sizes.SwitchWidth + 6), 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = options.Name,
		TextSize = Theme.TextSizes.Element,
		TextColor3 = colors.ElementText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
	})

	self.Switch = Create.new("Frame", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(sizes.SwitchWidth, sizes.SwitchHeight),
		BackgroundColor3 = colors.SwitchOff,
		BorderSizePixel = 0,
		Parent = self.Frame,
		Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	self.Knob = Create.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(knob, knob),
		BackgroundColor3 = colors.Knob,
		BorderSizePixel = 0,
		Parent = self.Switch,
		Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	self.Frame.Activated:Connect(function()
		self:Set(not self.Value)
	end)

	self:_set(options.Default == true, false)
	self.Callback = options.Callback
	return self
end

function Toggle:Set(value)
	self:_set(value == true, true)
end

function Toggle:_set(value, animate)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local inset = sizes.KnobInset
	local x = if value then sizes.SwitchWidth - sizes.SwitchHeight + inset else inset
	Motion.Apply(self.Switch, { BackgroundColor3 = if value then colors.Accent else colors.SwitchOff }, animate)
	Motion.Apply(self.Knob, { Position = UDim2.new(0, x, 0.5, 0) }, animate)

	if value ~= self.Value then
		self.Value = value
		if self.Callback then
			task.spawn(self.Callback, value)
		end
	end
end

function Toggle:Get()
	return self.Value
end

return Toggle
