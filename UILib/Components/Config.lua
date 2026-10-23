local import = ...
local Files = import("Util/Files")

local Config = {}
Config.__index = Config

local AUTOLOAD = "autoload.txt"

function Config.new(window, options)
	local folder = options.ConfigFolder or ("UILib/configs/" .. Files.Clean(options.Title or "UILib"))
	return setmetatable({ Window = window, Folder = folder }, Config)
end

function Config:_path(name)
	return self.Folder .. "/" .. name .. ".json"
end

function Config:Elements()
	local list = {}
	for _, page in self.Window.Pages do
		for _, group in page.Groups do
			for _, element in group.Elements do
				if not element.NoConfig and element.Flag and type(element.Get) == "function" then
					table.insert(list, element)
				end
			end
		end
	end
	return list
end

local function encode(value)
	if typeof(value) == "Color3" then
		return { Color = value:ToHex() }
	end
	return value
end

local function decode(value)
	if type(value) == "table" and type(value.Color) == "string" then
		local ok, color = pcall(Color3.fromHex, value.Color)
		return if ok then color else nil
	end
	return value
end

function Config:Snapshot()
	local values = {}
	for _, element in self:Elements() do
		local entry = { Value = encode(element:Get()) }
		if element.Enabled ~= nil then
			entry.Enabled = element.Enabled
		end
		values[element.Flag] = entry
	end
	return values
end

function Config:Apply(values)
	if type(values) ~= "table" then
		return 0
	end
	local applied = 0
	for _, element in self:Elements() do
		local entry = values[element.Flag]
		if type(entry) == "table" then
			local value = decode(entry.Value)
			if value ~= nil and type(element.Set) == "function" then
				pcall(element.Set, element, value)
			end
			if entry.Enabled ~= nil and type(element.SetEnabled) == "function" and entry.Enabled ~= element.Enabled then
				pcall(element.SetEnabled, element, entry.Enabled)
			end
			applied += 1
		end
	end
	return applied
end

function Config:Save(name)
	name = Files.Clean(name)
	if name == "" then
		return false, "Type a config name first."
	end
	if not Files.Available() then
		return false, "This executor can't save files."
	end
	local ok, err = Files.WriteJson(self:_path(name), { Version = 1, Values = self:Snapshot() })
	if not ok then
		return false, err
	end
	return true, name
end

function Config:Load(name)
	name = Files.Clean(name)
	if name == "" then
		return false, "Pick a config first."
	end
	local data = Files.ReadJson(self:_path(name))
	if type(data) ~= "table" then
		return false, "Couldn't read config \"" .. name .. "\"."
	end
	return true, self:Apply(data.Values)
end

function Config:Delete(name)
	name = Files.Clean(name)
	if name == "" then
		return false, "Pick a config first."
	end
	if not Files.Delete(self:_path(name)) then
		return false, "Couldn't delete \"" .. name .. "\"."
	end
	if self:GetAutoload() == name then
		self:SetAutoload(nil)
	end
	return true
end

function Config:List()
	return Files.List(self.Folder, ".json")
end

function Config:GetAutoload()
	local name = Files.ReadText(self.Folder .. "/" .. AUTOLOAD)
	name = Files.Clean(name)
	return if name ~= "" then name else nil
end

function Config:SetAutoload(name)
	return Files.WriteText(self.Folder .. "/" .. AUTOLOAD, Files.Clean(name))
end

return Config
