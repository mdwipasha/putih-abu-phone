local function applyChildren(instance: Instance, children: { Instance }?)
	if not children then
		return
	end

	for _, child in ipairs(children) do
		child.Parent = instance
	end
end

local function create(className: string, properties: { [string]: any }?, children: { Instance }?): Instance
	local instance = Instance.new(className)

	if properties then
		for key, value in pairs(properties) do
			(instance :: any)[key] = value
		end
	end

	applyChildren(instance, children)
	return instance
end

return create
