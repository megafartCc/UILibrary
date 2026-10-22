-- Window: the black box with sharp corners. Holds the sidebar and the pages.

local import = ...
local Theme = import("Theme")
local Create = import("Util/Create")
local Sidebar = import("Components/Sidebar")
local Page = import("Components/Page")

local Players = game:GetService("Players")

local Window = {}
Window.__index = Window

--[[
	options:
		Title   = "Black Box"          -- name shown top left
		Width, Height                  -- optional, defaults from Theme
		Parent                         -- optional, defaults to PlayerGui
		DefaultPage = "Home"           -- optional, otherwise the first page in order
		Pages = { ... }                -- optional quick setup, see README
]]
function Window.new(options)
	options = options or {}
	local self = setmetatable({}, Window)
	local sizes, colors = Theme.Sizes, Theme.Colors

	self.Pages = {}
	self.SelectedPage = nil
	self._userPicked = false
	self._defaultPage = options.DefaultPage
	self._sections = {}

	self.Gui = Create.new("ScreenGui", {
		Name = options.Title or "UILib",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	-- No UICorner: the box keeps sharp corners.
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

	-- 1px line between sidebar and content
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

	-- Quick setup: Pages = { { Name = "Home", Icon = "home", Section = "Main" }, ... }
	if type(options.Pages) == "table" then
		for _, pageOptions in ipairs(options.Pages) do
			self:AddPage(pageOptions)
		end
	end

	self.Gui.Parent = options.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
	return self
end

-- Change the window name (top left)
function Window:SetTitle(text)
	self.Sidebar:SetTitle(text)
	self.Gui.Name = text
end

-- AddSection("Main") or AddSection({ Name = "Main", Order = 1 })
function Window:AddSection(options)
	local section = self.Sidebar:AddSection(options)
	self._sections[section.Name] = section
	return section
end

-- Add a page straight to the window. Uses options.Section (created if needed),
-- or a section with no label when no Section is given.
function Window:AddPage(options)
	local sectionName = options.Section or ""
	local section = self._sections[sectionName]
	if not section then
		section = self:AddSection({ Name = sectionName, ShowLabel = sectionName ~= "" })
	end
	return section:AddPage(options)
end

function Window:GetPage(name)
	return self.Pages[name]
end

-- Called by Section:AddPage
function Window:_registerPage(options, button, layoutOrder)
	assert(self.Pages[options.Name] == nil, "UILib: a page named " .. options.Name .. " already exists")

	local page = Page.new(options)
	page.Frame.Parent = self.Content
	page.Button = button
	page.LayoutOrder = layoutOrder
	self.Pages[options.Name] = page

	button.Activated:Connect(function()
		self._userPicked = true
		self:SelectPage(options.Name)
	end)

	-- Until someone picks a page, show the default page or the first one in order.
	if not self._userPicked then
		if self._defaultPage then
			if options.Name == self._defaultPage then
				self:SelectPage(options.Name)
			elseif self.SelectedPage == nil then
				self:SelectPage(options.Name)
			end
		else
			local current = self.SelectedPage and self.Pages[self.SelectedPage]
			if not current or layoutOrder < current.LayoutOrder then
				self:SelectPage(options.Name)
			end
		end
	end
	return page
end

function Window:SelectPage(name)
	if not self.Pages[name] then
		warn("UILib: no page named " .. tostring(name))
		return
	end
	for pageName, page in pairs(self.Pages) do
		local on = pageName == name
		page:SetVisible(on)
		page.Button:SetSelected(on)
	end
	self.SelectedPage = name
end

function Window:Destroy()
	self.Gui:Destroy()
end

return Window
