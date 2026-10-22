local BASE_URL = "https://raw.githubusercontent.com/megafartCc/UILibrary/main/UILib/"

local PENDING, FAILED = {}, {}
local sources, modules, loading = {}, {}, {}

local function download(path)
	if sources[path] ~= nil then
		return
	end
	sources[path] = PENDING
	task.spawn(function()
		local ok, body = pcall(function()
			return game:HttpGet(BASE_URL .. path .. ".lua")
		end)
		if ok and type(body) == "string" and body ~= "" then
			for dependency in string.gmatch(body, 'import%("([^"]+)"%)') do
				download(dependency)
			end
			sources[path] = body
		else
			sources[path] = FAILED
		end
	end)
end

local function source(path)
	download(path)
	while sources[path] == PENDING do
		task.wait()
	end
	if sources[path] == FAILED then
		error("UILib: could not download " .. BASE_URL .. path .. ".lua", 0)
	end
	return sources[path]
end

local function import(path)
	if modules[path] ~= nil then
		return modules[path]
	end
	if loading[path] then
		error("UILib: circular import of " .. path, 0)
	end
	loading[path] = true

	local chunk, err = loadstring(source(path), "=UILib/" .. path)
	if not chunk then
		error("UILib: failed to compile " .. path .. ": " .. tostring(err), 0)
	end
	local result = chunk(import)

	loading[path] = nil
	modules[path] = if result == nil then true else result
	return modules[path]
end

return import("init")
