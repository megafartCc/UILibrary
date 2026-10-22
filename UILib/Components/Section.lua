local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")

local SLOT = 1000

local Section = {}
Section.__index = Section

function Section.new(sidebar, options, order)
	local self = setmetatable({ Sidebar = sidebar, Name = options.Name, Order = order, _pageCount = 0 }, Section)

	self.Label = Create.new("TextLabel", {
		Name = "Section_" .. options.Name,
		LayoutOrder = order * SLOT,
		Size = UDim2.new(1, 0, 0, Theme.Sizes.SectionLabelHeight),
		Font = Theme.Fonts.SectionLabel,
		Text = string.upper(options.Name),
		TextSize = Theme.TextSizes.SectionLabel,
		TextColor3 = Theme.Colors.SectionLabel,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		Visible = options.Name ~= "" and options.ShowLabel ~= false,
		Parent = sidebar.Frame,
		Create.Padding(Theme.Sizes.ItemPadX, 0, 0, Theme.Sizes.SectionLabelPadBottom),
	})

	return self
end

function Section:AddPage(options)
	assert(type(options) == "table" and options.Name, "UILib: AddPage needs a Name")
	self._pageCount += 1
	local order = math.clamp(options.Order or self._pageCount, 1, SLOT - 1)
	return self.Sidebar.Window:_addPage(options, self.Order * SLOT + order)
end

return Section
