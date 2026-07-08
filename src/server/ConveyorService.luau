--!strict
-- Conveyor purchase lane (Phase 4, visual-overhaul/tycoon plan). Steal-a-Brainrot's
-- signature buy mechanic: hot dogs ride the central street on a belt; step on one to
-- buy it (a ProximityPrompt grants the dog + charges coins). Offers are picked
-- deterministically (reuse ShopService's daily-offer logic) so all servers agree.
-- Server owns the spawned belt objects + the buy transaction; there's nothing for the
-- client to request (it just walks up), so this service has no client remotes.
--
-- SCAFFOLD: the belt spawner + step-to-buy ProximityPrompts are TODO(Phase4). Today
-- init only captures deps so Main can wire it alongside the other services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)

local ConveyorService = {}

local updateLeaderstats: (player: Player) -> ()
local onInventoryChanged: (player: Player) -> ()

function ConveyorService.init(deps: {
	updateLeaderstats: (player: Player) -> (),
	onInventoryChanged: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	onInventoryChanged = deps.onInventoryChanged
	-- TODO(Phase4): spawn a belt down the central aisle (GameConfig.PlotRowSeparation
	-- wide), ride GameConfig.ConveyorMaxOnBelt dogs along it on GameConfig.ConveyorSpawnInterval,
	-- and attach a step-to-buy ProximityPrompt to each. On buy: validate coins, charge,
	-- grant the dog (through Variants/MutationService like doCook), then call
	-- updateLeaderstats + onInventoryChanged. Reuse ShopService's deterministic offers.
	local _ = GameConfig
	local _ = DataManager
	local _ = updateLeaderstats
	local _ = onInventoryChanged
end

return ConveyorService
