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
	RollManager.convertBooleansToNumbers(rRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end


function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "heal";
	rRoll.aDice = rAction.aDice or { };
	rRoll.nMod = rAction.nHeal or rAction.nModifier or 0;
	
	rRoll.sLabel = rAction.label or "";
	rRoll.sStat = rAction.sStat;
	rRoll.sHealStat = rAction.sHealStat;
	rRoll.nEffort = rAction.nEffort or 0;
	rRoll.bNoOverflow = rAction.bNoOverflow or false;
	
	rRoll.sDesc = ActionHeal.getRollLabel(rActor, rAction, rRoll)

	-- Handle self-targeting
	if rAction.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end

	RollManager.encodeTarget(rAction.rTarget, rRoll);
	
	return rRoll;
end

function getRollLabel(rActor, rAction, rRoll)
	return string.format(
		"[HEAL (%s)] %s", 
		StringManager.capitalize(rRoll.sHealStat),
		rRoll.sLabel);
end

function getEffectFilter(rRoll)
	local aFilter = { "heal", "healing" };
	if rRoll.sStat then
		table.insert(aFilter, rRoll.sStat);
	end
	return aFilter
end

function modRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	if ActionHeal.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	rTarget = RollManager.decodeTarget(rRoll, rTarget, true);

	local aFilter = ActionHeal.getEffectFilter(rRoll)

	-- Adjust mod based on effort
	rRoll.nEffort = (rRoll.nEffort or 0) + RollManager.processEffort(rSource, rTarget, aFilter, rRoll.nEffort);
	if (rRoll.nEffort or 0) > 0 then
		rRoll.nMod = rRoll.nMod + (rRoll.nEffort * 3);
	end

	local aHealEffectFilter = {};
	if rRoll.sStat then
		table.insert(aHealEffectFilter, rRoll.sStat);
	end
	local nHealBonus = EffectManagerCypher.getHealEffectBonus(rSource, aHealEffectFilter, rTarget)
	if nHealBonus ~= 0 then
		rRoll.nMod = rRoll.nMod + nHealBonus;
	end

	RollManager.encodeEffort(nEffort, rRoll)
	RollManager.encodeEffects(rRoll, nHealBonus);
	if rRoll.bNoOverflow then
		rRoll.sDesc = rRoll.sDesc .. " [SINGLE STAT]"
	end

	RollManager.convertBooleansToNumbers(rRoll);
end

function rebuildRoll(rSource, rTarget, rRoll)
	local bRebuilt = false;

	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[HEAL.*%]([^%[]+)"));
		bRebuilt = true;
	end
	if not rRoll.sHealStat then
		rRoll.sHealStat = RollManager.decodeStat(rRoll, true);
	end
	if not rRoll.nEffort then
		rRoll.nEffort = RollManager.decodeEffort(rRoll, true);
	end
	if not rRoll.bNoOverflow then
		rRoll.bNoOverflow = rRoll.sDesc:match("%[SINGLE STAT%]") ~= nil;
	end

	rRoll.bRebuilt = bRebuilt;
	return bRebuilt;
end

function onRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	rTarget = RollManager.decodeTarget(rRoll, rTarget);
	
	-- For some reason the boolean bNoOverflow is entirely stripped out here
	-- so we need to re-build it from the description
	rRoll.bNoOverflow = rRoll.sDesc:match("%[SINGLE STAT%]") ~= nil;

	ActionDamage.buildRollResult(rSource, rTarget, rRoll);
	rRoll.nTotal = rRoll.nTotal * -1; --Invert the roll total because negative damage is healing

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "roll_heal";
	Comm.deliverChatMessage(rMessage);

	-- Apply damage to the PC or CT entry referenced
	if rRoll.nTotal ~= 0 then
		ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll);
	end
end