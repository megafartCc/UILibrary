local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local Button = {}
Button.__index = Button

function Button.new(group, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local self = setmetatable({ Name = options.Name, Callback = options.Callback }, Button)

	self.Frame = Create.new("TextButton", {
		Name = "Button_" .. options.Name,
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

	self.Square = Create.new("Frame", {
		Name = "Square",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(sizes.SwitchWidth - sizes.ButtonSize) / 2, 0.5, 0),
		Size = UDim2.fromOffset(sizes.ButtonSize, sizes.ButtonSize),
		BackgroundColor3 = colors.Track,
		BorderSizePixel = 0,
		Parent = self.Frame,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.ButtonRadius) }),
	})
	self._scale = Create.new("UIScale", { Parent = self.Square })

	self.Icon = Create.new("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(sizes.ButtonIconSize, sizes.ButtonIconSize),
		ImageColor3 = colors.Muted,
		Parent = self.Square,
	})
	Icons.Apply(self.Icon, options.Icon or "chevron-right")

	self.Frame.Activated:Connect(function()
		self:Press()
	end)

	return self
end

function Button:Press()
	local colors, motion = Theme.Colors, Theme.Motion
	self._scale.Scale = motion.PressScale
	self.Square.BackgroundColor3 = colors.Accent
	self.Icon.ImageColor3 = colors.Text
	Motion.Apply(self._scale, { Scale = 1 }, true, motion.PressDuration, Enum.EasingStyle.Back)
	Motion.Apply(self.Square, { BackgroundColor3 = colors.Track }, true, motion.PressDuration, Enum.EasingStyle.Quad)
	Motion.Apply(self.Icon, { ImageColor3 = colors.Muted }, true, motion.PressDuration, Enum.EasingStyle.Quad)

	if self.Callback then
		task.spawn(self.Callback)
	end
end

return Button
