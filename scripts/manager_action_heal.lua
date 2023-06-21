function onInit()
	ActionsManager.registerModHandler("heal", modRoll);
	ActionsManager.registerResultHandler("heal", onRoll);
end

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "heal";

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		ActionHeal.performRoll(draginfo, rActor, rAction);
	end
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionHeal.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end


function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "heal";
	rRoll.aDice = { };
	rRoll.nMod = rAction.nHeal or rAction.nModifier or 0;
	
	rRoll.sLabel = rAction.label or "";
	rRoll.sStat = rAction.sStat;
	rRoll.sHealStat = rAction.sHealStat;
	rRoll.nEffort = rAction.nEffort or 0;
	
	rRoll.sDesc = string.format(
		"[HEAL (%s)] %s", 
		StringManager.capitalize(rRoll.sHealStat), 
		rRoll.sLabel);

	-- Handle self-targeting
	if rAction.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	if ActionHeal.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	local aFilter = { "heal", "healing", rRoll.sStat };

	-- Adjust mod based on effort
	rRoll.nEffort = (rRoll.nEffort or 0) + RollManager.processEffort(rSource, rTarget, aFilter, rRoll.nEffort);
	if (rRoll.nEffort or 0) > 0 then
		rRoll.nMod = rRoll.nMod + (rRoll.nEffort * 3);
	end

	local nHealBonus, nHealEffectCount = EffectManagerCypher.getEffectsBonusByType(rSource, "HEAL", { sStat }, rTarget)
	if nHealBonus ~= 0 then
		rRoll.nMod = rRoll.nMod + nHealBonus;
	end

	RollManager.encodeEffort(nEffort, rRoll)
	RollManager.encodeEffects(rRoll, nHealBonus);
end

function rebuildRoll(rSource, rTarget, rRoll)
	local bRebuilt = false;

	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[HEAL.*%]([^%[]+)"));
		bRebuilt = true;
	end
	if not rRoll.sStat then
		rRoll.sStat = RollManager.decodeStat(rRoll, true);
	end
	if not rRoll.nEffort then
		rRoll.nEffort = RollManager.decodeEffort(rRoll, true);
	end

	rRoll.bRebuilt = bRebuilt;
	return bRebuilt;
end

function onRoll(rSource, rTarget, rRoll)
	local rResult = ActionDamage.buildRollResult(rSource, rTarget, rRoll);
	rResult.nTotal = rResult.nTotal * -1; --Invert the roll total because negative damage is healing

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_heal";
	Comm.deliverChatMessage(rMessage);

	-- Apply damage to the PC or CT entry referenced
	if rResult.nTotal ~= 0 then
		ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll, rResult);
	end
end