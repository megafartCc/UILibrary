local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")

local Elements = {
	Slider = import("Elements/Slider"),
}

local Group = {}
Group.__index = Group

function Group.new(column, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local pad = sizes.GroupPad
	local self = setmetatable({ Name = options.Name, Elements = {} }, Group)

	self.Frame = Create.new("Frame", {
		Name = "Group_" .. options.Name,
		LayoutOrder = order,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = colors.Group,
		BorderSizePixel = 0,
		Parent = column,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.GroupRadius) }),
	})

	self.Body = Create.new("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self.Frame,
		Create.Padding(pad, pad, pad, pad),
		Create.List(Enum.FillDirection.Vertical, sizes.GroupItemGap),
	})

	self.Title = Create.new("TextLabel", {
		Name = "Title",
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, sizes.GroupTitleHeight),
		FontFace = Theme.Fonts.GroupTitle,
		Text = options.Name,
		TextSize = Theme.TextSizes.GroupTitle,
		TextColor3 = colors.GroupTitle,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Body,
	})

	return self
end

function Group:_add(kind, options)
	assert(type(options) == "table" and options.Name, "UILib: Add" .. kind .. " needs a Name")
	local element = Elements[kind].new(self, options, #self.Elements + 1)
	table.insert(self.Elements, element)
	return element
end

for kind in Elements do
	Group["Add" .. kind] = function(self, options)
		return self:_add(kind, options)
	end
end

return Group
