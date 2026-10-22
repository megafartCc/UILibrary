local import = ...
local IconData = import("Vendor/Lucide/IconData")

local Icons = {}
local custom = {}

function Icons.Register(name, image)
	custom[string.lower(name)] = image
end

function Icons.Get(icon)
	if icon == nil or icon == "" then
		return nil
	end
	if type(icon) == "number" then
		icon = "rbxassetid://" .. icon
	end
	local key = string.lower(icon)
	if custom[key] then
		icon = custom[key]
		if type(icon) == "number" then
			icon = "rbxassetid://" .. icon
		end
	end
	if string.match(icon, "^rbxassetid://") then
		return { Image = icon, ImageRectSize = Vector2.zero, ImageRectOffset = Vector2.zero }
	end

	local entry = IconData["48px"][key]
	if not entry then
		warn("UILib: no Lucide icon named \"" .. tostring(icon) .. "\"")
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
	if not asset then
		return false
	end
	imageLabel.Image = asset.Image
	imageLabel.ImageRectSize = asset.ImageRectSize
	imageLabel.ImageRectOffset = asset.ImageRectOffset
	return true
end

return Icons
