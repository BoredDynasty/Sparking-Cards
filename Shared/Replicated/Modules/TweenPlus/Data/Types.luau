-- Signal types from Signal+.
export type Connection = {
	Connected: boolean,
	Disconnect: typeof(function(connection: Connection) end),
}
export type Signal<Parameters...> = {
	Connect: typeof(function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end),
	Once: typeof(function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end),
	Wait: typeof(function(signal: Signal<Parameters...>): Parameters... end),

	Fire: typeof(function(signal: Signal<Parameters...>, ...: Parameters...) end),

	DisconnectAll: typeof(function(signal: Signal<Parameters...>) end),
	Destroy: typeof(function(signal: Signal<Parameters...>) end),
}

-- Internal server tween base.
export type InternalTween = {
	Index: number?,

	Playing: boolean,

	Updated: Signal?,
	Started: Signal?,
	Stopped: Signal?,
	Completed: Signal?,

	Instance: Instance,
	Values: Values,

	UpdateFunctions: { (alpha: number) -> () },
	ResetFunctions: { () -> () },

	InverseTweenTime: number,
	Ease: (alpha: number) -> (),
	RepeatCount: number,
	Reverses: boolean,
	Interval: number?,
	Table: {},

	StartTime: number,
	StopTime: number?,
	WaitTime: number?,
	LastUpdate: number?,

	Repetitions: number,
	Reverse: boolean,
	Alpha: number,
}

-- Obligatory module return.
return nil
