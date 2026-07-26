local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local IPhone5Device = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("IPhone5Device"))
local AnimationController = require(script.Parent:WaitForChild("AnimationController"))
local AppManager = require(script.Parent:WaitForChild("AppManager"))
local NotificationManager = require(script.Parent:WaitForChild("NotificationManager"))
local InputManager = require(script.Parent:WaitForChild("InputManager"))
local PlayerArmAnimation = require(script.Parent:WaitForChild("PlayerArmAnimation"))
local CameraService = require(root:WaitForChild("Services"):WaitForChild("CameraService"))
local AudioService = require(root:WaitForChild("Services"):WaitForChild("AudioService"))
local SaveService = require(root:WaitForChild("Services"):WaitForChild("SaveService"))

local PhoneController = {}
PhoneController.__index = PhoneController

function PhoneController.new()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "IPhone5Framework"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local device = IPhone5Device.new(gui)
	local animator = AnimationController.new(device)

	local self = setmetatable({
		_player = player,
		_gui = gui,
		_device = device,
		_animator = animator,
		_armAnim = PlayerArmAnimation.new(),
		_opened = false,
		_locked = true,
		_autoCloseNotif = false,
		_remote = ReplicatedStorage:WaitForChild(Constants.RemoteName, 10),
		_services = {
			CameraService = CameraService.new(),
			AudioService = AudioService.new(),
			SaveService = SaveService.new(),
		},
	}, PhoneController)

	local context = {
		Root = device.Root,
		Screen = device.ScreenContent,
		Services = self._services,
		OpenApp = function(appId: string)
			self:OpenApp(appId)
		end,
		CloseCurrentApp = function()
			self:CloseCurrentApp()
		end,
		Unlock = function()
			self:Unlock()
		end,
		Lock = function()
			self:Lock()
		end,
		SendNotification = function(notification: any)
			self:SendNotification(notification)
		end,
		GetApps = function()
			return self._appManager:GetApps()
		end,
	}

	self._appManager = AppManager.new(context, device.ScreenContent, animator)
	self._notifications = NotificationManager.new(device.ScreenContent)
	self._appManager:RegisterFolder(script.Parent.Parent:WaitForChild("Apps"))
	self._inputManager = InputManager.new(self)
	self._appManager:Open("lock")

	device.HomeButton.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if self._locked then
				self:Unlock()
			else
				self:CloseCurrentApp()
			end
		end
	end)

	local function resolveContactName(phone: string?, fallbackName: string?): string
		local rawPhone = phone or fallbackName or ""
		local targetClean = string.gsub(rawPhone, "[%s%-]", "")
		if targetClean == "" then return rawPhone end

		local saveSvc = self._services and self._services.SaveService
		local contacts = if saveSvc then saveSvc:Get("Contacts", {}) else {}
		for _, c in ipairs(contacts) do
			local cPhone = string.gsub(c.Phone or "", "[%s%-]", "")
			if cPhone == targetClean and c.Name and c.Name ~= "" then
				return c.Name
			end
		end
		return rawPhone
	end

	if self._remote and self._remote:IsA("RemoteEvent") then
		self._remote.OnClientEvent:Connect(function(action: string, payload: any)
			if action == "LoadPhoneData" and payload then
				if self._services and self._services.SaveService then
					self._services.SaveService:LoadData(payload)
				end
			elseif action == "ReceiveAirDropContact" and payload then
				self:SendNotification({
					AppId = "contacts",
					AppName = "Contacts",
					AppIcon = "rbxassetid://114778546922350",
					Title = "📡 AirDrop Kontak Masuk",
					Body = resolveContactName(payload.contactData and payload.contactData.Phone, payload.senderName) .. " mengirim kontak via AirDrop.",
					Duration = 5,
				})
			elseif action == "IncomingCall" and payload then
				local callerDisp = resolveContactName(payload.callerPhone, payload.callerName)
				self:SendNotification({
					AppId = "phone",
					AppName = "Phone",
					AppIcon = "rbxassetid://71727318918905",
					Title = "📞 Panggilan Masuk",
					Body = callerDisp .. " memanggil Anda...",
					Duration = 6,
				})
				-- Requirement 3: Panggilan Masuk Membuka HP Otomatis
				if not self._opened then
					self:Open()
				end
				self._locked = false
				self._autoCloseNotif = false
				if self._inputManager then
					self._inputManager:SetButtonVisualState(true)
				end
				self._appManager:Open("phone")

			elseif action == "ReceiveSMS" and payload then
				local senderDisp = resolveContactName(payload.senderPhone, payload.senderName)
				self:SendNotification({
					AppId = "messages",
					AppName = "Messages",
					AppIcon = "rbxassetid://108650574179237",
					Title = "💬 Pesan Masuk",
					Body = senderDisp .. ": " .. (payload.messageText or ""),
					Duration = 5,
				})
			end
		end)

		-- Minta data telepon yang tersimpan di DataStore server saat pertama kali muat
		task.defer(function()
			self._remote:FireServer("RequestPhoneData")
		end)
	end

	return self
end

function PhoneController:_setHolding(isHolding: boolean)
	if self._remote and self._remote:IsA("RemoteEvent") then
		self._remote:FireServer("SetHolding", isHolding)
	end
end

function PhoneController:Open()
	if self._opened then
		return
	end

	self._opened = true
	self._locked = true
	self._appManager:Open("lock")
	self:_setHolding(true)
	self._animator:Open()
	-- Animasi tangan memegang HP
	local character = self._player.Character
	if character then
		self._armAnim:PlayHold(character)
	end
	if self._inputManager then
		self._inputManager:SetButtonVisualState(true)
	end
end

function PhoneController:Close()
	if not self._opened then
		return
	end

	self._opened = false
	self._animator:Close(function()
		self._appManager:CloseCurrent()
		self._locked = true
		self._appManager:Open("lock")
	end)
	self:_setHolding(false)
	-- Animasi masukkan HP ke kantong
	local character = self._player.Character
	if character then
		self._armAnim:PlayPocket(character)
	end
	if self._inputManager then
		self._inputManager:SetButtonVisualState(false)
	end
end

function PhoneController:Lock()
	self._locked = true
	self._appManager:Open("lock")
	self._animator:FadeScreen(1)
	if self._inputManager then
		self._inputManager:SetButtonVisualState(false)
	end
end

function PhoneController:Unlock()
	self._autoCloseNotif = false
	if not self._opened then
		return
	end

	self._locked = false
	self._appManager:Open("home")
	if self._inputManager then
		self._inputManager:SetButtonVisualState(true)
	end
end

function PhoneController:OpenApp(appId: string)
	self._autoCloseNotif = false
	if not self._opened then
		self:Open()
	end

	if self._locked and appId ~= "camera" then
		return
	end

	self._appManager:Open(appId)
end

function PhoneController:CloseCurrentApp()
	self._autoCloseNotif = false
	if self._locked then
		return
	end
	self._appManager:Open("home")
end

function PhoneController:SendNotification(notification: any)
	-- Cek apakah HP sedang dibuka & pemain sedang di aplikasi penerima event
	-- Gunakan _currentAppId langsung (AppManager tidak punya GetCurrentAppId)
	local currentApp = ""
	if self._opened and not self._locked and self._appManager then
		currentApp = string.lower(self._appManager._currentAppId or "")
	end

	local notifApp = string.lower(notification.AppId or notification.App or "")

	-- Kontekstual: Jika pemain sedang AKTIF di aplikasi yang menerima event tersebut,
	-- jangan tampilkan banner (informasi sudah terlihat langsung di dalam aplikasi).
	-- Tapi tetap tampilkan jika di Home Screen (currentApp == "home") atau aplikasi lain.
	if self._opened and not self._locked
		and notifApp ~= ""
		and currentApp ~= ""
		and currentApp ~= "home"
		and currentApp == notifApp
	then
		return
	end

	local wereClosed = not self._opened

	if wereClosed then
		self:Open()
		self._autoCloseNotif = true
	end

	self._notifications:Send(
		notification,
		function(wasClicked: boolean)
			if wasClicked then
				self._autoCloseNotif = false
				if notification.AppId then
					self:Unlock()
					self:OpenApp(notification.AppId)
				end
			end
		end,
		function()
			if self._autoCloseNotif and self._opened then
				self._autoCloseNotif = false
				self:Close()
			end
		end
	)
end

function PhoneController:IsOpened()
	return self._opened
end

function PhoneController:IsLocked()
	return self._locked
end

function PhoneController:Destroy()
	self:_setHolding(false)
	if self._inputManager then
		self._inputManager:Destroy()
	end
	if self._appManager then
		self._appManager:Destroy()
	end
	self._gui:Destroy()
end

return PhoneController
