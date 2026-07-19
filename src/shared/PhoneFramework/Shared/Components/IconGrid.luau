local Constants = require(script.Parent.Parent.Constants)
local AppIcon = require(script.Parent.AppIcon)
local create = require(script.Parent.Parent.Utilities.Create)

local IconGrid = {}

function IconGrid.new(parent: Instance, apps: { any }, openApp: (string) -> (), dockIds: { string })
	local root = create("Frame", {
		Name = "IconGrid",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 25,
		Parent = parent,
	})

	local byId = {}
	for _, app in ipairs(apps) do
		byId[app.Id] = app
	end

	local dockLookup = {}
	for _, id in ipairs(dockIds) do
		dockLookup[id] = true
	end

	local row = 0
	local column = 0
	for _, app in ipairs(apps) do
		if not app.IsSystem and not dockLookup[app.Id] then
			local icon = AppIcon.new(root, app, function()
				openApp(app.Id)
			end)
			icon.Position = UDim2.fromScale(
				Constants.Screen.GridLeft + column * (Constants.Screen.IconSize + Constants.Screen.GridXGap),
				Constants.Screen.GridTop + row * (Constants.Screen.IconSize + Constants.Screen.GridYGap)
			)
			icon.Size = UDim2.fromScale(Constants.Screen.IconSize, Constants.Screen.IconSize)

			column += 1
			if column >= 4 then
				column = 0
				row += 1
			end
		end
	end

	local pageDots = create("Frame", {
		Name = "PageIndicator",
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.812),
		Size = UDim2.fromScale(0.18, 0.025),
		ZIndex = 29,
		Parent = root,
	})
	for index = 1, 3 do
		local dot = create("Frame", {
			Name = "Dot" .. index,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = if index == 1 then 0 else 0.64,
			Position = UDim2.fromScale(0.2 + (index - 1) * 0.3, 0.5),
			Size = UDim2.fromScale(0.14, 0.55),
			ZIndex = 30,
			Parent = pageDots,
		})
		create("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = dot,
		})
	end

	local dock = create("Frame", {
		Name = "Dock",
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(214, 224, 232),
		BackgroundTransparency = 0.2,
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, Constants.Screen.DockHeight),
		ZIndex = 26,
		Parent = root,
	})
	create("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 178, 186)),
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 0.2),
		}),
		Parent = dock,
	})
	create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 0.2,
		Parent = dock,
	})

	for index, id in ipairs(dockIds) do
		local app = byId[id]
		if app then
			local icon = AppIcon.new(dock, app, function()
				openApp(app.Id)
			end)
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.14 + (index - 1) * 0.24, 0.65)
			icon.Size = UDim2.fromScale(0.2, 0.95)
		end
	end

	return root
end

return IconGrid
