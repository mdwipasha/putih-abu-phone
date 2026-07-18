local AudioService = {}
AudioService.__index = AudioService

function AudioService.new()
	return setmetatable({
		_muted = false,
	}, AudioService)
end

function AudioService:SetMuted(muted: boolean)
	self._muted = muted
end

function AudioService:IsMuted()
	return self._muted
end

return AudioService
