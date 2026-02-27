--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Network.luau
-- wip
-- uses sleitnicks TypedRemote.

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local typedremote = require(ReplicatedStorage.Packages.typedremote)

local remote_function, remote_event = typedremote.parent()

export type Event<T...> = Instance & {
	OnClientEvent: SignalPlus.Signal<T...>,
	OnServerEvent: SignalPlus.Signal<Player, T...>,
	FireClient: (self: Event<T...>, player: Player, T...) -> (),
	FireAllClients: (self: Event<T...>, T...) -> (),
	FireServer: (self: Event<T...>, T...) -> (),
}

export type UnreliableEvent<T...> = Event<T...>

export type Function<T..., R...> = Instance & {
	InvokeServer: (self: Function<T..., R...>, T...) -> R...,
	OnServerInvoke: (player: Player, T...) -> R...,
}

type RF<T..., R...> = Function<T..., R...>
type RE<T...> = Event<T...>

return {
	blow_firework = remote_function("blow-firework") :: RF<(number, Vector3), (boolean)>,
	purchase_card = remote_function("purchase-card") :: RF<(string)>,
	sell_card = remote_function("sell-card") :: RF<(string)>,
	pay_prisms = remote_function("pay-prisms") :: RF<(string, number)>, -- username, amount
	bookmark_shop_card = remote_event("bookmark-shop-card") :: RE<(string)>,
}
