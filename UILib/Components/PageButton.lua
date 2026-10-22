local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local PageButton = {}
PageButton.__index = PageButton

function PageButton.new(options, layoutOrder)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local self = setmetatable({ Selected = false, Hovered = false }, PageButton)

	self.Frame = Create.new("TextButton", {
		Name = "Page_" .. options.Name,
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, 0, 0, sizes.RowHeight),
		BackgroundColor3 = colors.Hover,
		BackgroundTransparency = 1,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.HighlightRadius) }),
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

	self.Frame.MouseEnter:Connect(function()
		self.Hovered = true
		self:_refresh(true)
	end)
	self.Frame.MouseLeave:Connect(function()
		self.Hovered = false
		self:_refresh(true)
	end)

	return self
end

function PageButton:SetSelected(on, animate)
	self.Selected = on
	self:_refresh(animate)
end

function PageButton:_refresh(animate)
	local colors = Theme.Colors
	local hover = self.Hovered and not self.Selected
	local color = if self.Selected then colors.Text elseif hover then colors.HoverText else colors.Muted
	Motion.Apply(self.Frame, { BackgroundTransparency = if hover then 0 else 1 }, animate)
	Motion.Apply(self.Label, { TextColor3 = color, FontFace = if self.Selected then Theme.Fonts.PageSelected else Theme.Fonts.Page }, animate)
	Motion.Apply(self.Icon, { ImageColor3 = color }, animate)
end

return PageButton
