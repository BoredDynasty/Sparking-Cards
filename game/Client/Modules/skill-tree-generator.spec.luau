--!strict

return function()
	local SkillTreeGenerator = require(script.Parent["skill-tree-generator"])

	describe("SkillTreeGenerator", function()
		it("should initialize with a userId", function()
			local generator = SkillTreeGenerator.new(12345)
			expect(generator).to.be.ok()
			expect(generator.random).to.be.ok()
		end)

		-- Note: Further tests might require mocking Roblox UI objects (GuiObject, etc.)
		-- if run in a non-Roblox environment.
	end)
end
