local Motion = {}

function Motion.Apply(instance, props)
	for prop, value in props do
		instance[prop] = value
	end
end

return Motion
