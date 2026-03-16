--!strict

type EventConnecterType<T> = {
	-- Methods
	Wait: (self: EventConnecterType<T>, timeout: number?) -> (...any | "timeout"),
	Connect: (self: EventConnecterType<T>, handler: T) -> RBXScriptConnection,
	Once: (self: EventConnecterType<T>, handler: T) -> RBXScriptConnection,
}
type EventObserverType<T> = {
	-- Methods
	Wait: (self: EventObserverType<T>, timeout: number?) -> (...any | "timeout"),
	Connect: (self: EventObserverType<T>, handler: T) -> RBXScriptConnection,
	Observe: (self: EventObserverType<T>, observer: T) -> RBXScriptConnection,
	Once: (self: EventObserverType<T>, handler: T) -> RBXScriptConnection,
}
type PathArrayType = {string | number}

-- Plums modules
type PlumsSharedType = {
	-- Methods
	Init: (self: PlumsClientType | PlumsServerType) -> (),
	AwaitInitialized: (self: PlumsClientType | PlumsServerType) -> (),
	WaitForPlum: (self: PlumsClientType | PlumsServerType, plumId: number, debugTag: string?) -> PlumsClientType | PlumsServerType;
}
export type PlumsClientType = {
	-- Events
	PlumReceived: (plumClassName: string) -> EventObserverType<(plum: PlumClientType, wasObserved: boolean) -> ()>,
	AnyPlumReceived: EventObserverType<(plum: PlumClientType, wasObserved: boolean) -> ()>,
} & PlumsSharedType
export type PlumsServerType = {
	-- Plum constructor
	new: (plumClassName: string, plumData: {[any]: any?}?) -> PlumServerType,

	-- Events
	PlumCreated: (plumClassName: string) -> EventObserverType<(plum: PlumServerType, wasObserved: boolean) -> ()>,
	AnyPlumCreated: EventObserverType<(plum: PlumServerType, wasObserved: boolean) -> ()>,
} & PlumsSharedType

-- Plum objects
type PlumSharedType = {
	-- Properties
	Data: {[any]: any?},
	Id: number,
	ClassName: string,
	IsDestroyed: boolean?,
	Clients: {Player?},

	-- Methods
	IsClient: (self: PlumServerType | PlumClientType, player: Player) -> boolean,
	WaitFor: (self: PlumServerType | PlumClientType, path: PathArrayType) -> any,

	-- Events
	ValueChanged: (path: PathArrayType) -> EventObserverType<(newValue: any, oldValue: any, wasObserved: boolean) -> ()>,
	OnArrayInsert: (path: PathArrayType) -> EventObserverType<(newValue: any, index: number, wasObserved: boolean) -> ()>,
	OnArrayRemove: (path: PathArrayType) -> EventConnecterType<(oldValue: any, index: number) -> ()>,
	OnRaw: EventConnecterType<(methodName: string, path: PathArrayType, ...any) -> ()>,
	OnBroadcast: EventConnecterType<(client: Player, ...any) -> ()>,
	ClientAdded: EventObserverType<(client: Player, wasObserved: boolean) -> ()>,
	ClientRemoved: EventConnecterType<(client: Player) -> ()>,
	Destroyed: EventConnecterType<() -> ()>,
}
export type PlumServerType = {
	-- Properties
	OnServerInvoke: ((client: Player, ...any?) -> ...any?)?,
	
	-- Methods
	SetValue: (self: PlumServerType, path: PathArrayType, newValue: any?) -> any?,
	IncValue: (self: PlumServerType, path: PathArrayType, increment: number?) -> number,
	DecValue: (self: PlumServerType, path: PathArrayType, decrement: number?) -> number,
	MultiplyValue: (self: PlumServerType, path: PathArrayType, multiplier: number) -> number,
	ArrayInsert: (self: PlumServerType, path: PathArrayType, newValue: any, index: number?) -> (),
	ArrayRemove: (self: PlumServerType, path: PathArrayType, index: number?) -> any?,
	SetValueServerOnly: (self: PlumServerType, path: PathArrayType, newValue: any?) -> any?,
	IncValueServerOnly: (self: PlumServerType, path: PathArrayType, increment: number?) -> number,
	DecValueServerOnly: (self: PlumServerType, path: PathArrayType, decrement: number?) -> number,
	MultiplyValueServerOnly: (self: PlumServerType, path: PathArrayType, multiplier: number?) -> number,
	ArrayInsertServerOnly: (self: PlumServerType, path: PathArrayType, newValue: any, index: number?) -> (),
	ArrayRemoveServerOnly: (self: PlumServerType, path: PathArrayType, index: number) -> any,
	AddClients: (self: PlumServerType, clients: Player | {Player}) -> PlumServerType,
	AddAllClients: (self: PlumServerType) -> PlumServerType,
	RemoveClients: (self: PlumServerType, clients: Player | {Player}) -> (),
	EnableAutoAddClient: (self: PlumServerType) -> PlumServerType,
	DisableAutoAddClient: (self: PlumServerType) -> (),
	Destroy: (self: PlumServerType) -> (),
	BindToInstance: (self: PlumServerType, instance: Instance) -> PlumServerType,
	Broadcast: (self: PlumServerType, ...any?) -> (),
	BroadcastTo: (self: PlumServerType, clients: {Player} | Player, ...any?) -> (),
} & PlumSharedType
export type PlumClientType = {
	-- Methods
	InvokeServer: (self: PlumClientType, ...any?) -> any,	
	
	-- Events
	LocalClientAdded: EventConnecterType<() -> ()>,
	LocalClientRemoved: EventConnecterType<() -> ()>,
} & PlumSharedType

return {}