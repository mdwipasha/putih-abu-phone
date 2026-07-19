local Constants = require(script.Parent.Parent.Shared.Constants)
local StatusBar = require(script.Parent.Parent.Shared.Components.StatusBar)
local create = require(script.Parent.Parent.Shared.Utilities.Create)

local Settings = {
	Id = "settings",
	Name = "Settings",
	Icon = { 
		Background = Color3.fromRGB(115, 115, 122), 
		Image = "rbxassetid://129638627110007",
	},
	Order = 70,
}

function Settings.Create(context: any)
	local saveService = context.Services.SaveService

	local function applyWallpaper(inputText: string)
		saveService:Set("WallpaperImage", inputText)
		context.SendNotification({
			Title = "Wallpaper",
			Body = "Wallpaper berhasil diganti.",
		})
	end

	local root = create("Frame", {
		Name = "SettingsApp",
		BackgroundColor3 = Color3.fromRGB(239, 239, 244),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})
	StatusBar.new(root, { Light = false, Battery = "100%" })

	local nav = create("Frame", {
		Name = "NavigationBar",
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, Constants.Screen.StatusBarHeight),
		Size = UDim2.fromScale(1, 0.08),
		ZIndex = 51,
		Parent = root,
	})

	local back = create("TextButton", {
		Name = "BackButton",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "<",
		TextColor3 = Color3.fromRGB(0, 122, 255),
		TextScaled = true,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.12, 0.7),
		ZIndex = 52,
		Parent = nav,
	})
	back.Activated:Connect(context.CloseCurrentApp)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Settings",
		TextColor3 = Color3.fromRGB(20, 20, 20),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.55),
		ZIndex = 52,
		Parent = nav,
	})

	local group = create("Frame", {
		Name = "WallpaperGroup",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.035, 0.18),
		Size = UDim2.fromScale(0.93, 0.255),
		ZIndex = 51,
		Parent = root,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0.025, 0),
		Parent = group,
	})

	create("TextLabel", {
		Name = "WallpaperLabel",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "Wallpaper Image",
		TextColor3 = Color3.fromRGB(30, 30, 30),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.05, 0.08),
		Size = UDim2.fromScale(0.9, 0.18),
		ZIndex = 52,
		Parent = group,
	})

	local input = create("TextBox", {
		Name = "WallpaperAssetInput",
		BackgroundColor3 = Color3.fromRGB(242, 242, 247),
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Regular,
		PlaceholderText = "Roblox image asset id",
		Text = saveService:Get("WallpaperImage", ""),
		TextColor3 = Color3.fromRGB(20, 20, 20),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.05, 0.34),
		Size = UDim2.fromScale(0.9, 0.24),
		ZIndex = 52,
		Parent = group,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0.08, 0),
		Parent = input,
	})
	create("UIPadding", {
		PaddingLeft = UDim.new(0.04, 0),
		PaddingRight = UDim.new(0.04, 0),
		Parent = input,
	})

	local apply = create("TextButton", {
		Name = "ApplyWallpaper",
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(0, 122, 255),
		Font = Constants.Fonts.Semibold,
		Text = "Set Wallpaper",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Position = UDim2.fromScale(0.05, 0.67),
		Size = UDim2.fromScale(0.9, 0.23),
		ZIndex = 52,
		Parent = group,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0.08, 0),
		Parent = apply,
	})
	apply.Activated:Connect(function()
		applyWallpaper(input.Text)
	end)
	input.FocusLost:Connect(function(enterPressed: boolean)
		if enterPressed then
			applyWallpaper(input.Text)
		end
	end)

	return root
end

return Settings
