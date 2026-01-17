--!nocheck

-- Packets.luau
-- for TweenPlus
-- during runtime, this SHOULD work.

local Packet = require("./PacketPlus")

return {
	Loaded = Packet(),

	CreateTween = Packet(Packet.NumberU8, Packet.Instance, Packet.Any, Packet.Any),
	StartTween = Packet(Packet.NumberU8, Packet.Any, Packet.Any),
	StopTween = Packet(Packet.NumberU8),
	ResetTween = Packet(Packet.NumberU8),
	DestroyTween = Packet(Packet.NumberU8),
}
