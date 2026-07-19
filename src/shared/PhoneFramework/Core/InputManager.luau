local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Constants = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("Constants"))
local create = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

local InputManager = {}
InputManager.__index = InputManager

function InputManager.new(phone: any)
	local self = setmetatable({
		_phone = phone,
		_connections = {},
	}, InputManager)

	-- Register keyboard/mouse toggle input
	table.insert(
		self._connections,
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end

			if input.KeyCode == Constants.Input.ToggleKey then
				self:TogglePhone()
			elseif input.KeyCode == Constants.Input.CloseKey and phone:IsOpened() then
				phone:Close()
			end
		end)
	)

	-- Deteksi perangkat mobile (Touch screen, tidak ada keyboard default)
	if UserInputService.TouchEnabled then
		self:CreateMobileToggleButton(phone)
	end

	return self
end

function InputManager:TogglePhone()
	if self._phone:IsOpened() then
		self._phone:Close()
	else
		self._phone:Open()
	end
end

function InputManager:CreateMobileToggleButton(phone: any)
	-- Gunakan ScreenGui yang sama dari phone controller
	local gui = phone._gui
	if not gui then return end

	-- Container ScreenGui khusus untuk Mobile Button agar selalu di atas
	local mobileGui = Instance.new("ScreenGui")
	mobileGui.Name = "PhoneMobileButton"
	mobileGui.ResetOnSpawn = false
	mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mobileGui.Parent = gui.Parent -- dimasukkan langsung ke PlayerGui agar terpisah

	-- Buat tombol utama (default: hijau telepon)
	local toggleButton = create("ImageButton", {
		Name = "TogglePhoneButton",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(33, 213, 66), -- Hijau iOS telepon
		BackgroundTransparency = 0.1,
		Position = UDim2.new(1, -25, 0.5, 0), -- di kanan tengah layar agar mudah dijangkau jempol
		Size = UDim2.fromOffset(60, 60),
		ZIndex = 9999,
		Parent = mobileGui,
	})
	self._toggleButton = toggleButton
	
	create("UICorner", {
		CornerRadius = UDim.new(1, 0), -- Lingkaran sempurna
		Parent = toggleButton,
	})

	create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 2,
		Transparency = 0.15,
		Parent = toggleButton,
	})

	-- Icon handphone di dalam tombol
	local icon = create("ImageLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://71727318918905", -- Icon phone rbxassetid
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.6, 0.6),
		ZIndex = 10000,
		Parent = toggleButton,
	})

	-- Mikro-animasi saat ditekan (Bounce Effect)
	local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local shrinkTween = TweenService:Create(toggleButton, tweenInfo, {
		Size = UDim2.fromOffset(50, 50)
	})
	local restoreTween = TweenService:Create(toggleButton, tweenInfo, {
		Size = UDim2.fromOffset(60, 60)
	})

	toggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			shrinkTween:Play()
		end
	end)

	toggleButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			restoreTween:Play()
		end
	end)

	toggleButton.Activated:Connect(function()
		self:TogglePhone()
	end)

	table.insert(self._connections, mobileGui)
end

function InputManager:SetButtonVisualState(opened)
	if not self._toggleButton then return end

	local targetPosition
	local targetColor
	local targetRotation

	if opened then
		-- HP terbuka: Geser ke kiri di luar frame HP (-275px dari kanan layar)
		-- Warna berubah menjadi merah (seperti matikan panggilan/tutup)
		targetPosition = UDim2.new(1, -265, 0.5, 0)
		targetColor = Color3.fromRGB(255, 50, 50) -- Merah iOS
		targetRotation = 135 -- Putar miring untuk estetika
	else
		-- HP tertutup: Kembali ke pinggir kanan layar dengan warna hijau
		targetPosition = UDim2.new(1, -25, 0.5, 0)
		targetColor = Color3.fromRGB(33, 213, 66) -- Hijau iOS
		targetRotation = 0
	end

	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(self._toggleButton, tweenInfo, {
		Position = targetPosition,
		BackgroundColor3 = targetColor,
		Rotation = targetRotation
	}):Play()
end

function InputManager:Destroy()
	for _, connection in ipairs(self._connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		elseif connection:IsA("Instance") then
			connection:Destroy()
		end
	end
	table.clear(self._connections)
end

return InputManager
