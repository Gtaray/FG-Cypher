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

	-- We have to encode to string here because table
	-- values are stripped out of the rRoll table.
	RollManager.encodeTarget(rAction.rTarget, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	-- Rebuild roll data from a chat message in the case of drag/drop
	-- from the chat window. If we rebuild a roll from chat, we do not want to
	-- process any other modifiers
	if ActionStat.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	rTarget = RollManager.decodeTarget(rRoll, rTarget, true);
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
	rRoll.nConditionMod = RollManager.processStandardConditionsForActor(rSource);

	RollManager.encodeTraining(rRoll.sTraining, rRoll);
	RollManager.encodeEffort(rRoll.nEffort, rRoll);
	RollManager.encodeAssets(rRoll.nAssets, rRoll);
	RollManager.encodeEaseHindrance(rRoll, rRoll.nEase, rRoll.nHinder);

	-- We only need to encode the condition mods because all other effect handling
	-- is stored in the asset, ease, hinder, and effort tags
	-- Might want to consider adding a basic "EFFECTS" tag if there were effects that 
	-- modified assets, effort, ease, or hinder
	if rRoll.nConditionMod > 0 then
		rRoll.sDesc = string.format("%s [EFFECTS %s]", rRoll.sDesc, rRoll.nConditionMod)
	end
end

function onRoll(rSource, rTarget, rRoll)
	-- Hacky way to force the rebuilt flag to either be true or false, never an empty string
	rRoll.bRebuilt = (rRoll.bRebuilt == true) or (rRoll.bRebuilt or "") ~= "";
	rTarget = RollManager.decodeTarget(rRoll, rTarget);
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

	-- We need to process the roll result (success/failure) before printing
	-- anything to chat, because our messages require us to know if 
	-- the roll was an automatic success or not.
	rRoll.nDifficulty = RollManager.getBaseRollDifficulty(rSource, rTarget, { "stat", "stats", rRoll.sStat });
	RollManager.calculateDifficultyForRoll(rSource, rTarget, rRoll);

	local aAddIcons = {};
	local bAutomaticSuccess = rRoll.nDifficulty <= 0;

	-- Only assign these booleans if we have dice. If there are no dice, then the 
	-- rebuildRoll() function will assign these booleans
	if #(rRoll.aDice) == 1 then
		local nFirstDie = rRoll.aDice[1].result or 0;

		rRoll.bMajorEffect = not bAutomaticSuccess and nFirstDie == 20;
		rRoll.bMinorEffect = not bAutomaticSuccess and nFirstDie == 19;
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
	elseif rRoll.bGmIntrusion then
		if not rRoll.bRebuilt then
			rMessage.text = rMessage.text .. " [GM INTRUSION]";
		end
		table.insert(aAddIcons, "roll1");
	end

	RollManager.updateRollMessageIcons(rMessage, aAddIcons);
	Comm.deliverChatMessage(rMessage);

	ActionStat.applyRoll(rSource, rTarget, rRoll)
end

function applyRoll(rSource, rTarget, rRoll)
	local nTotal, bSuccess, bAutomaticSuccess = RollManager.processRollResult(rSource, rTarget, rRoll);
	local bPvP = ActorManager.isPC(rSource) and ActorManager.isPC(rTarget);
	local msgShort = { font = "msgfont", icon = "task" .. (rRoll.nDifficulty or 0) };
	local msgLong = { font = "msgfont", icon = "task" .. (rRoll.nDifficulty or 0) };

	msgShort.text = "[Stat";
	msgLong.text = "[Stat";

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

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
-- Returns boolean determining whether the roll was rebuilt from a chat message
function rebuildRoll(rSource, rTarget, rRoll)
	local bRebuilt = false;

	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[STAT.*%]([^%[]+)"));
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