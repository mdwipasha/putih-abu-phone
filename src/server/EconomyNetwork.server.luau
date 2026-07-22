--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(script.Parent.EconomyFramework.Init)

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function getOrCreateRemoteFunction(parent: Instance, name: string): RemoteFunction
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end

	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function getOrCreateRemoteEvent(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local network = getOrCreateFolder(ReplicatedStorage, "Network")
local remotes = getOrCreateFolder(network, "Economy")

local getBalance = getOrCreateRemoteFunction(remotes, "GetBalance")
local getPhoneNumber = getOrCreateRemoteFunction(remotes, "GetPhoneNumber")
local getTransactionHistory = getOrCreateRemoteFunction(remotes, "GetTransactionHistory")
local getPlayerData = getOrCreateRemoteFunction(remotes, "GetPlayerData")
local transferByPhone = getOrCreateRemoteFunction(remotes, "TransferByPhone")

local balanceChanged = getOrCreateRemoteEvent(remotes, "BalanceChanged")
local transactionCreated = getOrCreateRemoteEvent(remotes, "TransactionCreated")
local playerDataLoaded = getOrCreateRemoteEvent(remotes, "PlayerDataLoaded")

local function safeCall<T>(fallback: T, callback: () -> T): T
	local ok, result = pcall(callback)
	if ok then
		return result
	end

	warn("[EconomyNetwork]", result)
	return fallback
end

local function displayNameFor(userId: any): string
	if typeof(userId) ~= "number" then
		return "Unknown"
	end

	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.DisplayName
	end

	local data = Economy.GetPlayerData(userId)
	if data and data.Profile and typeof(data.Profile.DisplayName) == "string" then
		return data.Profile.DisplayName
	end

	return tostring(userId)
end

local function normalizeTransaction(player: Player, raw: any): {[string]: any}?
	if typeof(raw) ~= "table" then
		return nil
	end

	local sender = raw.From
	local receiver = raw.To
	local direction = "neutral"
	if sender == player.UserId and receiver ~= player.UserId then
		direction = "outgoing"
	elseif receiver == player.UserId and sender ~= player.UserId then
		direction = "incoming"
	end

	return {
		Id = if typeof(raw.Id) == "string" then raw.Id else "-",
		Type = if typeof(raw.Type) == "string" then raw.Type else "TRANSFER",
		Direction = direction,
		Amount = tonumber(raw.Amount) or 0,
		Description = if typeof(raw.Description) == "string" and raw.Description ~= "" then raw.Description else "-",
		Timestamp = tonumber(raw.Timestamp) or 0,
		Sender = displayNameFor(sender),
		Receiver = displayNameFor(receiver),
		Status = "Completed",
	}
end

local function getHistoryFor(player: Player): {{[string]: any}}
	return safeCall({}, function()
		local history = Economy.GetTransactionHistory(player)
		if typeof(history) ~= "table" then
			return {}
		end

		local normalized = {}
		for _, transaction in ipairs(history) do
			local item = normalizeTransaction(player, transaction)
			if item then
				table.insert(normalized, item)
			end
		end

		table.sort(normalized, function(left, right)
			return (tonumber(left.Timestamp) or 0) > (tonumber(right.Timestamp) or 0)
		end)

		return normalized
	end)
end

getBalance.OnServerInvoke = function(player: Player): number
	return safeCall(0, function()
		return Economy.GetBalance(player) or 0
	end)
end

getPhoneNumber.OnServerInvoke = function(player: Player): string
	return safeCall("-", function()
		return Economy.GetPhoneNumber(player) or "-"
	end)
end

getTransactionHistory.OnServerInvoke = function(player: Player): {{[string]: any}}
	return getHistoryFor(player)
end

getPlayerData.OnServerInvoke = function(player: Player): {[string]: any}
	return safeCall({
		Balance = 0,
		PhoneNumber = "-",
		PlayerName = "Unknown",
		Transactions = {},
		Loaded = false,
	}, function()
		local data = Economy.GetPlayerData(player)
		return {
			Balance = Economy.GetBalance(player) or 0,
			PhoneNumber = Economy.GetPhoneNumber(player) or "-",
			PlayerName = if data and data.Profile and typeof(data.Profile.DisplayName) == "string" then data.Profile.DisplayName else player.DisplayName,
			Transactions = getHistoryFor(player),
			Loaded = data ~= nil,
		}
	end)
end

transferByPhone.OnServerInvoke = function(player: Player, phoneNumber: any, amount: any, description: any): {[string]: any}
	return safeCall({
		Success = false,
		Code = "UNKNOWN_ERROR",
		Message = "Transfer failed.",
	}, function()
		if typeof(phoneNumber) ~= "string" or phoneNumber:match("^%d+$") == nil then
			return {
				Success = false,
				Code = "INVALID_PHONE_NUMBER",
				Message = "Invalid phone number.",
			}
		end

		local transferAmount = tonumber(amount)
		if not transferAmount or transferAmount <= 0 then
			return {
				Success = false,
				Code = "INVALID_AMOUNT",
				Message = "Invalid amount.",
			}
		end

		local cleanDescription = if typeof(description) == "string" then description else nil
		local success, message = Economy.TransferByPhone(player, phoneNumber, transferAmount, cleanDescription)
		return {
			Success = success,
			Code = if success then "OK" else "TRANSFER_FAILED",
			Message = message or if success then "Transfer complete." else "Transfer failed.",
			Balance = Economy.GetBalance(player) or 0,
		}
	end)
end

Economy.Events.BalanceChanged.Event:Connect(function(userId: number, _oldBalance: number, newBalance: number)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		balanceChanged:FireClient(player, newBalance)
	end
end)

Economy.Events.TransactionCreated.Event:Connect(function(userId: number, transaction: any)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		transactionCreated:FireClient(player, normalizeTransaction(player, transaction))
	end
end)

Economy.Events.PlayerDataLoaded.Event:Connect(function(player: Player)
	playerDataLoaded:FireClient(player)
end)

Economy.Init()
