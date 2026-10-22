local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")
local Sidebar = import("Components/Sidebar")
local PageButton = import("Components/PageButton")
local Page = import("Components/Page")
local Search = import("Components/Search")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local PRESS = { [Enum.UserInputType.MouseButton1] = true, [Enum.UserInputType.Touch] = true }
local MOVE = { [Enum.UserInputType.MouseMovement] = true, [Enum.UserInputType.Touch] = true }

local Window = {}
Window.__index = Window

function Window.new(options)
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
		Create.new("UIStroke", { Color = colors.Text, Thickness = sizes.SerifBold }),
	})

	self.CloseButton = Create.new("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(sizes.ContentPadX - (sizes.CloseSize - sizes.CloseIconSize) / 2), 0.5, 0),
		Size = UDim2.fromOffset(sizes.CloseSize, sizes.CloseSize),
		BackgroundColor3 = colors.Selected,
		BackgroundTransparency = 1,
		Parent = self.Header,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.HighlightRadius) }),
	})
	local closeIcon = Create.new("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(sizes.CloseIconSize, sizes.CloseIconSize),
		ImageColor3 = colors.Muted,
		Parent = self.CloseButton,
	})
	Icons.Apply(closeIcon, "x")
	self.CloseButton.MouseEnter:Connect(function()
		Motion.Apply(self.CloseButton, { BackgroundTransparency = 0 }, true)
		Motion.Apply(closeIcon, { ImageColor3 = colors.Text }, true)
	end)
	self.CloseButton.MouseLeave:Connect(function()
		Motion.Apply(self.CloseButton, { BackgroundTransparency = 1 }, true)
		Motion.Apply(closeIcon, { ImageColor3 = colors.Muted }, true)
	end)
	self.CloseButton.Activated:Connect(function()
		self:Destroy()
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
		TextColor3 = colors.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Bottom,
		Create.new("UIStroke", { Color = colors.Muted, Thickness = sizes.SerifBold }),
	})

	self:_makeDraggable({ self.Header, self.Bottom })
	self.Search = Search.new(self)

	self.Sidebar = Sidebar.new(self)
	self.Sidebar.Frame.Parent = self.Frame

	Create.new("Frame", {
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

	self.Gui.Parent = options.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
	return self
end

function Window:SetTitle(text)
	self.Title.Text = text
	self.Gui.Name = text
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

function Window:_makeDraggable(handles)
	local dragInput, startPointer, startPosition

	for _, handle in handles do
		handle.InputBegan:Connect(function(input)
			if PRESS[input.UserInputType] and not dragInput then
				dragInput = input
				startPointer = input.Position
				startPosition = self.Frame.Position
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
			local screen, size = self.Gui.AbsoluteSize, self.Frame.AbsoluteSize
			local delta = input.Position - startPointer
			local x = clamp(startPosition.X.Scale * screen.X + startPosition.X.Offset + delta.X, size.X, screen.X)
			local y = clamp(startPosition.Y.Scale * screen.Y + startPosition.Y.Offset + delta.Y, size.Y, screen.Y)
			Motion.Apply(self.Frame, { Position = UDim2.fromOffset(x, y) }, true, Theme.Motion.DragDuration, Theme.Motion.DragStyle)
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
