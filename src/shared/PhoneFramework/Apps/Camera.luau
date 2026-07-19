local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

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
	local saveService = context.Services.SaveService

	local root = create("Frame", {
		Name = "CameraApp",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})

	-- Status Bar (Warna putih di atas kamera)
	StatusBar.new(root, { Light = true, Carrier = "Putih-Abu", Battery = "100%" })

	-- State management
	local cameraMode = "back" -- "back" atau "front" (selfie)
	local currentFilter = "Normal" -- "Normal", "Mono", "Chrome", "Fade"
	local flashMode = "Auto" -- "Auto", "On", "Off"
	local hdrMode = "Off" -- "On", "Off"
	local activeConnections = {}
	local renderObjects = {}

	-- Sound Shutter (Gunakan default sound camera klik dari Roblox)
	local shutterSound = Instance.new("Sound")
	shutterSound.SoundId = "rbxassetid://4743477170" -- Suara jepretan kamera yang valid
	shutterSound.Volume = 0.8
	shutterSound.Parent = root

	-- ─── HEADER PANEL (Flash, HDR, Switch) ───────────────────────
	local header = create("Frame", {
		Name = "HeaderBar",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, Constants.Screen.StatusBarHeight, 0),
		Size = UDim2.new(1, 0, 0.08, 0),
		ZIndex = 52,
		Parent = root,
	})

	local flashButton = create("TextButton", {
		Name = "FlashButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⚡ Auto",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Position = UDim2.fromScale(0.04, 0.15),
		Size = UDim2.fromScale(0.2, 0.6),
		ZIndex = 53,
		Parent = header,
	})

	local hdrButton = create("TextButton", {
		Name = "HDRButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "HDR Off",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Position = UDim2.fromScale(0.38, 0.15),
		Size = UDim2.fromScale(0.24, 0.7),
		ZIndex = 53,
		Parent = header,
	})

	local switchButton = create("ImageButton", {
		Name = "SwitchButton",
		BackgroundTransparency = 1,
		Image = "rbxassetid://78679058545087", -- Icon switch/rotate camera
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.82, 0.15),
		Size = UDim2.fromScale(0.12, 0.7),
		ZIndex = 53,
		Parent = header,
	})
	create("UIAspectRatioConstraint", {
		AspectRatio = 1,
		Parent = switchButton,
	})

	-- ─── VIEWFINDER CONTAINER ──────────────────────────────────
	local viewfinderFrame = create("Frame", {
		Name = "Viewfinder",
		BackgroundColor3 = Color3.fromRGB(12, 12, 15),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.116, 0),
		Size = UDim2.new(1, 0, 0.65, 0),
		ZIndex = 51,
		ClipsDescendants = true,
		Parent = root,
	})

	local viewport = create("ViewportFrame", {
		Name = "Viewport",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 52,
		Parent = viewfinderFrame,
	})

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local viewportCamera = Instance.new("Camera")
	viewportCamera.FieldOfView = 60
	viewport.CurrentCamera = viewportCamera
	viewportCamera.Parent = viewport

	-- Filter tint/color correction overlay
	local filterOverlay = create("Frame", {
		Name = "FilterOverlay",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 53,
		Parent = viewfinderFrame,
	})

	-- Shutter Flash Overlay (Putih berkedip saat memotret)
	local flashOverlay = create("Frame", {
		Name = "FlashOverlay",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 55,
		Parent = viewfinderFrame,
	})

	-- ─── BOTTOM CONTROL BAR (Shutter, Preview, Filter) ─────────
	local controlBar = create("Frame", {
		Name = "ControlBar",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.816, 0),
		Size = UDim2.new(1, 0, 0.184, 0),
		ZIndex = 52,
		Parent = root,
	})

	-- Tombol Shutter (Bulat Putih)
	local shutterOuter = create("Frame", {
		Name = "ShutterOuter",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.85,
		Position = UDim2.fromScale(0.52, 0.4),
		Size = UDim2.fromOffset(55, 55),
		ZIndex = 53,
		Parent = controlBar,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = shutterOuter })

	local shutterInner = create("TextButton", {
		Name = "ShutterButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.51, 0.48),
		Size = UDim2.fromOffset(44, 44),
		Text = "",
		ZIndex = 54,
		Parent = shutterOuter,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = shutterInner })

	-- Preview Thumbnail (Kiri Shutter)
	local previewButton = create("ImageButton", {
		Name = "PreviewButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Position = UDim2.fromScale(0.18, 0.4),
		Size = UDim2.fromOffset(42, 42),
		ZIndex = 53,
		ClipsDescendants = true,
		Parent = controlBar,
	})
	create("UICorner", { CornerRadius = UDim.new(0.12, 0), Parent = previewButton })

	-- Filter Button (Kanan Shutter - 3 Bulatan iOS 7 style)
	local filterButton = create("ImageButton", {
		Name = "FilterButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://133785936737274", -- Bulatan bertumpuk (Filter icon)
		ImageColor3 = Color3.fromRGB(200, 200, 200),
		Position = UDim2.fromScale(0.82, 0.4),
		Size = UDim2.fromOffset(36, 36),
		ZIndex = 53,
		Parent = controlBar,
	})

	-- Label Indikator Filter Aktif di atas tombol filter
	local filterLabel = create("TextLabel", {
		Name = "FilterLabel",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Normal",
		TextColor3 = Color3.fromRGB(254, 203, 46),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.82, 0, 0.13, 0),
		Size = UDim2.fromScale(0.3, 0.15),
		Visible = false,
		ZIndex = 55,
		Parent = controlBar,
	})

	-- ─── SISTEM RENDER VIEWPORT ───────────────────────────────
	
	-- Update filter visual
	local function applyFilter(filterName)
		currentFilter = filterName
		filterLabel.Text = filterName
		filterLabel.Visible = true
		task.delay(1.2, function()
			if currentFilter == filterName then
				filterLabel.Visible = false
			end
		end)

		if filterName == "Normal" then
			viewport.ImageColor3 = Color3.fromRGB(255, 255, 255)
			filterOverlay.BackgroundTransparency = 1
		elseif filterName == "Mono" then -- Hitam Putih
			viewport.ImageColor3 = Color3.fromRGB(130, 130, 130)
			filterOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			filterOverlay.BackgroundTransparency = 0.9 -- Sedikit reduce contrast
		elseif filterName == "Chrome" then -- Vibrant/Contrast
			viewport.ImageColor3 = Color3.fromRGB(255, 230, 200)
			filterOverlay.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
			filterOverlay.BackgroundTransparency = 0.94
		elseif filterName == "Fade" then -- Sepia/Vintage
			viewport.ImageColor3 = Color3.fromRGB(220, 200, 170)
			filterOverlay.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
			filterOverlay.BackgroundTransparency = 0.88
		end
	end

	-- Menghapus objek di WorldModel
	local function clearRenderWorld()
		for _, obj in ipairs(renderObjects) do
			obj:Destroy()
		end
		table.clear(renderObjects)
		worldModel:ClearAllChildren()
	end

	-- Dapatkan part CFrame pose dari karakter asli (R6) untuk direkonstruksi nanti di Photos App
	local function getCharacterPose(char: Model)
		local pose = {}
		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if not rootPart then return nil end

		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then
				pose[item.Name] = rootPart.CFrame:ToObjectSpace(item.CFrame)
			end
		end
		return pose
	end

	-- Setup Camera Depan (Selfie)
	local function setupFrontCamera()
		clearRenderWorld()
		local char = player.Character
		if not char then return end

		char.Archivable = true
		local clone = char:Clone()
		char.Archivable = false

		-- Bersihkan script & efek suara agar aman
		for _, item in ipairs(clone:GetDescendants()) do
			if item:IsA("LuaSourceContainer") or item:IsA("Sound") or item:IsA("Animator") then
				item:Destroy()
			end
		end

		clone:TranslateBy(Vector3.new(0, 1200, 0)) -- posisikan dummy jauh di atas awan
		clone.Parent = worldModel
		table.insert(renderObjects, clone)

		local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
		local cloneHead = clone:FindFirstChild("Head")

		if cloneRoot and cloneHead then
			cloneRoot.Anchored = true
			-- Kamera diposisikan di depan wajah dummy, menatap lurus ke wajah dummy
			viewportCamera.CFrame = cloneHead.CFrame * CFrame.new(0, 0, -3.2) * CFrame.Angles(0, math.rad(180), 0)
		end

		-- Sync pose dummy dengan karakter asli agar real-time!
		local conn = RunService.RenderStepped:Connect(function()
			if not clone.Parent or not char.Parent then return end
			local charRoot = char:FindFirstChild("HumanoidRootPart")
			if not charRoot then return end

			-- Update CFrame setiap part sesuai dengan offset karakter asli
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") then
					local clonePart = clone:FindFirstChild(part.Name)
					if clonePart and clonePart:IsA("BasePart") then
						-- Posisikan relatif terhadap root dummy di 1200 studs y-offset
						local relCF = charRoot.CFrame:ToObjectSpace(part.CFrame)
						clonePart.CFrame = (charRoot.CFrame + Vector3.new(0, 1200, 0)) * relCF
					end
				end
			end
		end)
		table.insert(activeConnections, conn)
	end

	-- Setup Kamera Belakang (Merender lingkungan sekitar)
	local function setupBackCamera()
		clearRenderWorld()

		-- Letakkan dummy/pemandangan sederhana di worldmodel untuk simulasi viewfinder belakang
		-- Kita bisa meniru dunia sekitar player (Workspace) dengan melakukan clone part terdekat
		local playerChar = player.Character
		if not playerChar then return end

		local function updateBackCameraWorld()
			worldModel:ClearAllChildren()
			table.clear(renderObjects)

			-- Cari part/model terdekat di depan pemain
			local playerRoot = playerChar:FindFirstChild("HumanoidRootPart")
			if not playerRoot then return end

			-- Buat grid baseplate kecil di dalam viewport sebagai lantai
			local base = Instance.new("Part")
			base.Size = Vector3.new(100, 1, 100)
			base.Color = Color3.fromRGB(60, 60, 65)
			base.Material = Enum.Material.SmoothPlastic
			base.Anchored = true
			base.Position = playerRoot.Position + Vector3.new(0, -3.5, 0)
			base.Parent = worldModel
			table.insert(renderObjects, base)

			-- Cari model-model terdekat (pemain lain, rig, part berukuran wajar)
			for _, item in ipairs(workspace:GetChildren()) do
				if item ~= playerChar and (item:IsA("Model") or (item:IsA("BasePart") and not item.Anchored)) then
					local root = item:FindFirstChild("HumanoidRootPart") or item:FindFirstChildWhichIsA("BasePart")
					if root then
						local dist = (playerRoot.Position - root.Position).Magnitude
						if dist < 35 then
							item.Archivable = true
							local c = item:Clone()
							item.Archivable = false
							
							-- Hapus scripts
							for _, sub in ipairs(c:GetDescendants()) do
								if sub:IsA("LuaSourceContainer") or sub:IsA("Sound") then
									sub:Destroy()
								end
							end
							c.Parent = worldModel
							table.insert(renderObjects, c)
						end
					end
				end
			end
		end

		updateBackCameraWorld()

		-- Jalankan loop update berkala untuk part terdekat dan posisi kamera
		local lastUpdate = 0
		local conn = RunService.RenderStepped:Connect(function()
			-- Kamera viewport mengikuti kamera game player
			viewportCamera.CFrame = workspace.CurrentCamera.CFrame

			local now = os.clock()
			if now - lastUpdate > 0.8 then -- Update isi workspace setiap 0.8s agar tidak berat
				lastUpdate = now
				updateBackCameraWorld()
			end
		end)
		table.insert(activeConnections, conn)
	end

	-- Switch Camera Toggle
	local function toggleCameraSource()
		-- Animasi flip screen
		local flipTween = TweenService:Create(viewport, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0, 1),
			Position = UDim2.fromScale(0.5, 0)
		})
		flipTween:Play()
		flipTween.Completed:Once(function()
			-- Putuskan koneksi loop render lama
			for _, conn in ipairs(activeConnections) do
				conn:Disconnect()
			end
			table.clear(activeConnections)

			-- Ganti mode
			if cameraMode == "back" then
				cameraMode = "front"
				setupFrontCamera()
			else
				cameraMode = "back"
				setupBackCamera()
			end

			-- Flip kembali
			TweenService:Create(viewport, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0, 0)
			}):Play()
		end)
	end

	-- Update preview thumbnail dari simpanan SaveService
	local function updatePreviewThumbnail()
		local photos = saveService:Get("Photos", {})
		if #photos > 0 then
			local lastPhoto = photos[#photos]
			if lastPhoto.Type == "front" then
				-- Untuk selfie, tampilkan icon default selfie atau placeholder
				previewButton.Image = "rbxassetid://101194280432848" -- Icon photos
			else
				previewButton.Image = "rbxassetid://101194280432848"
			end
		else
			previewButton.Image = ""
		end
	end

	-- ─── INTERAKSI TOMBOL-TOMBOL ─────────────────────────────
	
	-- Toggle Flash
	flashButton.Activated:Connect(function()
		if flashMode == "Auto" then
			flashMode = "On"
			flashButton.Text = "⚡ On"
		elseif flashMode == "On" then
			flashMode = "Off"
			flashButton.Text = "⚡ Off"
		else
			flashMode = "Auto"
			flashButton.Text = "⚡ Auto"
		end
	end)

	-- Toggle HDR
	hdrButton.Activated:Connect(function()
		if hdrMode == "Off" then
			hdrMode = "On"
			hdrButton.TextColor3 = Color3.fromRGB(254, 203, 46) -- Warna kuning aktif
			hdrButton.Text = "HDR On"
		else
			hdrMode = "Off"
			hdrButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			hdrButton.Text = "HDR Off"
		end
	end)

	-- Rotate Camera
	switchButton.Activated:Connect(toggleCameraSource)

	-- Filter Button
	filterButton.Activated:Connect(function()
		if currentFilter == "Normal" then
			applyFilter("Mono")
		elseif currentFilter == "Mono" then
			applyFilter("Chrome")
		elseif currentFilter == "Chrome" then
			applyFilter("Fade")
		else
			applyFilter("Normal")
		end
	end)

	-- Shutter Klik (Jepret Foto!)
	shutterInner.Activated:Connect(function()
		-- Mainkan sound jepretan
		shutterSound:Play()

		-- Efek Flash Shutter (Kedipan putih di viewfinder)
		flashOverlay.BackgroundTransparency = 0
		TweenService:Create(flashOverlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()

		-- Simpan data metadata foto ke SaveService
		local photos = saveService:Get("Photos", {})
		local char = player.Character
		local poseData = (cameraMode == "front" and char) and getCharacterPose(char) or nil

		local photoId = tostring(math.random(100000, 999999))
		table.insert(photos, {
			Id = photoId,
			Type = cameraMode,
			Filter = currentFilter,
			Time = DateTime.now():FormatLocalTime("MMMM D, YYYY h:mm A", "en-us"),
			Timestamp = os.time(),
			Pose = poseData
		})
		saveService:Set("Photos", photos)

		-- Update thumbnail di pojok kiri bawah
		updatePreviewThumbnail()

		-- Animasi thumbnail bounce saat foto berhasil diambil
		previewButton.Size = UDim2.fromOffset(10, 10)
		TweenService:Create(previewButton, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(42, 42)
		}):Play()
	end)

	-- Buka Photos App saat Preview diklik
	previewButton.Activated:Connect(function()
		context.OpenApp("gallery") -- gallery = Photos app
	end)

	-- Inisialisasi awal
	setupBackCamera()
	updatePreviewThumbnail()

	-- Bersihkan loop koneksi saat App di-destroy
	root.Destroying:Connect(function()
		for _, conn in ipairs(activeConnections) do
			conn:Disconnect()
		end
		clearRenderWorld()
	end)

	return root
end

return CameraApp
