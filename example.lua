local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/megafartCc/UILibrary/main/loader.lua"))()

local Window = UILib:CreateWindow({
	Title = "Black Box",
	DefaultPage = "Home",
})

local Main = Window:AddSection({ Name = "Main", Order = 1 })
local Home = Main:AddPage({ Name = "Home", Icon = "home", Order = 1 })
Main:AddPage({ Name = "Play", Icon = "play", Order = 2 })

local Items = Window:AddSection({ Name = "Items", Order = 2 })
Items:AddPage({ Name = "Shop", Icon = "shopping-bag" })
Items:AddPage({ Name = "Inventory", Icon = "package" })

local Other = Window:AddSection({ Name = "Other", Order = 3 })
Other:AddPage({ Name = "Settings", Icon = "settings" })

local Aimbot = Home:AddGroup({ Name = "Aimbot", Side = "Left" })
Aimbot:AddSlider({ Name = "FOV", Min = 0, Max = 100, Default = 25, Suffix = "%" })
Aimbot:AddSlider({ Name = "Smoothness", Min = 0, Max = 1, Step = 0.05, Default = 0.5 })

local Visuals = Home:AddGroup({ Name = "Visuals", Side = "Right" })
Visuals:AddSlider({
	Name = "Brightness",
	Min = 0,
	Max = 200,
	Default = 100,
	Suffix = "%",
	Callback = function(value)
		print("Brightness", value)
	end,
})

Home:AddGroup({ Name = "Misc", Side = "Left" })
Home:AddGroup({ Name = "World", Side = "Right" })
