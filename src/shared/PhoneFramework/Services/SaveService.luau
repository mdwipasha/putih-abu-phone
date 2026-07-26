local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(script.Parent.Parent.Shared.Utilities.Signal)
local Constants = require(script.Parent.Parent.Shared.Constants)

local SaveService = {}
SaveService.__index = SaveService

function SaveService.new()
	local self = setmetatable({
		_values = {},
		_remote = ReplicatedStorage:FindFirstChild(Constants.RemoteName),
		Changed = Signal.new(),
	}, SaveService)

	return self
end

function SaveService:Set(key: string, value: any, skipRemote: boolean?)
	self._values[key] = value
	self.Changed:Fire(key, value)

	-- Sync ke Server DataStore jika bukan data internal sementara (berawalan '_')
	if not skipRemote and not key:match("^%_") then
		if not self._remote then
			self._remote = ReplicatedStorage:FindFirstChild(Constants.RemoteName)
		end
		if self._remote and self._remote:IsA("RemoteEvent") then
			self._remote:FireServer("SavePhoneData", {
				Key = key,
				Value = value,
			})
		end
	end
end

function SaveService:Get(key: string, defaultValue: any?)
	local value = self._values[key]
	if value == nil then
		return defaultValue
	end
	return value
end

function SaveService:LoadData(phoneData: { [string]: any })
	if type(phoneData) ~= "table" then return end
	for k, v in pairs(phoneData) do
		self:Set(k, v, true)
	end
end

function SaveService:Destroy()
	self.Changed:Destroy()
end

return SaveService
