local CameraService = {}
CameraService.__index = CameraService

function CameraService.new()
	return setmetatable({
		_enabled = false,
	}, CameraService)
end

function CameraService:Open()
	self._enabled = true
end

function CameraService:Close()
	self._enabled = false
end

function CameraService:IsOpen()
	return self._enabled
end

return CameraService
