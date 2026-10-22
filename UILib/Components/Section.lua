local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")
local PageButton = import("Components/PageButton")

local SLOT = 1000

local Section = {}
Section.__index = Section

function Section.new(sidebar, options)
	local self = setmetatable({}, Section)
	self.Sidebar = sidebar
	self.Name = options.Name
	self.Order = options.Order or sidebar:NextSectionOrder()
	self._pageCount = 0

	self.Label = Create.new("TextLabel", {
		Name = "Section_" .. options.Name,
		LayoutOrder = self.Order * SLOT,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.SectionLabel,
		Text = string.upper(options.Name),
		TextSize = Theme.TextSizes.SectionLabel,
		TextColor3 = Theme.Colors.SectionLabel,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		Visible = options.ShowLabel ~= false,
		Parent = sidebar.Frame,
	}, { Create.Padding(Theme.Sizes.ItemPadX, 0, 0, 2) })

	return self
end

function Section:AddPage(options)
	assert(type(options) == "table" and options.Name, "UILib: AddPage needs a Name")
	self._pageCount += 1
	local order = math.clamp(options.Order or self._pageCount, 1, SLOT - 1)
	local layoutOrder = self.Order * SLOT + order

	local button = PageButton.new(options, layoutOrder)
	button.Frame.Parent = self.Sidebar.Frame
	return self.Sidebar.Window:_registerPage(options, button, layoutOrder)
end

return Section
