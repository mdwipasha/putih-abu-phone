--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Config.Config)
local Signals = require(script.Parent.Parent.Events.Signals)
local Cache = require(script.Parent.Cache)
local SaveQueue = require(script.Parent.SaveQueue)
local DefaultPlayerData = require(script.Parent.DefaultPlayerData)

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local initialized = false
local DataManager = {}

local function key(userId: number): string
	return Config.DataStoreKeyPrefix .. tostring(userId)
end

local function retry<T>(operation: () -> T): (boolean, T?)
	for attempt = 1, Config.DataStoreRetryCount do
		local ok, result = pcall(operation)
		if ok then return true, result end
		warn("[Economy] DataStore attempt " .. attempt .. " failed: " .. tostring(result))
		if attempt < Config.DataStoreRetryCount then task.wait(Config.DataStoreRetryDelaySeconds) end
	end
	return false, nil
end

function DataManager.LoadPlayer(player: Player): (boolean, string?)
	if Cache.Get(player.UserId) then return true end
	local ok, stored = retry(function()
		return store:GetAsync(key(player.UserId))
	end)
	if not ok then return false, "Unable to load player data." end

	-- Prefix + absolute UserId is deterministic and stays numeric for local Studio test players.
	local generatedPhone = Config.PhonePrefix .. tostring(math.abs(player.UserId))
	local data = if type(stored) == "table"
		then DefaultPlayerData.Reconcile(stored :: {[string]: any}, player.DisplayName, generatedPhone)
		else DefaultPlayerData.Create(player.DisplayName, generatedPhone)
	Cache.Set(player.UserId, data)
	SaveQueue.Add(player.UserId)
	Signals.PlayerDataLoaded:Fire(player, data)
	return true
end

function DataManager.SaveUserId(userId: number, queueVersion: number?): (boolean, string?)
	local data = Cache.Get(userId)
	if not data then return false, "Player data is not loaded." end
	local savedVersion = queueVersion or SaveQueue.GetVersion(userId)
	local ok = retry(function()
		store:UpdateAsync(key(userId), function()
			return data
		end)
	end)
	if not ok then
		SaveQueue.Add(userId)
		return false, "Unable to save player data."
	end
	if savedVersion then
		SaveQueue.MarkSaved(userId, savedVersion)
	else
		SaveQueue.Remove(userId)
	end
	local player = Players:GetPlayerByUserId(userId)
	Signals.PlayerDataSaved:Fire(player, userId)
	return true
end

function DataManager.QueueSave(userId: number)
	if Cache.Get(userId) then SaveQueue.Add(userId) end
end

function DataManager.SetStoreForTests(testStore: any)
	store = testStore
end

function DataManager.RunAutoSaveCycleForTests()
	for userId, version in SaveQueue.Snapshot() do
		DataManager.SaveUserId(userId, version)
	end
end

function DataManager.Init()
	if initialized then return end
	initialized = true
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local ok, message = DataManager.LoadPlayer(player)
			if not ok then warn("[Economy] " .. (message or "Load failed")) end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		DataManager.SaveUserId(player.UserId)
		Cache.Remove(player.UserId)
	end)
	task.spawn(function()
		while initialized do
			task.wait(Config.AutoSaveIntervalSeconds)
			for userId, version in SaveQueue.Snapshot() do
				DataManager.SaveUserId(userId, version)
			end
		end
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do DataManager.SaveUserId(player.UserId) end
	end)
	for _, player in Players:GetPlayers() do task.spawn(DataManager.LoadPlayer, player) end
end

return DataManager
