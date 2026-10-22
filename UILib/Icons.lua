--[[
	Icons: Lucide icons (https://lucide.dev) by name, e.g. "home", "settings".
	Uses the icon sheet from lucide-roblox (Vendor/Lucide, MIT + ISC), which is
	already uploaded to Roblox, so nothing is downloaded at runtime.
	All names: https://github.com/latte-soft/lucide-roblox/blob/master/md/icon-index.md

	You can also pass your own image: "rbxassetid://123" or a number.
]]

local import = ...
local IconData = import("Vendor/Lucide/IconData")

local Icons = {}
local custom = {}

-- Use your own image for a name: Icons.Register("logo", "rbxassetid://123")
function Icons.Register(name, image)
	custom[string.lower(name)] = image
end

-- Returns { Image, ImageRectSize, ImageRectOffset } or nil.
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

-- Puts the icon on an ImageLabel. Returns true if it worked.
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
