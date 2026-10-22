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

local function space(group, height)
	local filler = Instance.new("Frame")
	filler.BackgroundTransparency = 1
	filler.Size = UDim2.new(1, 0, 0, height)
	filler.Parent = group.Body
end

space(Home:AddGroup({ Name = "Aimbot", Side = "Left" }), 90)
space(Home:AddGroup({ Name = "Visuals", Side = "Right" }), 30)
space(Home:AddGroup({ Name = "Misc", Side = "Left" }), 20)
space(Home:AddGroup({ Name = "World", Side = "Right" }), 110)
