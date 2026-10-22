local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")
local Group = import("Components/Group")

local Page = {}
Page.__index = Page

local function column(name, x, parent)
	local sizes = Theme.Sizes
	return Create.new("Frame", {
		Name = name,
		Position = UDim2.new(x, if x == 0 then 0 else sizes.ColumnGap / 2, 0, 0),
		Size = UDim2.new(0.5, -sizes.ColumnGap / 2, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
		Create.Padding(0, 0, sizes.GroupTitleRaise + 1, 1),
		Create.List(Enum.FillDirection.Vertical, sizes.GroupGap),
	})
end

function Page.new(options)
	local sizes = Theme.Sizes
	local padX, padY = sizes.ContentPadX, sizes.EdgePadY
	local self = setmetatable({ Name = options.Name, Groups = {}, _counts = { Left = 0, Right = 0 } }, Page)

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
		Size = UDim2.new(1, -(sizes.CloseSize + 4), 0, sizes.TitleHeight),
		FontFace = Theme.Fonts.Title,
		Text = options.Name,
		TextSize = Theme.TextSizes.PageTitle,
		TextColor3 = Theme.Colors.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
	})

	self.Body = Create.new("ScrollingFrame", {
		Name = "Body",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 1, -(sizes.TitleHeight + sizes.PageGap)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = self.Frame,
	})

	self.Columns = {
		Left = column("Left", 0, self.Body),
		Right = column("Right", 0.5, self.Body),
	}

	return self
end

function Page:AddGroup(options)
	if type(options) == "string" then
		options = { Name = options }
	end
	assert(type(options) == "table" and options.Name, "UILib: AddGroup needs a Name")

	local side = options.Side
	if side ~= "Left" and side ~= "Right" then
		side = if self._counts.Right < self._counts.Left then "Right" else "Left"
	end
	self._counts[side] += 1

	local group = Group.new(self.Columns[side], options, #self.Groups + 1)
	table.insert(self.Groups, group)
	return group
end

function Page:SetSelected(on, animate)
	self.Frame.Visible = on
	if self.Button then
		self.Button:SetSelected(on, animate)
	end
end

return Page
