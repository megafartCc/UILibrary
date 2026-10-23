local import = ...
local Files = import("Util/Files")

local Config = {}
Config.__index = Config

local AUTOLOAD = "autoload.txt"
local AUTOSAVE = "autosave.json"
local PREFS = "settings.json"
local DEFAULT = "default"

function Config.new(window, options)
	local folder = options.ConfigFolder or ("UILib/configs/" .. Files.Clean(options.Title or "UILib"))
	local self = setmetatable({ Window = window, Folder = folder, AutoSave = true, _token = 0 }, Config)
	local prefs = Files.ReadJson(folder .. "/" .. PREFS)
	self.Prefs = if type(prefs) == "table" then prefs else {}
	if self.Prefs.AutoSave == false then
		self.AutoSave = false
	end
	local stored = Files.ReadJson(folder .. "/" .. AUTOSAVE)
	self.Stored = if type(stored) == "table" then stored else {}
	return self
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

local function entryFor(element)
	local entry = { Value = encode(element:Get()) }
	if element.Enabled ~= nil then
		entry.Enabled = element.Enabled
	end
	return entry
end

local function applyEntry(element, entry)
	if type(entry) ~= "table" then
		return false
	end
	local value = decode(entry.Value)
	if value ~= nil and type(element.Set) == "function" then
		pcall(element.Set, element, value)
	end
	if entry.Enabled ~= nil and type(element.SetEnabled) == "function" and entry.Enabled ~= element.Enabled then
		pcall(element.SetEnabled, element, entry.Enabled)
	end
	return true
end

function Config:Snapshot()
	local values = {}
	for _, element in self:Elements() do
		values[element.Flag] = entryFor(element)
	end
	return values
end

function Config:Apply(values)
	if type(values) ~= "table" then
		return 0
	end
	local applied = 0
	for _, element in self:Elements() do
		if applyEntry(element, values[element.Flag]) then
			applied += 1
		end
	end
	return applied
end

function Config:Restore(element)
	if self.AutoSave and element.SaveKey and not element.NoConfig then
		applyEntry(element, self.Stored[element.SaveKey])
	end
end

function Config:QueueAutosave()
	if not self.AutoSave then
		return
	end
	self._token += 1
	local token = self._token
	task.delay(1, function()
		if self._token == token then
			self:Flush()
		end
	end)
end

function Config:Flush()
	if not self.AutoSave or not Files.Available() then
		return false
	end
	local changed = false
	for _, element in self:Elements() do
		if element.SaveKey then
			self.Stored[element.SaveKey] = entryFor(element)
			changed = true
		end
	end
	if changed then
		Files.WriteJson(self.Folder .. "/" .. AUTOSAVE, self.Stored)
	end
	if self:GetAutoload() == DEFAULT then
		Files.WriteJson(self:_path(DEFAULT), { Version = 1, Values = self:Snapshot() })
	end
	return true
end

function Config:_savePrefs()
	self.Prefs.AutoSave = self.AutoSave
	Files.WriteJson(self.Folder .. "/" .. PREFS, self.Prefs)
end

function Config:SetAutoSave(on)
	self.AutoSave = on == true
	self:_savePrefs()
	if self.AutoSave then
		self:Flush()
	end
end

function Config:SetAutoloadOff(off)
	self.Prefs.AutoloadOff = off == true
	self:_savePrefs()
end

function Config:EnsureDefault()
	if not Files.Available() or self.Prefs.AutoloadOff == true or self:GetAutoload() then
		return false
	end
	if not table.find(self:List(), DEFAULT) then
		self:Save(DEFAULT)
	end
	self:SetAutoload(DEFAULT)
	return true
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
	local names = {}
	for _, name in Files.List(self.Folder, ".json") do
		if name .. ".json" ~= AUTOSAVE and name .. ".json" ~= PREFS then
			table.insert(names, name)
		end
	end
	return names
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
