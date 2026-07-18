export type AppDefinition = {
	Id: string,
	Name: string,
	Icon: { Background: Color3, Glyph: string },
	Order: number?,
	IsSystem: boolean?,
	Create: (context: any) -> Instance,
	OnOpen: ((self: any) -> ())?,
	OnClose: ((self: any) -> ())?,
}

export type PhoneContext = {
	Root: Frame,
	Screen: Frame,
	Services: { [string]: any },
	OpenApp: (appId: string) -> (),
	CloseCurrentApp: () -> (),
	Unlock: () -> (),
	Lock: () -> (),
	SendNotification: (notification: any) -> (),
}

return {}
