local import = ...
local Theme = import("Theme")
local Icons = import("Icons")
local Motion = import("Motion")
local Window = import("Components/Window")

local UILib = {}
UILib.Theme = Theme
UILib.Icons = Icons
UILib.Motion = Motion

function UILib:CreateWindow(options)
	return Window.new(options)
end

function UILib.new(options)
	return Window.new(options)
end

return UILib
