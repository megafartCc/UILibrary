local import = ...
local Theme = import("Theme")

local TweenService = game:GetService("TweenService")

local Motion = { Enabled = true }

local TWEENABLE = { number = true, Color3 = true, UDim = true, UDim2 = true, Vector2 = true }
local playing = setmetatable({}, { __mode = "k" })

local function cancel(instance, props)
	local active = playing[instance]
	if not active then
		return
	end
	for prop in props do
		local tween = active[prop]
		if tween then
			tween:Cancel()
			for key, other in active do
				if other == tween then
					active[key] = nil
				end
			end
		end
	end
end

function Motion.Apply(instance, props, animate, duration, style)
	cancel(instance, props)

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
		local active = playing[instance] or {}
		playing[instance] = active
		for prop in goals do
			active[prop] = tween
		end
		tween:Play()
	end
end

return Motion
