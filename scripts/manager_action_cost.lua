function onInit()
	ActionsManager.registerModHandler("cost", modRoll)
	ActionsManager.registerResultHandler("cost", onRoll);
end

-------------------------------------------------------------------------------
-- COST STATE MANAGEMENT
-------------------------------------------------------------------------------
local rLastAction;

-------------------------------------------------------------------------------
-- ROLLING
-------------------------------------------------------------------------------
function addEdgeToAction(rActor, rAction, aFilter)
	if not rActor or not ActorManager.isPC(rActor) or (rAction.sStat or "") == "" then
		return;
	end

	rAction.nEdge = ActorManagerCypher.getEdge(rActor, rAction.sStat, aFilter);
end

-------------------------------------------------------------------------------
-- ROLLING
-------------------------------------------------------------------------------
-- returns true if a the cost roll is made
-- returns false if no roll is made
function performRoll(draginfo, rActor, rAction)
	ActionCost.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addWoundedToAction(rActor, rAction, "stat");
	RollManager.addArmorCostToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rActor, rAction);
	RollManager.resolveMaximumEffort(rActor, rAction, aFilter);
	RollManager.calculateBaseEffortCost(rActor, rAction);
	RollManager.adjustEffortCostWithEffects(rActor, rAction, aFilter);
end

function getRoll()
end

function modRoll()
end

function onRoll()
end