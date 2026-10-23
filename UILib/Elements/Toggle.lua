local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")
local Parts = import("Util/Parts")

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(group, options, order)
	local sizes = Theme.Sizes
	local self = setmetatable({ Name = options.Name }, Toggle)

	self.Frame = Create.new("TextButton", {
		Name = "Toggle_" .. options.Name,
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

	self.Switch = Parts.Switch(self.Frame)
	Parts.Hover(self, self.Frame)
	self.Frame.Activated:Connect(function()
		self:Set(not self.Value)
	end)

	self:_set(options.Default == true, false)
	self.Callback = options.Callback
	return self
end

function Toggle:Set(value)
	self:_set(value == true, true)
end

function Toggle:_set(value, animate)
	self.Switch.Set(value, animate)
	if value ~= self.Value then
		self.Value = value
		if self.Callback then
			task.spawn(self.Callback, value)
		end
	end
end

function Toggle:Get()
	return self.Value
end

return Toggle
