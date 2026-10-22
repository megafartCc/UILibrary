local import = ...
local Theme = import("Theme")

local TweenService = game:GetService("TweenService")

local Motion = { Enabled = true }

local TWEENABLE = { number = true, Color3 = true, UDim = true, UDim2 = true, Vector2 = true }

function Motion.Apply(instance, props, animate)
	local goals
	for prop, value in props do
		if animate and Motion.Enabled and TWEENABLE[typeof(value)] then
			goals = goals or {}
			goals[prop] = value
		else
			instance[prop] = value
		end
	end
	if goals then
		local info = TweenInfo.new(Theme.Motion.Duration, Theme.Motion.Style, Enum.EasingDirection.Out)
		TweenService:Create(instance, info, goals):Play()
	end
end

return Motion
