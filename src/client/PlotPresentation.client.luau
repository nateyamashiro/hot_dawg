--!strict
-- Client-only presentation of the plots. Everything here is created/toggled on the
-- LOCAL player's machine, so it only ever changes what THIS player sees — it never
-- touches authoritative state. It reads each plot's replicated `OwnerUserId`
-- attribute (set by PlotManager on assign) to decide what to show:
--   * YOUR stand  -> green Highlight + "🏠 YOUR STAND" banner; Steal prompts on your
--                    own dogs hidden (you can't steal yourself); Vault/Deposit labels shown.
--   * RIVAL stands -> Vault/Deposit labels hidden (less world clutter); the stealable
--                     dog name/rarity billboards + owner-name sign stay visible so you
--                     can still see what's worth raiding.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Theme = require(ReplicatedStorage.Shared.Theme)

local player = Players.LocalPlayer

local function isOwned(model: Instance): boolean
	return model:GetAttribute("OwnerUserId") == player.UserId
end

-- A Steal prompt sits on a glizzy model's PrimaryPart inside a "DogUnit" model on a
-- pedestal. Hide it on your OWN dogs. (Ancestor check, not parent: the prompt's
-- parent is the Sausage part, not the model itself.)
local function applyPromptState(prompt: ProximityPrompt, owned: boolean)
	local model = prompt:FindFirstAncestorWhichIsA("Model")
	if model and model.Name == "DogUnit" then
		prompt.Enabled = not owned
	end
end

-- The Vault/Deposit billboards are structural clutter on someone else's stand.
local function applyLabel(gui: BillboardGui, owned: boolean)
	if gui.Name == "VaultLabel" or gui.Name == "DepositLabel" then
		gui.Enabled = owned
	end
end

-- The owner-only visuals (highlight + banner) we create for the local player's plot.
local ownedVisuals: { [Model]: { highlight: Highlight, banner: BillboardGui } } = {}

local function ensureOwnedVisuals(model: Model)
	if ownedVisuals[model] then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Theme.Semantic.Owner
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.fromRGB(120, 255, 150)
	highlight.OutlineTransparency = 0
	highlight.Parent = model

	local signPost = model:WaitForChild("SignPost", 5) :: BasePart?
	local banner = Instance.new("BillboardGui")
	banner.Name = "YourStandBanner"
	banner.Size = UDim2.fromOffset(220, 60)
	banner.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	banner.AlwaysOnTop = true
	banner.MaxDistance = 250
	banner.Parent = signPost or model

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(150, 255, 170)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Text = "🏠 YOUR STAND"
	label.Parent = banner

	ownedVisuals[model] = { highlight = highlight, banner = banner }
end

local function removeOwnedVisuals(model: Model)
	local visuals = ownedVisuals[model]
	if visuals then
		visuals.highlight:Destroy()
		visuals.banner:Destroy()
		ownedVisuals[model] = nil
	end
end

-- Bring the whole plot to the correct presentation for the current owner.
local function refresh(model: Model)
	local owned = isOwned(model)
	if owned then
		ensureOwnedVisuals(model)
	else
		removeOwnedVisuals(model)
	end
	for _, d in model:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			applyPromptState(d, owned)
		elseif d:IsA("BillboardGui") then
			applyLabel(d, owned)
		end
	end
end

local function watchPlot(model: Model)
	refresh(model)
	-- Ownership changes when players join/leave and plots get reassigned.
	model:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		refresh(model)
	end)
	-- Dog units (and their Steal prompts) stream in as the owner cooks/steals; apply
	-- the current ownership rule to each new descendant as it arrives.
	model.DescendantAdded:Connect(function(d)
		local owned = isOwned(model)
		if d:IsA("ProximityPrompt") then
			applyPromptState(d, owned)
		elseif d:IsA("BillboardGui") then
			applyLabel(d, owned)
		end
	end)
end

local function tryWatch(child: Instance)
	if child:IsA("Model") and string.match(child.Name, "^Plot%d+$") then
		watchPlot(child :: Model)
	end
end

for _, child in Workspace:GetChildren() do
	tryWatch(child)
end
Workspace.ChildAdded:Connect(tryWatch)
