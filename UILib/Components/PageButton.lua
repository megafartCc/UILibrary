local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local PageButton = {}
PageButton.__index = PageButton

function PageButton.new(options, layoutOrder)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local self = setmetatable({}, PageButton)

	self.Frame = Create.new("TextButton", {
		Name = "Page_" .. options.Name,
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, 0, 0, sizes.RowHeight),
		BackgroundTransparency = 1,
		Create.Padding(sizes.ItemPadX, sizes.ItemPadX),
		Create.List(Enum.FillDirection.Horizontal, sizes.IconGap),
	})
	self.Activated = self.Frame.Activated

	self.Icon = Create.new("ImageLabel", {
		Name = "Icon",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(sizes.IconSize, sizes.IconSize),
		ImageColor3 = colors.Muted,
		Parent = self.Frame,
	})
	self.Icon.Visible = Icons.Apply(self.Icon, options.Icon)

	self.Label = Create.new("TextLabel", {
		Name = "Label",
		LayoutOrder = 2,
		Size = UDim2.new(1, -(sizes.IconSize + sizes.IconGap), 1, 0),
		FontFace = Theme.Fonts.Page,
		Text = options.Name,
		TextSize = Theme.TextSizes.Page,
		TextColor3 = colors.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
	})

	return self
end

function PageButton:SetSelected(on, animate)
	local color = if on then Theme.Colors.Text else Theme.Colors.Muted
	Motion.Apply(self.Label, { TextColor3 = color, FontFace = if on then Theme.Fonts.PageSelected else Theme.Fonts.Page }, animate)
	Motion.Apply(self.Icon, { ImageColor3 = color }, animate)
end

return PageButton
