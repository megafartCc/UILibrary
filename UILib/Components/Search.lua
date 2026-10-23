local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")

local UserInputService = game:GetService("UserInputService")

local PRESS = { [Enum.UserInputType.MouseButton1] = true, [Enum.UserInputType.Touch] = true }

local Search = {}
Search.__index = Search

local function matches(text, query)
	return string.find(string.lower(tostring(text)), query, 1, true) ~= nil
end

local function inside(gui, position)
	local origin, size = gui.AbsolutePosition, gui.AbsoluteSize
	return position.X >= origin.X and position.X <= origin.X + size.X and position.Y >= origin.Y and position.Y <= origin.Y + size.Y
end

function Search.new(window)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local self = setmetatable({ Window = window, _rows = {} }, Search)

	self.Frame = Create.new("Frame", {
		Name = "Search",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(sizes.SearchWidth, sizes.SearchHeight),
		BackgroundColor3 = colors.Search,
		BorderSizePixel = 0,
		Parent = window.Header,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.SearchRadius) }),
	})

	local icon = Create.new("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(sizes.SearchIconSize, sizes.SearchIconSize),
		ImageColor3 = colors.Muted,
		Parent = self.Frame,
	})
	Icons.Apply(icon, "search")

	self.Box = Create.new("TextBox", {
		Name = "Input",
		Position = UDim2.fromOffset(sizes.SearchIconSize + 14, 0),
		Size = UDim2.new(1, -(sizes.SearchIconSize + 20), 1, 0),
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = colors.Muted,
		FontFace = Theme.Fonts.Element,
		TextSize = Theme.TextSizes.Search,
		TextColor3 = colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Frame,
	})

	self.Results = Create.new("Frame", {
		Name = "SearchResults",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, sizes.HeaderHeight + 4 - sizes.ResultsSlide),
		Size = UDim2.fromOffset(sizes.ResultsWidth, 0),
		BackgroundColor3 = colors.Results,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 10,
		Parent = window.Frame,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.SearchRadius) }),
		Create.Padding(4, 4, 4, 4),
		Create.List(Enum.FillDirection.Vertical, 0),
	})

	self._stroke = Create.new("UIStroke", { Color = colors.Divider, Thickness = 1, Transparency = 1, Parent = self.Results })
	self._token = 0
	self.Shown = false

	self.Box:GetPropertyChangedSignal("Text"):Connect(function()
		self:_update()
	end)
	self.Box.Focused:Connect(function()
		self:_update()
	end)
	self.Box.FocusLost:Connect(function(enterPressed)
		if enterPressed and self._first then
			self:_open(self._first)
		end
	end)

	local connection = UserInputService.InputBegan:Connect(function(input)
		if PRESS[input.UserInputType] and self.Shown then
			task.defer(function()
				if not inside(self.Results, input.Position) and not inside(self.Frame, input.Position) then
					self:_hide()
				end
			end)
		end
	end)
	self.Frame.Destroying:Connect(function()
		connection:Disconnect()
	end)

	return self
end

function Search:Find(query)
	query = string.lower(query)
	local results = {}
	local pages = {}
	for _, page in self.Window.Pages do
		table.insert(pages, page)
	end
	table.sort(pages, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for _, page in pages do
		if matches(page.Name, query) then
			table.insert(results, { Text = page.Name, Path = "Page", Page = page })
		end
		for _, group in page.Groups do
			if matches(group.Name, query) then
				table.insert(results, { Text = group.Name, Path = page.Name, Page = page, Group = group })
			end
			for _, element in group.Elements do
				if matches(element.Name, query) then
					table.insert(results, {
						Text = element.Name,
						Path = page.Name .. " › " .. group.Name,
						Page = page,
						Group = group,
						Element = element,
					})
				end
			end
		end
	end
	return results
end

function Search:_clear()
	for _, row in self._rows do
		row:Destroy()
	end
	table.clear(self._rows)
end

function Search:_update()
	self._first = nil
	local query = string.match(self.Box.Text, "^%s*(.-)%s*$")
	if query == "" then
		self:_hide()
		return
	end

	self:_clear()
	local results = self:Find(query)
	self._first = results[1]
	for index = 1, math.min(#results, Theme.Sizes.MaxResults) do
		table.insert(self._rows, self:_row(results[index], index))
	end
	if #results == 0 then
		table.insert(self._rows, self:_row({ Text = "No results", Path = "" }, 1))
	end
	self:_show(#self._rows)
end

function Search:_show(count)
	local sizes = Theme.Sizes
	self._token += 1
	if not self.Shown then
		self.Shown = true
		self.Results.Visible = true
	end
	Motion.Apply(self.Results, {
		Size = UDim2.fromOffset(sizes.ResultsWidth, count * sizes.ResultHeight + 8),
		Position = UDim2.new(0.5, 0, 0, sizes.HeaderHeight + 4),
		BackgroundTransparency = 0,
	}, true)
	Motion.Apply(self._stroke, { Transparency = 0 }, true)
end

function Search:_hide()
	if not self.Shown then
		return
	end
	local sizes = Theme.Sizes
	self.Shown = false
	self._token += 1
	local token = self._token
	Motion.Apply(self.Results, {
		Size = UDim2.fromOffset(sizes.ResultsWidth, 0),
		Position = UDim2.new(0.5, 0, 0, sizes.HeaderHeight + 4 - sizes.ResultsSlide),
		BackgroundTransparency = 1,
	}, true)
	Motion.Apply(self._stroke, { Transparency = 1 }, true)
	task.delay(Theme.Motion.Duration, function()
		if self._token == token then
			self.Results.Visible = false
			self:_clear()
		end
	end)
end

function Search:_row(result, order)
	local sizes, colors = Theme.Sizes, Theme.Colors
	local row = Create.new("TextButton", {
		Name = "Result",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, sizes.ResultHeight),
		BackgroundColor3 = colors.ResultHover,
		BackgroundTransparency = 1,
		Parent = self.Results,
		Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
		Create.Padding(8, 8),
	})

	Create.new("TextLabel", {
		Name = "Name",
		Size = UDim2.new(0.5, 0, 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = result.Text,
		TextSize = Theme.TextSizes.Element,
		TextColor3 = if result.Page then colors.Text else colors.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	Create.new("TextLabel", {
		Name = "Path",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.5, -6, 1, 0),
		FontFace = Theme.Fonts.Element,
		Text = result.Path,
		TextSize = Theme.TextSizes.ResultPath,
		TextColor3 = colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	if result.Page then
		row.MouseEnter:Connect(function()
			Motion.Apply(row, { BackgroundTransparency = 0 }, true)
		end)
		row.MouseLeave:Connect(function()
			Motion.Apply(row, { BackgroundTransparency = 1 }, true)
		end)
		row.Activated:Connect(function()
			self:_open(result)
		end)
	end
	return row
end

function Search:_open(result)
	self.Box.Text = ""
	self.Box:ReleaseFocus()
	self:_update()
	self.Window:SelectPage(result.Page.Name)
	if result.Group then
		if result.Group.Collapsed then
			result.Group:SetCollapsed(false, false)
		end
		task.defer(function()
			result.Page:Reveal(result.Group, result.Element, self.Window.UIScale.Scale)
		end)
	end
end

return Search
