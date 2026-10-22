local import = ...
local Theme = import("Theme")
local Motion = import("Motion")
local Create = import("Util/Create")
local Section = import("Components/Section")

local Sidebar = {}
Sidebar.__index = Sidebar

function Sidebar.new(window)
	local sizes = Theme.Sizes
	local self = setmetatable({ Window = window, Sections = {}, _autoOrder = 0 }, Sidebar)

	local top = sizes.HeaderHeight + 1
	self.Frame = Create.new("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(0, sizes.SidebarWidth, 1, -(top + sizes.BottomHeight + 1)),
		BackgroundTransparency = 1,
		Create.Padding(sizes.SidebarPadX, sizes.SidebarPadX, sizes.EdgePadY, sizes.EdgePadY),
	})

	self.List = Create.new("ScrollingFrame", {
		Name = "Pages",
		Size = UDim2.fromScale(1, 1),
		Parent = self.Frame,
	})

	self.HighlightFrame = Create.new("Frame", {
		Name = "Highlight",
		Size = UDim2.new(1, 0, 0, sizes.RowHeight),
		BackgroundColor3 = Theme.Colors.Selected,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 1,
		Parent = self.List,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.HighlightRadius) }),
	})

	local layout = Create.List(Enum.FillDirection.Vertical, sizes.ItemGap)
	self.Items = Create.new("Frame", {
		Name = "Items",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = self.List,
		layout,
	})

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		task.defer(function()
			if self._selected then
				self:Highlight(self._selected, false)
			end
		end)
	end)

	return self
end

function Sidebar:Highlight(button, animate)
	self._selected = button
	local frame = button.Frame
	local scale = if frame.AbsoluteSize.Y > 0 then frame.AbsoluteSize.Y / Theme.Sizes.RowHeight else 1
	local y = (frame.AbsolutePosition.Y - self.Items.AbsolutePosition.Y) / scale
	self.HighlightFrame.Visible = true
	Motion.Apply(self.HighlightFrame, { Position = UDim2.fromOffset(0, y) }, animate)
end

function Sidebar:AddSection(options)
	if type(options) == "string" then
		options = { Name = options }
	end
	assert(type(options) == "table" and options.Name, "UILib: AddSection needs a Name")

	local section = self.Sections[options.Name]
	if not section then
		local order = options.Order
		if not order then
			self._autoOrder += 1
			order = self._autoOrder
		end
		section = Section.new(self, options, order)
		self.Sections[options.Name] = section
	end
	return section
end

return Sidebar
