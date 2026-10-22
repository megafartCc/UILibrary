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
| `UILib:CreateWindow({ Title, DefaultPage, Width, Height, Pages, OnClose })` | Opens a window. The X in the top right closes it for good |
| `Window:OnClose(fn)` | Runs `fn` when the window closes; stop your loops here |
| `Window:SetTitle(text)` | Renames the window |
| `Window:AddSection(name)` or `Window:AddSection({ Name, Order })` | Adds a section label, or returns the existing one with that name |
| `Section:AddPage({ Name, Icon, Order })` | Adds a page to a section |
| `Window:AddPage({ Name, Icon, Section, Order })` | Adds a page, making the section if needed |
| `Window:SelectPage(name)` | Shows a page. Pages added later won't take over the selection |
| `Window:GetPage(name)` | Returns a page |
| `Page:AddGroup(name)` or `Page:AddGroup({ Name, Side })` | Adds an outlined box to the page. `Side` is `"Left"` or `"Right"`; leave it out to use the column with fewer boxes. Put your UI in `group.Body`; the box grows to fit it |
| `Group:AddSlider({ Name, Min, Max, Default, Step, Suffix, Callback })` | Adds a one-row slider: name on the left, bar on the right. `slider:Set(value)` and `slider:Get()` read and change it; `Callback(value)` runs when the value changes |
| `Group:AddToggle({ Name, Default, Callback })` | Adds an iPhone-style switch. `toggle:Set(true)` and `toggle:Get()`; `Callback(on)` runs when it changes |
| `Window:Destroy()` | Same as the X: runs OnClose, clears every callback and value, disconnects input, deletes the UI. `Window.Destroyed` turns true |
| `UILib:Destroy()` | Destroys every window this UILib made |

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
  Components/
    Window.lua           the black box, creates pages and handles selection
    Sidebar.lua          title, sections by name and order
    Section.lua          section label, page ordering
    PageButton.lua       icon + name row, selected highlight
    Page.lua             content area for one page, two columns
    Group.lua            filled box, title half over its top edge; Add<Element> methods come from UILib/Elements
  Elements/
    Slider.lua           slider with a fill and the value in the middle
    Toggle.lua           pill switch with a sliding knob
  Vendor/Lucide/         icon sheet data from lucide-roblox (MIT + ISC)
```

To add an element: create `UILib/Elements/Name.lua` with `Name.new(group, options, order)` and add it to the `Elements` table in `Group.lua`; `Group:AddName` then exists.

To add a module: create `UILib/Something.lua`, start it with
`local import = ...`, and load other modules with `import("Theme")`.

## Rules

- The window has sharp corners. Only the selected page highlight is rounded, and it slides between pages.
- No CanvasGroup.
- Animations go through `Motion.lua`. Speed and easing live in `Theme.Motion`.
