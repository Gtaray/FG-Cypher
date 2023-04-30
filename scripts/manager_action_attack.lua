-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("attack", modRoll);
	ActionsManager.registerResultHandler("attack", onRoll);
end

function performRoll(draginfo, rActor, rAction)
	local aFilter = { "attack", "atk", rAction.sStat };

	RollManager.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addWoundedToAction(rActor, rAction, aFilter);
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
	end
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "attack";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;
	rRoll.sDesc = string.format("[ATTACK (%s)] %s", rAction.sAttackRange, rAction.label);
	rRoll.nDifficulty = rAction.nDifficulty or 0;

	RollManager.encodeStat(rAction, rRoll);
	RollManager.encodeDefenseStat(rAction, rRoll);
	RollManager.encodeTraining(rAction, rRoll);
	RollManager.encodeAssets(rAction, rRoll);
	RollManager.encodeEdge(rAction, rRoll);
	RollManager.encodeEffort(rAction, rRoll);
	-- RollManager.encodeCost(rAction, rRoll); -- Might not need this as nothing cares about cost after initiating the roll
	RollManager.encodeWeaponType(rAction, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local bPersist = rTarget == nil;
	local sStat = RollManager.decodeStat(rRoll, bPersist);
	local sDefenseStat = RollManager.decodeDefenseStat(rRoll, true); -- We need this in the onRoll handler, so it's always persisted.
	local nAssets = RollManager.decodeAssets(rRoll, true);
	local nEffort = RollManager.decodeEffort(rRoll, true);
	local bInability, bTrained, bSpecialized = RollManager.decodeTraining(rRoll, true);
	local sWeaponType = RollManager.decodeWeaponType(rRoll, false); -- Don't persist

	if rTarget and not ActorManager.isPC(rTarget) then
		rRoll.nDifficulty = ActorManagerCypher.getCreatureLevel(rTarget, rSource, { "defense", "def", sDefenseStat });
	end

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, { "attack", "atk" }, { sStat })
	nAssets = nAssets + nAssetMod;

	-- Adjust difficulty based on assets
	nAssets = nAssets + RollManager.processAssets(rSource, rTarget, { "attack", "atk", sStat }, nAssets);

	-- Adjust difficulty based on effort
	nEffort = nEffort + RollManager.processEffort(rSource, rTarget, sStat, { "attack", "atk", sStat }, nEffort);

	-- Get ease/hinder effects
	local bEase, bHinder = RollManager.resolveEaseHindrance(rSource, rTarget, { "attack", "atk", sStat });

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
	local bPersist = rTarget == nil;
	local sDefenseStat = RollManager.decodeDefenseStat(rRoll, bPersist);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_attack";

	if rTarget then
		rMessage.icon = "roll_attack";
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
	end
	
	local aAddIcons = {};
	local nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		nFirstDie = rRoll.aDice[1].result or 0;
	end
	if nFirstDie >= 20 then
		rMessage.text = rMessage.text .. " [DAMAGE +4 OR MAJOR EFFECT]";
		table.insert(aAddIcons, "roll20");
	elseif nFirstDie == 19 then
		rMessage.text = rMessage.text .. " [DAMAGE +3 OR MINOR EFFECT]";
		table.insert(aAddIcons, "roll19");
	elseif nFirstDie == 18 then
		rMessage.text = rMessage.text .. " [DAMAGE +2]";
		table.insert(aAddIcons, "roll18");
	elseif nFirstDie == 17 then
		rMessage.text = rMessage.text .. " [DAMAGE +1]";
		table.insert(aAddIcons, "roll17");
	elseif nFirstDie == 1 then
		rMessage.text = rMessage.text .. " [GM INTRUSION]";
		table.insert(aAddIcons, "roll1");
	end
	
	-- Only process roll successes if a PC is attacking an NPC (not PC vs PC)
	local bSuccess, bAutomaticSuccess = RollManagerCPP.processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons);
	if rTarget and not ActorManager.isPC(rTarget) then
		local sIcon = "";
		if bSuccess then
			if bAutomaticSuccess then
				rMessage.text = rMessage.text .. " [AUTOMATIC HIT]";
			else
				rMessage.text = rMessage.text .. " [HIT]";
			end
			if nFirstDie >= 17 then
				sIcon = "roll_attack_crit";
			else
				sIcon = "roll_attack_hit";
			end
		else
			rMessage.text = rMessage.text .. " [MISS]";

			if nFirstDie == 1 then
				sIcon = "roll_attack_crit_miss";
			else
				sIcon = "roll_attack_miss";
			end
		end

		-- If we have multiple icons, replace the first.
		if type(rMessage.icon) == "table" then
			rMessage.icon[1] = sIcon
		else
			rMessage.icon = sIcon;
		end
	end
	
	Comm.deliverChatMessage(rMessage);

	-- for PC vs PC rolls, prompt a defense roll
	if ActorManager.isPC(rSource) and rTarget and ActorManager.isPC(rTarget) then
		
		local rDefense = {};
		rDefense.nDifficulty = nTotal;
		rDefense.sStat = RollManager.resolveStat(sDefenseStat, "speed"); -- default to Speed defense if for some reason the stat is missing
		rDefense.rTarget = rSource;

		-- Attempt to prompt the target to defend
		-- if there's no one controlling the defending PC, then automatically roll defense
		if Session.IsHost then
			local bPrompt = PromptManager.promptDefenseRoll(rSource, rTarget, rDefense);

			if not bPrompt then
				ActionDefense.performRoll(nil, rTarget, rDefense);
			end
		else
			PromptManager.initiateDefensePrompt(rSource, rTarget, rDefense);
		end
	end
end
