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

	if self._remote and self._remote:IsA("RemoteEvent") then
		self._remote.OnClientEvent:Connect(function(action: string, payload: any)
			if action == "ReceiveAirDropContact" and payload then
				self:SendNotification({
					Title = "📡 AirDrop Kontak Masuk",
					Text = (payload.senderName or "Seseorang") .. " mengirim kontak via AirDrop. Buka app Contacts!",
					Duration = 5,
				})
			elseif action == "IncomingCall" and payload then
				self:SendNotification({
					Title = "📞 Panggilan Masuk",
					Text = (payload.callerName or "Seseorang") .. " memanggil Anda... Buka app Phone!",
					Duration = 6,
				})
				if self._opened and not self._locked then
					self:OpenApp("phone")
				end
			elseif action == "ReceiveSMS" and payload then
				self:SendNotification({
					Title = "💬 Pesan Masuk",
					Text = (payload.senderName or "SMS") .. ": " .. (payload.messageText or ""),
					Duration = 5,
				})
			end
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
	if not self._opened then
		self:Open()
	end

	if self._locked and appId ~= "camera" then
		return
	end

	self._appManager:Open(appId)
end

function PhoneController:CloseCurrentApp()
	if self._locked then
		return
	end
	self._appManager:Open("home")
end

function PhoneController:SendNotification(notification: any)
	self._notifications:Send(notification)
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
