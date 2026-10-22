local import = ...
local Window = import("Components/Window")
local Notifications = import("Components/Notifications")

local UILib = {
	Theme = import("Theme"),
	Icons = import("Icons"),
	Motion = import("Motion"),
	Window = Window,
}

local windows = {}

function UILib.new(options)
	local window = Window.new(options, UILib)
	table.insert(windows, window)
	return window
end

function UILib:CreateWindow(options)
	return UILib.new(options)
end

function UILib:Notify(options, text, duration)
	return Notifications.Notify(options, text, duration)
end

function UILib:Destroy()
	for _, window in windows do
		window:Destroy()
	end
	table.clear(windows)
	Notifications.Clear()
end

return UILib
