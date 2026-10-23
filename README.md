# UILibrary

A Roblox UI library. Right now it makes one thing: a black window with sharp
corners and a sidebar of pages, sized for phones in landscape.

## Load it

```lua
local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/megafartCc/UILibrary/main/loader.lua"))()
```

## Make a window

```lua
local Window = UILib:CreateWindow({
	Title = "Black Box",      -- window name, top left
	DefaultPage = "Home",     -- optional
})

local Main = Window:AddSection({ Name = "Main", Order = 1 })
Main:AddPage({ Name = "Home", Icon = "home", Order = 1 })
Main:AddPage({ Name = "Play", Icon = "play", Order = 2 })
```

Or all at once:

```lua
local Window = UILib:CreateWindow({
	Title = "Black Box",
	Pages = {
		{ Section = "Main", Name = "Home", Icon = "home" },
		{ Section = "Main", Name = "Play", Icon = "play" },
		{ Section = "Other", Name = "Settings", Icon = "settings" },
	},
})
```

See `example.lua` for a full example.

## API

| Call | What it does |
| --- | --- |
| `UILib:CreateWindow({ Title, Footer, DefaultPage, Width, Height, Scale, Pages, OnClose })` | Opens a window with a header bar (title, search, X) and a bottom bar (`Footer` text). The X closes it for good |
| `Window:SetFooter(text)` | Changes the bottom bar text |
| `Window:SetScale(scale)` | Makes the whole window bigger or smaller. Default is `Theme.Scale` (1.2) |
| Search (top centre) | Type to find pages, boxes and controls as you go. Tap a result (or press Enter for the first) to open that page, scroll to the box and flash it. Tap outside to hide the list. `Window.Search:Find(text)` returns the matches |
| Moving the window | Drag the header or bottom bar with mouse or finger. It follows smoothly and stays on screen |
| `Window:OnClose(fn)` | Runs `fn` when the window closes; stop your loops here |
| `Window:SetTitle(text)` | Renames the window |
| `Window:AddSection(name)` or `Window:AddSection({ Name, Order })` | Adds a section label, or returns the existing one with that name |
| `Section:AddPage({ Name, Icon, Order })` | Adds a page to a section |
| `Window:AddPage({ Name, Icon, Section, Order })` | Adds a page, making the section if needed |
| `Window:SelectPage(name)` | Shows a page. Pages added later won't take over the selection |
| `Window:GetPage(name)` | Returns a page |
| `Page:AddGroup(name)` or `Page:AddGroup({ Name, Side, Collapsed })` | Adds a box with a header (name, ^ to collapse) and a thin line under it. Tap the header to fold or unfold it; `group:SetCollapsed(true)` / `group:Toggle()` from code, `Collapsed = true` to start folded. `Side` is `"Left"` or `"Right"`; leave it out to use the column with fewer boxes. Put your UI in `group.Body`; the box grows to fit it |
| `Group:AddSlider({ Name, Min, Max, Default, Step, Suffix, Callback })` | Adds a one-row slider: name on the left, bar on the right. `slider:Set(value)` and `slider:Get()` read and change it; `Callback(value)` runs when the value changes |
| `Group:AddToggle({ Name, Default, Callback })` | Adds an iPhone-style switch. `toggle:Set(true)` and `toggle:Get()`; `Callback(on)` runs when it changes |
| `Group:AddButton({ Name, Icon, Callback })` | Adds a row with a small rounded square on the right. Tapping the row runs `Callback()` with a press animation. `Icon` is any Lucide name (default `pointer`) |
| `Group:AddDropdown({ Name, Options, Default, Multi, Callback })` | Adds a dropdown that opens a list under the row. With `Multi = true` you can tick several and `Default`/values are tables. `dropdown:Set(v)`, `:Get()`, `:SetOptions(list)`, `:Open()`, `:Close()` |
| `Group:AddSliderToggle({ Name, Min, Max, Default, Step, Suffix, Enabled, Callback })` | Slider and switch on one line. `Callback(value, enabled)` runs when either changes. `:SetEnabled(on)` |
| `Group:AddDropdownToggle({ Name, Options, Default, Multi, Enabled, Callback })` | Dropdown and switch on one line. `Callback(choice, enabled)` runs when either changes. `:SetEnabled(on)` |
| `Group:AddDropdownButton({ Name, Options, Default, Icon, Callback })` | Dropdown and button on one line. Picking only selects; tapping the button runs `Callback(choice)` |
| `Group:AddMultiDropdown({ Name, Options, Default, Callback })` | Dropdown where each option has a checkbox; tick as many as you want and the list stays open. `Default` and `Callback(list)` use tables |
| `Group:AddMultiDropdownToggle({ Name, Options, Default, Enabled, Callback })` | Multi-select dropdown and switch on one line. `Callback(list, enabled)` |
| `Group:AddColorPicker({ Name, Default, Callback })` | Colour swatch on the right; tap the row to open a saturation square, hue bar and hex box under it. `Callback(color)` gets a Color3. `:Set(color)`, `:Get()`, `:Open()`, `:Close()` |
| `Window:Destroy()` | Same as the X: runs OnClose, clears every callback and value, disconnects input, deletes the UI. `Window.Destroyed` turns true |
| `UILib:Notify({ Title, Text, Duration })` or `UILib:Notify(title, text, duration)` | Shows a notification in the top right. It slides in, a line at the bottom drains until it slides out, and tapping it closes it early. Up to 5 stack. Returns a handle with `:Close()` |
| `UILib:Destroy()` | Destroys every window this UILib made and clears notifications |

## Key system

Same logic and the same card design as the old UiLib. While locked, only the
key card shows (KEY SYSTEM, key box, status line, **Get Key** and **Unlock**);
drag it by the card to move it. A valid key expands it into the full UI. `CreateWindow` waits until the key is accepted, so code
after it only runs once unlocked (`WaitForKey = false` turns that off).

```lua
-- your own fixed key
local Window = UILib:CreateWindow({ Title = "Black Box", KeySystem = true, Key = "my-key" })

-- UnknownHub key server
local Window = UILib:CreateWindow({
	Title = "Black Box",
	KeySystem = true,
	ScriptId = "your-script-id", -- or ProjectId
})
```

| Option | What it does |
| --- | --- |
| `KeySystem = true` | Turns the key screen on |
| `Key` | A fixed key checked locally |
| `ScriptId` / `ProjectId` | Checks keys with the UnknownHub server instead |
| `KeyVerifyUrl` | Server address (default `https://unknownhub.win/api/lua/key/verify`) |
| `GetKeyLink` | Link Get Key copies (default `https://unknownhub.win/#get-key`) |
| `OnGetKey(link)` | Your own Get Key action; return `true` to skip the copy |
| `DeveloperKey` | A key that always works |
| `KeyFolder`, `KeyStorageTag` | Where the accepted key is saved (default `UILib/key.json`) |
| `GetKeyText`, `SubmitKeyText` | Button labels |
| `Expire` | Text for the expiry when the server gives no time (default `never`) |
| `WaitForKey = false` | Don't pause `CreateWindow` until unlocked |

- **Server check:** sends the key, script/project id, Roblox user id, place id, job id and HWID. It needs a valid response with a signed unlock ticket.
- **Error messages:** invalid, expired, script disabled, script not registered, missing ticket, HTTP errors, no executor `request`.
- **Saved key:** the accepted key is saved and checked again on the next run, so players don't retype it.
- **For your script:** the key and ticket are published to `getgenv()`, `_G` and `shared` under the same names as the old UiLib (`UnknownHubKey`, `UnknownHubTicket`, `UnknownHub.getKey()`), and also as `UILib.Key` / `UILib.GetKey()`.
- **Expiry:** if the server returns `keySecondsRemaining`, the bottom bar counts down and the window locks again when it runs out.
- `Window.KeyVerified` tells you whether it's unlocked.

**Order:** sections sort by their `Order`, and pages sort by `Order` inside
their section. Leave it out and they appear in the order you add them.

**Icons:** any [Lucide](https://lucide.dev) name, e.g. `"home"`,
`"settings"`, `"shopping-bag"`. Full list:
https://github.com/latte-soft/lucide-roblox/blob/master/md/icon-index.md
You can also pass `"rbxassetid://123"`.

## Files

```
loader.lua               downloads the modules in parallel and returns UILib
example.lua              example window
UILib/
  init.lua               UILib:CreateWindow
  Theme.lua              colors, sizes, fonts (every number the layout uses)
  Icons.lua              Lucide icons by name
  Motion.lua             all state changes go through here (tweens, set Motion.Enabled = false to turn off)
  Util/Create.lua        instance helpers with per-class defaults
  Util/Parts.lua         shared switch and button square, and the extra control on combined rows
  Components/
    Window.lua           the black box, creates pages and handles selection
    Sidebar.lua          title, sections by name and order
    Section.lua          section label, page ordering
    PageButton.lua       icon + name row, selected highlight
    Page.lua             content area for one page, two columns
    Notifications.lua    top-right notifications
    Search.lua           search box in the header and live results
    Group.lua            box with a collapsible header and line; Add<Element> methods come from UILib/Elements
  Elements/
    Slider.lua           slider with a fill and the value in the middle
    Toggle.lua           pill switch with a sliding knob
    Button.lua           row with a tappable rounded square
    Dropdown.lua         single or multi select list that opens under the row
    ColorPicker.lua      swatch with a saturation square, hue bar and hex input
  Key/
    Backend.lua          key check against the server, saving, publishing, clipboard
    Gate.lua             key card (old UiLib design, draggable), lock/unlock, expiry countdown
  Vendor/Lucide/         icon sheet data from lucide-roblox (MIT + ISC)
```

To add an element: create `UILib/Elements/Name.lua` with `Name.new(group, options, order)` and add it to the `Elements` table in `Group.lua`; `Group:AddName` then exists.

To add a module: create `UILib/Something.lua`, start it with
`local import = ...`, and load other modules with `import("Theme")`.

## Rules

- The window has sharp corners. Only the selected page highlight is rounded, and it slides between pages.
- No CanvasGroup.
- Animations go through `Motion.lua`. Speed and easing live in `Theme.Motion`.
