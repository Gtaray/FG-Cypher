function onInit()
	ActionsManager.registerModHandler("stat", modRoll)
	ActionsManager.registerResultHandler("stat", onRoll);
end

function performRoll(draginfo, rActor, rAction)
	local aFilter = { "stat", "stats", rAction.sStat };

	RollManager.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addWoundedToAction(rActor, rAction, "stat");
	RollManager.addArmorCostToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rActor, rAction);
	RollManager.resolveMaximumEffort(rActor, rAction, aFilter);
	RollManager.resolveMaximumAssets(rActor, rAction, aFilter);
	RollManager.calculateBaseEffortCost(rActor, rAction);
	RollManager.adjustEffortCostWithEffects(rActor, rAction, aFilter);

	local bCanRoll = RollManager.spendPointsForRoll(rActor, rAction);

	if bCanRoll then
		local rRoll = ActionStat.getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "stat";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;

	local sStat = "";
	if (rAction.sStat or "") ~= "" then
		sStat = string.format(" (%s)", StringManager.capitalize(rAction.sStat));
	end

	rRoll.sDesc = string.format("[STAT%s] %s", sStat, rAction.label or "");
	rRoll.nDifficulty = rAction.nDifficulty or 0;

	RollManager.encodeTraining(rAction, rRoll);
	RollManager.encodeAssets(rAction, rRoll);
	RollManager.encodeEdge(rAction, rRoll);
	RollManager.encodeEffort(rAction, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = rRoll.sDesc:match("%[STAT%] (%w+)");
	local nEffort = RollManager.decodeEffort(rRoll, true);
	local nAssets = RollManager.decodeAssets(rRoll, true);
	local bInability, bTrained, bSpecialized = RollManager.decodeTraining(rRoll, true);

	rRoll.nDifficulty = RollManager.getBaseRollDifficulty(rSource, rTarget, { "stat", "stats", sStat });

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, { "stat", "stats" }, { sStat })
	nAssets = nAssets + nAssetMod;

	-- Adjust difficulty based on assets
	nAssets = nAssets + RollManager.processAssets(rSource, rTarget, { "stat", "stats", sStat }, nAssets);

	-- Adjust difficulty based on effort
	nEffort = nEffort + RollManager.processEffort(rSource, rTarget, { "stat", "stats", sStat }, nEffort);

	-- Get ease/hinder effects
	local bEase, bHinder = RollManager.resolveEaseHindrance(rSource, rTarget, rRoll, { "stat", "stats", sStat });

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
	local bSuccess, bAutomaticSuccess = RollManager.processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons);

	if bAutomaticSuccess then
		rMessage.text = rMessage.text .. " [AUTOMATIC SUCCESS]";
	elseif bSuccess then
		rMessage.text = rMessage.text .. " [SUCCESS]";
	else
		rMessage.text = rMessage.text .. " [FAILED]";
	end

	-- Since players technically shouldn't roll if the difficulty is reduced to 0
	-- they also don't have the chance to get major/minor/intrusion effects, so don't put them here.
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

	RollManager.updateRollMessageIcons(rMessage, aAddIcons);
	Comm.deliverChatMessage(rMessage);
end