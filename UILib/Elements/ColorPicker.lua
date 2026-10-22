local import = ...
local Theme = import("Theme")
local Motion = import("Motion")
local Create = import("Util/Create")
local Parts = import("Util/Parts")

local UserInputService = game:GetService("UserInputService")

local PRESS = { [Enum.UserInputType.MouseButton1] = true, [Enum.UserInputType.Touch] = true }
local MOVE = { [Enum.UserInputType.MouseMovement] = true, [Enum.UserInputType.Touch] = true }

local ColorPicker = {}
ColorPicker.__index = ColorPicker

local function hueSequence()
	local points = {}
	for index = 0, 6 do
		table.insert(points, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6 % 1, 1, 1)))
	end
	return ColorSequence.new(points)
end

local function overlay(parent, color, rotation, radius)
	return Create.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = parent,
		Create.new("UICorner", { CornerRadius = UDim.new(0, radius) }),
		Create.new("UIGradient", {
			Rotation = rotation,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		}),
	})
end

function ColorPicker.new(group, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local pad, radius = sizes.PickerPad, sizes.PickerRadius
	local self = setmetatable({ Name = options.Name, Opened = false, _token = 0 }, ColorPicker)

	self.Frame = Create.new("Frame", {
		Name = "ColorPicker_" .. options.Name,
		LayoutOrder = order,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = group.Body,
		Create.List(Enum.FillDirection.Vertical, 4),
	})

	self.Header = Create.new("TextButton", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, sizes.ElementHeight),
		BackgroundTransparency = 1,
		Parent = self.Frame,
	})

	self.Label = Create.new("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -Parts.Trailing(true), 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = options.Name,
		TextSize = Theme.TextSizes.Element,
		TextColor3 = colors.ElementText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Header,
	})

	self.Swatch = Create.new("Frame", {
		Name = "Swatch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(sizes.SwitchWidth - sizes.ButtonSize) / 2, 0.5, 0),
		Size = UDim2.fromOffset(sizes.ButtonSize, sizes.ButtonSize),
		BorderSizePixel = 0,
		Parent = self.Header,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.ButtonRadius) }),
		Create.new("UIStroke", { Color = colors.SwatchStroke, Thickness = 1 }),
	})

	self.Panel = Create.new("Frame", {
		Name = "Picker",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = colors.Track,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Parent = self.Frame,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.DropdownRadius) }),
	})

	self.Square = Create.new("TextButton", {
		Name = "Saturation",
		Position = UDim2.fromOffset(pad, pad),
		Size = UDim2.new(1, -(pad * 3 + sizes.HueWidth), 0, sizes.PickerHeight),
		BorderSizePixel = 0,
		Parent = self.Panel,
		Create.new("UICorner", { CornerRadius = UDim.new(0, radius) }),
	})
	overlay(self.Square, Color3.new(1, 1, 1), 0, radius)
	local shade = overlay(self.Square, Color3.new(0, 0, 0), 270, radius)
	shade.ZIndex = 2

	self.Cursor = Create.new("Frame", {
		Name = "Cursor",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(sizes.PickerCursor, sizes.PickerCursor),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = self.Square,
		Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create.new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5 }),
	})

	self.Hue = Create.new("TextButton", {
		Name = "Hue",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -pad, 0, pad),
		Size = UDim2.fromOffset(sizes.HueWidth, sizes.PickerHeight),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = self.Panel,
		Create.new("UICorner", { CornerRadius = UDim.new(0, radius) }),
		Create.new("UIGradient", { Color = hueSequence(), Rotation = 90 }),
	})

	self.HueBar = Create.new("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 4, 0, 3),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = self.Hue,
		Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create.new("UIStroke", { Color = colors.Box, Thickness = 1, Transparency = 0.4 }),
	})

	self.Hex = Create.new("TextBox", {
		Name = "Hex",
		Position = UDim2.fromOffset(pad, pad * 2 + sizes.PickerHeight),
		Size = UDim2.new(1, -pad * 2, 0, sizes.HexHeight),
		BackgroundColor3 = colors.Group,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		FontFace = Theme.Fonts.Element,
		Text = "",
		TextSize = Theme.TextSizes.Dropdown,
		TextColor3 = colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Panel,
		Create.new("UICorner", { CornerRadius = UDim.new(0, radius) }),
		Create.Padding(pad + 2, pad),
	})

	self.Header.Activated:Connect(function()
		if self.Opened then
			self:Close()
		else
			self:Open()
		end
	end)

	self.Hex.FocusLost:Connect(function()
		local text = string.gsub(self.Hex.Text, "[^%x]", "")
		local ok, color = pcall(Color3.fromHex, text)
		if ok and #text == 6 then
			self:Set(color)
		else
			self:_apply(false)
		end
	end)

	local dragging
	local function drag(target, position)
		local origin, size = target.AbsolutePosition, target.AbsoluteSize
		local x = math.clamp((position.X - origin.X) / math.max(size.X, 1), 0, 1)
		local y = math.clamp((position.Y - origin.Y) / math.max(size.Y, 1), 0, 1)
		if target == self.Square then
			self._s, self._v = x, 1 - y
		else
			self._h = y
		end
		self:_apply(true)
	end

	for _, target in { self.Square, self.Hue } do
		target.InputBegan:Connect(function(input)
			if PRESS[input.UserInputType] then
				dragging = target
				drag(target, input.Position)
			end
		end)
	end

	local connections = {
		UserInputService.InputChanged:Connect(function(input)
			if dragging and MOVE[input.UserInputType] then
				drag(dragging, input.Position)
			end
		end),
		UserInputService.InputEnded:Connect(function(input)
			if PRESS[input.UserInputType] then
				dragging = nil
			end
		end),
	}
	self.Frame.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)

	self._h, self._s, self._v = (options.Default or Color3.new(1, 1, 1)):ToHSV()
	self:_apply(false)
	self.Callback = options.Callback
	return self
end

function ColorPicker:_apply(fire)
	local color = Color3.fromHSV(self._h, self._s, self._v)
	self.Swatch.BackgroundColor3 = color
	self.Square.BackgroundColor3 = Color3.fromHSV(self._h, 1, 1)
	self.Cursor.Position = UDim2.fromScale(self._s, 1 - self._v)
	self.HueBar.Position = UDim2.fromScale(0.5, self._h)
	self.Hex.Text = "#" .. string.upper(color:ToHex())

	local changed = self.Value == nil or self.Value:ToHex() ~= color:ToHex()
	self.Value = color
	if fire and changed and self.Callback then
		task.spawn(self.Callback, color)
	end
end

function ColorPicker:Set(color)
	self._h, self._s, self._v = color:ToHSV()
	self:_apply(true)
end

function ColorPicker:Get()
	return self.Value
end

function ColorPicker:Open()
	local sizes = Theme.Sizes
	self.Opened = true
	self._token += 1
	self.Panel.Visible = true
	local height = sizes.PickerPad * 3 + sizes.PickerHeight + sizes.HexHeight
	Motion.Apply(self.Panel, { Size = UDim2.new(1, 0, 0, height) }, true)
end

function ColorPicker:Close()
	self.Opened = false
	self._token += 1
	local token = self._token
	Motion.Apply(self.Panel, { Size = UDim2.fromScale(1, 0) }, true)
	task.delay(Theme.Motion.Duration, function()
		if self._token == token then
			self.Panel.Visible = false
		end
	end)
end

return ColorPicker
