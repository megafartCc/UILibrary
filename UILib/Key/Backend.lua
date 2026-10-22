local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Backend = {}

Backend.DEFAULT_VERIFY_URL = "https://unknownhub.win/api/lua/key/verify"
Backend.DEFAULT_KEY_LINK = "https://unknownhub.win/#get-key"

local function trim(value)
	return (string.gsub(tostring(value or ""), "^%s*(.-)%s*$", "%1"))
end
Backend.Trim = trim

local function env(name)
	local ok, value = pcall(function()
		return (getgenv and getgenv()[name]) or getfenv(0)[name]
	end)
	return if ok then value else nil
end

function Backend.RequestFunction()
	for _, candidate in {
		env("request"),
		env("http_request"),
		(env("http") or {}).request,
		(env("syn") or {}).request,
		(env("fluxus") or {}).request,
	} do
		if type(candidate) == "function" then
			return candidate
		end
	end
	return nil
end

function Backend.Hwid()
	local sources = {
		function()
			return env("get_hwid") and env("get_hwid")()
		end,
		function()
			return env("gethwid") and env("gethwid")()
		end,
		function()
			return game:GetService("RbxAnalyticsService"):GetClientId()
		end,
	}
	for _, source in sources do
		local ok, value = pcall(source)
		if ok and value and tostring(value) ~= "" then
			return tostring(value)
		end
	end
	return ""
end

local function ticketFrom(payload)
	if type(payload) ~= "table" then
		return "", "", nil
	end
	local ticket = trim(payload.ticket or payload.unlockTicket or payload.keyTicket)
	local expiresAt = trim(payload.ticketExpiresAt or payload.ticket_expires_at or payload.unlockTicketExpiresAt)
	local seconds = tonumber(payload.ticketSecondsRemaining or payload.ticket_seconds_remaining or payload.ticketTtlSeconds or payload.ticket_ttl_seconds)
	return ticket, expiresAt, seconds
end
Backend.TicketFrom = ticketFrom

function Backend.KeySecondsRemaining(payload)
	if type(payload) ~= "table" then
		return nil
	end
	return tonumber(payload.keySecondsRemaining or payload.key_seconds_remaining or payload.secondsRemaining or payload.seconds_remaining)
end

local function ticketLooksSigned(ticket)
	return type(ticket) == "string" and #ticket >= 80 and string.match(ticket, "^[%w_%-]+%.[%w_%-]+$") ~= nil
end

local function statusCode(response)
	if type(response) ~= "table" then
		return 0
	end
	return tonumber(response.StatusCode or response.Status or response.status_code or response.status) or 0
end

local function body(response)
	if type(response) == "string" then
		return response
	end
	if type(response) ~= "table" then
		return ""
	end
	return tostring(response.Body or response.body or response.ResponseBody or "")
end

function Backend.CheckRemote(verifyUrl, scriptId, projectId, key)
	scriptId, projectId, key = trim(scriptId), trim(projectId), trim(key)
	if scriptId == "" and projectId == "" then
		return false, { code = "UNKNOWNHUB_TARGET_ID_MISSING", message = "ScriptId or ProjectId is missing." }
	end
	if key == "" then
		return false, { code = "KEY_EMPTY", message = "Enter a key first." }
	end

	local request = Backend.RequestFunction()
	if not request then
		return false, { code = "UNKNOWNHUB_REQUEST_UNAVAILABLE", message = "Executor HTTP request is unavailable." }
	end

	local player = Players.LocalPlayer
	local okRequest, response = pcall(request, {
		Url = verifyUrl,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json", ["Accept"] = "application/json" },
		Body = HttpService:JSONEncode({
			key = key,
			script_id = scriptId,
			project_id = projectId,
			roblox_user_id = if player then tostring(player.UserId) else "",
			place_id = tostring(game.PlaceId or ""),
			job_id = tostring(game.JobId or ""),
			hwid = Backend.Hwid(),
		}),
	})
	if not okRequest then
		return false, { code = "UNKNOWNHUB_REQUEST_FAILED", message = tostring(response or "Key verification request failed.") }
	end

	local okDecode, payload = pcall(HttpService.JSONDecode, HttpService, body(response))
	if not okDecode or type(payload) ~= "table" then
		local code = statusCode(response)
		return false, {
			code = "UNKNOWNHUB_BAD_RESPONSE",
			message = if code > 0 then "Key server returned HTTP " .. code .. "." else "Key server returned an invalid response.",
		}
	end

	if payload.valid == true then
		local ticket, expiresAt, seconds = ticketFrom(payload)
		if not ticketLooksSigned(ticket) then
			return false, { code = "KEY_TICKET_MISSING", message = "Key server did not return a signed unlock ticket." }
		end
		if seconds ~= nil and seconds <= 0 then
			return false, { code = "KEY_TICKET_EXPIRED", message = "Key unlock ticket expired. Try again." }
		end
		payload.ticket, payload.unlockTicket = ticket, ticket
		payload.ticketExpiresAt, payload.ticketSecondsRemaining = expiresAt, seconds
		return true, payload
	end

	if type(payload.code) ~= "string" or payload.code == "" then
		payload.code = payload.error or "KEY_INVALID"
	end
	if type(payload.message) ~= "string" or payload.message == "" then
		payload.message = payload.error or payload.code
	end
	return false, payload
end

local WARN = Color3.fromRGB(255, 188, 120)
local BAD = Color3.fromRGB(255, 160, 160)

function Backend.Describe(status)
	local code = string.lower(trim(type(status) == "table" and status.code or ""))
	local message = type(status) == "table" and status.message or nil
	if code == "key_empty" then
		return "Enter a key first.", BAD
	elseif code == "unknownhub_target_id_missing" or code == "unknownhub_script_id_missing" or code == "missing_script_id" then
		return "ScriptId or ProjectId is missing.", BAD
	elseif code == "unknownhub_request_unavailable" or code == "unknownhub_request_failed" or code == "unknownhub_bad_response" then
		return tostring(message or "Key verification failed."), WARN
	elseif code == "script_disabled" then
		return "The owner has temporarily disabled the script.", WARN
	elseif code == "script_unknown" then
		return "Script is not registered.", WARN
	elseif code == "key_expired" or code == "expired" then
		return "Key expired. Get a new one and retry.", WARN
	elseif code == "key_incorrect" or code == "key_invalid" or code == "invalid_key" then
		return "Invalid key.", BAD
	elseif type(message) == "string" and message ~= "" then
		return message, BAD
	end
	return "Invalid key.", BAD
end

local function fileApi(name)
	local value = env(name)
	return if type(value) == "function" then value else nil
end

local function path(folder, tag)
	return folder .. "/" .. string.gsub(tag, "[^%w_%-]", "_") .. ".json"
end

function Backend.Read(folder, tag)
	local isfile, readfile = fileApi("isfile"), fileApi("readfile")
	if not readfile then
		return nil
	end
	local file = path(folder, tag)
	local ok, data = pcall(function()
		if isfile and not isfile(file) then
			return nil
		end
		return HttpService:JSONDecode(readfile(file))
	end)
	return if ok then data else nil
end

function Backend.Write(folder, tag, value)
	local writefile = fileApi("writefile")
	if not writefile then
		return false
	end
	local isfolder, makefolder = fileApi("isfolder"), fileApi("makefolder")
	return (pcall(function()
		if makefolder and not (isfolder and isfolder(folder)) then
			makefolder(folder)
		end
		writefile(path(folder, tag), HttpService:JSONEncode(value))
	end))
end

function Backend.Publish(library, key, meta)
	local ticket, expiresAt, seconds = ticketFrom(meta)

	local function update(store)
		if type(store) ~= "table" then
			return
		end
		store.UnknownHubKey, store.unknownHubKey, store.unknownhub_key = key, key, key
		if ticket ~= "" then
			store.UnknownHubTicket, store.unknownHubTicket, store.unknownhub_ticket = ticket, ticket, ticket
		end
		if expiresAt ~= "" then
			store.UnknownHubTicketExpiresAt = expiresAt
		end
		if seconds ~= nil then
			store.UnknownHubTicketSecondsRemaining = seconds
		end
		local hub = if type(store.UnknownHub) == "table" then store.UnknownHub else {}
		store.UnknownHub = hub
		hub.key, hub.Key, hub.script_key, hub.scriptKey, hub.license_key, hub.licenseKey, hub.value = key, key, key, key, key, key, key
		if ticket ~= "" then
			hub.ticket, hub.Ticket, hub.unlock_ticket, hub.unlockTicket = ticket, ticket, ticket, ticket
		end
		if expiresAt ~= "" then
			hub.ticketExpiresAt, hub.unlockTicketExpiresAt = expiresAt, expiresAt
		end
		if seconds ~= nil then
			hub.ticketSecondsRemaining = seconds
		end
		hub.getKey = function()
			return key
		end
		hub.GetKey = hub.getKey
	end

	local getgenv = env("getgenv")
	if type(getgenv) == "function" then
		local ok, genv = pcall(getgenv)
		if ok then
			pcall(update, genv)
		end
	end
	pcall(update, _G)
	if type(shared) == "table" then
		pcall(update, shared)
	end

	if library then
		library.Key, library.key, library.UnknownHubKey = key, key, key
		if ticket ~= "" then
			library.UnknownHubTicket = ticket
		end
		library.GetKey = function()
			return key
		end
		library.getKey = library.GetKey
	end
end

function Backend.CopyToClipboard(text)
	text = trim(text)
	if text == "" then
		return false
	end
	for _, name in { "setclipboard", "toclipboard", "set_clipboard", "writeclipboard" } do
		local fn = fileApi(name)
		if fn and pcall(fn, text) then
			return true
		end
	end
	local syn = env("syn")
	if type(syn) == "table" and type(syn.write_clipboard) == "function" and pcall(syn.write_clipboard, text) then
		return true
	end
	return false
end

function Backend.FormatDuration(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds % 86400 / 3600)
	local minutes = math.floor(seconds % 3600 / 60)
	local secs = seconds % 60
	if days > 0 then
		return string.format("%dd %02dh %02dm", days, hours, minutes)
	elseif hours > 0 then
		return string.format("%02dh %02dm %02ds", hours, minutes, secs)
	end
	return string.format("%02dm %02ds", minutes, secs)
end

return Backend
