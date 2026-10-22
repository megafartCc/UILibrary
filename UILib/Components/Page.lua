local import = ...
local Theme = import("Theme")
local Motion = import("Motion")
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
	})

	self.Body = Create.new("ScrollingFrame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
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
	group.Page = self
	table.insert(self.Groups, group)
	return group
end

function Page:Reveal(group, element, scale)
	scale = scale or 1
	local body = self.Body
	local offset = (group.Frame.AbsolutePosition.Y - body.AbsolutePosition.Y) / scale
	local y = offset + body.CanvasPosition.Y - Theme.Sizes.GroupTitleRaise - 4
	Motion.Apply(body, { CanvasPosition = Vector2.new(0, math.max(y, 0)) }, true)

	local colors, motion = Theme.Colors, Theme.Motion
	group.Frame.BackgroundColor3 = colors.Flash
	Motion.Apply(group.Frame, { BackgroundColor3 = colors.Group }, true, motion.FlashDuration, Enum.EasingStyle.Quad)
	if element and element.Label then
		element.Label.TextColor3 = colors.Accent
		Motion.Apply(element.Label, { TextColor3 = colors.ElementText }, true, motion.FlashDuration, Enum.EasingStyle.Quad)
	end
end

function Page:SetSelected(on, animate)
	self.Frame.Visible = on
	if self.Button then
		self.Button:SetSelected(on, animate)
	end
end

return Page
