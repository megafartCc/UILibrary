local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Create = import("Util/Create")
local Sidebar = import("Components/Sidebar")
local PageButton = import("Components/PageButton")
local Page = import("Components/Page")

local Players = game:GetService("Players")

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

	self.Sidebar = Sidebar.new(self, options.Title or "UI Library")
	self.Sidebar.Frame.Parent = self.Frame

	Create.new("Frame", {
		Name = "Divider",
		Position = UDim2.fromOffset(sizes.SidebarWidth - 1, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = colors.Divider,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = self.Frame,
	})

	Create.new("Frame", {
		Name = "HeaderLine",
		Position = UDim2.fromOffset(0, sizes.EdgePadY + sizes.TitleHeight + sizes.PageGap / 2),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = colors.Divider,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = self.Frame,
	})

	self.CloseButton = Create.new("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -sizes.EdgePadY, 0, sizes.EdgePadY + sizes.TitleHeight / 2),
		Size = UDim2.fromOffset(sizes.CloseSize, sizes.CloseSize),
		BackgroundColor3 = colors.Selected,
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = self.Frame,
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

	self.Content = Create.new("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(sizes.SidebarWidth, 0),
		Size = UDim2.new(1, -sizes.SidebarWidth, 1, 0),
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
	self.Sidebar.Title.Text = text
	self.Gui.Name = text
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
