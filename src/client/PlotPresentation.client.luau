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

-- Two prompts sit on a glizzy's PrimaryPart inside a "DogUnit" model: Steal (E,
-- rivals only) and Pick Up (F, owner only). Show each side only theirs — the
-- server re-validates both, this is pure de-clutter. (Ancestor check, not parent:
-- the prompt's parent is the Sausage part, not the model itself.)
local function applyPromptState(prompt: ProximityPrompt, owned: boolean)
	local model = prompt:FindFirstAncestorWhichIsA("Model")
	if model and model.Name == "DogUnit" then
		if prompt.Name == "PickupPrompt" then
			prompt.Enabled = owned
		else
			prompt.Enabled = not owned
		end
	end
end

-- Structural labels are OWNER-facing information: vault/deposit tags, the buy-pad
-- costs, and the cook/stove machine tags mean nothing on a rival's stand and stack
-- into text soup across the street. Hide them all on stands you don't own — the
-- owner sign + per-dog unit plates stay, which is exactly the raid-scouting info
-- the genre keeps visible (see Steal a Brainrot).
local HIDDEN_ON_RIVALS: { [string]: boolean } = {
	VaultLabel = true,
	DepositLabel = true,
	PadLabel = true,
	CookLabel = true,
	StoveLabel = true,
}
-- Toggle the TextLabel child, NOT BillboardGui.Enabled: the server flips pad
-- billboards' Enabled every sync tick and would fight (and win) a client override.
-- .Visible on the label is never written server-side, so the local hide sticks.
local function applyLabel(label: TextLabel, owned: boolean)
	local gui = label.Parent
	if gui and gui:IsA("BillboardGui") and HIDDEN_ON_RIVALS[gui.Name] then
		label.Visible = owned
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
	banner.Size = UDim2.fromOffset(160, 40)
	banner.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	banner.AlwaysOnTop = true
	banner.MaxDistance = 200
	banner.Parent = signPost or model

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(150, 255, 170)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Theme.UI.TitleFont
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
		elseif d:IsA("TextLabel") then
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
		elseif d:IsA("TextLabel") then
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

-- You never see the Snatch prompt on the glizzy in YOUR OWN hand — it's for
-- rivals (PickupService validates server-side; this is pure de-clutter, same
-- pattern as the plot prompts above).
local function watchOwnCharacter(character: Model)
	local function hideOwnSnatch(d: Instance)
		if d:IsA("ProximityPrompt") and d.Name == "HandStealPrompt" then
			d.Enabled = false
		end
	end
	for _, d in character:GetDescendants() do
		hideOwnSnatch(d)
	end
	character.DescendantAdded:Connect(hideOwnSnatch)
end
if player.Character then
	watchOwnCharacter(player.Character)
end
player.CharacterAdded:Connect(watchOwnCharacter)
