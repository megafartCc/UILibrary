local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")

local Group = {}
Group.__index = Group

function Group.new(column, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local titleSize = Theme.TextSizes.GroupTitle
	local pad = sizes.GroupPad
	local self = setmetatable({ Name = options.Name }, Group)

	self.Frame = Create.new("Frame", {
		Name = "Group_" .. options.Name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, sizes.GroupMinHeight),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = column,
		Create.new("UIStroke", { Color = colors.GroupBorder, Thickness = 1 }),
	})

	self.Title = Create.new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(sizes.GroupTitleInset, 0),
		Size = UDim2.fromOffset(0, titleSize),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = colors.Box,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		FontFace = Theme.Fonts.GroupTitle,
		Text = options.Name,
		TextSize = titleSize,
		TextColor3 = colors.GroupTitle,
		ZIndex = 2,
		Parent = self.Frame,
		Create.Padding(sizes.GroupTitlePadX, sizes.GroupTitlePadX),
	})

	self.Body = Create.new("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self.Frame,
		Create.Padding(pad, pad, pad + math.ceil(titleSize / 2), pad),
		Create.List(Enum.FillDirection.Vertical, sizes.GroupItemGap),
	})

	return self
end

return Group
