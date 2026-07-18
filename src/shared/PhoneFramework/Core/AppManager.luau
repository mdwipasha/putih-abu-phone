local AppManager = {}
AppManager.__index = AppManager

function AppManager.new(context: any, screenRoot: Frame, animator: any)
	return setmetatable({
		_context = context,
		_screenRoot = screenRoot,
		_animator = animator,
		_registry = {},
		_instances = {},
		_currentAppId = nil,
	}, AppManager)
end

function AppManager:Register(appModule: any)
	assert(type(appModule.Id) == "string", "Phone app must provide Id")
	assert(type(appModule.Create) == "function", "Phone app must provide Create(context)")
	self._registry[appModule.Id] = appModule
end

function AppManager:RegisterFolder(folder: Instance)
	local modules = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ModuleScript") then
			table.insert(modules, child)
		end
	end

	table.sort(modules, function(left, right)
		return left.Name < right.Name
	end)

	for _, moduleScript in ipairs(modules) do
		self:Register(require(moduleScript))
	end
end

function AppManager:GetApp(appId: string)
	return self._registry[appId]
end

function AppManager:GetApps()
	local apps = {}
	for _, app in pairs(self._registry) do
		table.insert(apps, app)
	end
	table.sort(apps, function(left, right)
		return (left.Order or 1000) < (right.Order or 1000)
	end)
	return apps
end

function AppManager:_getInstance(appId: string): GuiObject?
	local app = self._registry[appId]
	if not app then
		warn("[PhoneFramework] Unknown app:", appId)
		return nil
	end

	if not self._instances[appId] then
		local instance = app.Create(self._context)
		instance.Name = app.Id .. "Screen"
		instance.Visible = false
		self._instances[appId] = instance
	end

	return self._instances[appId]
end

function AppManager:Open(appId: string)
	local nextInstance = self:_getInstance(appId)
	if not nextInstance then
		return
	end

	if self._currentAppId and self._currentAppId ~= appId then
		local current = self._instances[self._currentAppId]
		if current then
			current.Visible = false
		end
	end

	self._currentAppId = appId
	nextInstance.Visible = true
	self._animator:SwapIn(nextInstance)
end

function AppManager:CloseCurrent()
	if self._currentAppId then
		local current = self._instances[self._currentAppId]
		if current then
			current.Visible = false
		end
	end
	self._currentAppId = nil
end

function AppManager:Destroy()
	for _, instance in pairs(self._instances) do
		instance:Destroy()
	end
	table.clear(self._instances)
	table.clear(self._registry)
end

return AppManager
