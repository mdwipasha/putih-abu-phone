import re

with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "r", encoding="utf-8") as f:
    content = f.read()

# 1. currentTabId
content = content.replace('local currentTabId     = "library"  -- "library" | "search" | "now"',
                          'local currentTabId     = "home"  -- "home" | "now"')

# 2. TAB_DEFS
old_tabs = """	local TAB_DEFS = {
		{ id = "library", label = "Library",   emoji = "♫" },
		{ id = "search",  label = "Search",    emoji = "⌕" },
		{ id = "now",     label = "Now Playing",emoji = "▶" },
	}"""
new_tabs = """	local TAB_DEFS = {
		{ id = "home",  label = "Home",    emoji = "⌕" },
		{ id = "now",     label = "Now Playing",emoji = "▶" },
	}"""
content = content.replace(old_tabs, new_tabs)

# 3. Remove LibraryPanel block
# We remove from '-- ─── LIBRARY PANEL' up to '-- ─── SEARCH PANEL'
content = re.sub(r"-- ─── LIBRARY PANEL ──────────.*?-- ─── SEARCH PANEL ──────────.*?\n", 
                 "-- ─── HOME PANEL ────────────────────────────────────────────────\n", 
                 content, flags=re.DOTALL)

# 4. Update SearchPanel -> HomePanel properties
content = content.replace('local searchPanel = create("Frame", {', 'local searchPanel = create("Frame", {') # keep var name for simplicity
content = content.replace('Name = "SearchPanel",', 'Name = "HomePanel",')
content = content.replace('Name = "SearchNav",', 'Name = "HomeNav",')
content = content.replace('Name = "SearchTitle",', 'Name = "HomeTitle",')
content = content.replace('Text = "Search",', 'Text = "Home",', 1) # First occurrence after SearchTitle is Text = "Search"

# Add back button to HomeNav (searchNav var)
nav_title_block = """	create("TextLabel", {
		Name = "HomeTitle",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Home",
		TextColor3 = Color3.fromRGB(252, 252, 255),
		TextScaled = false,
		TextSize = 16,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.7, 0.6),
		ZIndex = 55,
		Parent = searchNav,
	})"""

new_nav_title_block = nav_title_block + """
	local searchBackBtn = create("TextButton", {
		Name = "HomeBackBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "く",
		TextColor3 = Color3.fromRGB(252, 60, 92),
		TextScaled = true,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.1, 0.7),
		ZIndex = 55,
		Parent = searchNav,
	})
	searchBackBtn.Activated:Connect(context.CloseCurrentApp)"""

content = content.replace(nav_title_block, new_nav_title_block)

# 5. Remove swatch from createSongRow
old_row_start = """		-- Album color swatch
		local swatch = create("Frame", {
			Name = "Swatch",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = getAlbumColor(song),
			Position = UDim2.fromScale(0.04, 0.5),
			Size = UDim2.fromOffset(32, 32),
			ZIndex = 54,
			Parent = row,
		})
		create("UICorner", { CornerRadius = UDim.new(0.15, 0), Parent = swatch })
		create("TextLabel", {
			Name = "SwatchNote",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = "♫",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = 0.3,
			TextScaled = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.65, 0.65),
			ZIndex = 55,
			Parent = swatch,
		})

		-- Song info"""
content = content.replace(old_row_start, "		-- Song info")

content = content.replace('Position = UDim2.fromScale(0.22, 0.12),', 'Position = UDim2.fromScale(0.04, 0.12),')
content = content.replace('Size = UDim2.fromScale(0.62, 0.38),', 'Size = UDim2.fromScale(0.8, 0.38),')
content = content.replace('Position = UDim2.fromScale(0.22, 0.52),', 'Position = UDim2.fromScale(0.04, 0.52),')
content = content.replace('Size = UDim2.fromScale(0.62, 0.32),', 'Size = UDim2.fromScale(0.8, 0.32),')

# 6. Tab transitions in HitBtn
old_hit = """			for _, p in ipairs({libraryPanel, searchPanel, nowPanel}) do
				p.Visible = false
			end"""
new_hit = """			for _, p in ipairs({searchPanel, nowPanel}) do
				p.Visible = false
			end"""
content = content.replace(old_hit, new_hit)

# 7. Remove populateLibrary
content = re.sub(r"\t-- ── Populate Library ──────────.*?-- ── Populate Search ──────────.*?\n", 
                 "\t-- ── Populate Search ───────────────────────────────────────────────\n", 
                 content, flags=re.DOTALL)

# 8. switchTab logic
old_switch = """	local function switchTab(tabId: string)
		currentTabId = tabId
		libraryPanel.Visible = (tabId == "library")
		searchPanel.Visible  = (tabId == "search")
		nowPanel.Visible     = (tabId == "now")

		for id, btn in pairs(tabButtons) do
			btn.TextColor3 = (id == tabId)
				and Color3.fromRGB(252, 60, 92)
				or Color3.fromRGB(130, 130, 140)
		end

		if tabId == "search" then
			populateSearch(searchInput.Text)
		end
	end"""

new_switch = """	local function switchTab(tabId: string)
		currentTabId = tabId
		searchPanel.Visible  = (tabId == "home")
		nowPanel.Visible     = (tabId == "now")

		for id, btn in pairs(tabButtons) do
			btn.TextColor3 = (id == tabId)
				and Color3.fromRGB(252, 60, 92)
				or Color3.fromRGB(130, 130, 140)
		end

		if tabId == "home" then
			populateSearch(searchInput.Text)
		end
	end"""
content = content.replace(old_switch, new_switch)

# 9. Initial state
old_init = """	-- ── Initial state ─────────────────────────────────────────────────
	populateLibrary()
	switchTab("library")
	updateNowPlayingUI()"""
new_init = """	-- ── Initial state ─────────────────────────────────────────────────
	populateSearch("")
	switchTab("home")
	updateNowPlayingUI()"""
content = content.replace(old_init, new_init)

with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "w", encoding="utf-8") as f:
    f.write(content)

print("Modifications applied successfully.")
