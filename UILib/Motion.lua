local import = ...
local Theme = import("Theme")

local TweenService = game:GetService("TweenService")

local Motion = { Enabled = true }

local TWEENABLE = { number = true, Color3 = true, UDim = true, UDim2 = true, Vector2 = true }
local playing = setmetatable({}, { __mode = "k" })

function Motion.Apply(instance, props, animate, duration, style)
	if playing[instance] then
		playing[instance]:Cancel()
		playing[instance] = nil
	end

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
		local info = TweenInfo.new(duration or Theme.Motion.Duration, style or Theme.Motion.Style, Enum.EasingDirection.Out)
		local tween = TweenService:Create(instance, info, goals)
		playing[instance] = tween
		tween:Play()
	end
end

return Motion
