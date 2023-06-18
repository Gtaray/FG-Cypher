function onInit()
	ActionsManager.registerModHandler("cost", modRoll)
	ActionsManager.registerResultHandler("cost", onRoll);
end

-------------------------------------------------------------------------------
-- COST STATE MANAGEMENT
-------------------------------------------------------------------------------
local rLastAction;
function setLastAction(rAction)
	rLastAction = rAction;
end

function getLastAction()
	return rLastAction;
end

function clearLastAction()
	rLastAction = nil;
end

-------------------------------------------------------------------------------
-- CALCS AND MODIFICACTIONS
-------------------------------------------------------------------------------
local rRollTypeFilters = {
	["stat"] = { "stat", "stats" },
	["attack"] = { "attack", "atk" },
	["damage"] = { "damage", "dmg" },
	["defense"] = { "defense", "def" },
	["heal"] = { "heal" },
	["initiative"] = { "initiative", "init" },
	["skill"] = { "skill", "skills" },
}

function getEffectFilter(rRoll)
	local aFilters = rRollTypeFilters[rRoll.sSourceRollType];
	if not aFilters then
		return {};
	end

	local aResult = UtilityManager.copyDeep(aFilters);

	if (rRoll.sCostStat or "") ~= "" then
		table.insert(aResult, rRoll.sCostStat);
	end

	return aResult;
end

function calculateEffortCost(rRoll)
	local nCost = 0;
	if (rRoll.nEffort or 0) > 0 then
		nCost = 3; -- Base cost
		nCost = nCost + ((rRoll.nEffort - 1) * 2); -- Plus 2 for every extra level of effort spent
	end

	return nCost;
end

-------------------------------------------------------------------------------
-- ROLLING
-------------------------------------------------------------------------------
-- returns true if a the cost roll is made
-- returns false if no roll is made
function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionCost.getRoll(rActor, rAction);

	if rRoll.nMod > 0 or rRoll.nEffort > 0 then
		ActionCost.setLastAction(rAction)
		ActionsManager.performAction(draginfo, rActor, rRoll);
		return true;
	end

	return false;
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "cost";
	rRoll.aDice = { };
	rRoll.nMod = rAction.nCost or 0;

	RollManager.resolveStatUsedForCost(rAction); -- resolve the cost stat first
	rRoll.sCostStat = rAction.sCostStat;
	
	rRoll.sDesc = "[COST"
	if (rRoll.sCostStat or "") ~= "" then
		local sStat = StringManager.capitalize(rRoll.sCostStat);

		-- This prevents double-writing the stat used to chat
		if rAction.label ~= sStat then
			rRoll.sDesc = string.format("%s (%s)", rRoll.sDesc, sStat);
		end
	end
	rRoll.sDesc = string.format("%s] %s", rRoll.sDesc, rAction.label or "");

	if rAction.sSourceRollType then
		rRoll.sSourceRollType = rAction.sSourceRollType;
	end

	-- We have to get effort used here because that can determine if there is 
	-- even a roll.
	-- i.e. a skill roll normally never has a cost, but if effort is applied 
	-- then it will. So we need to know if effort was applied here, and not
	-- in modRoll()
	rRoll.nEffort = RollManager.getEffortFromDifficultyPanel();

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local aFilter = ActionCost.getEffectFilter(rRoll);

	-- Add base effort from mod panel
	-- We have to save the max effort here because we can't reliably call it again
	-- when we re-roll the source roll. Because if the MAXEFF effect is a one-shot effect
	-- it'll get used up here and not be available in the source roll
	-- So we save it here and re-use it there.

	rRoll.nMaxEffort = ActorManagerCypher.getMaxEffort(rSource, rRoll.sCostStat, aFilter);
	rRoll.nEffort = math.min(rRoll.nEffort or 0, rRoll.nMaxEffort or 0);
	if rRoll.nEffort > 0 then
		rRoll.nMod = rRoll.nMod + 3 + ((rRoll.nEffort - 1) * 2);
	end

	-- Handle cost increase for being wounded
	if ActorManagerCypher.getDamageTrack(rSource) > 0 then
		-- If the user is wounded, then add 1 for every level of
		-- effort spent
		rRoll.nMod = rRoll.nMod + rRoll.nEffort; 
	end

	-- Add effort penalty based on armor
	if rRoll.sCostStat == "speed" then
		rRoll.nMod = rRoll.nMod + ActorManagerCypher.getArmorSpeedCost(rSource);
	end

	-- Reduce cost by Edge (if it's enabled)
	rRoll.bDisableEdge = RollManager.isEdgeDisabled();
	if not rRoll.bDisableEdge then
		rRoll.nEdge = ActorManagerCypher.getEdge(rSource, rRoll.sCostStat, aFilter);
		rRoll.nMod = rRoll.nMod - (rRoll.nEdge or 0);
	end

	-- Finally, adjust based on COST effects
	local nEffectMod = EffectManagerCypher.getEffectsBonusByType(rSource, "COST", aFilter);
	rRoll.nMod = rRoll.nMod + nEffectMod;

	-- Final clamping of the mod to a min of 0
	rRoll.nMod = math.max(rRoll.nMod, 0);

	-- Add all of the relevant text to the roll
	if (rRoll.nEffort or 0) > 0 then
		rRoll.sDesc = string.format("%s [APPLIED %s EFFORT]", rRoll.sDesc, rRoll.nEffort);
	end

	if rRoll.bDisableEdge then
		rRoll.sDesc = string.format("%s [EDGE DISABLED]", rRoll.sDesc, rRoll.nEdge);
	elseif rRoll.nEdge > 0 then
		rRoll.sDesc = string.format("%s [APPLIED %s EDGE]", rRoll.sDesc, rRoll.nEdge);
	end

	if nEffectMod > 0 then
		rRoll.sDesc = string.format("%s [EFFECTS +%s]", rRoll.sDesc, nEffectMod)
	elseif nEffectMod < 0 then
		rRoll.sDesc = string.format("%s [EFFECTS %s]", rRoll.sDesc, nEffectMod)
	end
end

function onRoll(rSource, rTarget, rRoll)
	-- TODO: actually deduct the cost from stat pool
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "roll_damage";

	Comm.deliverChatMessage(rMessage);

	local rAction = ActionCost.getLastAction();
	
	if rAction then
		-- Make sure to update the relevant properties
		rAction.nEffort = rRoll.nEffort;
		rAction.nMaxEffort = rRoll.nMaxEffort;

		ActionCost.invokeSourceAction(rSource, rAction);
		ActionCost.clearLastAction();
	end
end

function invokeSourceAction(rSource, rAction)
	if rAction.sSourceRollType == "stat" then
		ActionStat.performRoll(nil, rSource, rAction)
	elseif rAction.sSourceRollType == "skill" then
		ActionSkill.performRoll(nil, rSource, rAction)
	elseif rAction.sSourceRollType == "defense" then
		ActionDefense.performRoll(nil, rSource, rAction)
	elseif rAction.sSourceRollType == "attack" then
		ActionAttack.performRoll(nil, rSource, rAction)
	elseif rAction.sSourceRollType == "init" then
		ActionInit.performRoll(nil, rSource, rAction)
	end
end