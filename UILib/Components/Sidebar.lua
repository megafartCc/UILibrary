local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")
local Section = import("Components/Section")

local Sidebar = {}
Sidebar.__index = Sidebar

function Sidebar.new(window, title)
	local sizes = Theme.Sizes
	local self = setmetatable({ Window = window, Sections = {}, _autoOrder = 0 }, Sidebar)

	self.Frame = Create.new("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, sizes.SidebarWidth, 1, 0),
		BackgroundColor3 = Theme.Colors.Box,
		BorderSizePixel = 0,
		Create.Padding(sizes.SidebarPadX, sizes.SidebarPadX, sizes.EdgePadY, sizes.EdgePadY),
		Create.List(Enum.FillDirection.Vertical, sizes.ItemGap),
	})

	self.Title = Create.new("TextLabel", {
		Name = "Title",
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, sizes.TitleHeight),
		Font = Theme.Fonts.Title,
		Text = title,
		TextSize = Theme.TextSizes.Title,
		TextColor3 = Theme.Colors.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
		Create.Padding(sizes.ItemPadX),
	})

	return self
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
