local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local PageButton = {}
PageButton.__index = PageButton

function PageButton.new(options, layoutOrder)
	local self = setmetatable({}, PageButton)
	local sizes, colors = Theme.Sizes, Theme.Colors

	self.Frame = Create.new("TextButton", {
		Name = "Page_" .. options.Name,
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, 0, 0, sizes.RowHeight),
		BackgroundColor3 = colors.Selected,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, {
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.HighlightRadius) }),
		Create.Padding(sizes.ItemPadX, sizes.ItemPadX, 0, 0),
		Create.List(Enum.FillDirection.Horizontal, sizes.IconGap),
	})
	self.Activated = self.Frame.Activated

	self.Icon = Create.new("ImageLabel", {
		Name = "Icon",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(sizes.IconSize, sizes.IconSize),
		BackgroundTransparency = 1,
		ImageColor3 = colors.Muted,
		Parent = self.Frame,
	})
	self.Icon.Visible = Icons.Apply(self.Icon, options.Icon)

	self.Label = Create.new("TextLabel", {
		Name = "Label",
		LayoutOrder = 2,
		Size = UDim2.new(1, -(sizes.IconSize + sizes.IconGap), 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Fonts.Page,
		Text = options.Name,
		TextSize = Theme.TextSizes.Page,
		TextColor3 = colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
	})

	return self
end

function PageButton:SetSelected(on)
	local colors = Theme.Colors
	local color = on and colors.Text or colors.Muted

	Motion.Apply(self.Frame, { BackgroundTransparency = on and 0 or 1 })
	Motion.Apply(self.Label, {
		TextColor3 = color,
		Font = on and Theme.Fonts.PageSelected or Theme.Fonts.Page,
	})
	Motion.Apply(self.Icon, { ImageColor3 = color })
end

return PageButton
