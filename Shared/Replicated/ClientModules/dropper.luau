--!nonstrict

local drop_manager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local random = require(ReplicatedStorage.Utility.random)
local trove = require(ReplicatedStorage.Packages.trove)

-- // Util
local randomseed = random.create()
local _trove = trove.new()

drop_manager._trove = _trove
drop_manager._randomseed = randomseed

--[[
	Drop function

	@param player - The player to drop the item for
	@param amount - The amount of items to drop
	@param object - The object to drop (optional, defaults to "CardDrop")

	CardDrop should really be "PrismDrop" tho.

	```luau
	-- Example usage:

	drop_manager:Drop(player, 5, "PrismDrop")
	```
]]
function drop_manager:Drop(player: Player, amount: number, object: string?)
	local obj = fetchAsset(object or "CardDrop") :: BasePart?
	if not obj then
		return
	end

	_trove:Add(obj)

	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character.HumanoidRootPart

	for i = 1, amount do
		local clone = _trove:Clone(obj)

		clone.Transparency = 0
		clone.Parent = workspace
		clone.CFrame = rootPart.CFrame

		local randomX = randomseed.integer(randomseed, -5, 5)
		local randomZ = randomseed.integer(randomseed, -5, 5)
		local randomY = randomseed.integer(randomseed, 45, 55)

		local maxForce = 250
		local vectorVelocity = vector.create(randomX, randomY, randomZ)

		local attachment = Instance.new("Attachment")
		attachment.Parent = clone

		local already_touched = observer.new(false)
		local conn = clone.Touched:Once(function(a0: BasePart)
			if already_touched:Get() then
				return
			end

			-- TODO) do a dialog
		end)

		_trove:Add(attachment)
		_trove:Add(already_touched)
		_trove:Add(conn)

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.Parent = clone
		linearVelocity.MaxForce = maxForce
		linearVelocity.Attachment0 = attachment
		linearVelocity.VectorVelocity = vectorVelocity

		_trove:Add(linearVelocity)

		promise
			.delay(0.25)
			:andThen(function()
				_trove:Remove(linearVelocity)
				_trove:Remove(attachment)
			end)
			:catch(print)

		promise
			.delay(5)
			:andThen(function()
				_trove:Remove(clone)
				_trove:Remove(conn)
				_trove:Remove(already_touched)
			end)
			:catch(print)
	end

	task.delay(2, _trove.Clean, trove)
end

return drop_manager
