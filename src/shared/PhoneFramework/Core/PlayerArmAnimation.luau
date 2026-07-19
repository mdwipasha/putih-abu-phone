--[[
	PlayerArmAnimation.luau
	Menganimasikan tangan kanan player R6 menggunakan Motor6D tweak
	saat membuka dan menutup HP.

	Saat BUKA:
	  - Tangan kanan terangkat ke depan, siku tertekuk, seolah melihat HP
	Saat TUTUP:
	  - Tangan bergerak ke samping bawah (arah kantong), lalu kembali idle
--]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local PlayerArmAnimation = {}
PlayerArmAnimation.__index = PlayerArmAnimation

-- CFrame pose untuk Right Shoulder Motor6D di R6
-- (Motor6D CFrame0 → CFrame1 = offset dari joint ke arm)
-- Default R6 Right Shoulder idle: CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), 0)

local POSE_IDLE = CFrame.Angles(0, math.rad(90), 0)
-- Tangan terangkat ke depan: rotasi ke atas ~75° dan ke depan
local POSE_HOLD = CFrame.Angles(math.rad(-75), math.rad(90), math.rad(10))
-- Pose kantong: tangan turun & sedikit ke depan
local POSE_POCKET = CFrame.Angles(math.rad(25), math.rad(90), math.rad(-8))

local TWEEN_HOLD = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_POCKET = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local TWEEN_IDLE = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

function PlayerArmAnimation.new()
	local self = setmetatable({}, PlayerArmAnimation)
	self._activeTweens = {}
	self._currentPose = "idle"
	return self
end

function PlayerArmAnimation:_getMotor(character)
	-- R6: Motor6D ada di Torso dengan nama "Right Shoulder"
	local torso = character:FindFirstChild("Torso")
	if torso then
		local motor = torso:FindFirstChild("Right Shoulder")
		if motor and motor:IsA("Motor6D") then
			return motor
		end
	end

	-- R15 fallback: Motor6D di RightUpperArm
	local upperArm = character:FindFirstChild("RightUpperArm")
	if upperArm then
		local motor = upperArm:FindFirstChild("RightShoulderRigAttachment")
			or upperArm:FindFirstChildWhichIsA("Motor6D")
		if motor and motor:IsA("Motor6D") then
			return motor
		end
	end

	return nil
end

function PlayerArmAnimation:_cancelAll()
	for _, tween in ipairs(self._activeTweens) do
		tween:Cancel()
	end
	table.clear(self._activeTweens)
end

function PlayerArmAnimation:_tweenMotor(motor, targetCF, tweenInfo, onComplete)
	self:_cancelAll()
	local tween = TweenService:Create(motor, tweenInfo, { Transform = targetCF })
	table.insert(self._activeTweens, tween)
	if onComplete then
		tween.Completed:Once(onComplete)
	end
	tween:Play()
end

-- Animasi memegang HP: tangan naik ke depan wajah
function PlayerArmAnimation:PlayHold(character)
	if self._currentPose == "hold" then return end
	self._currentPose = "hold"

	local motor = self:_getMotor(character)
	if not motor then return end

	self:_tweenMotor(motor, POSE_HOLD, TWEEN_HOLD)
end

-- Animasi tutup HP: tangan ke kantong, lalu balik idle
function PlayerArmAnimation:PlayPocket(character)
	if self._currentPose == "idle" then return end
	self._currentPose = "idle"

	local motor = self:_getMotor(character)
	if not motor then return end

	-- Fase 1: turun ke posisi kantong
	self:_tweenMotor(motor, POSE_POCKET, TWEEN_POCKET, function()
		-- Fase 2: balik ke idle setelah sebentar
		task.delay(0.12, function()
			if self._currentPose == "idle" and motor and motor.Parent then
				self:_tweenMotor(motor, POSE_IDLE, TWEEN_IDLE)
			end
		end)
	end)
end

-- Reset paksa ke idle (misal saat respawn)
function PlayerArmAnimation:Reset(character)
	self._currentPose = "idle"
	local motor = self:_getMotor(character)
	if motor then
		self:_tweenMotor(motor, POSE_IDLE, TWEEN_IDLE)
	end
end

return PlayerArmAnimation
