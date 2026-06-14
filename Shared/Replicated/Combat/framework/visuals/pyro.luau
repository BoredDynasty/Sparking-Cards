--!strict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- pyro visuals
-- Shared visual helpers for the Pyro Katana moveset and reaction broadcasts.

local module = {}

export type ReactionPayload = {
	reaction: string,
	source: Player?,
	target: Player?,
	primary_element: string?,
	secondary_element: string?,
	position: Vector3?,
	exp_award: number?,
}

local FIRE = Color3.fromRGB(255, 92, 31)
local GOLD = Color3.fromRGB(255, 199, 87)
local SMOKE = Color3.fromRGB(101, 104, 110)

local function get_visual_container(): Folder
	local folder = Workspace:FindFirstChild("_CombatVisuals") :: Folder?
	if folder then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = "_CombatVisuals"
	folder.Parent = Workspace

	return folder
end

local function find_in_server_storage(name: string): Instance?
	if not RunService:IsServer() then
		return nil
	end

	local ok, server_storage = pcall(function()
		return game:GetService("ServerStorage")
		-- im sorry, i used ai for this
	end)

	if not ok then
		return nil
	end

	local assets = server_storage:FindFirstChild("Assets")
	if not assets then
		return nil
	end

	local exact = assets:FindFirstChild(name, true)
	if exact then
		return exact
	end

	return nil
end

local function find_asset(name: string): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if assets then
		local exact = assets:FindFirstChild(name, true)
		if exact then
			return exact
		end
	end

	return find_in_server_storage(name)
end

local function prep_part(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
end

local function pivot(instance: Instance, cframe: CFrame)
	if instance:IsA("BasePart") then
		prep_part(instance)
		instance.CFrame = cframe
	elseif instance:IsA("Model") then
		for _, descendant in ipairs(instance:GetDescendants()) do
			if descendant:IsA("BasePart") then
				prep_part(descendant)
			end
		end

		instance:PivotTo(cframe)
	end
end

local function tint_emitters(instance: Instance, color: Color3)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Color = ColorSequence.new(color, GOLD)
		elseif descendant:IsA("Beam") or descendant:IsA("Trail") then
			descendant.Color = ColorSequence.new(color, GOLD)
		elseif descendant:IsA("PointLight") then
			descendant.Color = color
		end
	end
end

local function emit(instance: Instance, emit_count: number?)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			local configured_count = descendant:GetAttribute("EmitCount")
			local count = if typeof(configured_count) == "number"
				then configured_count
				else emit_count or math.max(8, math.floor(descendant.Rate * 0.25))

			descendant.Enabled = true
			descendant:Emit(count)

			task.delay(0.2, function()
				if descendant.Parent then
					descendant.Enabled = false
				end
			end)
		elseif descendant:IsA("Beam") or descendant:IsA("Trail") then
			descendant.Enabled = true
			task.delay(0.35, function()
				if descendant.Parent then
					descendant.Enabled = false
				end
			end)
		elseif descendant:IsA("PointLight") then
			descendant.Enabled = true
			task.delay(0.25, function()
				if descendant.Parent then
					descendant.Enabled = false
				end
			end)
		end
	end
end

local function spawn_asset(name: string, cframe: CFrame, lifetime: number?, emit_count: number?): Instance?
	local template = find_asset(name)
	if not template then
		return nil
	end

	local clone = template:Clone()
	clone.Name = `_Pyro_{name}`
	pivot(clone, cframe)
	clone.Parent = get_visual_container()
	emit(clone, emit_count)

	Debris:AddItem(clone, lifetime or 2)

	return clone
end

local function make_flash_part(cframe: CFrame, size: Vector3, color: Color3, lifetime: number): BasePart
	local part = Instance.new("Part")
	part.Name = "_PyroFlash"
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.25
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Size = size
	part.CFrame = cframe
	part.Parent = get_visual_container()

	TweenService:Create(part, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = size * 1.35,
		Transparency = 1,
	}):Play()

	Debris:AddItem(part, lifetime + 0.1)

	return part
end

local function make_sphere(position: Vector3, radius: number, color: Color3, lifetime: number): BasePart
	local sphere = make_flash_part(CFrame.new(position), Vector3.one * radius, color, lifetime)
	sphere.Shape = Enum.PartType.Ball
	sphere.Material = Enum.Material.ForceField

	return sphere
end

local function get_root(character: Model): BasePart?
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function module.m1_slash(character: Model, combo_index: number)
	local root = get_root(character)
	if not root then
		return
	end

	local angle = ({ -24, 18, -8 })[combo_index] or 0
	local slash_cframe = root.CFrame * CFrame.new(0, 1.4, -3.2) * CFrame.Angles(0, 0, math.rad(angle))

	spawn_asset("IgnitionBurst-01", slash_cframe, 1.25, 18)
	make_flash_part(slash_cframe, Vector3.new(0.25, 4.8, 0.18), FIRE, 0.22)
end

function module.hit(position: Vector3)
	spawn_asset("IgnitionBurst-01", CFrame.new(position), 1.5, 14)
	make_sphere(position, 2.2, FIRE, 0.25)
end

function module.skill_slash(character: Model, range: number)
	local root = get_root(character)
	if not root then
		return
	end

	local slash_cframe = root.CFrame * CFrame.new(0, 1.3, -(range * 0.45))
	local asset = spawn_asset("Fire-Slash-01", slash_cframe, 2, 24)
	if asset then
		tint_emitters(asset, FIRE)
	else
		make_flash_part(slash_cframe, Vector3.new(0.5, 8, range), FIRE, 0.35)
	end
end

function module.ultimate(position: Vector3)
	spawn_asset("Explosion-01", CFrame.new(position), 3, 45)
	spawn_asset("Big-Crack-01", CFrame.new(position), 4, 20)
	make_sphere(position, 18, FIRE, 0.55)
	make_sphere(position, 9, GOLD, 0.4)
end

function module.heat_aura(player: Player, duration: number)
	local character = player.Character
	if not character then
		return
	end

	local root = get_root(character)
	if not root then
		return
	end

	local aura = spawn_asset("Fire-Aura-01", root.CFrame, duration + 1, 18)
	if not aura then
		aura = spawn_asset("Shield-01", root.CFrame, duration + 1, 10)
	end

	if aura then
		tint_emitters(aura, FIRE)
	end

	local shield =
		make_sphere(root.Position, math.max(8, character:GetExtentsSize().Magnitude * 0.9), FIRE, duration)
	shield.Transparency = 0.62

	local started = os.clock()
	local connection: RBXScriptConnection?
	connection = RunService.Heartbeat:Connect(function()
		if not character.Parent or os.clock() - started > duration then
			if connection then
				connection:Disconnect()
				connection = nil
			end

			return
		end

		local current_root = get_root(character)
		if current_root then
			shield.CFrame = current_root.CFrame

			if aura then
				pivot(aura, current_root.CFrame)
			end
		end
	end)
end

function module.reaction(payload: ReactionPayload)
	local position = payload.position
	local target = payload.target
	if not position and target and target.Character then
		local root = get_root(target.Character)
		position = root and root.Position or nil
	end

	if not position then
		return
	end

	if payload.reaction == "Melt" then
		spawn_asset("IgnitionBurst-01", CFrame.new(position), 1.5, 28)
		spawn_asset("Smoke-01", CFrame.new(position), 2, 12)
		make_sphere(position, 5, FIRE, 0.35)
	elseif payload.reaction == "Steam Burst" then
		spawn_asset("Smoke-01", CFrame.new(position), 2.5, 28)
		spawn_asset("Flamethrower-01", CFrame.new(position), 1.5, 16)
		make_sphere(position, 7, SMOKE, 0.5)
	elseif payload.reaction == "Frozen" then
		make_sphere(position, 5, Color3.fromRGB(135, 213, 255), 0.4)
	elseif payload.reaction == "Cryocharge" then
		spawn_asset("elec", CFrame.new(position), 1.5, 18)
		make_sphere(position, 5, Color3.fromRGB(178, 155, 255), 0.35)
	else
		make_sphere(position, 5, GOLD, 0.35)
	end
end

return module
