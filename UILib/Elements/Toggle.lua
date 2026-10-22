local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(group, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
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
		Size = UDim2.new(1, -(sizes.CheckSize + 6), 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = options.Name,
		TextSize = Theme.TextSizes.Element,
		TextColor3 = colors.ElementText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
	})

	self.Box = Create.new("Frame", {
		Name = "Box",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -1, 0.5, 0),
		Size = UDim2.fromOffset(sizes.CheckSize, sizes.CheckSize),
		BackgroundColor3 = colors.Track,
		BorderSizePixel = 0,
		Parent = self.Frame,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.CheckRadius) }),
	})

	self.Stroke = Create.new("UIStroke", {
		Color = colors.CheckBorder,
		Thickness = 1,
		Parent = self.Box,
	})

	self.Check = Create.new("ImageLabel", {
		Name = "Check",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(sizes.CheckIconSize, sizes.CheckIconSize),
		ImageColor3 = colors.Accent,
		ImageTransparency = 1,
		Parent = self.Box,
	})
	Icons.Apply(self.Check, "check")

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
	local colors = Theme.Colors
	Motion.Apply(self.Box, { BackgroundColor3 = if value then colors.AccentSurface else colors.Track }, animate)
	Motion.Apply(self.Stroke, { Color = if value then colors.Accent else colors.CheckBorder }, animate)
	Motion.Apply(self.Check, { ImageTransparency = if value then 0 else 1 }, animate)

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
