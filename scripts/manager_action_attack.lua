-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	--ActionsManager.registerModHandler("attack", modRoll);
	ActionsManager.registerResultHandler("attack", onRoll);
end

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "attack";

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		ActionAttack.performRoll(draginfo, rActor, rAction);
		return true;
	end

	return false;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(rActor, rAction);
	RollManager.convertBooleansToNumbers(rRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "attack";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	rRoll.nMod = rAction.nModifier or 0;

	rRoll.sLabel = rAction.label;
	rRoll.sStat = rAction.sStat:lower();
	rRoll.sDefenseStat = rAction.sDefenseStat:lower();
	rRoll.sAttackRange = rAction.sAttackRange;

	rRoll.sDesc = ActionAttack.getRollLabel(rActor, rAction, rRoll)

	rRoll.nDifficulty = rAction.nDifficulty or 0;
	rRoll.nTraining = rAction.nTraining;
	rRoll.nAssets = rAction.nAssets or 0;
	rRoll.nEffort = rAction.nEffort or 0;
	rRoll.nEase = rAction.nEase or 0;
	rRoll.nHinder = rAction.nHinder or 0;
	rRoll.sWeaponType = rAction.sWeaponType;

	rRoll.nDamageEffort = rAction.nDamageEffort or 0
	
	RollManager.encodeTarget(rAction.rTarget, rRoll);

	return rRoll;
end

function getRollLabel(rActor, rAction, rRoll)
	local sLabel = string.format("[ATTACK (%s", StringManager.capitalize(rRoll.sStat));

	if (rAction.sAttackRange or "") ~= "" then
		sLabel = string.format("%s, %s", sLabel, rRoll.sAttackRange)
	end
	sLabel = string.format(
		"%s)] %s vs %s", 
		sLabel, 
		rRoll.sLabel,
		StringManager.capitalize(rRoll.sDefenseStat)
	);

	return sLabel
end

function getEffectFilter(rRoll)
	return { "attack", "atk", rRoll.sStat }
end

function modRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	if ActionAttack.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	-- If there's not already a target, then we try to decode one
	rTarget = RollManager.decodeTarget(rRoll, rTarget, true);
	local aFilter = ActionAttack.getEffectFilter(rRoll)
	if (rRoll.sAttackRange or "") ~= "" then
		table.insert(aFilter, rRoll.sAttackRange:lower());
	end
	if (rRoll.sWeaponType or "") ~= "" then
		table.insert(aFilter, rRoll.sWeaponType:lower());
	end

	-- Process training effects
	RollManager.processTrainingEffects(rSource, rTarget, rRoll, aFilter);

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, aFilter, { rRoll.sStat })
	rRoll.nAssets = rRoll.nAssets + nAssetMod + RollManager.getAssetsFromDifficultyPanel();
	rRoll.nAssets = rRoll.nAssets + RollManager.processAssets(rSource, rTarget, aFilter, rRoll.nAssets);

	-- Adjust difficulty based on effort
	rRoll.nEffort = rRoll.nEffort + RollManager.processEffort(rSource, rTarget, aFilter, rRoll.nEffort, rRoll.nMaxEffort);

	-- Get ease/hinder effects
	rRoll.nEase = rRoll.nEase + EffectManagerCypher.getEaseEffectBonus(rSource, aFilter, rTarget, { "defense", "def", rRoll.sDefenseStat });
	rRoll.nHinder = rRoll.nHinder + EffectManagerCypher.getHinderEffectBonus(rSource, aFilter, rTarget, { "defense", "def", rRoll.sDefenseStat });
	local nMiscAdjust = RollManager.getEaseHinderFromDifficultyPanel()
	if nMiscAdjust > 0 then
		rRoll.nEase = rRoll.nEase + nMiscAdjust
	elseif nMiscAdjust < 0 then
		rRoll.nHinder = rRoll.nHinder + nMiscAdjust
	end

	-- Process Lucky (advantage / disadvantage)
	local bAdv, bDis = RollManager.processAdvantage(rSource, rTarget, rRoll, aFilter)

	RollManager.encodeTraining(rRoll.nTraining, rRoll);
	RollManager.encodeEffort(rRoll.nEffort, rRoll);
	RollManager.encodeAssets(rRoll.nAssets, rRoll);
	RollManager.encodeEaseHindrance(rRoll, rRoll.nEase, rRoll.nHinder);
	RollManager.encodeAdvantage(rRoll, bAdv, bDis);

	if tonumber(rRoll.nDifficulty or "0") == 0 then
		rRoll.nDifficulty = RollManager.getBaseRollDifficulty(rSource, rTarget, { "defense", "def", rRoll.sDefenseStat });
	end
	RollManager.calculateDifficultyForRoll(rSource, rTarget, rRoll);

	if rRoll.sWeaponType == "light" then
		rRoll.sDesc = string.format("%s [LIGHT]", rRoll.sDesc)
	end
	if (rRoll.nConditionMod or 0) > 0 then
		rRoll.sDesc = string.format("%s [EFFECTS %s]", rRoll.sDesc, rRoll.nConditionMod)
	end
	RollManager.convertBooleansToNumbers(rRoll);

	if rRoll.nDifficulty <= 0 then
		rRoll.aDice = {}
	end
end

function onRoll(rSource, rTarget, rRoll)
	-- modRoll is not called by the actions manager, and is instead called manually here
	-- this is because when an action's sTargeting is set to 'all', modRoll doesn't have
	-- rTarget populated yet. But it is populated here. So instead of having it be
	-- done automatically, we just manually call the method here
	ActionAttack.modRoll(rSource, rTarget, rRoll);

	RollManager.convertNumbersToBooleans(rRoll);
	RollManager.decodeAdvantage(rRoll);
	rRoll.bMulti = RollManager.decodeMultiTarget(rRoll);

	-- Hacky way to force the rebuilt flag to either be true or false, never an empty string
	rRoll.bRebuilt = (rRoll.bRebuilt == true) or (rRoll.bRebuilt or "") ~= "";
	rRoll.bLightWeapon = (rRoll.bLightWeapon == "true") or (rRoll.bLightWeapon == "light");
	rTarget = RollManager.decodeTarget(rRoll, rTarget);
	rRoll.bLightWeapon = rRoll.sDesc:match("%[LIGHT%]") ~= nil;

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_attack";

	local aAddIcons = {};
	RollManager.processRollSpecialEffects(rRoll, true);
	RollManager.updateChatMessageWithSpecialEffects(rRoll, rMessage, aAddIcons);
	RollManager.updateRollMessageIcons(rMessage, aAddIcons);
	Comm.deliverChatMessage(rMessage);

	if rTarget or OptionsManagerCypher.isGlobalDifficultyEnabled() then
		ActionAttack.applyRoll(rSource, rTarget, rRoll);
	end

	RollHistoryManager.setLastRoll(rSource, rTarget, rRoll)

	-- Only save the attack effort if the option to split attack and damage
	-- effort costs is enabled. Otherwise costs are handled up front.
	if OptionsManagerCypher.splitAttackAndDamageEffort() then
		RollHistoryManager.setAttackEffort(rSource, rTarget, rRoll)
	end

	-- Might be a better way to do this, but we only update the modifier stack if
	-- it's empty. This way we don't add this value for every target.
	if ModifierStack.isEmpty() then
		if rRoll.bRolled17 then
			ModifierStack.addSlot("", 1)
		end
		if rRoll.bRolled18 then
			ModifierStack.addSlot("", 2)
		end
	end

	-- If this attack had damage effort set for it, then update the desktop panel
	rRoll.nDamageEffort = tonumber(rRoll.nDamageEffort) or 0
	if rRoll.nDamageEffort > 0 then
		RollManager.disableCost()
		RollManager.setDifficultyPanelEffort(rRoll.nDamageEffort)

		if rRoll.bMulti then
			RollManager.enableMultiTarget();
		end
	end
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

	msgShort.text = "[Attack";
	msgLong.text = "[Attack";

	if (rRoll.sLabel or ""):lower() ~= (rRoll.sStat or ""):lower() then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sStat);
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sStat);
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
		msgLong.text = string.format("%s [at %s (%s)]", msgLong.text, sTargetName, rRoll.sDefenseStat);
	else
		msgShort.text = string.format("%s [at global level]", msgShort.text);
		msgLong.text = string.format("%s [at global level]", msgLong.text);
	end
	
	if bPvP then
		RollManager.updateMessageWithConvertedTotal(rRoll, msgShort);
		RollManager.updateMessageWithConvertedTotal(rRoll, msgLong);

	else
		if bSuccess then
			if bAutomaticSuccess then
				msgLong.text = string.format("%s [AUTOMATIC]", msgLong.text);
			else
				msgLong.text = string.format("%s %s", msgLong.text, getHitResultText());
			end

			if rRoll.bMajorEffect or rRoll.bMinorEffect or
			   rRoll.bRolled18 or rRoll.bRolled17 then
				
				msgShort.icon[1] = "roll_attack_crit";
				msgLong.icon[1] = "roll_attack_crit";
			else
				msgShort.icon[1] = "roll_attack_hit";
				msgLong.icon[1] = "roll_attack_hit";
			end
		else
			msgLong.text = string.format("%s %s", msgLong.text, getMissResultText());

			if rRoll.bGmIntrusion then
				
				msgShort.icon[1] = "roll_attack_crit_miss";
				msgLong.icon[1] = "roll_attack_crit_miss";
			else
				msgShort.icon[1] = "roll_attack_miss";
				msgLong.icon[1] = "roll_attack_miss";
			end
		end
	end

	if rRoll.bMinorEffect then
		PromptManager.promptForMinorEffectOnAttack(rSource)
	elseif rRoll.bMajorEffect then
		PromptManager.promptForMajorEffectOnAttack(rSource)
	end
	
	ActionsManager.outputResult(rRoll.bSecret, rSource, rTarget, msgLong, msgShort);

	if not bSuccess and rRoll.bMulti then
		TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
	end

	-- for PC vs PC rolls, prompt a defense roll
	if bPvP then
		local rDefense = {};
		rDefense.nDifficulty = nSuccesses;
		rDefense.sStat = RollManager.resolveStat(rRoll.sDefenseStat, "speed"); -- default to Speed defense if for some reason the stat is missing
		rDefense.rTarget = rSource;

		-- Attempt to prompt the target to defend
		-- if there's no one controlling the defending PC, then automatically roll defense
		if Session.IsHost then
			local bPrompt = PromptManager.promptDefenseRoll(rSource, rTarget, rDefense);

			if not bPrompt then
				ActionDefense.payCostAndRoll(nil, rTarget, rDefense);
			end
		else
			PromptManager.initiateDefensePrompt(rSource, rTarget, rDefense);
		end
	end
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
-- Returns boolean determining whether the roll was rebuilt from a chat message
function rebuildRoll(rSource, rTarget, rRoll)
	local bRebuilt = false;

	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[ATTACK.*%]([^%[]+)"));
		bRebuilt = true;
	end
	if not rRoll.sStat then
		rRoll.sStat = RollManager.decodeStat(rRoll, true);
	end
	if not rRoll.sDefenseStat then
		rRoll.sDefenseStat = StringManager.trim(rRoll.sDesc:match("%[ATTACK.-%][^%[]+ vs ([^]%s]*)") or "");
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
	if rRoll.sWeaponType == nil and rRoll.sDesc:match("%[LIGHT%]") ~= nil then
		rRoll.sWeaponType = "light";
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
	return "[SUCCESS]"
end

function getMissResultText()
	if OptionsManagerCypher.useHitMissInChat() then
		return "[MISS]"
	end
	return "[FAILED]"
end