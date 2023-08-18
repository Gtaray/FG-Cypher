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

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "init";

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		ActionInit.performRoll(draginfo, rActor, rAction);
	end
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionInit.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "init";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;

	rRoll.sLabel = rAction.label;
	rRoll.sStat = (rAction.sStat or ""):lower();
	rRoll.sDesc = string.format(
		"[INIT] %s", 
		StringManager.capitalize(rRoll.sStat)
	);

	rRoll.nDifficulty = rAction.nDifficulty or 0;
	rRoll.sTraining = rAction.sTraining;
	rRoll.nAssets = rAction.nAssets or 0;
	rRoll.nEffort = rAction.nEffort or 0;
	rRoll.nEase = rAction.nEase or 0;
	rRoll.nHinder = rAction.nHinder or 0;

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local aFilter = { "initiative", "init", rRoll.sStat }

	-- Process training effects
	RollManager.processTrainingEffects(rSource, rTarget, rRoll, aFilter);

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAssetMod, nEffectMod = RollManager.processFlatModifiers(rSource, rTarget, rRoll, aFilter, { rRoll.sStat })
	rRoll.nAssets = rRoll.nAssets + nAssetMod + RollManager.getAssetsFromDifficultyPanel();
	rRoll.nAssets = rRoll.nAssets + RollManager.processAssets(rSource, rTarget, aFilter, rRoll.nAssets);

	-- Adjust difficulty based on effort
	rRoll.nEffort = rRoll.nEffort + RollManager.processEffort(rSource, rTarget, aFilter, rRoll.nEffort, rRoll.nMaxEffort);

	-- Get ease/hinder effects
	rRoll.nEase = rRoll.nEase + EffectManagerCypher.getEaseEffectBonus(rSource, aFilter, rTarget);
	if ModifierManager.getKey("EASE") then
		rRoll.nEase = rRoll.nEase + 1;
	end

	rRoll.nHinder = rRoll.nHinder + EffectManagerCypher.getHinderEffectBonus(rSource, aFilter, rTarget);
	if ModifierManager.getKey("HINDER") then
		rRoll.nHinder = rRoll.nHinder + 1;
	end

	-- Process conditions
	rRoll.nConditionMod = RollManager.processStandardConditionsForActor(rSource);

	-- Process Lucky (advantage / disadvantage)
	local bAdv, bDis = RollManager.processAdvantage(rSource, rTarget, rRoll, aFilter)

	RollManager.encodeTraining(rRoll.sTraining, rRoll);
	RollManager.encodeEffort(rRoll.nEffort, rRoll);
	RollManager.encodeAssets(rRoll.nAssets, rRoll);
	RollManager.encodeEaseHindrance(rRoll, rRoll.nEase, rRoll.nHinder);
	RollManager.encodeAdvantage(rRoll, bAdv, bDis);

	-- We only need to encode the condition mods because all other effect handling
	-- is stored in the asset, ease, hinder, and effort tags
	-- Might want to consider adding a basic "EFFECTS" tag if there were effects that 
	-- modified assets, effort, ease, or hinder
	if rRoll.nConditionMod > 0 then
		rRoll.sDesc = string.format("%s [EFFECTS %s]", rRoll.sDesc, rRoll.nConditionMod)
	end
	RollManager.convertBooleansToNumbers(rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	RollManager.decodeAdvantage(rRoll);

	-- Hacky way to force the rebuilt flag to either be true or false, never an empty string
	rRoll.bRebuilt = (rRoll.bRebuilt == true) or (rRoll.bRebuilt or "") ~= "";
	RollManager.calculateDifficultyForRoll(rSource, rTarget, rRoll)

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local aAddIcons = {};

	rMessage.icon = "action_roll";

	if #(rRoll.aDice) == 1 then
		local nFirstDie = rRoll.aDice[1].result or 0;
		
		rRoll.bMajorEffect = nFirstDie == 20;
		rRoll.bMinorEffect = nFirstDie == 19;
		rRoll.bGmIntrusion = nFirstDie == 1;
	end

	if rRoll.bMajorEffect then
		rMessage.text = rMessage.text .. " [MAJOR EFFECT]";
		table.insert(aAddIcons, "roll20");
	elseif rRoll.bMinorEffect then
		rMessage.text = rMessage.text .. " [MINOR EFFECT]";
		table.insert(aAddIcons, "roll19");
	elseif rRoll.bGmIntrusion then
		rMessage.text = rMessage.text .. " [GM INTRUSION]";
		table.insert(aAddIcons, "roll1");
	end

	-- Convert difficulty adjustments to their equivalent flat bonus
	RollManager.updateMessageWithConvertedTotal(rRoll, rMessage);
	RollManager.updateRollMessageIcons(rMessage, aAddIcons);

	Comm.deliverChatMessage(rMessage);
	notifyApplyInit(rSource, ActionsManager.total(rRoll));
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