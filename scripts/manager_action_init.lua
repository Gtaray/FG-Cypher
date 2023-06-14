-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYINIT = "applyinit";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYINIT, handleApplyInit);

	ActionsManager.registerModHandler("init", modRoll);
	ActionsManager.registerResultHandler("init", onRoll);
end

function performRoll(draginfo, rActor, rAction)
	local aFilter = { "initiative", "init", rAction.sStat};

	RollManager.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addWoundedToAction(rActor, rAction, "init");
	RollManager.addArmorCostToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rActor, rAction);
	RollManager.resolveMaximumEffort(rActor, rAction, aFilter);
	RollManager.resolveMaximumAssets(rActor, rAction, aFilter);
	RollManager.calculateBaseEffortCost(rActor, rAction);
	RollManager.adjustEffortCostWithEffects(rActor, rAction, aFilter);

	local bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);
	if bCanRoll then
		local rRoll = ActionInit.getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "init";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;
	rRoll.nDifficulty = rAction.nDifficulty or 0;
	rRoll.sDesc = string.format(
		"[INIT] %s", 
		StringManager.capitalize(rAction.sStat)
	);

	RollManager.encodeStat(rAction, rRoll);
	RollManager.encodeTraining(rAction, rRoll);
	RollManager.encodeAssets(rAction, rRoll);
	RollManager.encodeEdge(rAction, rRoll);
	RollManager.encodeEffort(rAction, rRoll);
	RollManager.encodeEaseHindrance(rRoll, (rAction.nEase or 0), (rAction.nHinder or 0));

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = RollManager.decodeStat(rRoll, false);
	local nAssets = RollManager.decodeAssets(rRoll, true);
	local nEffort = RollManager.decodeEffort(rRoll, true);
	local bInability, bTrained, bSpecialized = RollManager.decodeTraining(rRoll, true);

	-- Initiative rolls don't care about difficulty
	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, { "initiative", "init", sStat }, { sStat })
	nAssets = nAssets + nAssetMod;

	-- Adjust difficulty based on assets
	nAssets = nAssets + RollManager.processAssets(rSource, rTarget, { "initiative", "init", sStat }, nAssets);

	-- Adjust difficulty based on effort
	nEffort = nEffort + RollManager.processEffort(rSource, rTarget, { "initiative", "init", sStat }, nEffort);

	-- Get ease/hinder effects
	local nEase, nHinder = RollManager.resolveEaseHindrance(rSource, rTarget, rRoll, { "initiative", "init", sStat });

	-- Process conditions
	local nConditionEffects = RollManager.processStandardConditions(rSource, rTarget);

	-- Adjust difficulty based on training
	local nTrainingMod = RollManager.processTraining(bInability, bTrained, bSpecialized)

	rRoll.nDifficulty = rRoll.nDifficulty - nAssets - nEffort - nTrainingMod - nConditionEffects - nEase + nHinder;

	RollManager.encodeEffort(nEffort, rRoll);
	RollManager.encodeAssets(nAssets, rRoll);
	RollManager.encodeEaseHindrance(rRoll, nEase, nHinder);
	RollManager.encodeEffects(rRoll, nEffectMod);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

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

	-- Convert difficulty adjustments to their equivalent flat bonus
	RollManager.updateMessageWithConvertedTotal(rRoll, rMessage);

	local nTotal = ActionsManager.total(rRoll);

	Comm.deliverChatMessage(rMessage);
	notifyApplyInit(rSource, nTotal);
end

function notifyApplyInit(rSource, nTotal)
	if not rSource then
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYINIT;
	
	msgOOB.nTotal = nTotal;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end


function handleApplyInit(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	
	DB.setValue(ActorManager.getCTNode(rSource), "initresult", "number", nTotal);
end