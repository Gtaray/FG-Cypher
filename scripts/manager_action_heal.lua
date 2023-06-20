function onInit()
	ActionsManager.registerModHandler("heal", modRoll);
	ActionsManager.registerResultHandler("heal", onRoll);
end

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "heal";

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		actionHeal.performRoll(draginfo, rActor, rAction);
	end
end

function performRoll(draginfo, rActor, rAction)
	local aFilter = { "heal" };

	RollManager.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addArmorCostToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rActor, rAction);
	RollManager.resolveMaximumEffort(rActor, rAction, aFilter);
	RollManager.resolveMaximumAssets(rActor, rAction, aFilter);
	RollManager.calculateBaseEffortCost(rActor, rAction);
	RollManager.adjustEffortCostWithEffects(rActor, rAction, aFilter);

	local bCanRoll = true; -- NPCs can always roll
	if ActorManager.isPC(rActor) then
		bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);
	end

	if bCanRoll then
		local rRoll = ActionHeal.getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end


function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "heal";
	rRoll.aDice = { };
	rRoll.nMod = rAction.nHeal or rAction.nModifier or 0;
	
	rRoll.sDesc = string.format(
		"[HEAL (%s)] %s", 
		StringManager.capitalize(rAction.sHealStat), 
		rAction.label);

	-- Handle self-targeting
	if rAction.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end

	RollManager.encodeStat(rAction, rRoll);
	RollManager.encodeEdge(rAction, rRoll);
	RollManager.encodeEffort(rAction, rRoll);
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	-- We want to get rid of the [STAT: %s] tag here, because the onRoll handler
	-- will decode the [HEAL (%s)] stat tag (which is the stat that's being damaged)
	-- We only need the source's stat to handle effects
	local sStat = RollManager.decodeStat(rRoll, false);
	local nEffort = RollManager.decodeEffort(rRoll, true);

	-- Adjust mod based on effort
	nEffort = nEffort + RollManager.processEffort(rSource, rTarget, { "heal", "healing", sStat }, nEffort);
	if (nEffort or 0) > 0 then
		rRoll.nMod = rRoll.nMod + (nEffort * 3);
	end

	local nHealBonus, nHealEffectCount = EffectManagerCypher.getEffectsBonusByType(rSource, "HEAL", { sStat }, rTarget)
	if nHealBonus ~= 0 then
		rRoll.nMod = rRoll.nMod + nHealBonus;
	end

	RollManager.encodeEffort(nEffort, rRoll)
	RollManager.encodeEffects(rRoll, nHealBonus);
end

function onRoll(rSource, rTarget, rRoll)
	local rResult = ActionDamage.buildRollResult(rSource, rTarget, rRoll);
	RollManager.decodeStat(rRoll, false); -- Don't need this after getting rResult
	rResult.nTotal = rResult.nTotal * -1; --Invert the roll total because negative damage is healing

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_heal";
	Comm.deliverChatMessage(rMessage);

	-- Apply damage to the PC or CT entry referenced
	if rResult.nTotal ~= 0 then
		ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll, rResult);
	end
end