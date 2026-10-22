--[[
	Motion: every visual state change goes through Motion.Apply.
	Right now it sets properties instantly (no animations).
	To add animations later, change only this file, for example by
	tweening instead of assigning when Motion.Enabled is true.
]]

local Motion = {}

Motion.Enabled = false

function Motion.Apply(instance, props)
	for prop, value in pairs(props) do
		instance[prop] = value
	end
end

return Motion
