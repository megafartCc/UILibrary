local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")
local Parts = import("Util/Parts")

local Button = {}
Button.__index = Button

function Button.new(group, options, order)
	local sizes = Theme.Sizes
	local self = setmetatable({ Name = options.Name, Callback = options.Callback }, Button)

	self.Frame = Create.new("TextButton", {
		Name = "Button_" .. options.Name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, sizes.ElementHeight),
		BackgroundTransparency = 1,
		Parent = group.Body,
	})

	self.Label = Create.new("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -Parts.Trailing(true), 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = options.Name,
		TextSize = Theme.TextSizes.Element,
		TextColor3 = Theme.Colors.ElementText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
	})

	self.Square = Parts.Square(self.Frame, options.Icon)
	Parts.Hover(self, self.Frame)
	self.Frame.Activated:Connect(function()
		self:Press()
	end)

	return self
end

function Button:Press()
	self.Square.Press()
	if self.Callback then
		task.spawn(self.Callback)
	end
end

return Button
