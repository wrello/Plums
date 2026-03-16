--[[
comdoc "Changelog" 5 LastUpdated
	
	8.0.0-beta
	
	Added sub-plum functionality + more
	
	7.0.0-beta
	
	Removed write libraries in exchange for :Broadcast/:BroadcastTo/:InvokeServer
	
	6.2.0-beta
	
	Big changes to plum being destroyed... & better cleanup of signals in client and server plums
	
	6.1.1-beta
	
	Made it so server side plum methods could be called immediatly after :Init() (was a bug that prevented this to do with RE creation dependency)
	
	6.1.0-beta
	
	Added server only methods that won't replicate to client and also
	'ServerPlum:MultiplyValue()' and added oldValue returning to some methods

	6.0.1-beta
	
	Fixed 'PlumsClient.AnyPlumReceived' not observing

	6.0.0-beta

	Fixed plums cache memory leak Changed 'AddAllClients' to 'AddCurrentPlayers'

	5.0.1-beta

	Fixed bug that occurred when the client requested current plums and the
	server would send an empty unit if it failed to add the client

	5.0.0-beta

	Made .OnArrayInsert():Observe run automatically at least once if there's
	nothing in the array Also implemented ServerPlum.OnArrayInsert():Observe

	4.8.1-beta

	t.optional(t.any) for 'ArrayInsert' and 'SetValue' new values

	4.8.0-beta

	Added 'Plums.AnyPlumReceived/Created' event to listen for any plum creation

	4.7.1-beta

	Fixed ':BindToInstance()' destroying the instance if the plum gets destroyed

	4.7.0-beta

	Added 'ServerPlum:WaitFor()' and recursive 'PlumServer.ValueChanged'

	4.6.0-beta

	'PlumClient.ValueChanged' is now fired recursively for paths created by
	tables added through ':ArrayInsert()' or ':SetValue()'

	4.5.0-beta
	
	Added `ClientPlum:WaitFor()`
	
	4.4.0-beta
	
	Switched to using `ClientReady` module for client initialization Fixed a
	logic error of not adding the client until after they were ready
	
	4.3.0-beta
	
	Made it so you cannot `:Destroy()` a plum twice
	
	4.2.0-beta

	Errors if trying to replicate an instance. This is because if the server
	replicates an instance to the client before it gets replicated, it wills be
	nil on the client forever

	4.1.0-beta

	`Plum.Namespace.Plum` is automatically set internally 

	4.0.1-beta
	
	Removed 'Temp' from the plum if not passed during creation
	
	4.0.0-beta

	Added `Plum.LocalClientAdded` + `Plum.LocalClientRemoved` Made it so the
	client who has been removed also recieves the "RemoveClients"/"AddClients"
	method calls from the server (instead of "Destroy"). The client now fires
	`Plum.LocalClientRemoved`/`Plum.LocalClientAdded` automatically dependeng on
	who is added or removed through "AddClients"/"RemoveClients" method calls.
	Fixed "RemoveClients" memory leak in the case where a client leaves the game
	before the method call reaches the client
	
	3.5.1-beta
	
	Changed `ClientAdded`, `ClientRemoved`,  and `Destroying` to
	`RBXScriptSignal` types in the 'Types' module Resolving instance from
	instance id (through NetInstance) before `Plum.PlumReceived` is fired
	instead of in `Plums:GetPlumAsync()`
	
	3.5.0-beta
	
	Added `plumNamespace` to `Plum.new(plumClassName, plumData, writeLibName,
	plumTemp, plumNamespace)` constructor on the server
	
	3.4.4-beta
	
	Preserve `Plum.Namespace` for after `Plum:Destroy()` on the server
	
	3.4.3-beta
	
	task.spawn(observer, plum) vs observer(plum) in :Observe()
	
	3.4.2-beta
	
	Fixed `:IncValue()` and `:DecValue()` possibly setting the value as a float
	
	3.4.1-beta
	
	Updated 'Signal' module with deferred observe init functions
	
	3.4.0-beta
	
	Added `Plum:DecValue()`
	
	3.3.0-beta
	
	Added `Plum:IncValue()`
	
	3.2.0-beta
	
	Added `Plum.Namespace` for a non-replicated temporary namespace on the
	server
	
	3.1.0-beta
	
	Added observe init for `Plum.OnArrayInsert()` that will send all current
	values to the observer
	
	3.0.0-beta
	
	Removed client from being sent as second argument to write lib functions
	
	2.1.1-beta
	
	When the player leaves, the plum gets destroyed. Made it so that all methods
	no longer do anything to prevent errors.
	
	2.1.0-beta
	
	Made it so the `Signal` module would resume waiting threads upon
	`Signal:DisconnectAll()`

]]