local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local FOLDER = "sealixo"
local LIB_PATH = FOLDER .. "/sealixouilib.lua"
local DATA_PATH = FOLDER .. "/data.json"
local NOTES_PATH = FOLDER .. "/notes.txt"
local EXPORT_PATH = FOLDER .. "/config.json"
local SOURCE_URL = ""

local CANDIDATES = {
	"sealixouilib.lua",
	"sealixouilib.txt",
	"sealixouilib (1).txt",
	"sealixouilib (1).lua",
}

assert(readfile and writefile and isfile, "This executor has no readfile/writefile")

local function exists(path)
	local ok, result = pcall(isfile, path)
	return ok and result
end

local function ensureFolder()
	if makefolder and not (isfolder and isfolder(FOLDER)) then
		pcall(makefolder, FOLDER)
	end
end

local function readText(path)
	if not exists(path) then
		return nil
	end
	local ok, text = pcall(readfile, path)
	return if ok then text else nil
end

local function writeText(path, text)
	ensureFolder()
	return pcall(writefile, path, text)
end

local function readJson(path)
	local text = readText(path)
	if not text or text == "" then
		return nil
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, text)
	return if ok then data else nil
end

local function writeJson(path, data)
	local ok, text = pcall(HttpService.JSONEncode, HttpService, data)
	return ok and writeText(path, text)
end

local function librarySource()
	local cached = readText(LIB_PATH)
	if cached and cached ~= "" then
		return cached
	end
	for _, name in CANDIDATES do
		local source = readText(name)
		if source and source ~= "" then
			writeText(LIB_PATH, source)
			return source
		end
	end
	if SOURCE_URL ~= "" then
		local source = game:HttpGet(SOURCE_URL)
		writeText(LIB_PATH, source)
		return source
	end
	error("sealixouilib not found. Put sealixouilib.lua in your executor's workspace folder.", 0)
end

local chunk, compileError = loadstring(librarySource(), "=sealixouilib")
assert(chunk, compileError)
local Library = chunk()

local data = readJson(DATA_PATH) or {}
data.Launches = (tonumber(data.Launches) or 0) + 1
data.LastLaunch = os.date("%Y-%m-%d %H:%M:%S")
writeJson(DATA_PATH, data)

local ICONS = {
	Main = "rbxassetid://10723356830",
	Visuals = "rbxassetid://10734910430",
	Files = "rbxassetid://10734941499",
	About = "rbxassetid://10734966248",
}

local function options(list)
	local result = {}
	for _, value in list do
		table.insert(result, { Label = value, Value = value })
	end
	return result
end

local function notify(title, content, duration)
	Library:Notify({ Title = title, Content = content, Duration = duration or 3 })
end

local function humanoid()
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local Window = Library:CreateWindow({
	Title = "Sealixo Example",
	Sidebar = { Subtitle = "loaded from " .. LIB_PATH },
	Theme = "Default",
})

local state = { Speed = false, WalkSpeed = 16, JumpPower = 50 }

local function applyMovement()
	local hum = humanoid()
	if not hum then
		return
	end
	hum.WalkSpeed = if state.Speed then state.WalkSpeed else 16
	hum.UseJumpPower = true
	hum.JumpPower = state.JumpPower
end

local Main = Window:AddTab({ Title = "Main", Image = ICONS.Main, Columns = 2 })

local Movement = Main.Left:AddSection("Movement")
Movement:AddToggle("Speed boost", {
	Idx = "speed_enabled",
	Desc = "Uses the walk speed below",
	Default = false,
	Callback = function(on)
		state.Speed = on
		applyMovement()
	end,
})
Movement:AddSlider("Walk speed", {
	Idx = "walk_speed",
	Min = 16,
	Max = 100,
	Step = 1,
	Suffix = "",
	Default = 16,
	Callback = function(value)
		state.WalkSpeed = value
		applyMovement()
	end,
})
Movement:AddSlider("Jump power", {
	Idx = "jump_power",
	Min = 0,
	Max = 200,
	Step = 5,
	Suffix = "",
	Default = 50,
	Callback = function(value)
		state.JumpPower = value
		applyMovement()
	end,
})

local Controls = Main.Right:AddSection("Controls")
Controls:AddKeybind("Toggle UI", {
	Idx = "toggle_ui",
	Default = "RightShift",
	Mode = "Press",
	Callback = function()
		Window:ToggleVisible()
	end,
})
Controls:AddKeybind("Hold to sprint", {
	Idx = "sprint_key",
	Default = "LeftShift",
	Mode = "Hold",
	Callback = function(held)
		local hum = humanoid()
		if hum then
			hum.WalkSpeed = if held then 32 else (if state.Speed then state.WalkSpeed else 16)
		end
	end,
})
Controls:AddButton("Reset character", {
	Desc = "Respawns you",
	Callback = function()
		local hum = humanoid()
		if hum then
			hum.Health = 0
		end
	end,
})

local Advanced = Main:AddSubTab("Advanced", 1)
local Tuning = Advanced:AddSection("Tuning")
Tuning:AddSlider("Field of view", {
	Idx = "fov",
	Min = 70,
	Max = 120,
	Step = 1,
	Suffix = "°",
	Default = 70,
	Callback = function(value)
		workspace.CurrentCamera.FieldOfView = value
	end,
})
Tuning:AddToggle("Full bright", {
	Idx = "full_bright",
	Default = false,
	Callback = function(on)
		game:GetService("Lighting").Brightness = if on then 3 else 1
	end,
})

local Visuals = Window:AddTab({ Title = "Visuals", Image = ICONS.Visuals, Columns = 2 })

local Esp = Visuals.Left:AddSection("ESP")
Esp:AddToggle("Enabled", { Idx = "esp_enabled", Default = false })
Esp:AddDropdown("Target part", {
	Idx = "esp_part",
	Options = options({ "Head", "Torso", "HumanoidRootPart" }),
	Default = { "Head" },
	Callback = function(value)
		print("Target part", value)
	end,
})
Esp:AddDropdown("Show", {
	Idx = "esp_targets",
	Desc = "Pick as many as you want",
	Options = options({ "Players", "NPCs", "Items", "Chests" }),
	MaxSelection = 0,
	Default = { "Players" },
	Placeholder = "Nothing",
	Callback = function(values)
		print("ESP targets", table.concat(values, ", "))
	end,
})

local Colors = Visuals.Right:AddSection("Colors")
Colors:AddColorPicker("ESP color", {
	Idx = "esp_color",
	Default = Color3.fromRGB(255, 70, 95),
	Callback = function(color, alpha)
		print("ESP color", color:ToHex(), alpha)
	end,
})
Colors:AddColorPicker("Glow", {
	Idx = "glow_color",
	Default = Color3.fromRGB(110, 160, 255),
	Alpha = 0.5,
})
Colors:AddDropdown("Theme", {
	Options = options(Library:GetThemes()),
	Default = { Library:GetCurrentThemeName() },
	Callback = function(name)
		if name then
			Library:SetTheme(name)
		end
	end,
})

local Files = Window:AddTab({ Title = "Files", Image = ICONS.Files, Columns = 2 })

local Notes = Files.Left:AddSection("Notes")
Notes:AddInput("Note", {
	Desc = "Saved to " .. NOTES_PATH .. " with writefile",
	Default = readText(NOTES_PATH) or "",
	Placeholder = "Type something",
	Callback = function(text)
		if writeText(NOTES_PATH, text) then
			notify("Saved", "Note written to " .. NOTES_PATH)
		end
	end,
})
Notes:AddButton("Read note", {
	Callback = function()
		local text = readText(NOTES_PATH)
		notify("readfile", if text and text ~= "" then text else "No note saved yet")
	end,
})

local Config = Files.Right:AddSection("Config file")
Config:AddButton("Export config", {
	Desc = "Writes every control to " .. EXPORT_PATH,
	Callback = function()
		local snapshot = Library:Snapshot("export")
		if snapshot and writeJson(EXPORT_PATH, snapshot) then
			notify("Exported", EXPORT_PATH)
		else
			notify("Export failed", "Could not write " .. EXPORT_PATH)
		end
	end,
})
Config:AddButton("Import config", {
	Desc = "Reads " .. EXPORT_PATH .. " back in",
	Callback = function()
		local snapshot = readJson(EXPORT_PATH)
		if type(snapshot) ~= "table" then
			notify("Import failed", "No config at " .. EXPORT_PATH)
			return
		end
		Library:Apply(snapshot)
		notify("Imported", EXPORT_PATH)
	end,
})
Config:AddButton("Delete cached library", {
	Variant = "Destructive",
	Desc = "Next run copies it again from the workspace",
	Callback = function()
		if delfile and exists(LIB_PATH) then
			pcall(delfile, LIB_PATH)
			notify("Deleted", LIB_PATH)
		end
	end,
})

local About = Window:AddTab({ Title = "About", Image = ICONS.About, Columns = 1 })
local Info = About:AddSection("Info")
Info:AddParagraph({
	Title = "Local loading",
	Content = "The library is read from " .. LIB_PATH .. " with readfile and run with loadstring. Nothing is downloaded.",
})
Info:AddInfoRow("Library version", { Value = Library.Version or "?" })
Info:AddInfoRow("Launches", { Value = data.Launches })
Info:AddInfoRow("Last launch", { Value = data.LastLaunch })
Info:AddLabel("Press RightShift to hide or show the window.")
Info:AddButton("Unload", {
	Variant = "Destructive",
	Callback = function()
		Window:Confirm({
			Title = "Unload UI",
			Content = "Close the window and remove the UI?",
			Actions = {
				{
					Id = "yes",
					Label = "Unload",
					Variant = "Destructive",
					Callback = function()
						Library:Destroy()
					end,
				},
				{ Id = "no", Label = "Cancel", Variant = "Secondary" },
			},
		})
	end,
})

Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	applyMovement()
end)

notify("Sealixo Example", "Loaded from disk (launch #" .. data.Launches .. ")", 4)
