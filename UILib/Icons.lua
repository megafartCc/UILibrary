local import = ...
local Sheet = import("Vendor/Lucide/IconData")["48px"]

local Icons = {}
local custom = {}

function Icons.Register(name, image)
	custom[string.lower(name)] = image
end

function Icons.Get(icon)
	if icon == nil or icon == "" then
		return nil
	end
	if type(icon) == "string" then
		icon = custom[string.lower(icon)] or icon
	end
	if type(icon) == "number" then
		icon = "rbxassetid://" .. icon
	end
	if string.find(icon, "://", 1, true) then
		return { Image = icon, ImageRectSize = Vector2.zero, ImageRectOffset = Vector2.zero }
	end

	local entry = Sheet[string.lower(icon)]
	if not entry then
		warn('UILib: no Lucide icon named "' .. icon .. '"')
		return nil
	end
	return {
		Image = "rbxassetid://" .. entry[1],
		ImageRectSize = Vector2.new(entry[2][1], entry[2][2]),
		ImageRectOffset = Vector2.new(entry[3][1], entry[3][2]),
	}
end

function Icons.Apply(imageLabel, icon)
	local asset = Icons.Get(icon)
	if asset then
		imageLabel.Image = asset.Image
		imageLabel.ImageRectSize = asset.ImageRectSize
		imageLabel.ImageRectOffset = asset.ImageRectOffset
	end
	return asset ~= nil
end

return Icons
