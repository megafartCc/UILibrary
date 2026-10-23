local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local Slider = import("Elements/Slider")
local Dropdown = import("Elements/Dropdown")
local Input = import("Elements/Input")

local function variant(element, overrides)
	return {
		new = function(group, options, order)
			local merged = table.clone(options)
			for key, value in overrides do
				merged[key] = value
			end
			return element.new(group, merged, order)
		end,
	}
end

local Elements = {
	Slider = Slider,
	Toggle = import("Elements/Toggle"),
	Button = import("Elements/Button"),
	Dropdown = Dropdown,
	ColorPicker = import("Elements/ColorPicker"),
	Input = Input,
	TextBox = Input,
	SliderToggle = variant(Slider, { Accessory = "Toggle" }),
	DropdownToggle = variant(Dropdown, { Accessory = "Toggle" }),
	DropdownButton = variant(Dropdown, { Accessory = "Button" }),
	MultiDropdown = variant(Dropdown, { Multi = true }),
	MultiDropdownToggle = variant(Dropdown, { Multi = true, Accessory = "Toggle" }),
}

local Group = {}
Group.__index = Group

function Group.new(column, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local pad = sizes.GroupPad
	local self = setmetatable({ Name = options.Name, Elements = {}, Collapsed = false, _token = 0 }, Group)

	self.Frame = Create.new("Frame", {
		Name = "Group_" .. options.Name,
		LayoutOrder = order,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = colors.Group,
		BorderSizePixel = 0,
		Parent = column,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.GroupRadius) }),
		Create.new("UIStroke", { Color = colors.GroupStroke, Thickness = sizes.GroupStroke }),
		Create.List(Enum.FillDirection.Vertical, 0),
	})

	self.Header = Create.new("TextButton", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, sizes.GroupHeaderHeight),
		BackgroundTransparency = 1,
		Parent = self.Frame,
	})

	self.Title = Create.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(pad, 0),
		Size = UDim2.new(1, -(pad * 2 + sizes.GroupChevron + 4), 1, 0),
		FontFace = Theme.Fonts.GroupTitle,
		Text = options.Name,
		TextSize = Theme.TextSizes.GroupTitle,
		TextColor3 = colors.GroupTitle,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Header,
	})

	self.Chevron = Create.new("ImageLabel", {
		Name = "Chevron",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -pad, 0.5, 0),
		Size = UDim2.fromOffset(sizes.GroupChevron, sizes.GroupChevron),
		ImageColor3 = colors.Muted,
		Parent = self.Header,
	})
	Icons.Apply(self.Chevron, "chevron-up")

	self.Line = Create.new("Frame", {
		Name = "Line",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = colors.GroupLine,
		BorderSizePixel = 0,
		Parent = self.Frame,
	})

	self.Clip = Create.new("Frame", {
		Name = "Clip",
		LayoutOrder = 3,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = self.Frame,
	})

	self.Body = Create.new("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self.Clip,
		Create.Padding(pad, pad, sizes.GroupPadTop, sizes.GroupPadBottom),
		Create.List(Enum.FillDirection.Vertical, sizes.GroupItemGap),
	})

	self.Header.MouseEnter:Connect(function()
		Motion.Apply(self.Chevron, { ImageColor3 = colors.Text }, true)
	end)
	self.Header.MouseLeave:Connect(function()
		Motion.Apply(self.Chevron, { ImageColor3 = colors.Muted }, true)
	end)
	self.Header.Activated:Connect(function()
		self:Toggle()
	end)

	if options.Collapsed then
		self:SetCollapsed(true, false)
	end
	return self
end

function Group:_bodyHeight()
	local scale = if self.Header.AbsoluteSize.Y > 0 then self.Header.AbsoluteSize.Y / Theme.Sizes.GroupHeaderHeight else 1
	return self.Body.AbsoluteSize.Y / scale
end

function Group:SetCollapsed(collapsed, animate)
	if animate == nil then
		animate = true
	end
	self.Collapsed = collapsed
	self._token += 1
	local token = self._token

	local clip = self.Clip
	clip.AutomaticSize = Enum.AutomaticSize.None
	if collapsed then
		clip.Size = UDim2.new(1, 0, 0, self:_bodyHeight())
		Motion.Apply(clip, { Size = UDim2.fromScale(1, 0) }, animate)
	else
		Motion.Apply(clip, { Size = UDim2.new(1, 0, 0, self:_bodyHeight()) }, animate)
		local function release()
			if self._token == token then
				clip.AutomaticSize = Enum.AutomaticSize.Y
				clip.Size = UDim2.fromScale(1, 0)
			end
		end
		if animate then
			task.delay(Theme.Motion.Duration, release)
		else
			release()
		end
	end
	Motion.Apply(self.Chevron, { Rotation = if collapsed then 180 else 0 }, animate)
	Motion.Apply(self.Line, { BackgroundTransparency = if collapsed then 1 else 0 }, animate)
end

function Group:Toggle()
	self:SetCollapsed(not self.Collapsed)
end

function Group:_add(kind, options)
	assert(type(options) == "table" and options.Name, "UILib: Add" .. kind .. " needs a Name")
	local element = Elements[kind].new(self, options, #self.Elements + 1)
	element.Kind = kind
	element.Group = self
	element.SaveKey = options.SaveKey
	element.Flag = options.Flag or options.SaveKey or table.concat({ if self.Page then self.Page.Name else "", self.Name, options.Name }, ".")
	element.NoConfig = options.NoConfig == true or self.NoConfig == true
	table.insert(self.Elements, element)

	local window = self.Page and self.Page.Window
	local config = window and window.Config
	if config and not element.NoConfig and type(element.Get) == "function" then
		local original = element.Callback
		element.Callback = function(...)
			config:QueueAutosave()
			if original then
				original(...)
			end
		end
		config:Restore(element)
	end
	return element
end

for kind in Elements do
	Group["Add" .. kind] = function(self, options)
		return self:_add(kind, options)
	end
end

return Group
