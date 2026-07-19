local Constants = require(script.Parent.Parent.Constants)
local create = require(script.Parent.Parent.Utilities.Create)

local Wallpaper = {}

local DEFAULT_WALLPAPER = "rbxassetid://115291664497394"

local function normalizeImageId(value: any): string
	if type(value) ~= "string" or value == "" then
		return ""
	end

	value = string.gsub(value, "%s+", "")

	if string.find(value, "rbxassetid://", 1, true) or string.find(value, "rbxthumb://", 1, true) then
		return value
	end

	return "rbxassetid://" .. value
end

function Wallpaper.new(parent: Instance, variant: ("Home" | "Lock")?, context: any?)
	local root = create("Frame", {
		Name = (variant or "Home") .. "Wallpaper",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 11,
		Parent = parent,
	})

	-- Wallpaper image: gunakan custom dari SaveService jika ada, fallback ke default
	local savedImage = context and context.Services and context.Services.SaveService:Get("WallpaperImage", "") or ""
	local initialImage = if savedImage ~= "" then normalizeImageId(savedImage) else DEFAULT_WALLPAPER

	local wallpaperImg = create("ImageLabel", {
		Name = "WallpaperImage",
		BackgroundTransparency = 1,
		Image = initialImage,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 12,
		Parent = root,
	})

	if context and context.Services and context.Services.SaveService then
		context.Services.SaveService.Changed:Connect(function(key: string, value: any)
			if key == "WallpaperImage" then
				local newImage = normalizeImageId(value)
				wallpaperImg.Image = if newImage ~= "" then newImage else DEFAULT_WALLPAPER
			end
		end)
	end

	return root
end

return Wallpaper
