local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

local CameraApp = {
	Id = "camera",
	Name = "Camera",
	Icon = { 
		Background = Color3.fromRGB(255, 255, 255),
		Image = "rbxassetid://109293262112242", 
	},
	Order = 30,
}

function CameraApp.Create(context: any)
	local player = Players.LocalPlayer
	local cameraService = context.Services.CameraService
	local photoService = context.Services.PhotoService

	local rootFrame = create("Frame", {
		Name = "CameraApp",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})

	-- Status Bar (Light mode)
	StatusBar.new(rootFrame, { Light = true, Carrier = "Putih-Abu", Battery = "100%" })

	-- UI State
	local flashSetting = "Auto" -- "Auto", "On", "Off"
	local hdrSetting = "Off" -- "On", "Off"

	-- Shutter Sound
	local shutterSound = Instance.new("Sound")
	shutterSound.SoundId = "rbxassetid://4743477170"
	shutterSound.Volume = 0.95
	shutterSound.Parent = rootFrame

	-- ─── HEADER BAR (Flash, HDR, Switch Camera) ─────────────────
	local header = create("Frame", {
		Name = "HeaderBar",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, Constants.Screen.StatusBarHeight, 0),
		Size = UDim2.new(1, 0, 0, 38),
		ZIndex = 52,
		Parent = rootFrame,
	})

	local flashButton = create("TextButton", {
		Name = "FlashButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⚡ Auto",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0.04, 0, 0.15, 0),
		Size = UDim2.new(0.25, 0, 0.7, 0),
		ZIndex = 53,
		Parent = header,
	})

	local hdrButton = create("TextButton", {
		Name = "HDRButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "HDR Off",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Position = UDim2.new(0.38, 0, 0.15, 0),
		Size = UDim2.new(0.24, 0, 0.7, 0),
		ZIndex = 53,
		Parent = header,
	})

	local switchButton = create("ImageButton", {
		Name = "SwitchButton",
		BackgroundTransparency = 1,
		Image = "rbxassetid://78679058545087", -- Rotate camera icon
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0.85, 0, 0.15, 0),
		Size = UDim2.new(0, 24, 0, 24),
		ZIndex = 53,
		Parent = header,
	})

	-- ─── VIEWFINDER CONTAINER (16:9 Aspect Ratio) ───────────────
	local viewfinderContainer = create("Frame", {
		Name = "ViewfinderContainer",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 48),
		Size = UDim2.new(1, 0, 1, -128),
		ZIndex = 51,
		ClipsDescendants = true,
		Parent = rootFrame,
	})

	local viewfinderFrame = create("Frame", {
		Name = "Viewfinder16x9",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(10, 10, 12),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 51,
		ClipsDescendants = true,
		Parent = viewfinderContainer,
	})

	create("UIAspectRatioConstraint", {
		AspectRatio = 16 / 9,
		AspectType = Enum.AspectType.FitWithinMaxSize,
		DominantAxis = Enum.DominantAxis.Width,
		Parent = viewfinderFrame,
	})

	local viewport = create("ViewportFrame", {
		Name = "Viewport",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 52,
		Parent = viewfinderFrame,
	})

	local filterOverlay = create("Frame", {
		Name = "FilterOverlay",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 53,
		Parent = viewfinderFrame,
	})

	local flashOverlay = create("Frame", {
		Name = "FlashOverlay",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 56,
		Parent = viewfinderFrame,
	})

	local filterPopup = create("TextLabel", {
		Name = "FilterPopup",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Font = Constants.Fonts.Semibold,
		Text = "Normal",
		TextColor3 = Color3.fromRGB(254, 203, 46),
		TextSize = 12,
		Position = UDim2.new(0.5, 0, 0.05, 0),
		Size = UDim2.new(0, 80, 0, 22),
		Visible = false,
		ZIndex = 55,
		Parent = viewfinderFrame,
	})
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = filterPopup })

	-- Attach live ViewportFrame preview to CameraService
	if cameraService then
		cameraService:AttachViewport(viewport, filterOverlay)
	end

	-- Listen for filter changes to update popup
	if cameraService then
		cameraService.FilterChanged:Connect(function(filterName: string)
			filterPopup.Text = filterName
			filterPopup.Visible = true
			task.delay(1.2, function()
				filterPopup.Visible = false
			end)
		end)
	end

	-- ─── BOTTOM CONTROL BAR (Shutter, Preview, Filter) ─────────
	local controlBar = create("Frame", {
		Name = "ControlBar",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -80),
		Size = UDim2.new(1, 0, 0, 80),
		ZIndex = 52,
		Parent = rootFrame,
	})

	-- Tombol Shutter iOS 7
	local shutterOuter = create("Frame", {
		Name = "ShutterOuter",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.82,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(56, 56),
		ZIndex = 53,
		Parent = controlBar,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = shutterOuter })

	local shutterInner = create("TextButton", {
		Name = "ShutterButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(46, 46),
		Text = "",
		ZIndex = 54,
		Parent = shutterOuter,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = shutterInner })

	-- Thumbnail Foto Terakhir (Kiri Shutter)
	local previewBtn = create("TextButton", {
		Name = "PreviewButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.18, 0.5),
		Size = UDim2.fromOffset(44, 44),
		Text = "",
		ZIndex = 53,
		ClipsDescendants = true,
		Parent = controlBar,
	})
	create("UICorner", { CornerRadius = UDim.new(0.15, 0), Parent = previewBtn })
	create("UIStroke", { Color = Color3.fromRGB(80, 80, 85), Thickness = 1, Parent = previewBtn })

	local previewViewport = create("ViewportFrame", {
		Name = "PreviewViewport",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 54,
		Parent = previewBtn,
	})

	-- Tombol Filter (Kanan Shutter)
	local filterButton = create("ImageButton", {
		Name = "FilterButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://133785936737274",
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.82, 0.5),
		Size = UDim2.fromOffset(32, 32),
		ZIndex = 53,
		Parent = controlBar,
	})

	local function refreshPreviewThumbnail()
		if not photoService then return end
		local latest = photoService:GetLatestPhoto()
		if latest then
			photoService:RenderPhotoToViewport(previewViewport, latest)
		else
			previewViewport:ClearAllChildren()
		end
	end

	if photoService then
		photoService.PhotosChanged:Connect(refreshPreviewThumbnail)
	end

	-- ─── EVENT HANDLERS ───────────────────────────────────────

	flashButton.Activated:Connect(function()
		if flashSetting == "Auto" then
			flashSetting = "On"
			flashButton.Text = "⚡ On"
			flashButton.TextColor3 = Color3.fromRGB(254, 203, 46)
		elseif flashSetting == "On" then
			flashSetting = "Off"
			flashButton.Text = "⚡ Off"
			flashButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		else
			flashSetting = "Auto"
			flashButton.Text = "⚡ Auto"
			flashButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)

	hdrButton.Activated:Connect(function()
		if hdrSetting == "Off" then
			hdrSetting = "On"
			hdrButton.TextColor3 = Color3.fromRGB(254, 203, 46)
			hdrButton.Text = "HDR On"
		else
			hdrSetting = "Off"
			hdrButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			hdrButton.Text = "HDR Off"
		end
	end)

	switchButton.Activated:Connect(function()
		if cameraService then
			cameraService:ToggleMode()
		end
	end)

	filterButton.Activated:Connect(function()
		if cameraService then
			cameraService:NextFilter()
		end
	end)

	-- Shutter Button Click -> Capture!
	shutterInner.Activated:Connect(function()
		shutterSound:Play()

		-- Shutter flash effect
		flashOverlay.BackgroundTransparency = 0
		TweenService:Create(flashOverlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()

		-- Button scale animation
		TweenService:Create(shutterInner, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(38, 38)
		}):Play()
		task.delay(0.08, function()
			TweenService:Create(shutterInner, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(46, 46)
			}):Play()
		end)

		-- Capture snapshot via CameraService and save via PhotoService
		if cameraService and photoService then
			local snapshot = cameraService:CaptureSnapshot()
			photoService:SavePhoto(snapshot)
		end

		refreshPreviewThumbnail()
		previewBtn.Size = UDim2.fromOffset(12, 12)
		TweenService:Create(previewBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(44, 44)
		}):Play()
	end)

	previewBtn.Activated:Connect(function()
		context.OpenApp("gallery")
	end)

	refreshPreviewThumbnail()

	-- Detach viewport on app close / destroy
	rootFrame.Destroying:Connect(function()
		if cameraService then
			cameraService:DetachViewport()
		end
	end)

	return rootFrame
end

return CameraApp
