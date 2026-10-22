local import = ...
local Theme = import("Theme")
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
		_defaultPage = options.DefaultPage,
		_userPicked = false,
	}, Window)

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
	self:_show(name)
end

function Window:Destroy()
	self.Gui:Destroy()
	table.clear(self.Pages)
	self.SelectedPage = nil
end

function Window:_show(name)
	local previous = self.Pages[self.SelectedPage]
	if previous then
		previous:SetSelected(false)
	end
	self.Pages[name]:SetSelected(true)
	self.SelectedPage = name
end

function Window:_addPage(options, layoutOrder)
	local name = options.Name
	assert(self.Pages[name] == nil, "UILib: a page named " .. name .. " already exists")

	local page = Page.new(options)
	page.LayoutOrder = layoutOrder
	page.Button = PageButton.new(options, layoutOrder)
	page.Button.Frame.Parent = self.Sidebar.Frame
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
