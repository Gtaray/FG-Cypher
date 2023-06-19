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
	RollManager.encodeEaseHindrance(rRoll, (rAction.nEase or 0), (rAction.nHinder or 0));
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
	if (tonumber(rRoll.nDifficulty) or 0) == 0 then
		rRoll.nDifficulty = RollManager.getBaseRollDifficulty(rSource, rTarget,  { "attack", "atk", sStat });		
	end

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, { "defense", "def" }, { sStat })
	nAssets = nAssets + nAssetMod;

	-- Adjust difficulty based on assets. We can't hide everything behind processAssets here because
	-- shields grant an asset bonus
	local nMaxAssets = ActorManagerCypher.getMaxAssets(rSource, { "defense", "def", sStat });
	nAssets = nAssets + RollManager.processAssets(rSource, rTarget, { "defense", "def", sStat }, nAssets);

	-- Get the shield bonus of the defender
	local nShieldBonus = 0;
	if sStat == "speed" then
		nShieldBonus = ActorManagerCypher.getShieldBonus(rSource);
	end
	nAssets = math.min(nAssets + nShieldBonus, nMaxAssets);

	-- Adjust difficulty based on effort
	nEffort = nEffort + RollManager.processEffort(rSource, rTarget, { "defense", "def", sStat }, nEffort);

	-- Get ease/hinder effects
	local nEase, nHinder = RollManager.resolveEaseHindrance(rSource, rTarget, rRoll, { "defense", "def", sStat });

	-- Process conditions
	local nConditionEffects = RollManager.processStandardConditions(rSource, rTarget);

	-- Adjust difficulty based on training
	local nTrainingMod = RollManager.processTraining(bInability, bTrained, bSpecialized)

	-- Roll up all the level/mod adjustments and apply them to the difficulty here
	rRoll.nDifficulty = rRoll.nDifficulty - nAssets - nEffort - nTrainingMod + nConditionEffects - nEase + nHinder;

	RollManager.encodeEffort(nEffort, rRoll)
	RollManager.encodeAssets(nAssets, rRoll);
	RollManager.encodeEaseHindrance(rRoll, nEase, nHinder);
	RollManager.encodeEffects(rRoll, nEffectMod);
end

function onRoll(rSource, rTarget, rRoll)
	rTarget = RollManager.decodeTarget(rRoll, rTarget);
	local bPvP = ActorManager.isPC(rSource) and ActorManager.isPC(rTarget);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

	if rTarget then
		rMessage.text = rMessage.text .. " [from " .. (ActorManager.getDisplayName(rTarget) or "unknown") .. "]";
	end

	local aAddIcons = {};
	local nFirstDie = rRoll.aDice[1].result or 0;
	local bSuccess, bAutomaticSuccess = RollManager.processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons);
	local sIcon = "";

	-- only check for hit/miss on non-pvp rolls. Eventually this will change
	-- once I have a better way of handling pvp rolls
	if bPvP then
		RollManager.updateMessageWithConvertedTotal(rRoll, rMessage);
		
	else
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
	end

	if not bAutomaticSuccess then
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
	end

	RollManager.updateRollMessageIcons(rMessage, aAddIcons, sIcon);
	Comm.deliverChatMessage(rMessage);
end