local HttpService = game:GetService("HttpService")

local Files = {}

local function api(name)
	local ok, value = pcall(function()
		return (getgenv and getgenv()[name]) or getfenv(0)[name]
	end)
	return if ok and type(value) == "function" then value else nil
end

function Files.Available()
	return api("writefile") ~= nil and api("readfile") ~= nil
end

function Files.EnsureFolder(path)
	local isfolder, makefolder = api("isfolder"), api("makefolder")
	if not makefolder then
		return
	end
	local current = ""
	for part in string.gmatch(path, "[^/]+") do
		current = if current == "" then part else current .. "/" .. part
		pcall(function()
			if not (isfolder and isfolder(current)) then
				makefolder(current)
			end
		end)
	end
end

function Files.Clean(name)
	return (string.gsub(string.gsub(tostring(name or ""), "^%s*(.-)%s*$", "%1"), "[^%w%s_%-%.]", ""))
end

function Files.WriteJson(path, value)
	local writefile = api("writefile")
	if not writefile then
		return false, "This executor can't write files."
	end
	local folder = string.match(path, "^(.*)/[^/]+$")
	if folder then
		Files.EnsureFolder(folder)
	end
	local ok, err = pcall(function()
		writefile(path, HttpService:JSONEncode(value))
	end)
	return ok, if ok then nil else tostring(err)
end

function Files.ReadJson(path)
	local readfile, isfile = api("readfile"), api("isfile")
	if not readfile then
		return nil
	end
	local ok, value = pcall(function()
		if isfile and not isfile(path) then
			return nil
		end
		return HttpService:JSONDecode(readfile(path))
	end)
	return if ok then value else nil
end

function Files.WriteText(path, text)
	local writefile = api("writefile")
	if not writefile then
		return false
	end
	local folder = string.match(path, "^(.*)/[^/]+$")
	if folder then
		Files.EnsureFolder(folder)
	end
	return (pcall(writefile, path, text))
end

function Files.ReadText(path)
	local readfile, isfile = api("readfile"), api("isfile")
	if not readfile then
		return nil
	end
	local ok, value = pcall(function()
		if isfile and not isfile(path) then
			return nil
		end
		return readfile(path)
	end)
	return if ok then value else nil
end

function Files.Delete(path)
	local delfile = api("delfile")
	if not delfile then
		return false
	end
	return (pcall(delfile, path))
end

function Files.List(folder, extension)
	local listfiles = api("listfiles")
	if not listfiles then
		return {}
	end
	local ok, entries = pcall(listfiles, folder)
	if not ok or type(entries) ~= "table" then
		return {}
	end
	local names = {}
	for _, entry in entries do
		local file = string.match(string.gsub(tostring(entry), "\\", "/"), "([^/]+)$")
		if file and string.sub(file, -#extension) == extension then
			table.insert(names, string.sub(file, 1, -#extension - 1))
		end
	end
	table.sort(names, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	return names
end

return Files
