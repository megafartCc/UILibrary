local import = ...
local Theme = import("Theme")
local Motion = import("Motion")
local Create = import("Util/Create")
local Parts = import("Util/Parts")

local UserInputService = game:GetService("UserInputService")

local PRESS = { [Enum.UserInputType.MouseButton1] = true, [Enum.UserInputType.Touch] = true }
local MOVE = { [Enum.UserInputType.MouseMovement] = true, [Enum.UserInputType.Touch] = true }

local Slider = {}
Slider.__index = Slider

local function decimalsOf(step)
	local text = tostring(step)
	local dot = string.find(text, ".", 1, true)
	return if dot then #text - dot else 0
end

function Slider.new(group, options, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local trailing = Parts.Trailing(options.Accessory)
	local self = setmetatable({
		Name = options.Name,
		Min = options.Min or 0,
		Max = options.Max or 100,
		Step = options.Step or 1,
		Suffix = options.Suffix or "",
	}, Slider)
	assert(self.Max > self.Min, "UILib: Slider Max must be greater than Min")
	self._format = "%." .. decimalsOf(self.Step) .. "f"

	self.Frame = Create.new("Frame", {
		Name = "Slider_" .. options.Name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, sizes.ElementHeight),
		BackgroundTransparency = 1,
		Parent = group.Body,
	})

	self.Label = Create.new("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1 - sizes.SliderBarWidth, -6, 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = options.Name,
		TextSize = Theme.TextSizes.Element,
		TextColor3 = colors.ElementText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Frame,
	})

	self.Track = Create.new("TextButton", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -trailing, 0.5, 0),
		Size = UDim2.new(sizes.SliderBarWidth, -trailing, 0, sizes.SliderBarHeight),
		BackgroundColor3 = colors.Track,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Frame,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.SliderRadius) }),
	})

	self.Fill = Create.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = colors.Accent,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = self.Track,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.SliderRadius) }),
	})

	self.ValueLabel = Create.new("TextLabel", {
		Name = "Value",
		Size = UDim2.fromScale(1, 1),
		FontFace = Theme.Fonts.SliderValue,
		TextSize = Theme.TextSizes.SliderValue,
		TextColor3 = colors.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
		Parent = self.Track,
	})

	local dragging = false
	local function slideTo(x, dragging)
		local track = self.Track
		local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		self:_set(self.Min + alpha * (self.Max - self.Min), true, dragging)
	end

	self.Track.InputBegan:Connect(function(input)
		if PRESS[input.UserInputType] then
			dragging = true
			slideTo(input.Position.X, false)
		end
	end)

	local connections = {
		UserInputService.InputChanged:Connect(function(input)
			if dragging and MOVE[input.UserInputType] then
				slideTo(input.Position.X, true)
			end
		end),
		UserInputService.InputEnded:Connect(function(input)
			if PRESS[input.UserInputType] then
				dragging = false
			end
		end),
	}
	self.Frame.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)

	Parts.Attach(self, self.Frame, options)
	self:_set(options.Default or self.Min, false)
	self.Callback = options.Callback
	return self
end

function Slider:Set(value)
	self:_set(value, true)
end

function Slider:_set(value, animate, dragging)
	value = math.clamp(value, self.Min, self.Max)
	value = self.Min + math.floor((value - self.Min) / self.Step + 0.5) * self.Step
	value = tonumber(string.format(self._format, math.clamp(value, self.Min, self.Max)))

	local size = UDim2.fromScale((value - self.Min) / (self.Max - self.Min), 1)
	if dragging then
		Motion.Apply(self.Fill, { Size = size }, true, Theme.Motion.DragDuration, Theme.Motion.DragStyle)
	else
		Motion.Apply(self.Fill, { Size = size }, animate)
	end
	self.ValueLabel.Text = string.format(self._format, value) .. self.Suffix

	if value ~= self.Value then
		self.Value = value
		self:_fire()
	end
end

function Slider:_fire()
	Parts.Fire(self, self.Value)
end

Slider.SetEnabled = Parts.SetEnabled

function Slider:Get()
	return self.Value
end

return Slider
