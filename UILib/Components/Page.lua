-- Page: the content area shown when its sidebar button is selected.
-- Put your own elements inside page.Body.

local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")

local Page = {}
Page.__index = Page

function Page.new(options)
	local self = setmetatable({}, Page)
	local sizes = Theme.Sizes

	self.Name = options.Name
	self.Frame = Create.new("Frame", {
		Name = "Page_" .. options.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	}, {
		Create.Padding(sizes.ContentPad, sizes.ContentPad, sizes.ContentPad, sizes.ContentPad),
		Create.List(Enum.FillDirection.Vertical, 8),
	})

	self.Title = Create.new("TextLabel", {
		Name = "Title",
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Title,
		Text = options.Name,
		TextSize = Theme.TextSizes.PageTitle,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Frame,
	})

	self.Body = Create.new("Frame", {
		Name = "Body",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 1, -26),
		BackgroundTransparency = 1,
		Parent = self.Frame,
	})

	return self
end

function Page:SetVisible(on)
	self.Frame.Visible = on
end

return Page
