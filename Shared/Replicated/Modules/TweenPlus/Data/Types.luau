-- Signal types from Signal+.
type Connection = {
	Connected: boolean,
	Disconnect: typeof(
		-- Disconnects the connection.
		-- To reconnect, make a new connection.
		function(connection: Connection) end
	)
}
export type Signal<Parameters...> = {
	Connect: typeof(
		-- Connects the given function.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Once: typeof(
		-- Connects the given function, but disconnects after first fire.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Wait: typeof(
		-- Yields the current thread until the next fire.
		function(signal: Signal<Parameters...>): Parameters... end
	),
	
	Fire: typeof(
		-- Fires all callbacks and resumes all waiting threads.
		function(signal: Signal<Parameters...>, ...: Parameters...) end
	),
	
	DisconnectAll: typeof(
		-- Disconnects all connections.
		function(signal: Signal<Parameters...>) end
	),
	Destroy: typeof(
		-- Disconnects all connections, and makes the signal unusable.
		function(signal: Signal<Parameters...>) end
	)
}

-- Internal server tween base.
export type InternalTween = {
	Index: number?,
	
	Instance: Instance,
	Values: Values,
	
	UpdateFunctions: {(alpha: number) -> ()},
	ResetFunctions: {() -> ()},
	
	InverseTweenTime: number,
	Ease: (alpha: number) -> (),
	RepeatCount: number,
	Interval: number?,
	Table: {},
	
	StartTime: number,
	StopTime: number?,
	WaitTime: number?,
	LastUpdate: number?,
	
	Repetitions: number,
	Reverses: boolean,
	Reverse: boolean
}

-- Obligatory return.
return nil