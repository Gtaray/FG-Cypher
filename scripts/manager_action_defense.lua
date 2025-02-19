function onInit()
	ActionsManager.registerModHandler("defense", modRoll)
	ActionsManager.registerResultHandler("defense", onRoll);
end

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "defense";

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		PromptManager.closeDefensePromptWindow(rActor);
		ActionDefense.performRoll(draginfo, rActor, rAction);
	end
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionDefense.getRoll(rActor, rAction);
	RollManager.convertBooleansToNumbers(rRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "defense";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	rRoll.nMod = rAction.nModifier or 0;

	rRoll.sLabel = rAction.label;
	rRoll.sStat = rAction.sStat:lower();
	rRoll.sDesc = ActionDefense.getRollLabel(rActor, rAction, rRoll)
	rRoll.sAttackRange = rAction.sAttackRange;
	rRoll.sAttackStat = rAction.sAttackStat

	if rAction.bConverted then
		rRoll.sDesc = string.format("%s [CONVERTED]", rRoll.sDesc);
	end

	rRoll.nDifficulty = rAction.nDifficulty or 0;
	rRoll.nTraining = rAction.nTraining or 0;
	rRoll.nAssets = rAction.nAssets or 0;
	rRoll.nEffort = rAction.nEffort or 0;
	rRoll.nEase = rAction.nEase or 0;
	rRoll.nHinder = rAction.nHinder or 0;

	RollManager.encodeTarget(rAction.rTarget, rRoll);

	return rRoll;
end

function getRollLabel(rActor, rAction, rRoll)
	return string.format("[DEFENSE] %s", rRoll.sLabel);
end

function getEffectFilter(rRoll)
	return { "defense", "def", rRoll.sStat }
end

function modRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	if ActionDefense.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	rTarget = RollManager.decodeTarget(rRoll, rTarget, true);
	local aFilter = ActionDefense.getEffectFilter(rRoll);
	if (rRoll.sAttackRange or "") ~= "" then
		table.insert(aFilter, rRoll.sAttackRange:lower());
	end

	-- Process training effects
	RollManager.processTrainingEffects(rSource, rTarget, rRoll, aFilter);

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, aFilter, { rRoll.sStat })
	rRoll.nAssets = rRoll.nAssets + nAssetMod + RollManager.getAssetsFromDifficultyPanel();
	local nAssets, nMaxAssets = RollManager.processAssets(rSource, rTarget, aFilter, rRoll.nAssets);
	rRoll.nAssets = rRoll.nAssets + nAssets;

	-- Get the shield bonus of the defender
	local nShieldBonus = 0;
	if rRoll.sStat == "speed" then
		nShieldBonus = CharArmorManager.getShieldBonus(rSource);
	end
	rRoll.nAssets = math.min(rRoll.nAssets + nShieldBonus, nMaxAssets);

	-- Adjust difficulty based on effort
	rRoll.nEffort = rRoll.nEffort + RollManager.processEffort(rSource, rTarget, aFilter, rRoll.nEffort, rRoll.nMaxEffort);

	-- Get ease/hinder effects
	rRoll.nEase = rRoll.nEase + EffectManagerCypher.getEaseEffectBonus(rSource, aFilter, rTarget, { "attack", "atk", rRoll.sAttackStat });
	rRoll.nHinder = rRoll.nHinder + EffectManagerCypher.getHinderEffectBonus(rSource, aFilter, rTarget, { "attack", "atk", rRoll.sAttackStat });
	local nMiscAdjust = RollManager.getEaseHinderFromDifficultyPanel()
	if nMiscAdjust > 0 then
		rRoll.nEase = rRoll.nEase + nMiscAdjust
	elseif nMiscAdjust < 0 then
		rRoll.nHinder = rRoll.nHinder + math.abs(nMiscAdjust)
	end

	-- Process Lucky (advantage / disadvantage)
	local bAdv, bDis = RollManager.processAdvantage(rSource, rTarget, rRoll, aFilter)

	RollManager.encodeTraining(rRoll.nTraining, rRoll);
	RollManager.encodeEffort(rRoll.nEffort, rRoll);
	RollManager.encodeAssets(rRoll.nAssets, rRoll);
	RollManager.encodeEaseHindrance(rRoll, rRoll.nEase, rRoll.nHinder);
	RollManager.encodeAdvantage(rRoll, bAdv, bDis);

	if tonumber(rRoll.nDifficulty or "0") == 0 then
		rRoll.nDifficulty = RollManager.getBaseRollDifficulty(rSource, rTarget, { "attack", "atk", rRoll.sStat });
	end
	RollManager.calculateDifficultyForRoll(rSource, rTarget, rRoll);

	if (rRoll.nConditionMod or 0) > 0 then
		rRoll.sDesc = string.format("%s [EFFECTS %s]", rRoll.sDesc, rRoll.nConditionMod)
	end
	RollManager.convertBooleansToNumbers(rRoll);

	if rRoll.nDifficulty <= 0 then
		rRoll.aDice = {}
	end
end

function onRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	RollManager.decodeAdvantage(rRoll);
	
	-- Hacky way to force the rebuilt flag to either be true or false, never an empty string
	rRoll.bRebuilt = (rRoll.bRebuilt == true) or (rRoll.bRebuilt or "") ~= "";
	rTarget = RollManager.decodeTarget(rRoll, rTarget);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

	local aAddIcons = {};
	RollManager.processRollSpecialEffects(rRoll);
	RollManager.updateChatMessageWithSpecialEffects(rRoll, rMessage, aAddIcons);
	RollManager.updateRollMessageIcons(rMessage, aAddIcons);
	Comm.deliverChatMessage(rMessage);

	if rTarget or OptionsManagerCypher.isGlobalDifficultyEnabled() then
		ActionDefense.applyRoll(rSource, rTarget, rRoll)
	end

	RollHistoryManager.setLastRoll(rSource, rTarget, rRoll)
end

function applyRoll(rSource, rTarget, rRoll)
	local nTotal, bSuccess, bAutomaticSuccess = RollManager.processRollResult(rSource, rTarget, rRoll);
	local bPvP = ActorManager.isPC(rSource) and ActorManager.isPC(rTarget);

	if (rRoll.nDifficulty or 0) < 0 then
		rRoll.nDifficulty = 0
	end
	
	local msgShort = { 
		font = "msgfont", 
		icon = { "roll_attack", "task" .. (rRoll.nDifficulty or 0) } 
	};
	local msgLong = { 
		font = "msgfont", 
		icon = { "roll_attack", "task" .. (rRoll.nDifficulty or 0) } 
	};

	msgShort.text = string.format("[Defense]", rRoll.sStat);
	msgLong.text = string.format("[Defense]", rRoll.sStat);

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
		msgShort.text = string.format("%s [from %s]", msgShort.text, sTargetName);
		msgLong.text = string.format("%s [from %s]", msgLong.text, sTargetName);
	else
		msgShort.text = string.format("%s [vs global level]", msgShort.text);
		msgLong.text = string.format("%s [vs global level]", msgLong.text);
	end
	
	if bPvP then
		RollManager.updateMessageWithConvertedTotal(rRoll, msgShort);
		RollManager.updateMessageWithConvertedTotal(rRoll, msgLong);

	else
		if bSuccess then
			if bAutomaticSuccess then
				msgLong.text = string.format("%s [AUTOMATIC]", msgLong.text);
			else
				msgLong.text = string.format("%s %s", msgLong.text, getMissResultText());
			end

			if rRoll.bMajorEffect or rRoll.bMinorEffect then
				msgShort.icon[1] = "roll_attack_crit_miss";
				msgLong.icon[1] = "roll_attack_crit_miss";
			else
				msgShort.icon[1] = "roll_attack_miss";
				msgLong.icon[1] = "roll_attack_miss";
			end
		else
			msgLong.text = string.format("%s %s", msgLong.text, getHitResultText());

			if rRoll.bGmIntrusion then
				msgShort.icon[1] = "roll_attack_crit";
				msgLong.icon[1] = "roll_attack_crit";
			else
				msgShort.icon[1] = "roll_attack_hit";
				msgLong.icon[1] = "roll_attack_hit";
			end
		end
	end
	
	ActionsManager.outputResult(rRoll.bSecret, rSource, rTarget, msgLong, msgShort);
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
-- Returns boolean determining whether the roll was rebuilt from a chat message
function rebuildRoll(rSource, rTarget, rRoll)
	local bRebuilt = false;

	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[DEFENSE.*%]([^%[]+)"));
		bRebuilt = true;
	end
	if not rRoll.sStat then
		rRoll.sStat = RollManager.decodeStat(rRoll, true);
	end
	if not rRoll.nAssets then
		rRoll.nAssets = RollManager.decodeAssets(rRoll, true);
	end
	if not rRoll.nEffort then
		rRoll.nEffort = RollManager.decodeEffort(rRoll, true);
	end
	if not rRoll.nEase and not rRoll.nHinder then
		rRoll.nEase, rRoll.nHinder = RollManager.decodeEaseHindrance(rRoll, true)
	end
	if not rRoll.nConditionMod then
		rRoll.nConditionMod = RollManager.decodeConditionMod(rRoll, true);
	end
	if not rRoll.nTraining then
		rRoll.nTraining = RollManager.decodeTraining(rRoll, true);
	end
	if rRoll.bMajorEffect == nil then
		rRoll.bMajorEffect = rRoll.sDesc:match("%[MAJOR EFFECT%]") ~= nil;
	end
	if rRoll.bMinorEffect == nil then
		rRoll.bMinorEffect = rRoll.sDesc:match("%[MINOR EFFECT%]") ~= nil;
	end
	if rRoll.bGmIntrusion == nil then
		rRoll.bGmIntrusion = rRoll.sDesc:match("%[GM INTRUSION%]") ~= nil;
	end

	rRoll.bRebuilt = bRebuilt;
	return bRebuilt;
end

function getHitResultText()
	if OptionsManagerCypher.useHitMissInChat() then
		return "[HIT]"
	end
	return "[FAILED]"
end

function getMissResultText()
	if OptionsManagerCypher.useHitMissInChat() then
		return "[MISS]"
	end
	return "[SUCCESS]"
end