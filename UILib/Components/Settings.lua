local import = ...
local Notifications = import("Components/Notifications")

local Settings = {}

local function notify(title, text, kind)
	Notifications.Notify({ Title = title, Text = text, Type = kind, Duration = 3 })
end

function Settings.Build(window, options)
	local config = window.Config
	local syncing = false

	local section = window:AddSection({ Name = "Settings", Order = 100000, ShowLabel = false })
	local page = section:AddPage({ Name = options.SettingsName or "Settings", Icon = "settings" })

	local configs = page:AddGroup({ Name = "CONFIGS", Side = "Left" })
	configs.NoConfig = true
	local interface = page:AddGroup({ Name = "INTERFACE", Side = "Right" })
	interface.NoConfig = true

	local nameInput = configs:AddInput({ Name = "Name", Placeholder = "my config" })
	local list, autoload

	local function selected()
		return list:Get()
	end

	local function syncAutoload()
		syncing = true
		autoload:Set(selected() ~= nil and selected() == config:GetAutoload())
		syncing = false
	end

	local function refresh(select)
		local names = config:List()
		list:SetOptions(names)
		if select and table.find(names, select) then
			list:Set(select)
		end
		syncAutoload()
		return names
	end

	configs:AddButton({
		Name = "Save",
		Icon = "save",
		Callback = function()
			local name = nameInput:Get()
			if name == nil or name == "" then
				name = selected()
			end
			local ok, result = config:Save(name or "")
			if ok then
				refresh(result)
				notify("Config saved", result, "Success")
			else
				notify("Couldn't save", result, "Error")
			end
		end,
	})

	list = configs:AddDropdown({
		Name = "Configs",
		Options = config:List(),
		Callback = function()
			if autoload then
				syncAutoload()
			end
		end,
	})

	configs:AddButton({
		Name = "Load",
		Icon = "folder-open",
		Callback = function()
			local name = selected()
			local ok, result = config:Load(name or "")
			if ok then
				notify("Config loaded", name .. " (" .. result .. " settings)", "Success")
			else
				notify("Couldn't load", result, "Error")
			end
		end,
	})

	configs:AddButton({
		Name = "Delete",
		Icon = "trash-2",
		Callback = function()
			local name = selected()
			local ok, result = config:Delete(name or "")
			if ok then
				refresh()
				notify("Config deleted", name, "Warning")
			else
				notify("Couldn't delete", result, "Error")
			end
		end,
	})

	configs:AddButton({
		Name = "Refresh",
		Icon = "refresh-cw",
		Callback = function()
			local names = refresh(selected())
			notify("Configs", #names .. " found", "Info")
		end,
	})

	autoload = configs:AddToggle({
		Name = "Autoload selected",
		Callback = function(on)
			if syncing then
				return
			end
			local name = selected()
			if on then
				if not name then
					syncing = true
					autoload:Set(false)
					syncing = false
					notify("Autoload", "Pick a config first.", "Warning")
					return
				end
				config:SetAutoload(name)
				notify("Autoload", name .. " loads on start", "Info")
			elseif config:GetAutoload() == name then
				config:SetAutoload(nil)
				notify("Autoload", "Turned off", "Info")
			end
		end,
	})

	interface:AddSlider({
		Name = "UI Scale",
		Min = 70,
		Max = 150,
		Step = 5,
		Suffix = "%",
		Default = math.floor(window.UIScale.Scale * 100 + 0.5),
		Callback = function(value)
			window:SetScale(value / 100)
		end,
	})

	interface:AddButton({
		Name = "Unload UI",
		Icon = "power",
		Callback = function()
			window:Destroy()
		end,
	})

	local name = config:GetAutoload()
	if name and table.find(config:List(), name) then
		list:Set(name)
		syncAutoload()
	end

	return {
		Page = page,
		Refresh = refresh,
		Autoload = function()
			local autoName = config:GetAutoload()
			if not autoName then
				return
			end
			local ok, result = config:Load(autoName)
			if ok then
				notify("Config loaded", autoName .. " (autoload)", "Success")
			else
				notify("Autoload failed", result, "Error")
			end
		end,
	}
end

return Settings
