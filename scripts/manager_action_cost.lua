function onInit()
	ActionsManager.registerModHandler("cost", modRoll)
	ActionsManager.registerResultHandler("cost", onRoll);
end

-------------------------------------------------------------------------------
-- COST STATE MANAGEMENT
-------------------------------------------------------------------------------
local rLastAction;
function setLastAction(rAction)
	-- If this action doesn't have a source roll type, then we bail
	-- currently the only place this occurs is if a COST roll is made
	-- on its own, not as part of any other roll.
	if not rAction.sSourceRollType then
		return;
	end
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
	["skill"] = { "skill", "skills" }
}

function getEffectFilter(rRoll)
	local sType = rRoll.sSourceRollType;
	if not sType then
		sType = "cost";
	end

	local aFilters = rRollTypeFilters[sType];
	if not aFilters then
		aFilters = { };
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
	-- NPCs always just move on through and don't pay cost
	-- could be neat if they could in the future though
	if not ActorManager.isPC(rActor) then
		return false;
	end

	local rRoll = ActionCost.getRoll(rActor, rAction);

	if rRoll.nMod > 0 or rRoll.nEffort > 0 then
		-- Need to set the last action BEFORE we prompt for cost conversion
		ActionCost.setLastAction(rAction)

		-- Check to see if the actor has a CONVERT effect that lets them convert
		-- one cost into another.
		-- But you cannot convert XP costs
		if rRoll.sStat ~= "xp" then
			local aConvert = EffectManagerCypher.getConversionEffect(rTarget, rRoll.sCostStat, { "cost" });
			if #aConvert > 0 then
				local w = Interface.openWindow("prompt_cost_conversion", "");
				w.setData(aConvert, rRoll.sCostStat);
				w.setRoll(rActor, rRoll);

				-- Don't want the original roll to fire so we return true;
				return true;
			end
		end

		RollManager.convertBooleansToNumbers(rRoll);
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
	rRoll.nEffort = 0;
	rRoll.nAttackEffort = rAction.nAttackEffort or 0

	RollManager.resolveStatUsedForCost(rAction); -- resolve the cost stat first
	rRoll.sCostStat = rAction.sCostStat;
	rRoll.sLabel = rAction.label or "";
	
	rRoll.sDesc = "[COST"
	if (rRoll.sCostStat or "") ~= "" then
		local sStat = StringManager.capitalize(rRoll.sCostStat);
		if rRoll.sCostStat == "xp" then
			sStat = sStat:upper();
		end

		-- This prevents double-writing the stat used to chat
		if rAction.label ~= sStat then
			rRoll.sDesc = string.format("%s (%s)", rRoll.sDesc, sStat);
		end
	end
	rRoll.sDesc = string.format("%s] %s", rRoll.sDesc, rRoll.sLabel);

	if rAction.sSourceRollType then
		rRoll.sSourceRollType = rAction.sSourceRollType;
	end

	-- We have to get effort used here because that can determine if there is 
	-- even a roll.
	-- i.e. a skill roll normally never has a cost, but if effort is applied 
	-- then it will. So we need to know if effort was applied here, and not
	-- in modRoll()
	if rRoll.sCostStat == "might" or rRoll.sCostStat == "speed" or rRoll.sCostStat == "intellect" then
		rRoll.nEffort = (rAction.nEffort or 0) + RollManager.getEffortFromDifficultyPanel();
	end

	rRoll.bDisableEdge = false
	rRoll.bIgnoreCost = rAction.bIgnoreCost or RollManager.isCostIgnored(false)

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	if ActionCost.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	-- XP costs cannot be modified in any way.
	if rRoll.sCostStat == "xp" then
		return;
	end

	local aFilter = ActionCost.getEffectFilter(rRoll);

	-- Add base effort from mod panel
	-- We have to save the max effort here because we can't reliably call it again
	-- when we re-roll the source roll. Because if the MAXEFF effect is a one-shot effect
	-- it'll get used up here and not be available in the source roll
	-- So we save it here and re-use it there.

	rRoll.nMaxEffort = ActorManagerCypher.getMaxEffort(rSource, rRoll.sCostStat, aFilter);

	-- Some wierd bug where this gets turned into a string when the roll is dragged
	rRoll.nAttackEffort = tonumber(rRoll.nAttackEffort)

	-- For damage rolls we need to account for the fact that the attack and damage have a combined maximum
	local nActualMax = (rRoll.nMaxEffort or 0) - (rRoll.nAttackEffort or 0)

	rRoll.nEffort = math.min((rRoll.nEffort or 0), nActualMax);
	if rRoll.nEffort > 0 then
		table.insert(aFilter, "effort")

		-- If we're using attack effort, then we know that we don't need to add the 3 for the first effort cost and 
		-- only have to multiply by 2
		if (rRoll.nAttackEffort or 0) > 0 then
			rRoll.nMod = rRoll.nMod + (rRoll.nEffort * 2);
		else
			rRoll.nMod = rRoll.nMod + 3 + ((rRoll.nEffort - 1) * 2);
		end
	end

	-- Handle cost increase for being wounded
	if CharManager.isImpaired(rSource) then
		-- If the user is wounded, then add 1 for every level of
		-- effort spent
		rRoll.nMod = rRoll.nMod + rRoll.nEffort; 
		rRoll.sDesc = string.format("%s [IMPAIRED]", rRoll.sDesc);
	end

	-- Add effort penalty based on armor
	if rRoll.sCostStat == "speed" then
		rRoll.nMod = rRoll.nMod + ActorManagerCypher.getArmorSpeedCost(rSource);
	end

	-- Reduce cost by Edge (if it's enabled)
	if not rRoll.bDisableEdge then
		rRoll.nEdge = ActorManagerCypher.getEdge(rSource, rRoll.sCostStat, aFilter);
		rRoll.nMod = rRoll.nMod - (rRoll.nEdge or 0);
	end

	-- Finally, adjust based on COST effects
	local nEffectMod = EffectManagerCypher.getCostEffectBonus(rSource, aFilter);
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

	RollManager.convertBooleansToNumbers(rRoll);
end

-- Not entirely necessary, but for completeness' sake
function rebuildRoll(rSource, rTarget, rRoll)
	local bRebuilt = false;

	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[COST.*%]([^%[]+)"));
		bRebuilt = true;
	end
	if not rRoll.sCostStat then
		rRoll.sCostStat = RollManager.decodeStat(rRoll, true);
	end
	if not rRoll.nEffort then
		rRoll.nEffort = RollManager.decodeEffort(rRoll, true);
	end

	rRoll.bRebuilt = bRebuilt;
	return bRebuilt;
end

function onRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);

	-- dragging from chat results in a nil rSource, but there is the drop target
	-- so we just set one to the other
	if not rSource then
		rSource = rTarget;
	end

	if not rRoll.bIgnoreCost then
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		rMessage.icon = "roll_damage";

		local nTotal = ActionsManager.total(rRoll);
		local bNotEnoughStats = false;
		local sNotEnoughStatsMsg = "";

		if rRoll.sCostStat == "xp" then
			bNotEnoughStats = ActorManagerCypher.getXP(rSource) < nTotal
			sNotEnoughStatsMsg = "[INSUFFICIENT XP]";
		else
			local nCurStat = ActorManagerCypher.getStatPool(rSource, rRoll.sCostStat);
			bNotEnoughStats = nCurStat < nTotal;
			sNotEnoughStatsMsg = "[INSUFFICIENT STATS]";
		end

		if bNotEnoughStats and sNotEnoughStatsMsg ~= "" then
			rMessage.text = string.format("%s %s", rMessage.text, sNotEnoughStatsMsg);
		end

		Comm.deliverChatMessage(rMessage);

		if bNotEnoughStats then
			return;
		end

		if rRoll.sCostStat == "xp" then
			ActorManagerCypher.deductXP(rSource, nTotal);
		else
			ActorManagerCypher.addToStatPool(rSource, rRoll.sCostStat, -nTotal)
		end
	end

	-- If this is an attack, and we don't want to pay attack and damage effort separately
	-- Then we show a prompt asking for the player to split effort between attack and damage
	if rRoll.sSourceRollType == "attack" and rRoll.nEffort > 0 and not OptionsManagerCypher.splitAttackAndDamageEffort() then
		local w = Interface.openWindow("prompt_attack_effort_split", "")
		w.setRoll(rSource, rTarget, rRoll)
		w.setEffort(rRoll.nEffort)
	
		return
	end

	ActionCost.performLastAction(rSource, rTarget, rRoll)
end

function performLastAction(rSource, rTarget, rRoll)
	local rAction = ActionCost.getLastAction();
	if rAction then
		-- Make sure to update the relevant properties
		rAction.nEffort = rRoll.nEffort;
		rAction.nMaxEffort = rRoll.nMaxEffort;
		if rTarget then
			rAction.rTarget = rTarget;
		end

		if rRoll.sSourceRollType == "attack" and (rRoll.nDamageEffort or 0) > 0 then
			rAction.nDamageEffort = rRoll.nDamageEffort
		end

		PromptManager.closeDefensePromptWindow(rSource);
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
	elseif rAction.sSourceRollType == "damage" then
		ActionDamage.performRoll(nil, rSource, rAction);
	elseif rAction.sSourceRollType == "heal" then
		ActionHeal.performRoll(nil, rSource, rAction);
	elseif rAction.sSourceRollType == "effect" then
		ActionEffectCypher.performRoll(nil, rSource, rAction);
	end
end