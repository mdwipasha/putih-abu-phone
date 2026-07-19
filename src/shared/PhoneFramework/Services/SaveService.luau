local Signal = require(script.Parent.Parent.Shared.Utilities.Signal)

local SaveService = {}
SaveService.__index = SaveService

function SaveService.new()
	return setmetatable({
		_values = {},
		Changed = Signal.new(),
	}, SaveService)
end

function SaveService:Set(key: string, value: any)
	self._values[key] = value
	self.Changed:Fire(key, value)
end

function SaveService:Get(key: string, defaultValue: any?)
	local value = self._values[key]
	if value == nil then
		return defaultValue
	end
	return value
end

function SaveService:Destroy()
	self.Changed:Destroy()
end

return SaveService
