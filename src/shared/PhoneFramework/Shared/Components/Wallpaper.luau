local Constants = require(script.Parent.Parent.Constants)
local create = require(script.Parent.Parent.Utilities.Create)

local Wallpaper = {}

function Wallpaper.new(parent: Instance, variant: ("Home" | "Lock")?)
	local root = create("Frame", {
		Name = (variant or "Home") .. "Wallpaper",
		BackgroundColor3 = Constants.Screen.WallpaperTop,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 11,
		Parent = parent,
	})

	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Constants.Screen.WallpaperTop),
			ColorSequenceKeypoint.new(
				0.48,
				if variant == "Lock" then Color3.fromRGB(77, 61, 92) else Constants.Screen.WallpaperMid
			),
			ColorSequenceKeypoint.new(
				0.74,
				if variant == "Lock" then Color3.fromRGB(165, 139, 141) else Color3.fromRGB(201, 85, 73)
			),
			ColorSequenceKeypoint.new(1, Constants.Screen.WallpaperBottom),
		}),
		Rotation = 90,
		Parent = root,
	})

	for index = 1, 7 do
		local ridge = create("Frame", {
			Name = "MountainRidge" .. index,
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = if variant == "Lock" then Color3.fromRGB(64, 61, 73) else Color3.fromRGB(12, 54, 72),
			BackgroundTransparency = 0.08 + index * 0.035,
			Position = UDim2.fromScale(0.08 + index * 0.14, 0.7 + (index % 3) * 0.055),
			Rotation = -18 + index * 6,
			Size = UDim2.fromScale(0.52, 0.14),
			ZIndex = 12,
			Parent = root,
		})
		create("UICorner", {
			CornerRadius = UDim.new(0.5, 0),
			Parent = ridge,
		})
	end

	return root
end

return Wallpaper
