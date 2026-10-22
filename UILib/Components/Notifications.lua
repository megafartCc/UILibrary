local import = ...
local Theme = import("Theme")
local Motion = import("Motion")
local Create = import("Util/Create")

local Players = game:GetService("Players")

local Notifications = {}

local gui, root
local toasts = {}
local serial = 0

local function host()
	if root and root.Parent and gui.Parent then
		return root
	end
	local sizes = Theme.Sizes
	gui = Create.new("ScreenGui", {
		Name = "UILibNotifications",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	root = Create.new("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -sizes.NotifyMargin, 0, sizes.NotifyMargin),
		Size = UDim2.new(0, sizes.NotifyWidth, 1, -2 * sizes.NotifyMargin),
		BackgroundTransparency = 1,
		Parent = gui,
		Create.List(Enum.FillDirection.Vertical, sizes.NotifyGap),
	})
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return root
end

function Notifications.Notify(options, text, duration)
	if type(options) ~= "table" then
		options = { Title = options, Text = text, Duration = duration }
	end
	local sizes, colors, motion = Theme.Sizes, Theme.Colors, Theme.Motion
	local pad = sizes.NotifyPad
	local lifetime = math.clamp(tonumber(options.Duration) or 3, 0.5, 60)
	local parent = host()

	serial += 1
	local slot = Create.new("Frame", {
		Name = "Notification",
		LayoutOrder = -serial,
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = parent,
	})

	local card = Create.new("TextButton", {
		Name = "Card",
		Position = UDim2.fromOffset(sizes.NotifySlide, 0),
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = colors.Notify,
		BackgroundTransparency = 1,
		Parent = slot,
		Create.new("UICorner", { CornerRadius = UDim.new(0, sizes.NotifyRadius) }),
	})
	local stroke = Create.new("UIStroke", { Color = colors.NotifyStroke, Transparency = 1, Parent = card })

	local content = Create.new("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = card,
		Create.Padding(pad, pad, pad, pad + sizes.NotifyLine + 4),
		Create.List(Enum.FillDirection.Vertical, 3),
	})

	local title = Create.new("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, Theme.TextSizes.NotifyTitle + 2),
		FontFace = Theme.Fonts.NotifyTitle,
		Text = tostring(options.Title or "Notification"),
		TextSize = Theme.TextSizes.NotifyTitle,
		TextColor3 = colors.Text,
		TextTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = content,
	})

	local body = Create.new("TextLabel", {
		Name = "Text",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		FontFace = Theme.Fonts.NotifyText,
		Text = tostring(options.Text or ""),
		TextSize = Theme.TextSizes.NotifyText,
		TextColor3 = colors.ElementText,
		TextTransparency = 1,
		TextWrapped = true,
		Visible = options.Text ~= nil and options.Text ~= "",
		Parent = content,
	})

	local line = Create.new("Frame", {
		Name = "Line",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, pad, 1, -pad / 2 - 1),
		Size = UDim2.new(1, -2 * pad, 0, sizes.NotifyLine),
		BackgroundColor3 = colors.Track,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = card,
		Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local fill = Create.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = colors.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = line,
		Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local toast = { Closed = false }

	function toast.Close()
		if toast.Closed then
			return
		end
		toast.Closed = true
		local index = table.find(toasts, toast)
		if index then
			table.remove(toasts, index)
		end
		Motion.Apply(card, { Position = UDim2.fromOffset(sizes.NotifySlide, 0), BackgroundTransparency = 1 }, true)
		Motion.Apply(stroke, { Transparency = 1 }, true)
		Motion.Apply(title, { TextTransparency = 1 }, true)
		Motion.Apply(body, { TextTransparency = 1 }, true)
		Motion.Apply(line, { BackgroundTransparency = 1 }, true)
		Motion.Apply(fill, { BackgroundTransparency = 1 }, true)
		Motion.Apply(slot, { Size = UDim2.fromScale(1, 0) }, true)
		task.delay(motion.Duration, function()
			slot:Destroy()
		end)
	end

	card.Activated:Connect(toast.Close)

	table.insert(toasts, 1, toast)
	while #toasts > sizes.NotifyMax do
		toasts[#toasts].Close()
	end

	task.spawn(function()
		task.wait()
		if toast.Closed then
			return
		end
		Motion.Apply(slot, { Size = UDim2.new(1, 0, 0, card.AbsoluteSize.Y) }, true)
		Motion.Apply(card, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0 }, true)
		Motion.Apply(stroke, { Transparency = 0 }, true)
		Motion.Apply(title, { TextTransparency = 0 }, true)
		Motion.Apply(body, { TextTransparency = 0 }, true)
		Motion.Apply(line, { BackgroundTransparency = 0 }, true)
		fill.BackgroundTransparency = 0
		Motion.Apply(fill, { Size = UDim2.fromScale(0, 1) }, true, lifetime, Enum.EasingStyle.Linear)
		task.delay(lifetime, toast.Close)
	end)

	return toast
end

function Notifications.Clear()
	if gui then
		gui:Destroy()
	end
	gui, root = nil, nil
	table.clear(toasts)
end

return Notifications
