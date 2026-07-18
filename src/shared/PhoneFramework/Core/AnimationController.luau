local TweenService = game:GetService("TweenService")

local Constants = require(script.Parent.Parent.Shared.Constants)

local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new(device: any)
	return setmetatable({
		_device = device,
		_activeTweens = {},
	}, AnimationController)
end

function AnimationController:_play(instance: Instance, tweenInfo: TweenInfo, goals: { [string]: any })
	local tween = TweenService:Create(instance, tweenInfo, goals)
	table.insert(self._activeTweens, tween)
	tween.Completed:Once(function()
		local index = table.find(self._activeTweens, tween)
		if index then
			table.remove(self._activeTweens, index)
		end
	end)
	tween:Play()
	return tween
end

function AnimationController:Cancel()
	for _, tween in ipairs(self._activeTweens) do
		tween:Cancel()
	end
	table.clear(self._activeTweens)
end

function AnimationController:Open()
	self:Cancel()
	local root = self._device.Root
	root.Visible = true
	root.Position = Constants.Device.ClosedPosition
	root.Rotation = -6
	self._device.Dimmer.BackgroundTransparency = 0

	local first = self:_play(
		root,
		TweenInfo.new(
			Constants.Animation.OpenTime,
			Constants.Animation.EasingStyle,
			Constants.Animation.EasingDirection
		),
		{
			Position = Constants.Device.OpenPosition,
			Rotation = 1.2,
		}
	)

	first.Completed:Once(function()
		self:_play(root, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Rotation = 0,
		})
		self:_play(
			self._device.Dimmer,
			TweenInfo.new(Constants.Animation.ScreenWakeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = 1,
			}
		)
	end)
end

function AnimationController:Close(onComplete: (() -> ())?)
	self:Cancel()
	self:_play(self._device.Dimmer, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	})

	local tween = self:_play(
		self._device.Root,
		TweenInfo.new(Constants.Animation.CloseTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Position = Constants.Device.ClosedPosition,
			Rotation = -5,
		}
	)

	tween.Completed:Once(function()
		self._device.Root.Visible = false
		if onComplete then
			onComplete()
		end
	end)
end

function AnimationController:SwapIn(instance: GuiObject)
	instance.Position = UDim2.fromScale(1, 0)
	instance.Parent = self._device.ScreenContent
	self:_play(instance, TweenInfo.new(Constants.Animation.AppTime, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0, 0),
	})
end

function AnimationController:FadeScreen(alpha: number)
	self:_play(
		self._device.Dimmer,
		TweenInfo.new(Constants.Animation.ScreenWakeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			BackgroundTransparency = alpha,
		}
	)
end

return AnimationController
