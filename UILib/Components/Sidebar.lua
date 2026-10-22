-- Sidebar: window title, section labels and page buttons.

local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")
local Section = import("Components/Section")

local Sidebar = {}
Sidebar.__index = Sidebar

function Sidebar.new(window, title)
	local self = setmetatable({}, Sidebar)
	local sizes, colors = Theme.Sizes, Theme.Colors

	self.Window = window
	self._sectionCount = 0

	self.Frame = Create.new("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, sizes.SidebarWidth, 1, 0),
		BackgroundColor3 = colors.Box,
		BorderSizePixel = 0,
	}, {
		Create.Padding(sizes.SidebarPadX, sizes.SidebarPadX, sizes.SidebarPadY, sizes.SidebarPadY),
		Create.List(Enum.FillDirection.Vertical, sizes.ItemGap),
	})

	-- Window name, top left. Always first.
	self.Title = Create.new("TextLabel", {
		Name = "Title",
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Title,
		Text = title,
		TextSize = Theme.TextSizes.Title,
		TextColor3 = colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
	}, { Create.Padding(sizes.ItemPadX, 0, 0, 0) })

	return self
end

function Sidebar:NextSectionOrder()
	self._sectionCount += 1
	return self._sectionCount
end

function Sidebar:SetTitle(text)
	self.Title.Text = text
end

function Sidebar:AddSection(options)
	if type(options) == "string" then
		options = { Name = options }
	end
	return Section.new(self, options)
end

return Sidebar
