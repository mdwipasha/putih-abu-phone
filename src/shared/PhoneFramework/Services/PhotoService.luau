local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local root = script.Parent.Parent
local Signal = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Signal"))

local PhotoService = {}
PhotoService.__index = PhotoService

function PhotoService.new(saveService: any)
	local self = setmetatable({
		_saveService = saveService,
		PhotosChanged = Signal.new(),
	}, PhotoService)

	if self._saveService then
		self._saveService.Changed:Connect(function(key: string, value: any)
			if key == "Photos" then
				self.PhotosChanged:Fire(self:GetPhotos())
			end
		end)
	end

	return self
end

-- Safely execute DataStore operation with pcall & retry logic
local function safeExecute<T>(op: () -> T, maxRetries: number?): (boolean, T?)
	local retries = maxRetries or 3
	for attempt = 1, retries do
		local ok, res = pcall(op)
		if ok then
			return true, res
		end
		warn("[PhotoService] DataStore operation attempt " .. attempt .. " failed: " .. tostring(res))
		if attempt < retries then
			task.wait(0.5 * attempt)
		end
	end
	return false, nil
end

-- Returns all saved photos sorted descending by Timestamp (NEWEST FIRST)
function PhotoService:GetPhotos()
	if not self._saveService then return {} end
	local photos = self._saveService:Get("Photos", {})
	local result = {}

	if type(photos) == "table" then
		for _, p in ipairs(photos) do
			if type(p) == "table" then
				table.insert(result, p)
			end
		end
	end

	-- Sort descending by timestamp (newest first)
	table.sort(result, function(a, b)
		return (a.Timestamp or 0) > (b.Timestamp or 0)
	end)

	return result
end

-- Returns the newest photo (first in list)
function PhotoService:GetLatestPhoto()
	local photos = self:GetPhotos()
	return photos[1]
end

-- Save photo snapshot to DataStore with pcall retry error handling
function PhotoService:SavePhoto(photoData: table)
	if not self._saveService then return false end
	if type(photoData) ~= "table" then return false end

	if not photoData.Id then
		photoData.Id = HttpService:GenerateGUID(false)
	end
	if not photoData.Timestamp then
		photoData.Timestamp = os.time()
	end
	if not photoData.TimeFormatted then
		photoData.TimeFormatted = DateTime.now():FormatLocalTime("MMMM D, YYYY h:mm A", "en-us")
	end

	local ok, err = safeExecute(function()
		local currentPhotos = self._saveService:Get("Photos", {})
		local updated = {}
		if type(currentPhotos) == "table" then
			for _, p in ipairs(currentPhotos) do
				table.insert(updated, p)
			end
		end
		table.insert(updated, photoData)
		self._saveService:Set("Photos", updated)
		return true
	end, 3)

	if ok then
		self.PhotosChanged:Fire(self:GetPhotos())
		return true
	else
		warn("[PhotoService] Failed to save photo: " .. tostring(err))
		return false
	end
end

-- Delete photo by ID with pcall retry error handling
function PhotoService:DeletePhoto(photoId: string)
	if not self._saveService or not photoId then return false end

	local ok, err = safeExecute(function()
		local currentPhotos = self._saveService:Get("Photos", {})
		local updated = {}
		if type(currentPhotos) == "table" then
			for _, p in ipairs(currentPhotos) do
				if p.Id ~= photoId then
					table.insert(updated, p)
				end
			end
		end
		self._saveService:Set("Photos", updated)
		return true
	end, 3)

	if ok then
		self.PhotosChanged:Fire(self:GetPhotos())
		return true
	else
		warn("[PhotoService] Failed to delete photo: " .. tostring(err))
		return false
	end
end

-- Render photo snapshot into any ViewportFrame (for grid, thumbnail, or fullscreen view)
function PhotoService:RenderPhotoToViewport(viewport: ViewportFrame, photoData: table)
	if not viewport or not photoData then return end

	viewport:ClearAllChildren()

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local viewportCam = Instance.new("Camera")
	viewportCam.FieldOfView = 60
	viewportCam.Parent = viewport
	viewport.CurrentCamera = viewportCam

	-- Apply Filter Overlay Color / Tint
	local filter = photoData.Filter or "Normal"
	if filter == "Normal" then
		viewport.ImageColor3 = Color3.fromRGB(255, 255, 255)
	elseif filter == "Mono" then
		viewport.ImageColor3 = Color3.fromRGB(130, 130, 130)
	elseif filter == "Chrome" then
		viewport.ImageColor3 = Color3.fromRGB(255, 230, 200)
	elseif filter == "Fade" then
		viewport.ImageColor3 = Color3.fromRGB(220, 200, 170)
	end

	local localPlayer = Players.LocalPlayer

	if photoData.Type == "front" then
		-- Render Selfie Avatar
		local char = localPlayer and localPlayer.Character
		if char then
			char.Archivable = true
			local clone = char:Clone()
			char.Archivable = false

			for _, sub in ipairs(clone:GetDescendants()) do
				if sub:IsA("LuaSourceContainer") or sub:IsA("Sound") or sub:IsA("Animator") then
					sub:Destroy()
				end
			end

			local cloneRoot = clone:FindFirstChild("HumanoidRootPart") :: BasePart?
			local cloneHead = clone:FindFirstChild("Head") :: BasePart?

			if cloneRoot then
				cloneRoot.Anchored = true
				if photoData.Pose then
					for partName, components in pairs(photoData.Pose) do
						local p = clone:FindFirstChild(partName)
						if p and p:IsA("BasePart") then
							local relCF = CFrame.new(unpack(components))
							p.CFrame = cloneRoot.CFrame * relCF
						end
					end
				end

				clone.Parent = worldModel

				if cloneHead then
					viewportCam.CFrame = cloneHead.CFrame * CFrame.new(0, 0.4, -3.4) * CFrame.Angles(math.rad(-6), math.rad(180), 0)
				else
					viewportCam.CFrame = cloneRoot.CFrame * CFrame.new(0, 0.5, -3.5) * CFrame.Angles(0, math.rad(180), 0)
				end
			end
		end
	else
		-- Render Back Camera Snapshot
		viewportCam.CFrame = CFrame.new(0, 0, 0)

		local base = Instance.new("Part")
		base.Size = Vector3.new(60, 1, 60)
		base.Color = Color3.fromRGB(50, 52, 58)
		base.Material = Enum.Material.SmoothPlastic
		base.Anchored = true
		base.CFrame = CFrame.new(0, -3.5, -10)
		base.Parent = worldModel

		if photoData.Snapshot and #photoData.Snapshot > 0 then
			for _, item in ipairs(photoData.Snapshot) do
				if item.Class == "BasePart" and item.CFrame then
					local p = Instance.new("Part")
					p.Size = Vector3.new(unpack(item.Size or {2, 2, 2}))
					p.Color = Color3.new(unpack(item.Color or {0.8, 0.8, 0.8}))
					p.Material = Enum.Material[item.Material] or Enum.Material.SmoothPlastic
					p.Anchored = true
					p.CFrame = CFrame.new(unpack(item.CFrame))
					p.Parent = worldModel
				end
			end
		else
			-- Fallback visual
			local demoBlock = Instance.new("Part")
			demoBlock.Size = Vector3.new(4, 4, 4)
			demoBlock.Color = Color3.fromRGB(18, 129, 91)
			demoBlock.Anchored = true
			demoBlock.CFrame = CFrame.new(0, 0, -8) * CFrame.Angles(0.3, 0.4, 0)
			demoBlock.Parent = worldModel
		end
	end
end

function PhotoService:Destroy()
	self.PhotosChanged:Destroy()
end

return PhotoService
