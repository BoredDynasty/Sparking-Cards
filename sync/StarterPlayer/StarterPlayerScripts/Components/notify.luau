--!nonstrict

-- notify.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

export type notification = ScreenGui & {
	CanvasGroup: CanvasGroup & {
		Holder: Frame & {},
	},
}

local state = observer.new(false)

local notification = playerGui:WaitForChild("Notify") :: notification

export type Actions<P...> = {
	{
		name: string,
		color: string?,
		parameters: { any }?,
		executor: (P...) -> ...unknown,
	}
}

export type Notification<T, P...> = {
	title: string?,
	details: string?,
	timeout: number?,
	actions: Actions<P...>?,
}
