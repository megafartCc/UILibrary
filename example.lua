local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/megafartCc/UILibrary/main/loader.lua"))()

local Window = UILib:CreateWindow({
	Title = "Black Box",
	DefaultPage = "Home",
	OnClose = function()
		print("UI closed")
	end,
})

local Main = Window:AddSection({ Name = "Main", Order = 1 })
local Home = Main:AddPage({ Name = "Home", Icon = "home", Order = 1 })
Main:AddPage({ Name = "Play", Icon = "play", Order = 2 })

local Items = Window:AddSection({ Name = "Items", Order = 2 })
Items:AddPage({ Name = "Shop", Icon = "shopping-bag" })
Items:AddPage({ Name = "Inventory", Icon = "package" })

local Other = Window:AddSection({ Name = "Other", Order = 3 })
Other:AddPage({ Name = "Settings", Icon = "settings" })

local Aimbot = Home:AddGroup({ Name = "AIMBOT", Side = "Left" })
Aimbot:AddToggle({
	Name = "Enabled",
	Default = true,
	Callback = function(on)
		print("Aimbot", on)
	end,
})
Aimbot:AddToggle({ Name = "Team Check" })
Aimbot:AddDropdown({
	Name = "Target Part",
	Options = { "Head", "Torso", "Closest" },
	Default = "Head",
	Callback = function(part)
		print("Target Part", part)
	end,
})
Aimbot:AddSlider({ Name = "FOV", Min = 0, Max = 100, Default = 25, Suffix = "%" })
Aimbot:AddSlider({ Name = "Smoothness", Min = 0, Max = 1, Step = 0.05, Default = 0.5 })

local Visuals = Home:AddGroup({ Name = "VISUALS", Side = "Right" })
Visuals:AddSliderToggle({
	Name = "Field of View",
	Min = 70,
	Max = 120,
	Default = 90,
	Enabled = false,
	Callback = function(value, enabled)
		print("FOV", value, enabled)
	end,
})
Visuals:AddDropdownToggle({
	Name = "Skybox",
	Options = { "Default", "Night", "Space" },
	Default = "Night",
	Callback = function(choice, enabled)
		print("Skybox", choice, enabled)
	end,
})
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

local Misc = Home:AddGroup({ Name = "MISC", Side = "Left" })
Misc:AddDropdownButton({
	Name = "Teleport",
	Options = { "Spawn", "Shop", "Arena" },
	Default = "Spawn",
	Callback = function(place)
		UILib:Notify({ Title = "Teleport", Text = "Going to " .. place })
	end,
})
Misc:AddToggle({ Name = "Anti AFK", Default = true })
Misc:AddToggle({ Name = "Auto Respawn" })
Misc:AddButton({
	Name = "Rejoin",
	Callback = function()
		UILib:Notify({ Title = "Rejoin", Text = "Rejoining the server...", Duration = 3 })
	end,
})
local World = Home:AddGroup({ Name = "WORLD", Side = "Right" })
World:AddDropdown({
	Name = "ESP Targets",
	Multi = true,
	Options = { "Players", "NPCs", "Items", "Chests" },
	Default = { "Players" },
	Callback = function(selected)
		print("ESP Targets", table.concat(selected, ", "))
	end,
})

UILib:Notify({ Title = "Black Box", Text = "Loaded successfully", Duration = 4 })
