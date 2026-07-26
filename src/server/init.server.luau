local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.PhoneFramework.Shared.Constants)
local Economy = require(script:WaitForChild("EconomyFramework"):WaitForChild("API"):WaitForChild("Economy"))

local remote = ReplicatedStorage:FindFirstChild(Constants.RemoteName)
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = Constants.RemoteName
	remote.Parent = ReplicatedStorage
end

local function cleanPhone(rawPhone: any): string
	if typeof(rawPhone) ~= "string" then return "" end
	return rawPhone:gsub("[%s%-]", "")
end

local function getPlayerPhone(p: Player): string
	local phone = Economy.GetPhoneNumber(p)
	if not phone or phone == "" or phone == "-" then
		phone = "08" .. tostring(math.abs(p.UserId))
	end
	return phone
end

local function findPlayerByPhoneNum(rawPhone: string): Player?
	local phoneStr = cleanPhone(rawPhone)
	if phoneStr == "" then return nil end

	local found = Economy.FindPlayerByPhone(phoneStr)
	if found then return found end

	for _, p in ipairs(Players:GetPlayers()) do
		local pPhone = cleanPhone(getPlayerPhone(p))
		if pPhone == phoneStr then
			return p
		end
	end
	return nil
end

-- Warna iPhone 5 Gold / Champagne
local COLOR_BODY       = Color3.fromRGB(212, 190, 150)  -- bodi gold champagne
local COLOR_EDGE       = Color3.fromRGB(198, 174, 120)  -- trim metal tepi
local COLOR_SCREEN     = Color3.fromRGB(8, 10, 16)      -- layar hitam
local COLOR_BEZEL      = Color3.fromRGB(18, 18, 20)     -- bezel hitam
local COLOR_HOME       = Color3.fromRGB(232, 228, 218)  -- home button silver
local COLOR_HOME_RING  = Color3.fromRGB(180, 165, 130)  -- ring home button
local COLOR_CAMERA     = Color3.fromRGB(22, 22, 28)     -- kamera
local COLOR_FLASH      = Color3.fromRGB(220, 180, 80)   -- led flash
local COLOR_SPEAKER    = Color3.fromRGB(40, 38, 35)     -- speaker grill

-- Ukuran iPhone 5 (dalam studs, skala ~1:8)
local PHONE_W = 0.54  -- lebar
local PHONE_H = 0.07  -- ketebalan
local PHONE_L = 1.05  -- panjang (tinggi HP)

local function weld(part0: BasePart, part1: BasePart): WeldConstraint
	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = part1
	w.Parent = part1
	return w
end

local function makePart(model: Model, name: string, size: Vector3, color: Color3, material: Enum.Material?, offsetCF: CFrame, bodyPart: BasePart): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CFrame = bodyPart.CFrame * offsetCF
	p.Parent = model
	weld(bodyPart, p)
	return p
end

local function getHand(character: Model): BasePart?
	return (character:FindFirstChild("RightHand")
		or character:FindFirstChild("Right Arm")
		or character:FindFirstChild("RightLowerArm")) :: BasePart?
end

local function removePhone(character: Model)
	local existing = character:FindFirstChild("VisiblePhone")
	if existing then
		existing:Destroy()
	end
end

local function addPhone(character: Model)
	removePhone(character)

	local hand = getHand(character)
	if not hand then return end

	local model = Instance.new("Model")
	model.Name = "VisiblePhone"

	-- ─── BODY UTAMA ──────────────────────────────────────────────
	local body = Instance.new("Part")
	body.Name = "PhoneBody"
	body.Anchored = false
	body.CanCollide = false
	body.Massless = true
	body.CastShadow = false
	body.Color = COLOR_BODY
	body.Material = Enum.Material.SmoothPlastic
	body.Size = Vector3.new(PHONE_W, PHONE_H, PHONE_L)
	-- Posisi: di atas telapak tangan, layar menghadap ke atas (ke arah wajah player)
	body.CFrame = hand.CFrame
		* CFrame.new(0, -0.22, -0.28)
		* CFrame.Angles(math.rad(35), math.rad(0), math.rad(0))
	body.Parent = model
	model.PrimaryPart = body

	-- Weld ke tangan
	local mainWeld = Instance.new("WeldConstraint")
	mainWeld.Part0 = hand
	mainWeld.Part1 = body
	mainWeld.Parent = body

	-- ─── LAYAR (SCREEN) ──────────────────────────────────────────
	makePart(model, "Screen", Vector3.new(PHONE_W * 0.74, PHONE_H * 0.3, PHONE_L * 0.64),
		COLOR_SCREEN, Enum.Material.Glass,
		CFrame.new(0, PHONE_H * 0.65, PHONE_L * 0.02), body)

	-- ─── BEZEL ATAS (area speaker + kamera depan) ────────────────
	makePart(model, "BezelTop", Vector3.new(PHONE_W * 0.9, PHONE_H * 0.28, PHONE_L * 0.135),
		COLOR_BEZEL, Enum.Material.SmoothPlastic,
		CFrame.new(0, PHONE_H * 0.65, PHONE_L * 0.42), body)

	-- ─── BEZEL BAWAH (area home button) ──────────────────────────
	makePart(model, "BezelBottom", Vector3.new(PHONE_W * 0.9, PHONE_H * 0.28, PHONE_L * 0.135),
		COLOR_BEZEL, Enum.Material.SmoothPlastic,
		CFrame.new(0, PHONE_H * 0.65, -PHONE_L * 0.42), body)

	-- ─── SPEAKER GRILL (atas layar) ──────────────────────────────
	makePart(model, "SpeakerGrill", Vector3.new(PHONE_W * 0.28, PHONE_H * 0.12, PHONE_L * 0.018),
		COLOR_SPEAKER, Enum.Material.SmoothPlastic,
		CFrame.new(0, PHONE_H * 0.7, PHONE_L * 0.432), body)

	-- ─── KAMERA DEPAN ────────────────────────────────────────────
	makePart(model, "FrontCamera", Vector3.new(PHONE_W * 0.06, PHONE_H * 0.12, PHONE_W * 0.06),
		COLOR_CAMERA, Enum.Material.Glass,
		CFrame.new(PHONE_W * 0.22, PHONE_H * 0.7, PHONE_L * 0.43), body)

	-- ─── HOME BUTTON RING ─────────────────────────────────────────
	makePart(model, "HomeButtonRing", Vector3.new(PHONE_W * 0.22, PHONE_H * 0.18, PHONE_W * 0.22),
		COLOR_HOME_RING, Enum.Material.Metal,
		CFrame.new(0, PHONE_H * 0.65, -PHONE_L * 0.425), body)

	-- ─── HOME BUTTON ─────────────────────────────────────────────
	makePart(model, "HomeButton", Vector3.new(PHONE_W * 0.165, PHONE_H * 0.22, PHONE_W * 0.165),
		COLOR_HOME, Enum.Material.Metal,
		CFrame.new(0, PHONE_H * 0.67, -PHONE_L * 0.425), body)

	-- ─── BACK BODY (belakang HP, warna emas) ─────────────────────
	makePart(model, "BackPanel", Vector3.new(PHONE_W * 0.88, PHONE_H * 0.1, PHONE_L * 0.7),
		COLOR_BODY, Enum.Material.SmoothPlastic,
		CFrame.new(0, -PHONE_H * 0.55, 0), body)

	-- ─── KAMERA BELAKANG ─────────────────────────────────────────
	makePart(model, "RearCamera", Vector3.new(PHONE_W * 0.1, PHONE_H * 0.28, PHONE_W * 0.1),
		COLOR_CAMERA, Enum.Material.Glass,
		CFrame.new(-PHONE_W * 0.26, -PHONE_H * 0.62, PHONE_L * 0.37), body)

	-- ─── LED FLASH ───────────────────────────────────────────────
	makePart(model, "Flash", Vector3.new(PHONE_W * 0.065, PHONE_H * 0.22, PHONE_W * 0.065),
		COLOR_FLASH, Enum.Material.Neon,
		CFrame.new(-PHONE_W * 0.26, -PHONE_H * 0.62, PHONE_L * 0.29), body)

	-- ─── TRIM TEPI KIRI ──────────────────────────────────────────
	makePart(model, "EdgeLeft", Vector3.new(PHONE_H * 0.35, PHONE_H * 1.05, PHONE_L * 0.96),
		COLOR_EDGE, Enum.Material.Metal,
		CFrame.new(-PHONE_W * 0.535, 0, 0), body)

	-- ─── TRIM TEPI KANAN ─────────────────────────────────────────
	makePart(model, "EdgeRight", Vector3.new(PHONE_H * 0.35, PHONE_H * 1.05, PHONE_L * 0.96),
		COLOR_EDGE, Enum.Material.Metal,
		CFrame.new(PHONE_W * 0.535, 0, 0), body)

	-- ─── TRIM TEPI ATAS ──────────────────────────────────────────
	makePart(model, "EdgeTop", Vector3.new(PHONE_W * 1.08, PHONE_H * 1.05, PHONE_H * 0.35),
		COLOR_EDGE, Enum.Material.Metal,
		CFrame.new(0, 0, PHONE_L * 0.51), body)

	-- ─── TRIM TEPI BAWAH ─────────────────────────────────────────
	makePart(model, "EdgeBottom", Vector3.new(PHONE_W * 1.08, PHONE_H * 1.05, PHONE_H * 0.35),
		COLOR_EDGE, Enum.Material.Metal,
		CFrame.new(0, 0, -PHONE_L * 0.51), body)

	-- ─── TOMBOL VOLUME (kiri atas & bawah) ───────────────────────
	makePart(model, "VolUp", Vector3.new(PHONE_H * 0.25, PHONE_H * 0.32, PHONE_L * 0.1),
		COLOR_EDGE, Enum.Material.Metal,
		CFrame.new(-PHONE_W * 0.555, 0, PHONE_L * 0.2), body)

	makePart(model, "VolDown", Vector3.new(PHONE_H * 0.25, PHONE_H * 0.32, PHONE_L * 0.1),
		COLOR_EDGE, Enum.Material.Metal,
		CFrame.new(-PHONE_W * 0.555, 0, PHONE_L * 0.07), body)

	-- ─── TOMBOL POWER (kanan atas) ───────────────────────────────
	makePart(model, "PowerButton", Vector3.new(PHONE_H * 0.25, PHONE_H * 0.32, PHONE_L * 0.1),
		COLOR_EDGE, Enum.Material.Metal,
		CFrame.new(PHONE_W * 0.555, 0, PHONE_L * 0.32), body)

	model.Parent = character
end

remote.OnServerEvent:Connect(function(player: Player, action: string, value: any)
	local character = player.Character
	if not character then return end

	if action == "SetHolding" then
		if value == true then
			addPhone(character)
		else
			removePhone(character)
		end

	elseif action == "PlayMusic" then
		-- value = { soundId = "...", rollOffMin = 40, rollOffMax = 80 }
		-- Hapus Part musik lama jika ada
		local oldPart = character:FindFirstChild("MusicSoundPart")
		if oldPart then oldPart:Destroy() end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local part = Instance.new("Part")
		part.Name        = "MusicSoundPart"
		part.Anchored    = false
		part.CanCollide  = false
		part.Massless    = true
		part.Transparency = 1
		part.Size        = Vector3.new(0.1, 0.1, 0.1)
		part.CFrame      = rootPart.CFrame
		part.Parent      = character  -- di dalam character agar replicate & ikut karakter

		local wc = Instance.new("WeldConstraint")
		wc.Part0   = part
		wc.Part1   = rootPart
		wc.Parent  = part

		local s = Instance.new("Sound")
		s.Name                = "MusicSound"
		s.SoundId             = value.soundId
		s.Volume              = value.volume or 0.25
		s.Looped              = value.looped or false
		s.RollOffMinDistance  = value.rollOffMin or 40
		s.RollOffMaxDistance  = value.rollOffMax or 80
		s.RollOffMode         = Enum.RollOffMode.LinearSquare
		s.Parent              = part
		
		-- Equalizer untuk melembutkan suara (mengurangi harsh treble/nusuk)
		local eq = Instance.new("EqualizerSoundEffect")
		eq.HighGain = -6 -- Cut treble tajam
		eq.MidGain = 0
		eq.LowGain = 3   -- Tambah sedikit bass agar lebih bulat
		eq.Parent = s

		s:Play()
		-- Seek ke posisi yang diminta (untuk scrubbing)
		if value.timePosition and value.timePosition > 0 then
			task.defer(function()
				s.TimePosition = value.timePosition
			end)
		end

	elseif action == "StopMusic" then
		local oldPart = character:FindFirstChild("MusicSoundPart")
		if oldPart then oldPart:Destroy() end

	elseif action == "PauseMusic" then
		local oldPart = character:FindFirstChild("MusicSoundPart")
		if oldPart then
			local s = oldPart:FindFirstChild("MusicSound")
			if s then s:Pause() end
		end

	elseif action == "ResumeMusic" then
		local oldPart = character:FindFirstChild("MusicSoundPart")
		if oldPart then
			local s = oldPart:FindFirstChild("MusicSound")
			if s then s:Resume() end
		end

	elseif action == "SetMusicVolume" then
		-- value = number (0-1)
		local oldPart = character:FindFirstChild("MusicSoundPart")
		if oldPart then
			local s = oldPart:FindFirstChild("MusicSound")
			if s then s.Volume = math.clamp(value or 1, 0, 1) end
		end

	elseif action == "AirDropContact" then
		-- value = { targetUserId = number, contactData = table }
		if type(value) == "table" and value.targetUserId and value.contactData then
			local targetPlayer = Players:GetPlayerByUserId(value.targetUserId)
			if targetPlayer and targetPlayer ~= player and targetPlayer.Character and character then
				local myHRP = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if myHRP and targetHRP then
					local distance = (myHRP.Position - targetHRP.Position).Magnitude
					if distance <= 40 then -- Maksimal radius 40 studs (~13 meter)
						remote:FireClient(targetPlayer, "ReceiveAirDropContact", {
							senderUserId = player.UserId,
							senderName = player.DisplayName or player.Name,
							contactData = value.contactData,
						})
					end
				end
			end
		end

	elseif action == "StartCall" then
		-- value = { targetUserId = number, targetPhone = string }
		if type(value) == "table" then
			local targetPhoneStr = cleanPhone(value.targetPhone)
			local targetPlayer = nil
			local targetName = nil
			local targetPhone = targetPhoneStr

			-- 1. Lookup by userId if provided
			if value.targetUserId then
				targetPlayer = Players:GetPlayerByUserId(value.targetUserId)
			end

			-- 2. Lookup by phone among all online players
			if not targetPlayer and targetPhoneStr ~= "" then
				targetPlayer = findPlayerByPhoneNum(targetPhoneStr)
			end

			if targetPlayer and targetPlayer ~= player then
				-- Target is online: ring them
				targetName = targetPlayer.DisplayName or targetPlayer.Name
				targetPhone = getPlayerPhone(targetPlayer)
				local callerPhone = getPlayerPhone(player)
				remote:FireClient(targetPlayer, "IncomingCall", {
					callerUserId = player.UserId,
					callerName = player.DisplayName or player.Name,
					callerPhone = callerPhone,
				})
				remote:FireClient(player, "CallRinging", {
					targetUserId = targetPlayer.UserId,
					targetName = targetName,
					targetPhone = targetPhone,
					isOnline = true,
				})
			elseif targetPhoneStr ~= "" and targetPhoneStr:match("^%d+$") and #targetPhoneStr >= 4 then
				-- Number looks valid but player is offline: allow call to ring ("Memanggil...")
				local displayNum = value.targetPhone or targetPhoneStr
				remote:FireClient(player, "CallRinging", {
					targetUserId = nil,
					targetName = displayNum,
					targetPhone = targetPhoneStr,
					isOnline = false,
				})
			else
				-- Number is empty, non-numeric, or clearly invalid
				local displayNum = if value.targetPhone and value.targetPhone ~= "" then value.targetPhone else "Nomor"
				remote:FireClient(player, "CallFailed", {
					reason = "Nomor telepon '" .. displayNum .. "' tidak terdaftar atau tidak valid.",
				})
			end
		end

	elseif action == "AnswerCall" then
		-- value = { callerUserId = number }
		if type(value) == "table" and value.callerUserId then
			local callerPlayer = Players:GetPlayerByUserId(value.callerUserId)
			if callerPlayer then
				remote:FireClient(callerPlayer, "CallConnected", {
					partnerUserId = player.UserId,
					partnerName = player.DisplayName or player.Name,
				})
				remote:FireClient(player, "CallConnected", {
					partnerUserId = callerPlayer.UserId,
					partnerName = callerPlayer.DisplayName or callerPlayer.Name,
				})
			end
		end

	elseif action == "DeclineCall" or action == "EndCall" then
		-- value = { partnerUserId = number }
		if type(value) == "table" and value.partnerUserId then
			local partnerPlayer = Players:GetPlayerByUserId(value.partnerUserId)
			if partnerPlayer then
				remote:FireClient(partnerPlayer, "CallEnded", {
					endedBy = player.UserId,
				})
			end
		end

	elseif action == "SendSMS" then
		-- value = { targetUserId = number, targetPhone = string, messageText = string }
		if type(value) == "table" and value.messageText and value.messageText ~= "" then
			local targetPhoneStr = cleanPhone(value.targetPhone)
			local targetPlayer = nil
			if value.targetUserId then
				targetPlayer = Players:GetPlayerByUserId(value.targetUserId)
			end
			if not targetPlayer and targetPhoneStr ~= "" then
				targetPlayer = findPlayerByPhoneNum(targetPhoneStr)
			end

			local senderPhone = getPlayerPhone(player)
			local now = os.time()

			if targetPlayer and targetPlayer ~= player then
				remote:FireClient(targetPlayer, "ReceiveSMS", {
					senderUserId = player.UserId,
					senderName = player.DisplayName or player.Name,
					senderPhone = senderPhone,
					messageText = value.messageText,
					timestamp = now,
				})
				remote:FireClient(player, "SMSSent", {
					targetUserId = targetPlayer.UserId,
					targetPhone = getPlayerPhone(targetPlayer),
					messageText = value.messageText,
					timestamp = now,
				})
			else
				local displayNum = if value.targetPhone and value.targetPhone ~= "" then value.targetPhone else "Tujuan"
				remote:FireClient(player, "SMSFailed", {
					reason = "Nomor telepon '" .. displayNum .. "' tidak terdaftar atau sedang tidak aktif.",
				})
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local character = player.Character
	if character then
		removePhone(character)
	end
end)
