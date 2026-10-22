local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")

local Page = {}
Page.__index = Page

function Page.new(options)
	local sizes = Theme.Sizes
	local padX, padY = sizes.ContentPadX, sizes.EdgePadY
	local self = setmetatable({ Name = options.Name }, Page)

	self.Frame = Create.new("Frame", {
		Name = "Page_" .. options.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Create.Padding(padX, padX, padY, padY),
		Create.List(Enum.FillDirection.Vertical, sizes.PageGap),
	})

	self.Title = Create.new("TextLabel", {
		Name = "Title",
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, sizes.TitleHeight),
		Font = Theme.Fonts.Title,
		Text = options.Name,
		TextSize = Theme.TextSizes.PageTitle,
		TextColor3 = Theme.Colors.Text,
		Parent = self.Frame,
	})

	self.Body = Create.new("Frame", {
		Name = "Body",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 1, -(sizes.TitleHeight + sizes.PageGap)),
		BackgroundTransparency = 1,
		Parent = self.Frame,
	})

	return self
end

function Page:SetSelected(on)
	self.Frame.Visible = on
	if self.Button then
		self.Button:SetSelected(on)
	end
end

return Page
