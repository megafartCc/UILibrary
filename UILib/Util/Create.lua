local Create = {}

local DEFAULTS = {
	TextLabel = { BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left },
	ImageLabel = { BackgroundTransparency = 1 },
	TextButton = { AutoButtonColor = false, Text = "" },
}

local function assign(instance, props)
	for key, value in props do
		if type(key) == "number" then
			value.Parent = instance
		elseif key ~= "Parent" then
			instance[key] = value
		end
	end
end

function Create.new(className, props)
	local instance = Instance.new(className)
	if DEFAULTS[className] then
		assign(instance, DEFAULTS[className])
	end
	if props then
		assign(instance, props)
		if props.Parent then
			instance.Parent = props.Parent
		end
	end
	return instance
end

function Create.Padding(left, right, top, bottom)
	return Create.new("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
	})
end

function Create.List(direction, gap)
	local list = Create.new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	if direction == Enum.FillDirection.Horizontal then
		list.VerticalAlignment = Enum.VerticalAlignment.Center
	end
	return list
end

return Create
