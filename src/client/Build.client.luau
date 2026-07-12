--!strict
-- Build menu window (P-D, design plan §4.3). The full BuildCatalog as a list on the
-- already-shipped BuildUpdate remote: owned ✅ / buildable 🏗️ (Buy button) / locked
-- 🔒 (shows the prereq). The walk-on pads at the stand stay the primary buy path —
-- this window is the overview + a remote buy for planners. Untrusted display only;
-- the server re-validates every Build request.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildGrants = require(ReplicatedStorage.Shared.BuildGrants)
local Format = require(ReplicatedStorage.Shared.Format)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local build = remotes:WaitForChild("Build") :: RemoteEvent
local buildUpdate = remotes:WaitForChild("BuildUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyBuild"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Build", "🏗️ Build")
local panel, content = MenuLayout.makePanel(gui, "🏗️ Build your Stand")

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local function render(built: { [string]: boolean }, coins: number)
	for _, child in content:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, entry in BuildGrants.all() do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 52)
		row.LayoutOrder = i
		row.BackgroundColor3 = MenuLayout.RowBg
		row.Parent = content
		MenuLayout.addChrome(row, 8)

		local owned = built[entry.id] == true
		local prereqOk = entry.prereq == nil or built[entry.prereq] == true
		local kindIcon = if BuildGrants.category(entry) == "decor" then "🎪" else "🏗️"

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -120, 1, -8)
		label.Position = UDim2.fromOffset(10, 4)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = row

		if owned then
			label.TextColor3 = MenuLayout.SuccessText
			label.Text = string.format("✅ %s", entry.label)
		elseif prereqOk then
			label.TextColor3 = MenuLayout.BodyText
			label.Text =
				string.format("%s %s — 💰%s", kindIcon, entry.label, Format.comma(entry.cost))

			local buy = Instance.new("TextButton")
			buy.Size = UDim2.fromOffset(96, 36)
			buy.Position = UDim2.new(1, -104, 0.5, -18)
			buy.Text = "Buy"
			buy.Parent = row
			MenuLayout.styleButton(buy, if coins >= entry.cost then "success" else "primary")
			buy.Activated:Connect(function()
				build:FireServer(entry.id)
			end)
		else
			local prereqEntry = entry.prereq and BuildGrants.entry(entry.prereq)
			local need = if prereqEntry then prereqEntry.label else entry.prereq or "?"
			label.TextColor3 = MenuLayout.MutedText
			label.Text = string.format("🔒 %s — needs %s", entry.label, need)
		end
	end
end

buildUpdate.OnClientEvent:Connect(
	function(_catalog: any, built: { [string]: boolean }?, coins: number?)
		render(built or {}, coins or 0)
	end
)

gui.Parent = player:WaitForChild("PlayerGui")
requestState:FireServer() -- pull the initial built-set snapshot past the join race
