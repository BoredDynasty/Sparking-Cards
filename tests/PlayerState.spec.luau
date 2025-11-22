--!strict
return function()
	local PlayerState = require(script.Parent.Parent.Shared.Replicated.Modules.PlayerState)

	describe("PlayerState", function()
		it("should be able to create a new PlayerState", function()
			local ps = PlayerState.new()
			expect(ps).to.be.ok()
		end)

		it("should be able to add and enter a state", function()
			local ps = PlayerState.new()
			local state = {
				Name = "Idle",
				Enter = function() end,
				Exit = function() end,
			}
			ps:addStateDefinition(state)
			ps:enterState("Idle")
			expect(ps:hasState("Idle")).to.be.equal(true)
		end)

		it("should be able to exit a state", function()
			local ps = PlayerState.new()
			local state = {
				Name = "Idle",
				Enter = function() end,
				Exit = function() end,
			}
			ps:addStateDefinition(state)
			ps:enterState("Idle")
			ps:exitState("Idle")
			expect(ps:hasState("Idle")).to.be.equal(false)
		end)

		it("should handle exclusive states", function()
			local ps = PlayerState.new()
			local idle_state = {
				Name = "Idle",
				Enter = function() end,
				Exit = function() end,
				Exclusive = {"Attacking"},
			}
			local attacking_state = {
				Name = "Attacking",
				Enter = function() end,
				Exit = function() end,
				Exclusive = {"Idle"},
			}
			ps:addStateDefinition(idle_state)
			ps:addStateDefinition(attacking_state)

			ps:enterState("Idle")
			ps:enterState("Attacking")

			expect(ps:hasState("Idle")).to.be.equal(false)
			expect(ps:hasState("Attacking")).to.be.equal(true)
		end)
	end)
end
