local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local root = script.Parent.Parent
local Signal = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Signal"))

local CameraService = {}
CameraService.__index = CameraService

function CameraService.new()
	local self = setmetatable({
		_active = false,
		_mode = "back", -- "back" atau "front" (selfie)
		_filter = "Normal", -- "Normal", "Mono", "Chrome", "Fade"
		_viewport = nil :: ViewportFrame?,
		_filterOverlay = nil :: Frame?,
		_renderConn = nil :: RBXScriptConnection?,
		_savedCamType = Enum.CameraType.Custom,
		_savedCamCF = CFrame.new(),
		_savedFOV = 70,

		ModeChanged = Signal.new(),
		FilterChanged = Signal.new(),
	}, CameraService)

	return self
end

function CameraService:AttachViewport(viewport: ViewportFrame, filterOverlay: Frame?)
	self:DetachViewport()

	self._viewport = viewport
	self._filterOverlay = filterOverlay
	self._active = true

	local cam = workspace.CurrentCamera
	if cam then
		self._savedCamType = cam.CameraType
		self._savedCamCF = cam.CFrame
		self._savedFOV = cam.FieldOfView
	end

	self:ApplyFilter(self._filter)
	self:_startLivePreview()
end

function CameraService:DetachViewport()
	self:_stopLivePreview()

	self._active = false
	self._viewport = nil
	self._filterOverlay = nil

	-- Restore camera type to default custom player camera
	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Custom
	end
end

function CameraService:SetMode(mode: string)
	if self._mode == mode then return end
	self._mode = mode
	self.ModeChanged:Fire(mode)

	if self._active then
		self:_stopLivePreview()
		self:_startLivePreview()
	end
end

function CameraService:ToggleMode()
	self:SetMode(if self._mode == "back" then "front" else "back")
end

function CameraService:GetMode(): string
	return self._mode
end

function CameraService:ApplyFilter(filterName: string)
	self._filter = filterName
	if self._filterOverlay then
		if filterName == "Normal" then
			self._filterOverlay.BackgroundTransparency = 1
		elseif filterName == "Mono" then
			self._filterOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			self._filterOverlay.BackgroundTransparency = 0.85
		elseif filterName == "Chrome" then
			self._filterOverlay.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
			self._filterOverlay.BackgroundTransparency = 0.92
		elseif filterName == "Fade" then
			self._filterOverlay.BackgroundColor3 = Color3.fromRGB(160, 110, 60)
			self._filterOverlay.BackgroundTransparency = 0.86
		end
	end
	self.FilterChanged:Fire(filterName)
end

function CameraService:GetFilter(): string
	return self._filter
end

function CameraService:NextFilter()
	if self._filter == "Normal" then
		self:ApplyFilter("Mono")
	elseif self._filter == "Mono" then
		self:ApplyFilter("Chrome")
	elseif self._filter == "Chrome" then
		self:ApplyFilter("Fade")
	else
		self:ApplyFilter("Normal")
	end
end

-- Start Live Camera Preview Engine (Gakuran Style)
function CameraService:_startLivePreview()
	self:_stopLivePreview()

	local player = Players.LocalPlayer
	if not player then return end

	local cam = workspace.CurrentCamera
	if not cam then return end

	if self._mode == "front" then
		-- ─── FRONT CAMERA (SELFIE MODE) ───────────────────────────
		cam.CameraType = Enum.CameraType.Scriptable

		self._renderConn = RunService.RenderStepped:Connect(function(dt: number)
			if not self._active then return end
			local char = player.Character
			if not char then return end

			local head = char:FindFirstChild("Head") :: BasePart?
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?

			local targetPart = head or hrp
			if targetPart then
				-- Position camera in front of character's head/chest facing character
				local targetCF = targetPart.CFrame * CFrame.new(0, 0.35, -3.5) * CFrame.Angles(math.rad(-6), math.rad(180), 0)
				-- Smoothly lerp camera CFrame for 60FPS fluid motion as character walks/jumps/turns
				cam.CFrame = cam.CFrame:Lerp(targetCF, math.clamp(dt * 25, 0.1, 1))
				cam.FieldOfView = 65
			end
		end)
	else
		-- ─── BACK CAMERA (REAR SPECTATE MODE) ─────────────────────
		cam.CameraType = Enum.CameraType.Custom

		-- High-performance live viewport sync:
		-- Viewfinder operates as an aperture window to workspace camera
		if self._viewport then
			self._viewport.BackgroundTransparency = 1
			-- Render a fallback ViewportFrame world model inside the cutout window if needed
			local wm = self._viewport:FindFirstChildOfClass("WorldModel") or Instance.new("WorldModel", self._viewport)
			local vpCam = self._viewport.CurrentCamera or Instance.new("Camera", self._viewport)
			self._viewport.CurrentCamera = vpCam

			self._renderConn = RunService.RenderStepped:Connect(function()
				if not self._active then return end
				local curCam = workspace.CurrentCamera
				if curCam and vpCam then
					vpCam.CFrame = curCam.CFrame
					vpCam.FieldOfView = curCam.FieldOfView
				end
			end)
		end
	end
end

function CameraService:_stopLivePreview()
	if self._renderConn then
		self._renderConn:Disconnect()
		self._renderConn = nil
	end
end

-- Capture Snapshot
function CameraService:CaptureSnapshot()
	local player = Players.LocalPlayer
	local char = player and player.Character
	local cam = workspace.CurrentCamera

	local snapshot = {
		Id = HttpService:GenerateGUID(false),
		Type = self._mode,
		Filter = self._filter,
		Aspect = "16:9",
		Timestamp = os.time(),
		TimeFormatted = DateTime.now():FormatLocalTime("MMMM D, YYYY h:mm A", "en-us"),
		UserId = player and player.UserId or 1,
		CameraCF = cam and { cam.CFrame:GetComponents() } or nil,
		FOV = cam and cam.FieldOfView or 70,
	}

	if self._mode == "front" then
		if char then
			local rootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				local pose = {}
				for _, part in ipairs(char:GetChildren()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						local cf = rootPart.CFrame:ToObjectSpace(part.CFrame)
						pose[part.Name] = { cf:GetComponents() }
					end
				end
				snapshot.Pose = pose
			end
		end
	else
		local partsSnapshot = {}
		if char and cam then
			local camCF = cam.CFrame
			for _, item in ipairs(workspace:GetChildren()) do
				if item ~= char and (item:IsA("Model") or item:IsA("BasePart")) then
					local itemRoot = item:IsA("Model") and (item:FindFirstChild("HumanoidRootPart") or item:FindFirstChildWhichIsA("BasePart")) or item
					if itemRoot then
						local dist = (camCF.Position - itemRoot.Position).Magnitude
						if dist < 50 then
							if item:IsA("BasePart") and not item.Anchored then
								table.insert(partsSnapshot, {
									Class = "BasePart",
									Size = { item.Size.X, item.Size.Y, item.Size.Z },
									Color = { item.Color.R, item.Color.G, item.Color.B },
									Material = item.Material.Name,
									CFrame = { camCF:ToObjectSpace(item.CFrame):GetComponents() },
								})
							end
						end
					end
				end
			end
		end
		snapshot.Snapshot = partsSnapshot
	end

	return snapshot
end

function CameraService:Destroy()
	self:DetachViewport()
	self.ModeChanged:Destroy()
	self.FilterChanged:Destroy()
end

return CameraService
