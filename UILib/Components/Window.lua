local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")
local Sidebar = import("Components/Sidebar")
local PageButton = import("Components/PageButton")
local Page = import("Components/Page")
local Search = import("Components/Search")
local Gate = import("Key/Gate")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local PRESS = { [Enum.UserInputType.MouseButton1] = true, [Enum.UserInputType.Touch] = true }
local MOVE = { [Enum.UserInputType.MouseMovement] = true, [Enum.UserInputType.Touch] = true }

local Window = {}
Window.__index = Window

function Window.new(options, library)
	options = options or {}
	local sizes, colors = Theme.Sizes, Theme.Colors
	local self = setmetatable({
		Pages = {},
		SelectedPage = nil,
		Destroyed = false,
		_defaultPage = options.DefaultPage,
		_userPicked = false,
		_onClose = {},
	}, Window)
	if options.OnClose then
		table.insert(self._onClose, options.OnClose)
	end

	self.Gui = Create.new("ScreenGui", {
		Name = options.Title or "UILib",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	self.Frame = Create.new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(options.Width or sizes.WindowWidth, options.Height or sizes.WindowHeight),
		BackgroundColor3 = colors.Box,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Gui,
	})
	self._fullSize = self.Frame.Size
	self.UIScale = Create.new("UIScale", { Scale = options.Scale or Theme.Scale, Parent = self.Frame })

	local top = sizes.HeaderHeight + 1
	local middle = top + sizes.BottomHeight + 1
	local textX = sizes.SidebarPadX + sizes.ItemPadX

	self.Header = Create.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, sizes.HeaderHeight),
		BackgroundColor3 = colors.Bar,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = self.Frame,
	})
	Create.new("Frame", {
		Name = "Line",
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = colors.Divider,
		BorderSizePixel = 0,
		Parent = self.Header,
	})

	self.Title = Create.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(0, sizes.SidebarWidth - textX - 4, 1, 0),
		FontFace = Theme.Fonts.Title,
		Text = options.Title or "UI Library",
		TextSize = Theme.TextSizes.Title,
		TextColor3 = colors.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Header,
	})

	local function headerButton(name, icon, slot, onClick)
		local right = sizes.ContentPadX - (sizes.CloseSize - sizes.CloseIconSize) / 2 + slot * (sizes.CloseSize + 2)
		local button = Create.new("TextButton", {
			Name = name,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -right, 0.5, 0),
			Size = UDim2.fromOffset(sizes.CloseSize, sizes.CloseSize),
			BackgroundColor3 = colors.Selected,
			BackgroundTransparency = 1,
			Parent = self.Header,
			Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.HighlightRadius) }),
		})
		local image = Create.new("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(sizes.CloseIconSize, sizes.CloseIconSize),
			ImageColor3 = colors.Muted,
			Parent = button,
		})
		Icons.Apply(image, icon)
		button.MouseEnter:Connect(function()
			Motion.Apply(button, { BackgroundTransparency = 0 }, true)
			Motion.Apply(image, { ImageColor3 = colors.Text }, true)
		end)
		button.MouseLeave:Connect(function()
			Motion.Apply(button, { BackgroundTransparency = 1 }, true)
			Motion.Apply(image, { ImageColor3 = colors.Muted }, true)
		end)
		button.Activated:Connect(onClick)
		return button
	end

	self.CloseButton = headerButton("Close", "x", 0, function()
		self:Destroy()
	end)
	self.MinimizeButton = headerButton("Minimize", "minus", 1, function()
		self:Minimize()
	end)

	self.Bottom = Create.new("Frame", {
		Name = "Bottom",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, sizes.BottomHeight),
		BackgroundColor3 = colors.Bar,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = self.Frame,
	})
	Create.new("Frame", {
		Name = "Line",
		Position = UDim2.fromOffset(0, -1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = colors.Divider,
		BorderSizePixel = 0,
		Parent = self.Bottom,
	})
	self.Footer = Create.new("TextLabel", {
		Name = "Footer",
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1, -textX * 2, 1, 0),
		FontFace = Theme.Fonts.Footer,
		Text = options.Footer or "",
		TextSize = Theme.TextSizes.Footer,
		TextColor3 = colors.SectionLabel,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Bottom,
	})

	self:_makeDraggable({ self.Header, self.Bottom })
	self.Search = Search.new(self)

	self.Sidebar = Sidebar.new(self)
	self.Sidebar.Frame.Parent = self.Frame

	self.Divider = Create.new("Frame", {
		Name = "Divider",
		Position = UDim2.fromOffset(sizes.SidebarWidth - 1, top),
		Size = UDim2.new(0, 1, 1, -middle),
		BackgroundColor3 = colors.Divider,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = self.Frame,
	})

	self.Content = Create.new("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(sizes.SidebarWidth, top),
		Size = UDim2.new(1, -sizes.SidebarWidth, 1, -middle),
		BackgroundTransparency = 1,
		Parent = self.Frame,
	})

	for _, pageOptions in ipairs(options.Pages or {}) do
		self:AddPage(pageOptions)
	end

	self.KeyVerified = true
	self.Gate = Gate.new(self, options, library)

	local parent = options.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
	local previous = parent:FindFirstChild(self.Gui.Name)
	if previous and previous:GetAttribute("UILib") then
		previous:Destroy()
	end
	self.Gui:SetAttribute("UILib", true)
	self.Gui.Parent = parent

	if self.Gate and options.WaitForKey ~= false then
		self.Gate:Wait()
	end
	return self
end

function Window:SetTitle(text)
	self.Title.Text = text
	self.Gui.Name = text
	if self.MiniBar then
		self.MiniBar.Title.Text = text
	end
end

function Window:SetScale(scale)
	self.UIScale.Scale = scale
end

function Window:SetFooter(text)
	self.Footer.Text = text
end

function Window:AddSection(options)
	return self.Sidebar:AddSection(options)
end

function Window:AddPage(options)
	return self:AddSection(options.Section or ""):AddPage(options)
end

function Window:GetPage(name)
	return self.Pages[name]
end

function Window:SelectPage(name)
	if not self.Pages[name] then
		warn("UILib: no page named " .. tostring(name))
		return
	end
	self._userPicked = true
	self:_show(name, true)
end

function Window:OnClose(callback)
	table.insert(self._onClose, callback)
end

function Window:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true

	for _, callback in self._onClose do
		task.spawn(callback)
	end
	table.clear(self._onClose)

	for _, page in self.Pages do
		for _, group in page.Groups do
			for _, element in group.Elements do
				element.Callback = nil
				element.Value = nil
			end
			table.clear(group.Elements)
		end
		table.clear(page.Groups)
	end

	self.Gui:Destroy()
	table.clear(self.Pages)
	self.SelectedPage = nil
end

function Window:_makeDraggable(handles, target)
	target = target or self.Frame
	local state = { Moved = false }
	local dragInput, startPointer, startPosition

	for _, handle in handles do
		handle.InputBegan:Connect(function(input)
			if PRESS[input.UserInputType] and not dragInput then
				dragInput = input
				startPointer = input.Position
				startPosition = target.Position
				state.Moved = false
			end
		end)
	end

	local function clamp(value, size, screen)
		if size >= screen then
			return value
		end
		return math.clamp(value, size / 2, screen - size / 2)
	end

	local connections = {
		UserInputService.InputChanged:Connect(function(input)
			if not dragInput or not MOVE[input.UserInputType] then
				return
			end
			if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then
				return
			end
			local screen, size = self.Gui.AbsoluteSize, target.AbsoluteSize
			local delta = input.Position - startPointer
			if math.abs(delta.X) + math.abs(delta.Y) > 4 then
				state.Moved = true
			end
			local x = clamp(startPosition.X.Scale * screen.X + startPosition.X.Offset + delta.X, size.X, screen.X)
			local y = clamp(startPosition.Y.Scale * screen.Y + startPosition.Y.Offset + delta.Y, size.Y, screen.Y)
			Motion.Apply(target, { Position = UDim2.fromOffset(x, y) }, true, Theme.Motion.DragDuration, Theme.Motion.DragStyle)
		end),
		UserInputService.InputEnded:Connect(function(input)
			if input == dragInput or (dragInput and input.UserInputType == Enum.UserInputType.MouseButton1) then
				dragInput = nil
			end
		end),
	}
	self.Gui.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	return state
end

function Window:_buildMiniBar()
	local sizes, colors = Theme.Sizes, Theme.Colors
	self.MiniBar = Create.new("TextButton", {
		Name = "Minimized",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, sizes.MiniTop + sizes.MiniHeight / 2),
		Size = UDim2.fromOffset(sizes.MiniWidth, sizes.MiniHeight),
		BackgroundColor3 = colors.Bar,
		Visible = false,
		Parent = self.Gui,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.MiniRadius) }),
		Create.new("UIStroke", { Color = colors.Divider, Thickness = 1 }),
		Create.new("UIScale", { Scale = self.UIScale.Scale }),
	})

	Create.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(sizes.MiniPad, 0),
		Size = UDim2.new(1, -(sizes.MiniPad * 2 + sizes.CloseIconSize + 6), 1, 0),
		FontFace = Theme.Fonts.Title,
		Text = self.Title.Text,
		TextSize = Theme.TextSizes.Mini,
		TextColor3 = colors.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.MiniBar,
	})

	local icon = Create.new("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -sizes.MiniPad, 0.5, 0),
		Size = UDim2.fromOffset(sizes.CloseIconSize, sizes.CloseIconSize),
		ImageColor3 = colors.Muted,
		Parent = self.MiniBar,
	})
	Icons.Apply(icon, "maximize-2")

	self.MiniBar.MouseEnter:Connect(function()
		Motion.Apply(self.MiniBar, { BackgroundColor3 = colors.Selected }, true)
		Motion.Apply(icon, { ImageColor3 = colors.Text }, true)
	end)
	self.MiniBar.MouseLeave:Connect(function()
		Motion.Apply(self.MiniBar, { BackgroundColor3 = colors.Bar }, true)
		Motion.Apply(icon, { ImageColor3 = colors.Muted }, true)
	end)

	local drag = self:_makeDraggable({ self.MiniBar }, self.MiniBar)
	self.MiniBar.Activated:Connect(function()
		if drag.Moved then
			drag.Moved = false
			return
		end
		self:Restore()
	end)
end

function Window:Minimize()
	if self.Minimized or self.Destroyed then
		return
	end
	self.Minimized = true
	if not self.MiniBar then
		self:_buildMiniBar()
	end
	self.Search:_hide()
	self.Frame.Visible = false
	self.MiniBar.Visible = true
end

function Window:Restore()
	if not self.Minimized or self.Destroyed then
		return
	end
	self.Minimized = false
	self.Frame.Visible = true
	self.MiniBar.Visible = false
end

function Window:ToggleMinimize()
	if self.Minimized then
		self:Restore()
	else
		self:Minimize()
	end
end

function Window:_show(name, animate)
	local previous = self.Pages[self.SelectedPage]
	if previous then
		previous:SetSelected(false, animate)
	end
	local page = self.Pages[name]
	page:SetSelected(true, animate)
	self.Sidebar:Highlight(page.Button, animate)
	self.SelectedPage = name
end

function Window:_addPage(options, layoutOrder)
	local name = options.Name
	assert(self.Pages[name] == nil, "UILib: a page named " .. name .. " already exists")

	local page = Page.new(options)
	page.LayoutOrder = layoutOrder
	page.Button = PageButton.new(options, layoutOrder)
	page.Button.Frame.Parent = self.Sidebar.Items
	page.Frame.Parent = self.Content
	self.Pages[name] = page

	page.Button.Activated:Connect(function()
		self:SelectPage(name)
	end)

	if not self._userPicked then
		local current = self.Pages[self.SelectedPage]
		local default = self._defaultPage
		if not current or name == default or (not default and layoutOrder < current.LayoutOrder) then
			self:_show(name)
		end
	end
	return page
end

return Window
