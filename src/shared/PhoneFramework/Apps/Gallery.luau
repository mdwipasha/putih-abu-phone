local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

local DEFAULT_IMAGES = {
	"rbxassetid://137618063796337",
	"rbxassetid://6031090532",
	"rbxassetid://15154178525",
	"rbxassetid://14732363934",
	"rbxassetid://115758366877536",
	"rbxassetid://125147726148745",
}

local function getPhotoThumbnail(photo, player)
	if photo.Type == "front" then
		return "rbxthumb://type=AvatarBust&id=" .. player.UserId .. "&w=420&h=420"
	end
	
	local hash = tonumber(photo.Id) or 1
	local index = (hash % #DEFAULT_IMAGES) + 1
	return DEFAULT_IMAGES[index]
end

local GalleryApp = {
	Id = "gallery",
	Name = "Photos",
	Icon = { 
		Background = Color3.fromRGB(255, 255, 255), 
		Image = "rbxassetid://101194280432848",
	},
	Order = 40,
}

function GalleryApp.Create(context)
	local player = Players.LocalPlayer
	local saveService = context.Services.SaveService

	local rootFrame = create("Frame", {
		Name = "GalleryRoot",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromScale(1, 1),
	})

	local statusBar = StatusBar.new(rootFrame, { Light = false })

	local navBar = create("Frame", {
		Name = "NavigationBar",
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(1, 0, 0, 40),
		ZIndex = 10,
		Parent = rootFrame,
	})
	
	create("Frame", {
		Name = "Separator",
		BackgroundColor3 = Color3.fromRGB(200, 200, 200),
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
		TextSize = 21,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 20),
		Size = UDim2.new(0, 100, 0, 10),
		Parent = navBar,
	})
	
	backBtn.Activated:Connect(function()
		context.CloseCurrentApp()
	end)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Moments",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 15,
		Position = UDim2.new(0.25, 0, 0, 15),
		Size = UDim2.new(0.5, 0, 0, 24),
		Parent = navBar,
	})

	local selectBtn = create("TextButton", {
		Name = "SelectButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "Select",
		TextColor3 = Color3.fromRGB(0, 122, 255),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -68, 0, 15),
		Size = UDim2.new(0, 60, 0, 24),
		Parent = navBar,
	})
	
	selectBtn.Activated:Connect(function()
		TweenService:Create(selectBtn, TweenInfo.new(0.1), { TextTransparency = 0.5 }):Play()
		task.delay(0.1, function()
			TweenService:Create(selectBtn, TweenInfo.new(0.1), { TextTransparency = 0 }):Play()
		end)
	end)

	local tabBar = create("Frame", {
		Name = "TabBar",
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -40),
		Size = UDim2.new(1, 0, 0, 40),
		ZIndex = 10,
		Parent = rootFrame,
	})
	create("Frame", {
		Name = "Separator",
		BackgroundColor3 = Color3.fromRGB(200, 200, 200),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = tabBar,
	})

	local tabs = {
		{ name = "Photos", color = Color3.fromRGB(0, 122, 255) },
		{ name = "Shared", color = Color3.fromRGB(150, 150, 150) },
		{ name = "Albums", color = Color3.fromRGB(150, 150, 150) }
	}
	
	local tabWidth = 1 / #tabs
	for i, tabInfo in ipairs(tabs) do
		local btn = create("TextButton", {
			Name = tabInfo.name,
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = tabInfo.name,
			TextColor3 = tabInfo.color,
			TextSize = 12,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Position = UDim2.new((i - 1) * tabWidth, 0, 0, 3),
			Size = UDim2.new(tabWidth, 0, 1, -10),
			Parent = tabBar,
		})
		
		btn.Activated:Connect(function()
			for _, child in ipairs(tabBar:GetChildren()) do
				if child:IsA("TextButton") then
					child.TextColor3 = Color3.fromRGB(150, 150, 150)
				end
			end
			btn.TextColor3 = Color3.fromRGB(0, 122, 255)
		end)
	end

	local scrollFrame = create("ScrollingFrame", {
		Name = "PhotosGrid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 64),
		Size = UDim2.new(1, 0, 1, -113),
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = rootFrame,
	})

	local gridLayout = create("UIGridLayout", {
		CellPadding = UDim2.new(0, 2, 0, 2),
		CellSize = UDim2.new(0, 100, 0, 100), -- Ukuran awal
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scrollFrame,
	})
	
	-- Sesuaikan grid size supaya persis memuat 3 kolom tanpa spasi sisa
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
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
	end)

	local photoModal = create("Frame", {
		Name = "PhotoModal",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 50,
		Parent = rootFrame,
	})

	local modalHeader = create("Frame", {
		Name = "ModalHeader",
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 64),
		ZIndex = 52,
		Parent = photoModal,
	})
	
	local modalBackBtn = create("TextButton", {
		Name = "BackButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "く Back",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 30),
		Size = UDim2.new(0, 60, 0, 24),
		ZIndex = 53,
		Parent = modalHeader,
	})
	
	local modalDateText = create("TextLabel", {
		Name = "DateLabel",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Today",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		Position = UDim2.new(0.2, 0, 0, 30),
		Size = UDim2.new(0.6, 0, 0, 24),
		ZIndex = 53,
		Parent = modalHeader,
	})

	local pageContainer = create("Frame", {
		Name = "PageContainer",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 51,
		Parent = photoModal,
	})

	local pageLayout = create("UIPageLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		EasingStyle = Enum.EasingStyle.Cubic,
		EasingDirection = Enum.EasingDirection.Out,
		TweenTime = 0.3,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = pageContainer,
	})
	
	pageLayout:GetPropertyChangedSignal("CurrentPage"):Connect(function()
		local currentPage = pageLayout.CurrentPage
		if currentPage then
			local dateVal = currentPage:FindFirstChild("DateInfo")
			if dateVal then
				modalDateText.Text = dateVal.Value
			end
		end
	end)
	
	local function closePhoto()
		photoModal.Visible = false
	end
	
	modalBackBtn.Activated:Connect(closePhoto)

	local function loadPhotos()
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("ImageButton") then
				child:Destroy()
			end
		end
		for _, child in ipairs(pageContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local photos = saveService:Get("Photos", {})

		table.sort(photos, function(a, b)
			return (a.Timestamp or 0) < (b.Timestamp or 0)
		end)

		for i, photoData in ipairs(photos) do
			local imgUrl = getPhotoThumbnail(photoData, player)
			
			local btn = create("ImageButton", {
				Name = "Photo_" .. i,
				BackgroundColor3 = Color3.fromRGB(230, 230, 230),
				BorderSizePixel = 0,
				Image = imgUrl,
				ScaleType = Enum.ScaleType.Crop,
				LayoutOrder = i,
				Parent = scrollFrame,
			})
			
			local page = create("Frame", {
				Name = "Page_" .. i,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				LayoutOrder = i,
				Parent = pageContainer,
			})
			
			local dateVal = Instance.new("StringValue")
			dateVal.Name = "DateInfo"
			dateVal.Value = photoData.Time or "Today"
			dateVal.Parent = page
			
			local fullImg = create("ImageLabel", {
				Name = "Image",
				BackgroundTransparency = 1,
				Image = imgUrl,
				Size = UDim2.fromScale(1, 1),
				ScaleType = Enum.ScaleType.Fit,
				Parent = page,
			})
			
			btn.Activated:Connect(function()
				photoModal.Visible = true
				pageLayout:JumpTo(page)
				modalDateText.Text = dateVal.Value
			end)
		end
	end

	loadPhotos()
	
	-- Refresh fotos saat app dibuka
	rootFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if rootFrame.Visible then
			loadPhotos()
		end
	end)
	
	return rootFrame
end

return GalleryApp
