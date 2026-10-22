--[[
	UILib example. Run this to open a window with pages.
	Right now UILib can only create pages. More elements come later.
]]

local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/megafartCc/UILibrary/main/loader.lua"))()

-- 1. Name the window (shown top left)
local Window = UILib:CreateWindow({
	Title = "Black Box",
	DefaultPage = "Home", -- optional: page shown first
})

-- 2. Add sections, then pages. Add as many as you want.
--    Order is optional. Without it, things show in the order you add them.
local Main = Window:AddSection({ Name = "Main", Order = 1 })
Main:AddPage({ Name = "Home", Icon = "home", Order = 1 })
Main:AddPage({ Name = "Play", Icon = "play", Order = 2 })

local Items = Window:AddSection({ Name = "Items", Order = 2 })
Items:AddPage({ Name = "Shop", Icon = "shopping-bag" })
Items:AddPage({ Name = "Inventory", Icon = "package" })

local Other = Window:AddSection({ Name = "Other", Order = 3 })
local Settings = Other:AddPage({ Name = "Settings", Icon = "settings" })

-- Put your own UI inside a page with page.Body
-- local label = Instance.new("TextLabel"); label.Parent = Settings.Body

--[[
	Quick setup: the same window in one call.

	local Window = UILib:CreateWindow({
		Title = "Black Box",
		Pages = {
			{ Section = "Main", Name = "Home", Icon = "home" },
			{ Section = "Main", Name = "Play", Icon = "play" },
			{ Section = "Items", Name = "Shop", Icon = "shopping-bag" },
			{ Section = "Items", Name = "Inventory", Icon = "package" },
			{ Section = "Other", Name = "Settings", Icon = "settings" },
		},
	})
]]
