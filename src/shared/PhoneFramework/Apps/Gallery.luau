local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

local GalleryApp = {
	Id = "gallery",
	Name = "Photos",
	Icon = { 
		Background = Color3.fromRGB(255, 255, 255), 
		Image = "rbxassetid://101194280432848",
	},
	Order = 40,
}

function GalleryApp.Create(context: any)
	local player = Players.LocalPlayer
	local photoService = context.Services.PhotoService

	local rootFrame = create("Frame", {
		Name = "GalleryRoot",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromScale(1, 1),
	})

	StatusBar.new(rootFrame, { Light = false, Carrier = "Putih-Abu", Battery = "100%" })

	-- ─── TOP NAVIGATION BAR ───────────────────────────────────────
	local navBar = create("Frame", {
		Name = "NavigationBar",
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, Constants.Screen.StatusBarHeight),
		Size = UDim2.new(1, 0, 0, 42),
		ZIndex = 10,
		Parent = rootFrame,
	})

	create("Frame", {
		Name = "Separator",
		BackgroundColor3 = Color3.fromRGB(200, 200, 205),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = navBar,
	})

	local backBtn = create("TextButton", {
		Name = "BackButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "く",
		TextColor3 = Color3.fromRGB(0, 122, 255),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 9),
		Size = UDim2.new(0, 70, 0, 24),
		ZIndex = 11,
		Parent = navBar,
	})

	backBtn.Activated:Connect(function()
		context.CloseCurrentApp()
	end)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Photos",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 16,
		Position = UDim2.new(0.3, 0, 0, 9),
		Size = UDim2.new(0.4, 0, 0, 24),
		ZIndex = 11,
		Parent = navBar,
	})

	local selectBtn = create("TextButton", {
		Name = "SelectButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "Select",
		TextColor3 = Color3.fromRGB(0, 122, 255),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -70, 0, 9),
		Size = UDim2.new(0, 60, 0, 24),
		ZIndex = 11,
		Parent = navBar,
	})

	-- ─── BOTTOM TAB BAR (iOS 7 Style) ───────────────────────────
	local tabBar = create("Frame", {
		Name = "TabBar",
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -44),
		Size = UDim2.new(1, 0, 0, 44),
		ZIndex = 10,
		Parent = rootFrame,
	})
	create("Frame", {
		Name = "Separator",
		BackgroundColor3 = Color3.fromRGB(200, 200, 205),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = tabBar,
	})

	local tabNames = { "Photos", "Shared", "Albums" }
	local tabWidth = 1 / #tabNames
	for i, name in ipairs(tabNames) do
		local btn = create("TextButton", {
			Name = name .. "Tab",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Semibold,
			Text = name,
			TextColor3 = if i == 1 then Color3.fromRGB(0, 122, 255) else Color3.fromRGB(140, 140, 145),
			TextSize = 12,
			Position = UDim2.new((i - 1) * tabWidth, 0, 0, 0),
			Size = UDim2.new(tabWidth, 0, 1, 0),
			Parent = tabBar,
		})
	end

	-- ─── PHOTOS GRID SCROLLING FRAME ─────────────────────────────
	local scrollFrame = create("ScrollingFrame", {
		Name = "PhotosGrid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 66),
		Size = UDim2.new(1, 0, 1, -110),
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = rootFrame,
	})

	local gridLayout = create("UIGridLayout", {
		CellPadding = UDim2.new(0, 2, 0, 2),
		CellSize = UDim2.new(0, 95, 0, 95),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scrollFrame,
	})

	-- Dynamic 3-column cell sizing
	scrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if scrollFrame.AbsoluteSize.X > 0 then
			local width = scrollFrame.AbsoluteSize.X
			local cols = 3
			local padding = 2
			local cellWidth = math.floor((width - (padding * (cols - 1))) / cols)
			gridLayout.CellSize = UDim2.new(0, cellWidth, 0, cellWidth)
		end
	end)

	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 12)
	end)

	-- Empty state label if no photos
	local emptyStateLabel = create("TextLabel", {
		Name = "EmptyState",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "No Photos or Videos\nYou can take photos using the Camera app.",
		TextColor3 = Color3.fromRGB(140, 140, 145),
		TextSize = 13,
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(0.8, 0, 0.3, 0),
		Visible = false,
		ZIndex = 5,
		Parent = rootFrame,
	})

	-- ─── FULLSCREEN PHOTO VIEWER MODAL ───────────────────────────
	local photoModal = create("Frame", {
		Name = "PhotoModal",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 100,
		Parent = rootFrame,
	})

	-- Header Fullscreen Modal
	local modalHeader = create("Frame", {
		Name = "ModalHeader",
		BackgroundColor3 = Color3.fromRGB(15, 15, 18),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, Constants.Screen.StatusBarHeight),
		Size = UDim2.new(1, 0, 0, 42),
		ZIndex = 102,
		Parent = photoModal,
	})

	local modalBackBtn = create("TextButton", {
		Name = "ModalBackButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "く",
		TextColor3 = Color3.fromRGB(0, 122, 255),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 9),
		Size = UDim2.new(0, 80, 0, 24),
		ZIndex = 103,
		Parent = modalHeader,
	})

	local modalDateTitle = create("TextLabel", {
		Name = "ModalDateTitle",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Photo",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Position = UDim2.new(0.25, 0, 0, 9),
		Size = UDim2.new(0.5, 0, 0, 24),
		ZIndex = 103,
		Parent = modalHeader,
	})

	-- Viewport Central Container (16:9 Display)
	local photoDisplayFrame = create("Frame", {
		Name = "PhotoDisplayFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 1, -100),
		ZIndex = 101,
		ClipsDescendants = true,
		Parent = photoModal,
	})

	create("UIAspectRatioConstraint", {
		AspectRatio = 16 / 9,
		AspectType = Enum.AspectType.FitWithinMaxSize,
		Parent = photoDisplayFrame,
	})

	local fullViewport = create("ViewportFrame", {
		Name = "FullViewport",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 101,
		Parent = photoDisplayFrame,
	})

	-- Bottom Toolbar (Delete / Trash Can & Share)
	local modalToolbar = create("Frame", {
		Name = "ModalToolbar",
		BackgroundColor3 = Color3.fromRGB(15, 15, 18),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -46),
		Size = UDim2.new(1, 0, 0, 46),
		ZIndex = 102,
		Parent = photoModal,
	})

	local deleteBtn = create("ImageButton", {
		Name = "DeleteButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://108650574179237", -- Trash / Action icon
		ImageColor3 = Color3.fromRGB(255, 59, 48), -- iOS Red
		Position = UDim2.new(0.85, 0, 0.5, 0),
		Size = UDim2.new(0, 24, 0, 24),
		ZIndex = 103,
		Parent = modalToolbar,
	})

	local deleteTextBtn = create("TextButton", {
		Name = "DeleteTextBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "🗑️",
		TextColor3 = Color3.fromRGB(255, 59, 48),
		TextSize = 14,
		Position = UDim2.new(0.7, 0, 0.15, 0),
		Size = UDim2.new(0.25, 0, 0.7, 0),
		ZIndex = 104,
		Parent = modalToolbar,
	})

	local currentActivePhotoId: string? = nil

	local function closePhotoModal()
		photoModal.Visible = false
		currentActivePhotoId = nil
		fullViewport:ClearAllChildren()
	end

	modalBackBtn.Activated:Connect(closePhotoModal)

	-- Handle photo deletion
	local function deleteCurrentPhoto()
		if not currentActivePhotoId or not photoService then return end
		local targetId = currentActivePhotoId
		photoService:DeletePhoto(targetId)
		closePhotoModal()
		loadPhotosGrid()
	end

	deleteTextBtn.Activated:Connect(deleteCurrentPhoto)
	deleteBtn.Activated:Connect(deleteCurrentPhoto)

	-- ─── LOAD & RENDER PHOTOS GRID ───────────────────────────────

	function loadPhotosGrid()
		-- Clear grid entries
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then
				child:Destroy()
			end
		end

		local photos = photoService and photoService:GetPhotos() or {}

		if #photos == 0 then
			emptyStateLabel.Visible = true
			return
		else
			emptyStateLabel.Visible = false
		end

		for i, photoData in ipairs(photos) do
			local cellBtn = create("TextButton", {
				Name = "PhotoCell_" .. (photoData.Id or i),
				AutoButtonColor = true,
				BackgroundColor3 = Color3.fromRGB(20, 20, 25),
				BorderSizePixel = 0,
				LayoutOrder = i, -- Terurut 1, 2, 3 (terbaru paling depan karena photos disort desending)
				Text = "",
				ClipsDescendants = true,
				Parent = scrollFrame,
			})

			local cellViewport = create("ViewportFrame", {
				Name = "Viewport",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
				Parent = cellBtn,
			})

			-- Render photo thumbnail ke ViewportFrame
			if photoService then
				photoService:RenderPhotoToViewport(cellViewport, photoData)
			end

			-- Open Fullscreen Photo Viewer saat diklik
			cellBtn.Activated:Connect(function()
				currentActivePhotoId = photoData.Id
				modalDateTitle.Text = photoData.TimeFormatted or "Photo"
				photoModal.Visible = true
				if photoService then
					photoService:RenderPhotoToViewport(fullViewport, photoData)
				end
			end)
		end
	end

	-- Listen for photo changes
	if photoService then
		photoService.PhotosChanged:Connect(function()
			if rootFrame.Visible then
				loadPhotosGrid()
			end
		end)
	end

	-- Refresh grid saat app dibuka
	rootFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if rootFrame.Visible then
			loadPhotosGrid()
		end
	end)

	loadPhotosGrid()

	return rootFrame
end

return GalleryApp
