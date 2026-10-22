local Motion = {}

Motion.Enabled = false

function Motion.Apply(instance, props)
	for prop, value in pairs(props) do
		instance[prop] = value
	end
end

return Motion
