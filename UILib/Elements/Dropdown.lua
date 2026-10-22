local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(group, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local self = setmetatable({
		Name = options.Name,
		Multi = options.Multi == true,
		Options = {},
		Opened = false,
		_rows = {},
		_selected = {},
		_token = 0,
	}, Dropdown)

	self.Frame = Create.new("Frame", {
		Name = "Dropdown_" .. options.Name,
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
		Size = UDim2.new(1 - sizes.SliderBarWidth, -6, 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = options.Name,
		TextSize = Theme.TextSizes.Element,
		TextColor3 = colors.ElementText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Header,
	})

	self.Selector = Create.new("Frame", {
		Name = "Selector",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(sizes.SliderBarWidth, 0, 0, sizes.DropdownHeight),
		BackgroundColor3 = colors.Track,
		BorderSizePixel = 0,
		Parent = self.Header,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.DropdownRadius) }),
	})

	self.ValueLabel = Create.new("TextLabel", {
		Name = "Value",
		Position = UDim2.fromOffset(sizes.DropdownPad, 0),
		Size = UDim2.new(1, -(sizes.DropdownPad * 2 + sizes.ChevronSize + 4), 1, 0),
		FontFace = Theme.Fonts.Element,
		TextSize = Theme.TextSizes.Dropdown,
		TextColor3 = colors.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Selector,
	})

	self.Chevron = Create.new("ImageLabel", {
		Name = "Chevron",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -sizes.DropdownPad, 0.5, 0),
		Size = UDim2.fromOffset(sizes.ChevronSize, sizes.ChevronSize),
		ImageColor3 = colors.Muted,
		Parent = self.Selector,
	})
	Icons.Apply(self.Chevron, "chevron-down")

	self.Panel = Create.new("Frame", {
		Name = "Options",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = colors.Track,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Parent = self.Frame,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.DropdownRadius) }),
	})

	self.List = Create.new("ScrollingFrame", {
		Name = "List",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = self.Panel,
		Create.Padding(4, 4, 4, 4),
		Create.List(Enum.FillDirection.Vertical, 0),
	})

	self.Header.Activated:Connect(function()
		if self.Opened then
			self:Close()
		else
			self:Open()
		end
	end)

	self:SetOptions(options.Options or {})
	if options.Default ~= nil then
		self:_select(options.Default)
	end
	self.Callback = options.Callback
	return self
end

function Dropdown:SetOptions(list)
	for _, row in self._rows do
		row.Button:Destroy()
	end
	table.clear(self._rows)
	self.Options = table.clone(list)

	for index, option in self.Options do
		table.insert(self._rows, self:_row(option, index))
	end

	local kept = {}
	for _, option in self.Options do
		if self._selected[option] then
			kept[option] = true
		end
	end
	self._selected = kept
	self:_refresh(false)
	if self.Opened then
		self:Open()
	end
end

function Dropdown:_row(option, index)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local button = Create.new("TextButton", {
		Name = "Option",
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, sizes.OptionHeight),
		BackgroundColor3 = colors.OptionHover,
		BackgroundTransparency = 1,
		Parent = self.List,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.DropdownRadius - 2) }),
	})

	local label = Create.new("TextLabel", {
		Name = "Label",
		Position = UDim2.fromOffset(sizes.DropdownPad, 0),
		Size = UDim2.new(1, -(sizes.DropdownPad * 2 + sizes.OptionCheckSize + 4), 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = tostring(option),
		TextSize = Theme.TextSizes.Dropdown,
		TextColor3 = colors.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})

	local check = Create.new("ImageLabel", {
		Name = "Check",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -sizes.DropdownPad, 0.5, 0),
		Size = UDim2.fromOffset(sizes.OptionCheckSize, sizes.OptionCheckSize),
		ImageColor3 = colors.Accent,
		ImageTransparency = 1,
		Parent = button,
	})
	Icons.Apply(check, "check")

	button.MouseEnter:Connect(function()
		Motion.Apply(button, { BackgroundTransparency = 0 }, true)
	end)
	button.MouseLeave:Connect(function()
		Motion.Apply(button, { BackgroundTransparency = 1 }, true)
	end)
	button.Activated:Connect(function()
		if self.Multi then
			self._selected[option] = not self._selected[option] or nil
		else
			self._selected = { [option] = true }
		end
		self:_refresh(true)
		self:_fire()
		if not self.Multi then
			self:Close()
		end
	end)

	return { Option = option, Button = button, Label = label, Check = check }
end

function Dropdown:_refresh(animate)
	local colors = Theme.Colors
	local picked = {}
	for _, row in self._rows do
		local on = self._selected[row.Option] == true
		if on then
			table.insert(picked, tostring(row.Option))
		end
		Motion.Apply(row.Label, { TextColor3 = if on then colors.Text else colors.Muted }, animate)
		Motion.Apply(row.Check, { ImageTransparency = if on then 0 else 1 }, animate)
	end

	if self.Multi then
		self.Value = {}
		for _, option in self.Options do
			if self._selected[option] then
				table.insert(self.Value, option)
			end
		end
	else
		self.Value = nil
		for _, option in self.Options do
			if self._selected[option] then
				self.Value = option
			end
		end
	end

	self.ValueLabel.Text = if #picked > 0 then table.concat(picked, ", ") else "None"
	self.ValueLabel.TextColor3 = if #picked > 0 then colors.Text else colors.Muted
end

function Dropdown:_fire()
	if self.Callback then
		task.spawn(self.Callback, if self.Multi then table.clone(self.Value) else self.Value)
	end
end

function Dropdown:_select(value)
	self._selected = {}
	if self.Multi and type(value) == "table" then
		for _, option in value do
			self._selected[option] = true
		end
	elseif value ~= nil then
		self._selected[value] = true
	end
	self:_refresh(true)
end

function Dropdown:Set(value)
	self:_select(value)
	self:_fire()
end

function Dropdown:Get()
	return if self.Multi then table.clone(self.Value) else self.Value
end

function Dropdown:Open()
	local sizes = Theme.Sizes
	self.Opened = true
	self._token += 1
	local visible = math.min(#self.Options, sizes.MaxVisibleOptions)
	local height = if visible > 0 then visible * sizes.OptionHeight + 8 else 0
	self.Panel.Visible = height > 0
	Motion.Apply(self.Panel, { Size = UDim2.new(1, 0, 0, height) }, true)
	Motion.Apply(self.Chevron, { Rotation = 180 }, true)
end

function Dropdown:Close()
	self.Opened = false
	self._token += 1
	local token = self._token
	Motion.Apply(self.Panel, { Size = UDim2.fromScale(1, 0) }, true)
	Motion.Apply(self.Chevron, { Rotation = 0 }, true)
	task.delay(Theme.Motion.Duration, function()
		if self._token == token then
			self.Panel.Visible = false
		end
	end)
end

return Dropdown
