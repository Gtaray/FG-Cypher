function onInit()
	ActionsManager.registerModHandler("stat", modRoll)
	ActionsManager.registerResultHandler("stat", onRoll);
end

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "stat";

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		ActionStat.performRoll(draginfo, rActor, rAction);
	end
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionStat.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "stat";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;

	rRoll.sLabel = rAction.label;
	rRoll.sStat = rAction.sStat;
	rRoll.sDesc = "[STAT"

	if (rRoll.sStat or "") ~= "" then
		local sStat = StringManager.capitalize(rRoll.sStat);

		-- This prevents double-writing the stat used to chat
		if rAction.label ~= sStat then
			rRoll.sDesc = string.format("%s (%s)", rRoll.sDesc, sStat);
		end
	end

	rRoll.sDesc = string.format("%s] %s", rRoll.sDesc, rRoll.sLabel or "");
	rRoll.nDifficulty = rAction.nDifficulty or 0;
	rRoll.sTraining = rAction.sTraining;
	rRoll.nAssets = rAction.nAssets or 0;
	rRoll.nEffort = rAction.nEffort or 0;
	rRoll.nEase = rAction.nEase or 0;
	rRoll.nHinder = rAction.nHinder or 0;

	-- RollManager.encodeTraining(rAction, rRoll);
	-- RollManager.encodeAssets(rAction, rRoll);
	-- RollManager.encodeEffort(rAction, rRoll);
	-- RollManager.encodeEaseHindrance(rRoll, (rAction.nEase or 0), (rAction.nHinder or 0));

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local aFilter = { "stat", "stats", rRoll.sStat }

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, aFilter, { rRoll.sStat })
	rRoll.nAssets = rRoll.nAssets + nAssetMod + RollManager.getAssetsFromDifficultyPanel();
	rRoll.nAssets = rRoll.nAssets + RollManager.processAssets(rSource, rTarget, aFilter, rRoll.nAssets);

	-- Adjust difficulty based on effort
	rRoll.nEffort = rRoll.nEffort + RollManager.processEffort(rSource, rTarget, aFilter, rRoll.nEffort, rRoll.nMaxEffort);

	-- Get ease/hinder effects
	rRoll.nEase = rRoll.nEase + EffectManagerCypher.getEffectsBonusByType(rSource, "EASE", aFilter, rTarget);
	if ModifierManager.getKey("EASE") then
		rRoll.nEase = rRoll.nEase + 1;
	end

	rRoll.nHinder = rRoll.nHinder + EffectManagerCypher.getEffectsBonusByType(rSource, "HINDER", aFilter, rTarget);
	if ModifierManager.getKey("HINDER") then
		rRoll.nHinder = rRoll.nHinder + 1;
	end

	-- Process conditions
	-- TODO: Refactor this so it only looks at a single actor. We only modify the source data
	-- here. Adjusting difficulty for target occurs later.
	rRoll.nConditionMod = RollManager.processStandardConditionsForActor(rSource);

	-- Roll up all the level/mod adjustments and apply them to the difficulty here
	-- TODO: Move this to the applyRoll() function. We're only collecting
	-- modifiers here
	--rRoll.nDifficulty = rRoll.nDifficulty - nAssets - nEffort - nTrainingMod - nConditionEffects - nEase + nHinder;

	RollManager.encodeTraining(rRoll.sTraining, rRoll);
	RollManager.encodeEffort(rRoll.nEffort, rRoll);
	RollManager.encodeAssets(rRoll.nAssets, rRoll);
	RollManager.encodeEaseHindrance(rRoll, rRoll.nEase, rRoll.nHinder);

	-- TODO: go back to more explicitly defined effect mods
	-- to support rebuilding the roll when dragging from the chat window
	if nEffectMod > 0 or rRoll.nConditionMod > 0 then
		rRoll.sDesc = string.format("%s [EFFECTS]", rRoll.sDesc)
	end
end

function onRoll(rSource, rTarget, rRoll)
	-- TODO: Rebuild detail fields if dragging from chat window

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

	-- We need to process the roll result (success/failure) before printing
	-- anything to chat, because our messages require us to know if 
	-- the roll was an automatic success or not.
	rRoll.nDifficulty = RollManager.getBaseRollDifficulty(rSource, rTarget, { "stat", "stats", rRoll.sStat });
	RollManager.calculateDifficultyForRoll(rSource, rTarget, rRoll);

	local aAddIcons = {};
	local nFirstDie = rRoll.aDice[1].result or 0;
	local bAutomaticSuccess = rRoll.nDifficulty <= 0;

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

	ActionStat.applyRoll(rSource, rTarget, rRoll)
end

function applyRoll(rSource, rTarget, rRoll)
	local aAddIcons = {};
	local nTotal, bSuccess, bAutomaticSuccess = RollManager.processRollResult(rSource, rTarget, rRoll, rMessage, aAddIcons);
	local bPvP = ActorManager.isPC(rSource) and ActorManager.isPC(rTarget);
	local msgShort = { font = "msgfont", icon = "task" .. (rRoll.nDifficulty or 0) };
	local msgLong = { font = "msgfont", icon = "task" .. (rRoll.nDifficulty or 0) };

	msgShort.text = "[Stat";
	msgLong.text = "[Stat";

	if (rRoll.sLabel or ""):lower() ~= (rRoll.sStat or ""):lower() then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sStat);
		msgLong.text = string.format("%s (%s)", msgShort.text, rRoll.sStat);
	end

	msgShort.text = string.format("%s]", msgShort.text);
	msgLong.text = string.format("%s]", msgLong.text);

	if (rRoll.sLabel or "") ~= "" then
		msgShort.text = string.format("%s %s", msgShort.text, rRoll.sLabel or "");
		msgLong.text = string.format("%s %s", msgLong.text, rRoll.sLabel or "");
	end
	msgLong.text = string.format("%s [%d]", msgLong.text, nTotal or 0);

	-- Targeting information
	msgShort.text = string.format("%s ->", msgShort.text);
	msgLong.text = string.format("%s ->", msgLong.text);
	if rTarget then
		local sTargetName = ActorManager.getDisplayName(rTarget);
		msgShort.text = string.format("%s [at %s]", msgShort.text, sTargetName);
		msgLong.text = string.format("%s [at %s]", msgLong.text, sTargetName);
	else
		msgShort.text = string.format("%s [at global level]", msgShort.text);
		msgLong.text = string.format("%s [at global level]", msgLong.text);
	end

	-- Add icons for difficulty

	if bPvP then
		RollManager.updateMessageWithConvertedTotal(rRoll, msgShort);
		RollManager.updateMessageWithConvertedTotal(rRoll, msgLong);
		
	else
		if bAutomaticSuccess then
			msgLong.text = string.format("%s [AUTOMATIC]", msgLong.text);
		elseif bSuccess then
			msgLong.text = string.format("%s [SUCCESS]", msgLong.text);
		else
			msgLong.text = string.format("%s [FAILED]", msgLong.text);
		end
	end

	ActionsManager.outputResult(rRoll.bSecret, rSource, rTarget, msgLong, msgShort);
end