function onInit()
	ActionsManager.registerModHandler("defense", modRoll)
	ActionsManager.registerResultHandler("defense", onRoll);
end

function performRoll(draginfo, rActor, rAction)
	local aFilter = { "defense", "def", rAction.sStat };

	RollManager.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addWoundedToAction(rActor, rAction, "defense");
	RollManager.addArmorCostToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rActor, rAction);
	RollManager.resolveMaximumEffort(rActor, rAction, aFilter);
	RollManager.resolveMaximumAssets(rActor, rAction, aFilter);
	RollManager.calculateBaseEffortCost(rActor, rAction);
	RollManager.adjustEffortCostWithEffects(rActor, rAction, aFilter);

	local bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);

	if bCanRoll then
		local rRoll = ActionDefense.getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
		return true;
	end

	return false;
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "defense";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;
	rRoll.sDesc = string.format("[DEFENSE] %s", rAction.label);

	rRoll.nDifficulty = rAction.nDifficulty or 0;

	RollManager.encodeStat(rAction, rRoll);
	RollManager.encodeTraining(rAction, rRoll);
	RollManager.encodeAssets(rAction, rRoll);
	RollManager.encodeEdge(rAction, rRoll);
	RollManager.encodeEffort(rAction, rRoll);
	RollManager.encodeTarget(rAction.rTarget, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = RollManager.decodeStat(rRoll, false);
	local nAssets = RollManager.decodeAssets(rRoll, true);
	local nEffort = RollManager.decodeEffort(rRoll, true);
	local bInability, bTrained, bSpecialized = RollManager.decodeTraining(rRoll, true);
	rTarget = RollManager.decodeTarget(rRoll, rTarget, true);

	-- Get base difficulty
	-- Only calc difficulty if it's not already been set
	-- this is because defense vs rolls will calc the difficulty of an NPC attack
	-- ahead of time. Defense rolls in response don't need to get the difficulty
	if rTarget and not ActorManager.isPC(rTarget) and rRoll.nDifficulty == 0 then
		rRoll.nDifficulty = ActorManagerCypher.getCreatureLevel(rTarget, rSource, { "attack", "atk", sStat });		
	end

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, { "defense", "def" }, { sStat })
	nAssets = nAssets + nAssetMod;

	-- Adjust difficulty based on assets
	nAssets = nAssets + RollManager.processAssets(rSource, rTarget, { "defense", "def", sStat }, nAssets);

	-- Adjust difficulty based on effort
	nEffort = nEffort + RollManager.processEffort(rSource, rTarget, sStat, { "defense", "def", sStat }, nEffort);

	-- Get ease/hinder effects
	local bEase, bHinder = RollManager.resolveEaseHindrance(rSource, rTarget, { "defense", "def", sStat });

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
	rTarget = RollManager.decodeTarget(rRoll, rTarget);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

	if rTarget then
		rMessage.text = rMessage.text .. " [from " .. (ActorManager.getDisplayName(rTarget) or "unknown") .. "]";
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
		local sIcon = "";
		if bSuccess then
			if bAutomaticSuccess then
				rMessage.text = rMessage.text .. " [AUTOMATIC MISS]";
			else
				rMessage.text = rMessage.text .. " [MISS]";
			end
			if nFirstDie >= 19 then
				sIcon = "roll_attack_crit_miss";
			else
				sIcon = "roll_attack_miss";
			end
		else
			rMessage.text = rMessage.text .. " [HIT]";

			if nFirstDie == 1 then
				sIcon = "roll_attack_crit";
			else
				sIcon = "roll_attack_hit";
			end
		end

		-- Replace the first icon ('action_roll') with proper hit/miss icon
		if type(rMessage.icon) == "table" then
			rMessage.icon[1] = sIcon
		else
			-- This should never be the case, since we should always have 2 icons (action_roll and task#)
			rMessage.icon = sIcon;
		end
	end

	Comm.deliverChatMessage(rMessage);
end