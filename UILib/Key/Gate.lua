local import = ...
local Theme = import("Theme")
local Motion = import("Motion")
local Create = import("Util/Create")
local Backend = import("Key/Backend")

local Gate = {}
Gate.__index = Gate

local BAD = Color3.fromRGB(255, 160, 160)
local WARN = Color3.fromRGB(255, 188, 120)
local PULSE = Color3.fromRGB(200, 90, 90)

local function first(options, ...)
	for index = 1, select("#", ...) do
		local value = options[select(index, ...)]
		if value ~= nil then
			return value
		end
	end
	return nil
end

function Gate.new(window, options, library)
	local trim = Backend.Trim
	local scriptId = trim(first(options, "ScriptId", "ScriptID", "UnknownHubScriptId", "UnknownHubScriptID"))
	local projectId = trim(first(options, "ProjectId", "ProjectID", "UnknownHubProjectId", "UnknownHubProjectID"))
	local fixedKey = trim(options.Key)
	local enabled = options.KeySystem == true
	local remote = options.UnknownHubKey == true
		or options.UnknownHubKeySystem == true
		or (enabled and fixedKey == "" and (scriptId ~= "" or projectId ~= ""))
	local mode = if remote then "remote" elseif enabled and fixedKey ~= "" then "fixed" else nil
	if not mode then
		return nil
	end

	if remote and scriptId == "" and projectId == "" and options.WaitForKey ~= false then
		error("UILib: the key system needs a ScriptId or ProjectId", 0)
	end

	local self = setmetatable({
		Window = window,
		Library = library,
		Mode = mode,
		ScriptId = scriptId,
		ProjectId = projectId,
		FixedKey = fixedKey,
		DeveloperKey = trim(first(options, "DeveloperKey", "DevKey")),
		VerifyUrl = trim(first(options, "KeyVerifyUrl", "UnknownHubVerifyUrl") or Backend.DEFAULT_VERIFY_URL),
		Link = trim(first(options, "GetKeyLink", "KeyLink") or Backend.DEFAULT_KEY_LINK),
		OnGetKey = options.OnGetKey,
		Folder = trim(options.KeyFolder or "UILib"),
		Tag = trim(options.KeyStorageTag or (if remote then "unknownhub_key" else "key")),
		ExpireText = options.Expire,
		SubmitText = options.SubmitKeyText or "Unlock",
		Unlocked = false,
		Busy = false,
	}, Gate)

	self:_build(options.GetKeyText or "Get Key")
	self:_buildExpiry()

	local saved = Backend.Read(self.Folder, self.Tag)
	local savedKey = trim(if type(saved) == "table" then saved.key or saved.value else saved)
	if savedKey ~= "" then
		self.Input.Text = savedKey
		local ok, meta = self:_validate(savedKey)
		if ok then
			self:_accept(savedKey, meta, false)
		end
	end
	if not self.Unlocked then
		self:_lock(false)
	end
	return self
end

local CARD = {
	Background = Color3.fromRGB(22, 22, 22),
	Line = Color3.fromRGB(29, 29, 29),
	Text = Color3.fromRGB(229, 229, 229),
	TextDim = Color3.fromRGB(150, 150, 150),
	TextMuted = Color3.fromRGB(100, 100, 100),
	Input = Color3.fromRGB(28, 28, 28),
	GetButton = Color3.fromRGB(32, 32, 32),
	GetButtonHover = Color3.fromRGB(42, 42, 42),
	Submit = Color3.fromRGB(45, 25, 30),
	SubmitHover = Color3.fromRGB(60, 30, 38),
}

function Gate:_build(getKeyText)
	self.Frame = Create.new("Frame", {
		Name = "KeyGateRoot",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 4,
		Parent = self.Window.Frame,
	})

	self.Card = Create.new("Frame", {
		Name = "KeyGateCard",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(360, 176),
		BackgroundColor3 = CARD.Background,
		BorderSizePixel = 0,
		Parent = self.Frame,
		Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create.new("UIStroke", { Color = CARD.Line, Transparency = 0.25 }),
	})

	Create.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(18, 14),
		Size = UDim2.new(1, -36, 0, 22),
		Font = Enum.Font.GothamBold,
		Text = "KEY SYSTEM",
		TextSize = 18,
		TextColor3 = CARD.Text,
		Parent = self.Card,
	})

	Create.new("TextLabel", {
		Name = "Subtitle",
		Position = UDim2.fromOffset(18, 38),
		Size = UDim2.new(1, -36, 0, 18),
		Font = Enum.Font.GothamMedium,
		Text = "Enter your key to unlock the window.",
		TextSize = 11,
		TextColor3 = CARD.TextDim,
		Parent = self.Card,
	})

	self.Input = Create.new("TextBox", {
		Name = "KeyInput",
		Position = UDim2.fromOffset(18, 72),
		Size = UDim2.new(1, -36, 0, 34),
		BackgroundColor3 = CARD.Input,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Font = Enum.Font.GothamMedium,
		PlaceholderText = "Enter key here",
		PlaceholderColor3 = CARD.TextMuted,
		Text = "",
		TextColor3 = CARD.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Card,
		Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
		Create.Padding(10, 10),
	})
	self.InputStroke = Create.new("UIStroke", { Color = CARD.Line, Transparency = 0.45, Parent = self.Input })

	self.Status = Create.new("TextLabel", {
		Name = "Status",
		Position = UDim2.fromOffset(18, 109),
		Size = UDim2.new(1, -36, 0, 14),
		Font = Enum.Font.GothamMedium,
		Text = "",
		TextSize = 10,
		TextColor3 = CARD.TextDim,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Card,
	})

	local function button(name, text, anchorX, position, background, hover, stroke, strokeTransparency, textColor)
		local frame = Create.new("TextButton", {
			Name = name,
			AnchorPoint = Vector2.new(anchorX, 0),
			Position = position,
			Size = UDim2.new(0.5, -23, 0, 30),
			BackgroundColor3 = background,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = text,
			TextColor3 = textColor,
			TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Selectable = false,
			Parent = self.Card,
			Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
			Create.new("UIStroke", {
				Color = stroke,
				Transparency = strokeTransparency,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		})
		frame.MouseEnter:Connect(function()
			Motion.Apply(frame, { BackgroundColor3 = hover }, true)
		end)
		frame.MouseLeave:Connect(function()
			Motion.Apply(frame, { BackgroundColor3 = background }, true)
		end)
		return frame
	end

	self.GetButton = button("GetKeyButton", getKeyText, 0, UDim2.new(0, 18, 1, -50),
		CARD.GetButton, CARD.GetButtonHover, CARD.Line, 0.4, CARD.Text)
	self.SubmitButton = button("SubmitKeyButton", self.SubmitText, 1, UDim2.new(1, -18, 1, -50),
		CARD.Submit, CARD.SubmitHover, Theme.Colors.Accent, 0.35, Color3.new(1, 1, 1))

	self.GetButton.Activated:Connect(function()
		self:GetKey()
	end)
	self.SubmitButton.Activated:Connect(function()
		self:TryUnlock()
	end)
	self.Input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			self:TryUnlock()
		end
	end)

	self.Window:_makeDraggable({ self.Card })

	if self.Mode == "remote" and self.ScriptId == "" and self.ProjectId == "" then
		self:_status("ScriptId or ProjectId is missing.", BAD)
	end
end

function Gate:_buildExpiry()
	local sizes, window = Theme.Sizes, self.Window
	self.ExpiryLabel = Create.new("TextLabel", {
		Name = "Expiry",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -(sizes.SidebarPadX + sizes.ItemPadX), 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		FontFace = Theme.Fonts.Element,
		RichText = true,
		Text = "",
		TextSize = Theme.TextSizes.Footer,
		TextColor3 = Theme.Colors.SectionLabel,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = window.Bottom,
	})

	task.spawn(function()
		while self.ExpiryLabel.Parent and not window.Destroyed do
			self:_tickExpiry()
			task.wait(1)
		end
	end)
end

function Gate:_tickExpiry()
	local value
	if self.Deadline then
		local remaining = math.max(0, math.ceil(self.Deadline - os.clock()))
		if remaining <= 0 then
			value = "expired"
			if self.Unlocked then
				self:Expire()
			end
		else
			value = Backend.FormatDuration(remaining)
		end
	else
		value = tostring(self.ExpireText or "never")
	end
	local accent = "#" .. string.upper(Theme.Colors.Accent:ToHex())
	self.ExpiryLabel.Text = string.format('expires <font color="%s">%s</font>', accent, value)
end

function Gate:_status(text, color)
	self.Status.Text = tostring(text or "")
	self.Status.TextColor3 = color or CARD.TextDim
end

function Gate:_pulse(color)
	Motion.Apply(self.InputStroke, { Color = color, Transparency = 0.1 }, true)
	task.delay(0.3, function()
		if self.InputStroke.Parent then
			Motion.Apply(self.InputStroke, { Color = CARD.Line, Transparency = 0.45 }, true)
		end
	end)
end

function Gate:_validate(key)
	key = Backend.Trim(key)
	if key == "" then
		return false, { code = "KEY_EMPTY", message = "Enter a key first." }
	end
	if self.DeveloperKey ~= "" and key == self.DeveloperKey then
		return true, { code = "KEY_VALID", message = "Developer key valid." }
	end
	if self.Mode == "fixed" then
		if key == self.FixedKey then
			return true, { code = "KEY_VALID", message = "Key valid." }
		end
		return false, { code = "KEY_INVALID", message = "Invalid key." }
	end
	return Backend.CheckRemote(self.VerifyUrl, self.ScriptId, self.ProjectId, key)
end

function Gate:TryUnlock()
	if self.Busy or self.Unlocked then
		return false
	end
	local key = Backend.Trim(self.Input.Text)
	if key == "" then
		self:_status("Enter a key first.", BAD)
		self:_pulse(PULSE)
		return false
	end

	self.Busy = true
	if self.Mode == "remote" then
		self.SubmitButton.Text = "Checking..."
		self:_status("Checking key...", Theme.Colors.Accent)
	end
	local ok, meta = self:_validate(key)
	self.Busy = false
	self.SubmitButton.Text = self.SubmitText

	if not ok then
		local text, color = Backend.Describe(meta)
		self:_status(text, color)
		self:_pulse(PULSE)
		return false
	end

	self:_accept(key, meta, true)
	return true
end

function Gate:_accept(key, meta, animate)
	local ticket, expiresAt, seconds = Backend.TicketFrom(meta)
	Backend.Write(self.Folder, self.Tag, {
		key = key,
		value = key,
		ticket = if ticket ~= "" then ticket else nil,
		ticketExpiresAt = if expiresAt ~= "" then expiresAt else nil,
		ticketSecondsRemaining = seconds,
		verified = true,
		mode = self.Mode,
		script_id = self.ScriptId,
		project_id = self.ProjectId,
	})
	Backend.Publish(self.Library, key, meta)

	local remaining = Backend.KeySecondsRemaining(meta)
	self.Deadline = if remaining then os.clock() + math.max(0, remaining) else nil
	self.Meta = meta
	self:_unlock(animate)
end

function Gate:GetKey()
	if type(self.OnGetKey) == "function" then
		local ok, handled = pcall(self.OnGetKey, self.Link)
		if ok and handled == true then
			return
		end
	end
	if self.Link == "" then
		self:_status("No key link configured.", BAD)
	elseif Backend.CopyToClipboard(self.Link) then
		self:_status("Key link copied to clipboard.", Theme.Colors.Accent)
	else
		self:_status("Clipboard unavailable: " .. self.Link, WARN)
	end
end

function Gate:Expire()
	self.Deadline = nil
	self.Input.Text = ""
	self:_status("Key expired. Get a new one and retry.", WARN)
	self:_lock(true)
end

function Gate:_setChrome(visible)
	local window = self.Window
	window.Header.Visible = visible
	window.Bottom.Visible = visible
	window.Sidebar.Frame.Visible = visible
	window.Content.Visible = visible
	window.Divider.Visible = visible
	window.Frame.BackgroundTransparency = if visible then 0 else 1
	if not visible then
		window.Search:_hide()
	end
end

function Gate:_lock(animate)
	local sizes = Theme.Sizes
	self.Unlocked = false
	self.Window.KeyVerified = false
	self:_setChrome(false)
	self.Frame.Visible = true
	Motion.Apply(self.Window.Frame, { Size = UDim2.fromOffset(sizes.KeyWidth, sizes.KeyHeight) }, animate)
end

function Gate:_unlock(animate)
	self.Unlocked = true
	self.Window.KeyVerified = true
	self.Frame.Visible = false
	self:_status("")
	self:_setChrome(true)
	Motion.Apply(self.Window.Frame, { Size = self.Window._fullSize }, animate)
end

function Gate:Wait()
	while not self.Unlocked and not self.Window.Destroyed do
		task.wait()
	end
	if not self.Unlocked then
		error("UILib: the key window was closed before the key was verified", 0)
	end
end

return Gate
