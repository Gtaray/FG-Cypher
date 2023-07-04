-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("attack", modRoll);
	ActionsManager.registerResultHandler("attack", onRoll);
end

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "attack";

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		ActionAttack.performRoll(draginfo, rActor, rAction);
	end
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "attack";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;

	rRoll.sLabel = rAction.label;
	rRoll.sStat = rAction.sStat:lower();
	rRoll.sDefenseStat = rAction.sDefenseStat:lower();
	rRoll.sAttackRange = rAction.sAttackRange;

	rRoll.sDesc = string.format("[ATTACK (%s", StringManager.capitalize(rRoll.sStat));
	if (rAction.sAttackRange or "") ~= "" then
		rRoll.sDesc = string.format("%s, %s", rRoll.sDesc, rAction.sAttackRange)
	end
	rRoll.sDesc = string.format(
		"%s)] %s vs %s", 
		rRoll.sDesc, 
		rRoll.sLabel,
		StringManager.capitalize(rRoll.sDefenseStat)
	);

	rRoll.nDifficulty = rAction.nDifficulty or 0;
	rRoll.sTraining = rAction.sTraining;
	rRoll.nAssets = rAction.nAssets or 0;
	rRoll.nEffort = rAction.nEffort or 0;
	rRoll.nEase = rAction.nEase or 0;
	rRoll.nHinder = rAction.nHinder or 0;
	rRoll.bLightWeapon = rAction.sWeaponType == "light";
	
	RollManager.encodeTarget(rAction.rTarget, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	if ActionAttack.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	rTarget = RollManager.decodeTarget(rRoll, rTarget, true);
	local aFilter = { "attack", "atk", rRoll.sStat };

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
	rRoll.nConditionMod = RollManager.processStandardConditionsForActor(rSource);

	RollManager.encodeTraining(rRoll.sTraining, rRoll);
	RollManager.encodeEffort(rRoll.nEffort, rRoll);
	RollManager.encodeAssets(rRoll.nAssets, rRoll);
	RollManager.encodeEaseHindrance(rRoll, rRoll.nEase, rRoll.nHinder);

	if rRoll.bLightWeapon then
		rRoll.sDesc = string.format("%s [LIGHT]", rRoll.sDesc)
	end
	if rRoll.nConditionMod > 0 then
		rRoll.sDesc = string.format("%s [EFFECTS %s]", rRoll.sDesc, rRoll.nConditionMod)
	end
end

function onRoll(rSource, rTarget, rRoll)
	-- Hacky way to force the rebuilt flag to either be true or false, never an empty string
	rRoll.bRebuilt = (rRoll.bRebuilt == true) or (rRoll.bRebuilt or "") ~= "";
	rTarget = RollManager.decodeTarget(rRoll, rTarget);
	rRoll.bLightWeapon = rRoll.sDesc:match("%[LIGHT%]") ~= nil;

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_attack";

	rRoll.nDifficulty = RollManager.getBaseRollDifficulty(rSource, rTarget, { "defense", "def", rRoll.sDefenseStat });
	RollManager.calculateDifficultyForRoll(rSource, rTarget, rRoll);

	local aAddIcons = {};
	local bAutomaticSuccess = rRoll.nDifficulty <= 0;

	if #(rRoll.aDice) == 1 then
		local nFirstDie = rRoll.aDice[1].result or 0;
		
		rRoll.bMajorEffect = not bAutomaticSuccess and nFirstDie == 20;
		rRoll.bMinorEffect = not bAutomaticSuccess and nFirstDie == 19;
		rRoll.bRolled18 = not bAutomaticSuccess and nFirstDie == 18;
		rRoll.bRolled17 = not bAutomaticSuccess and nFirstDie == 17;
		rRoll.bGmIntrusion = not bAutomaticSuccess and nFirstDie == 1;
	end

	if rRoll.bMajorEffect then
		if not rRoll.bRebuilt then
			rMessage.text = rMessage.text .. " [MAJOR EFFECT]";
		end
		table.insert(aAddIcons, "roll20");
	elseif rRoll.bMinorEffect then
		if not rRoll.bRebuilt then
			rMessage.text = rMessage.text .. " [MINOR EFFECT]";
		end
		table.insert(aAddIcons, "roll19");
	elseif rRoll.bRolled18 then
		if not rRoll.bRebuilt then
			rMessage.text = rMessage.text .. " [DAMAGE +2]";
		end
		table.insert(aAddIcons, "roll18");
	elseif rRoll.bRolled17 then
		if not rRoll.bRebuilt then
			rMessage.text = rMessage.text .. " [DAMAGE +1]";
		end
		table.insert(aAddIcons, "roll17");
	elseif rRoll.bGmIntrusion then
		if not rRoll.bRebuilt then
			rMessage.text = rMessage.text .. " [GM INTRUSION]";
		end
		table.insert(aAddIcons, "roll1");
	end

	RollManager.updateRollMessageIcons(rMessage, aAddIcons);
	Comm.deliverChatMessage(rMessage);

	ActionAttack.applyRoll(rSource, rTarget, rRoll);
end

function applyRoll(rSource, rTarget, rRoll)
	local nTotal, bSuccess, bAutomaticSuccess = RollManager.processRollResult(rSource, rTarget, rRoll);
	local bPvP = ActorManager.isPC(rSource) and ActorManager.isPC(rTarget);
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
				msgLong.text = string.format("%s [HIT]", msgLong.text);
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
			msgLong.text = string.format("%s [MISS]", msgLong.text);

			if rRoll.bGmIntrusion then
				msgShort.icon[1] = "roll_attack_crit_miss";
				msgLong.icon[1] = "roll_attack_crit_miss";
			else
				msgShort.icon[1] = "roll_attack_miss";
				msgLong.icon[1] = "roll_attack_miss";
			end
		end
	end
	
	ActionsManager.outputResult(rRoll.bSecret, rSource, rTarget, msgLong, msgShort);

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
	if not rRoll.sTraining then
		rRoll.sTraining = RollManager.decodeTraining(rRoll, true);
	end
	if rRoll.bLightWeapon == nil then
		rRoll.bLightWeapon = rRoll.sDesc:match("%[LIGHT%]") ~= nil;
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