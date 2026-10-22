local import = ...
local Window = import("Components/Window")

local UILib = {
	Theme = import("Theme"),
	Icons = import("Icons"),
	Motion = import("Motion"),
	Window = Window,
}

function UILib.new(options)
	return Window.new(options)
end

function UILib:CreateWindow(options)
	return Window.new(options)
end

return UILib
