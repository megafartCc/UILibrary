local Theme = {}

Theme.Colors = {
	Box = Color3.fromRGB(0, 0, 0),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(143, 143, 148),
	SectionLabel = Color3.fromRGB(102, 102, 107),
	Selected = Color3.fromRGB(33, 33, 38),
	Divider = Color3.fromRGB(36, 36, 38),
}

Theme.Sizes = {
	WindowWidth = 400,
	WindowHeight = 256,
	SidebarWidth = 124,
	SidebarPadX = 4,
	SidebarPadY = 10,
	ItemPadX = 5,
	ItemGap = 2,
	RowHeight = 28,
	IconSize = 14,
	IconGap = 5,
	HighlightRadius = 6,
	ContentPad = 16,
}

Theme.Fonts = {
	Title = Enum.Font.GothamBold,
	SectionLabel = Enum.Font.GothamMedium,
	Page = Enum.Font.GothamMedium,
	PageSelected = Enum.Font.GothamBold,
}

Theme.TextSizes = {
	Title = 13,
	SectionLabel = 8,
	Page = 11,
	PageTitle = 14,
}

return Theme
