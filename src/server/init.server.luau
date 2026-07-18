local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.PhoneFramework.Shared.Constants)

local remote = ReplicatedStorage:FindFirstChild(Constants.RemoteName)
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = Constants.RemoteName
	remote.Parent = ReplicatedStorage
end

local function getHand(character: Model): BasePart?
	local hand = character:FindFirstChild("RightHand")
		or character:FindFirstChild("Right Arm")
		or character:FindFirstChild("RightLowerArm")
	return hand :: BasePart?
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
	if not hand then
		return
	end

	local model = Instance.new("Model")
	model.Name = "VisiblePhone"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = false
	body.CanCollide = false
	body.Massless = true
	body.Color = Color3.fromRGB(245, 245, 242)
	body.Material = Enum.Material.SmoothPlastic
	body.Size = Vector3.new(0.55, 0.08, 1.08)
	body.CFrame = hand.CFrame * CFrame.new(0, -0.35, -0.18) * CFrame.Angles(math.rad(86), math.rad(0), math.rad(8))
	body.Parent = model

	local screen = Instance.new("Part")
	screen.Name = "Screen"
	screen.Anchored = false
	screen.CanCollide = false
	screen.Massless = true
	screen.Color = Color3.fromRGB(8, 10, 16)
	screen.Material = Enum.Material.Glass
	screen.Size = Vector3.new(0.45, 0.012, 0.72)
	screen.CFrame = body.CFrame * CFrame.new(0, -0.047, 0)
	screen.Parent = model

	local weldToHand = Instance.new("WeldConstraint")
	weldToHand.Part0 = hand
	weldToHand.Part1 = body
	weldToHand.Parent = body

	local weldScreen = Instance.new("WeldConstraint")
	weldScreen.Part0 = body
	weldScreen.Part1 = screen
	weldScreen.Parent = screen

	model.PrimaryPart = body
	model.Parent = character
end

remote.OnServerEvent:Connect(function(player: Player, action: string, value: any)
	local character = player.Character
	if not character then
		return
	end

	if action == "SetHolding" then
		if value == true then
			addPhone(character)
		else
			removePhone(character)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local character = player.Character
	if character then
		removePhone(character)
	end
end)
