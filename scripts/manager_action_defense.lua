function onInit()
	ActionsManager.registerModHandler("defense", modRoll)
	ActionsManager.registerResultHandler("defense", onRoll);
end

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "defense";

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		ActionDefense.performRoll(draginfo, rActor, rAction);
	end
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionDefense.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "defense";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;

	rRoll.sLabel = rAction.label;
	rRoll.sStat = rAction.sStat:lower();
	rRoll.sDesc = string.format("[DEFENSE] %s", rRoll.sLabel);

	rRoll.nDifficulty = rAction.nDifficulty or 0;
	rRoll.sTraining = rAction.sTraining;
	rRoll.nAssets = rAction.nAssets or 0;
	rRoll.nEffort = rAction.nEffort or 0;
	rRoll.nEase = rAction.nEase or 0;
	rRoll.nHinder = rAction.nHinder or 0;

	RollManager.encodeTarget(rAction.rTarget, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	if ActionDefense.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	rTarget = RollManager.decodeTarget(rRoll, rTarget, true);
	local aFilter = { "defense", "def", rRoll.sStat };

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, aFilter, { rRoll.sStat })
	rRoll.nAssets = rRoll.nAssets + nAssetMod + RollManager.getAssetsFromDifficultyPanel();
	local nAssets, nMaxAssets = RollManager.processAssets(rSource, rTarget, aFilter, rRoll.nAssets);
	rRoll.nAssets = rRoll.nAssets + nAssets;

	-- Get the shield bonus of the defender
	local nShieldBonus = 0;
	if rRoll.sStat == "speed" then
		nShieldBonus = ActorManagerCypher.getShieldBonus(rSource);
	end
	rRoll.nAssets = math.min(rRoll.nAssets + nShieldBonus, nMaxAssets);

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

	if rRoll.nConditionMod > 0 then
		rRoll.sDesc = string.format("%s [EFFECTS %s]", rRoll.sDesc, rRoll.nConditionMod)
	end
end

function onRoll(rSource, rTarget, rRoll)
	rTarget = RollManager.decodeTarget(rRoll, rTarget);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

	-- Only set the difficulty if the difficulty hasn't already been set 
	-- Difficulty is set when a defense roll is invoked from a defensevs roll
	if rRoll.nDifficulty == 0 then
		rRoll.nDifficulty = RollManager.getBaseRollDifficulty(rSource, rTarget, { "attack", "atk", rRoll.sStat });
	end

	RollManager.calculateDifficultyForRoll(rSource, rTarget, rRoll);

	local aAddIcons = {};
	local bAutomaticSuccess = rRoll.nDifficulty <= 0;

	if #(rRoll.aDice) == 1 then
		local nFirstDie = rRoll.aDice[1].result or 0;
		
		rRoll.bMajorEffect = not bAutomaticSuccess and nFirstDie == 20;
		rRoll.bMinorEffect = not bAutomaticSuccess and nFirstDie == 19;
		rRoll.bGmIntrusion = not bAutomaticSuccess and nFirstDie == 1;
	end

	if rRoll.bMajorEffect then
		if rRoll.bRebuilt then
			rMessage.text = rMessage.text .. " [MAJOR EFFECT]";
		end
		table.insert(aAddIcons, "roll20");
	elseif rRoll.bMinorEffect then
		if rRoll.bRebuilt then
			rMessage.text = rMessage.text .. " [MINOR EFFECT]";
		end
		table.insert(aAddIcons, "roll19");
	elseif rRoll.bGmIntrusion then
		if rRoll.bRebuilt then
			rMessage.text = rMessage.text .. " [GM INTRUSION]";
		end
		table.insert(aAddIcons, "roll1");
	end

	RollManager.updateRollMessageIcons(rMessage, aAddIcons);
	Comm.deliverChatMessage(rMessage);

	ActionDefense.applyRoll(rSource, rTarget, rRoll)
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
				msgLong.text = string.format("%s [MISS]", msgLong.text);
			end

			if rRoll.bMajorEffect or rRoll.bMinorEffect then
				msgShort.icon[1] = "roll_attack_crit_miss";
				msgLong.icon[1] = "roll_attack_crit_miss";
			else
				msgShort.icon[1] = "roll_attack_miss";
				msgLong.icon[1] = "roll_attack_miss";
			end
		else
			msgLong.text = string.format("%s [HIT]", msgLong.text);

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
	if not rRoll.sTraining then
		rRoll.sTraining = RollManager.decodeTraining(rRoll, true);
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