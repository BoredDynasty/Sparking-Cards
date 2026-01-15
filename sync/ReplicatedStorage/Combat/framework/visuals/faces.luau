--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local hydration = require(ReplicatedStorage.Utility.hydration)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- faces.luau
-- a module for managing facial expressions on characters

local module = {}

local expressions = {
	angry = fetchAsset("Angry-01"),
	confused = fetchAsset("Confused-01"),
	flaming_eyes = fetchAsset("Flaming-Eyes-01"),
	glowing_eyes = fetchAsset("Glowing-Eyes-01"),
	surprised = fetchAsset("Surprised-01"),
	surprised_variant = fetchAsset("Surprised-02"),
}

export type ExpressionModel = BasePart & {
	Main: Attachment & { ParticleEmitter },
}

type ExpressionName = keyof<typeof(expressions)>

function module:GetExpression(name: ExpressionName): ExpressionModel?
	return expressions[name] :: ExpressionModel?
end

function module:GetAllExpressions(): { [string]: ExpressionModel }
	return expressions :: { [string]: ExpressionModel }
end

function module:AttachExpression(name: ExpressionName, character: typemarshaller.Character)
	local expression_model = self:GetExpression(name)

	if not expression_model then
		return
	end

	local head = character:FindFirstChild("Head") :: BasePart?

	if not head then
		return
	end

	local expression_instance = expression_model:Clone()
	hydration(expression_instance) {
		Parent = head,
		CFrame = head.CFrame,
	}

	local attachment = expression_instance:FindFirstChild("Main") :: Attachment
	hydration(attachment) {
		CFrame = CFrame.new(0, 0, -0.6),
		Axis = Vector3.new(1, 0, 0),
		SecondaryAxis = Vector3.new(0, 1, 0),
	}

	expression_instance:SetAttribute("Expression_Instance", true)
end

function module:RemoveExpressions(character: typemarshaller.Character)
	local head = character:FindFirstChild("Head") :: BasePart?

	if not head then
		return
	end

	for _, child in ipairs(head:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("Expression_Instance") then
			child:Destroy()
		end
	end
end

return module
