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
| `UILib:CreateWindow({ Title, DefaultPage, Width, Height, Pages })` | Opens a window |
| `Window:SetTitle(text)` | Renames the window |
| `Window:AddSection(name)` or `Window:AddSection({ Name, Order })` | Adds a section label, or returns the existing one with that name |
| `Section:AddPage({ Name, Icon, Order })` | Adds a page to a section |
| `Window:AddPage({ Name, Icon, Section, Order })` | Adds a page, making the section if needed |
| `Window:SelectPage(name)` | Shows a page. Pages added later won't take over the selection |
| `Window:GetPage(name)` | Returns a page. Put your UI in `page.Body` |
| `Window:Destroy()` | Closes the window |

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
  Motion.lua             all state changes go through here (no animations yet)
  Util/Create.lua        instance helpers with per-class defaults
  Components/
    Window.lua           the black box, creates pages and handles selection
    Sidebar.lua          title, sections by name and order
    Section.lua          section label, page ordering
    PageButton.lua       icon + name row, selected highlight
    Page.lua             content area for one page
  Vendor/Lucide/         icon sheet data from lucide-roblox (MIT + ISC)
```

To add a module: create `UILib/Something.lua`, start it with
`local import = ...`, and load other modules with `import("Theme")`.

## Rules

- The window has sharp corners. Only the selected page highlight is rounded.
- No CanvasGroup.
- No animations for now. To add them later, change only `Motion.lua`.
