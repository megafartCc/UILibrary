local import = ...
local Theme = import("Theme")
local Motion = import("Motion")
local Create = import("Util/Create")
local Parts = import("Util/Parts")

local Input = {}
Input.__index = Input

function Input.new(group, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local self = setmetatable({
		Name = options.Name,
		Numeric = options.Numeric == true,
		Live = options.Live == true,
		Focused = false,
	}, Input)

	self.Frame = Create.new("Frame", {
		Name = "Input_" .. options.Name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, sizes.ElementHeight),
		BackgroundTransparency = 1,
		Parent = group.Body,
	})

	self.Label = Create.new("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1 - sizes.SliderBarWidth, -6, 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = options.Name,
		TextSize = Theme.TextSizes.Element,
		TextColor3 = colors.ElementText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
	})
	Parts.ClipLabel(self.Label)

	self.Box = Create.new("TextBox", {
		Name = "Box",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(sizes.SliderBarWidth, 0, 0, sizes.DropdownHeight),
		BackgroundColor3 = colors.Track,
		BorderSizePixel = 0,
		ClearTextOnFocus = options.ClearOnFocus == true,
		ClipsDescendants = true,
		FontFace = Theme.Fonts.Value,
		PlaceholderText = options.Placeholder or "",
		PlaceholderColor3 = colors.SectionLabel,
		Text = "",
		TextSize = Theme.TextSizes.Dropdown,
		TextColor3 = colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Frame,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.DropdownRadius) }),
		Create.Padding(sizes.DropdownPad, sizes.DropdownPad),
	})
	self.Stroke = Create.new("UIStroke", {
		Color = colors.Accent,
		Thickness = 1,
		Transparency = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = self.Box,
	})

	Parts.Hover(self, self.Frame, function(hovered)
		if not self.Focused then
			Motion.Apply(self.Box, { BackgroundColor3 = if hovered then colors.TrackHover else colors.Track }, true)
		end
	end)

	self.Box:GetPropertyChangedSignal("Text"):Connect(function()
		if self.Numeric then
			local cleaned = string.gsub(self.Box.Text, "[^%d%.%-]", "")
			if cleaned ~= self.Box.Text then
				self.Box.Text = cleaned
				return
			end
		end
		if self.Live then
			self:_commit(self.Box.Text)
		end
	end)

	self.Box.Focused:Connect(function()
		self.Focused = true
		Motion.Apply(self.Stroke, { Transparency = 0.3 }, true)
		Motion.Apply(self.Box, { BackgroundColor3 = colors.TrackHover }, true)
	end)

	self.Box.FocusLost:Connect(function()
		self.Focused = false
		Motion.Apply(self.Stroke, { Transparency = 1 }, true)
		Motion.Apply(self.Box, { BackgroundColor3 = if self.Hovered then colors.TrackHover else colors.Track }, true)
		self:_commit(self.Box.Text)
	end)

	if options.Default ~= nil then
		self.Box.Text = tostring(options.Default)
	end
	self.Value = self:_parse(self.Box.Text)
	self.Callback = options.Callback
	return self
end

function Input:_parse(text)
	if self.Numeric then
		return tonumber(text)
	end
	return text
end

function Input:_commit(text)
	local value = self:_parse(text)
	if value ~= self.Value then
		self.Value = value
		if self.Callback then
			task.spawn(self.Callback, value)
		end
	end
end

function Input:Set(value)
	self.Box.Text = if value == nil then "" else tostring(value)
	self:_commit(self.Box.Text)
end

function Input:Get()
	return self.Value
end

return Input
