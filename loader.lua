local BASE_URL = "https://raw.githubusercontent.com/megafartCc/UILibrary/main/UILib/"

local cache = {}
local loading = {}

local function fetch(path)
	local url = BASE_URL .. path .. ".lua"
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or type(body) ~= "string" or body == "" then
		error("UILib: could not download " .. url, 0)
	end
	return body
end

local import

function import(path)
	if cache[path] ~= nil then
		return cache[path]
	end
	if loading[path] then
		error("UILib: circular import of " .. path, 0)
	end
	loading[path] = true

	local source = fetch(path)
	local chunk, err = loadstring(source, "=UILib/" .. path)
	if not chunk then
		error("UILib: failed to compile " .. path .. ": " .. tostring(err), 0)
	end

	local result = chunk(import)
	cache[path] = result == nil and true or result
	loading[path] = nil
	return cache[path]
end

return import("init")
