--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local batch = require(ReplicatedStorage.Utility.batch)
local leventine = require(ReplicatedStorage.Utility.leventine)

-- fetchAsset.luau
-- a module for getting combat assets

local asset_folder = ReplicatedStorage:FindFirstChild("Assets")
if not asset_folder then
	warn("Assets folder not found in ReplicatedStorage. Asset fetching will fail.")
	asset_folder = Instance.new("Folder")
	asset_folder.Name = "Assets"
	asset_folder.Parent = ReplicatedStorage
end
local assetsProcessed = false

local function ensureAssetsProcessed()
	if not assetsProcessed then
		task.spawn(function()
			batch(asset_folder:GetDescendants())
			assetsProcessed = true
		end)
	end
end

local function fetch(abbreviation: string)
	ensureAssetsProcessed()
	local start_time = os.clock() -- benchmarks
	local n = 1000
	local raw_list = asset_folder:GetDescendants()
	local list = {}
	for _, asset in ipairs(raw_list) do
		table.insert(list, asset.Name)
	end
	-- we use a leventine cuhz im lazy lmao
	local closest, _ = leventine.closest(abbreviation, list)
	assert(closest, `Failed to find closest asset by abbreviation. Try being more detailed : {abbreviation} `)
	local asset = asset_folder:FindFirstChild(closest, true)
	assert(asset, "Couldn't get asset recursively.")
	asset = asset:Clone()
	local endTime = os.clock()
	-- print(`it took : {math.round((start_time - endTime) * n) / n} to get the asset.`)
	return asset
end

return fetch
