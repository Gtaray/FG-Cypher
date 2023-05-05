function onInit()
	ActionsManager.registerModHandler("skill", modRoll)
	ActionsManager.registerResultHandler("skill", onRoll);
end

function performRoll(draginfo, rActor, rAction)
	local aFilter = { "skill", "skills", rAction.sStat };

	RollManager.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addWoundedToAction(rActor, rAction, "skill");
	RollManager.addArmorCostToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rActor, rAction);
	RollManager.resolveMaximumEffort(rActor, rAction, aFilter);
	RollManager.resolveMaximumAssets(rActor, rAction, aFilter);
	RollManager.calculateBaseEffortCost(rActor, rAction);
	RollManager.adjustEffortCostWithEffects(rActor, rAction, aFilter);

	local bCanRoll = RollManager.spendPointsForRoll(rActor, rAction);

	if bCanRoll then
		local rRoll = ActionSkill.getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "skill";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;
	rRoll.sDesc = string.format(
		"[SKILL (%s)] %s", 
		StringManager.capitalize(rAction.sStat or ""), 
		rAction.label or "");
	rRoll.nDifficulty = rAction.nDifficulty or 0;

	RollManager.encodeStat(rAction, rRoll);
	RollManager.encodeSkill(rAction.label, rRoll);
	RollManager.encodeTraining(rAction, rRoll);
	RollManager.encodeAssets(rAction, rRoll);
	RollManager.encodeEdge(rAction, rRoll);
	RollManager.encodeEffort(rAction, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = RollManager.decodeStat(rRoll, false);
	local sSkill = RollManager.decodeSkill(rRoll, false);
	local nEffort = RollManager.decodeEffort(rRoll, true);
	local nAssets = RollManager.decodeAssets(rRoll, true);
	local bInability, bTrained, bSpecialized = RollManager.decodeTraining(rRoll, true);

	if rTarget and not ActorManager.isPC(rTarget) then
		rRoll.nDifficulty = ActorManagerCypher.getCreatureLevel(rTarget, rSource, { "skill", "skills", sStat, sSkill });
	end

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, { "skill", "skills" }, { sStat, sSkill })
	nAssets = nAssets + nAssetMod;

	-- Adjust difficulty based on assets
	nAssets = nAssets + RollManager.processAssets(rSource, rTarget, sStat, { "skill", "skills", sStat, sSkill }, nAssets);

	-- Adjust difficulty based on effort
	nEffort = nEffort + RollManager.processEffort(rSource, rTarget, sStat, { "skill", "skills", sStat, sSkill }, nEffort);

	-- Get ease/hinder effects
	local bEase, bHinder = RollManager.resolveEaseHindrance(rSource, rTarget, { "skill", "skills", sStat, sSkill });

	-- Process conditions
	local nConditionEffects = RollManager.processStandardConditions(rSource, rTarget);

	-- Adjust difficulty based on training
	local nTrainingMod = RollManager.processTraining(bInability, bTrained, bSpecialized)

	-- Roll up all the level/mod adjustments and apply them to the difficulty here
	rRoll.nDifficulty = rRoll.nDifficulty - nAssets - nEffort - nTrainingMod - nConditionEffects;
	if bEase then 
		rRoll.nDifficulty = rRoll.nDifficulty - 1;
	end
	if bHinder then
		rRoll.nDifficulty = rRoll.nDifficulty + 1;
	end

	RollManager.encodeEffort(nEffort, rRoll)
	RollManager.encodeAssets(nAssets, rRoll);
	RollManager.encodeEaseHindrance(rRoll, bEase, bHinder);
	RollManager.encodeEffects(rRoll, nEffectMod);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
	end

	local aAddIcons = {};
	local nFirstDie = rRoll.aDice[1].result or 0;
	if nFirstDie >= 20 then
		rMessage.text = rMessage.text .. " [MAJOR EFFECT]";
		table.insert(aAddIcons, "roll20");
	elseif nFirstDie == 19 then
		rMessage.text = rMessage.text .. " [MINOR EFFECT]";
		table.insert(aAddIcons, "roll19");
	elseif nFirstDie == 1 then
		rMessage.text = rMessage.text .. " [GM INTRUSION]";
		table.insert(aAddIcons, "roll1");
	end
	
	local bSuccess, bAutomaticSuccess = RollManager.processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons);

	if rTarget then
		if bAutomaticSuccess then
			rMessage.text = rMessage.text .. " [AUTOMATIC SUCCESS]";
		elseif bSuccess then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILED]";
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end