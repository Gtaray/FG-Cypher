OOB_MSG_TYPE_INITIATEDEFPRMOPT = "initiatedefprompt";
OOB_MSGTYPE_PROMPTDEFENSE = "promptdefense";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSG_TYPE_INITIATEDEFPRMOPT, handleInitiateDefensePrompt);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_PROMPTDEFENSE, handlePromptDefenseRoll);
end

function getUser(rPlayer)
	for _,sIdentity in pairs(User.getAllActiveIdentities()) do
		local sName = User.getIdentityLabel(sIdentity);
		if sName == rPlayer.sName then
			return User.getIdentityOwner(sIdentity)
		end
	end
end

function doesUserOwnIdentity(rPlayer)
	return Session.UserName == getUser(rPlayer)
end

-------------------------------------------------------------------------------
-- DEFENSE PROMPT
-------------------------------------------------------------------------------

-- This is used when a PC is prompted to make a defense roll
-- Since we only want to close the window if the roll was completed
function closeDefensePromptWindow(rSource)
	if not DB.isOwner(ActorManager.getCreatureNodeName(rSource)) then
		return;
	end

	for _, w in ipairs(Interface.getWindows("prompt_defense")) do
		w.close();
	end
end

-- We need a double OOB here so that the GM is the one sending out the 
-- defense prompt OOB
function initiateDefensePrompt(rSource, rPlayer, rResult)
	local msgOOB = {};
	msgOOB.type = OOB_MSG_TYPE_INITIATEDEFPRMOPT;
	msgOOB.sAttackerNode = ActorManager.getCTNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCTNodeName(rPlayer);
	msgOOB.nDifficulty = rResult.nDifficulty;
	msgOOB.sStat = rResult.sStat
	msgOOB.sAttackRange = rResult.sAttackRange;

	Comm.deliverOOBMessage(msgOOB);
end

function handleInitiateDefensePrompt(msgOOB)
	if not Session.IsHost then
		return;
	end

	local rPlayer = ActorManager.resolveActor(msgOOB.sTargetNode);
	local rTarget = ActorManager.resolveActor(msgOOb.sAttackerNode);

	-- Gets the username of the player who owns rPlayer
	local sUser = getUser(rPlayer);
	-- if there's no user, then auto-roll
	if sUser == nil then
		local rAction = getActionFromOobMsg(rPlayer, rTarget, msgOOB);
		ActionDefense.payCostAndRoll(nil, rPlayer, rAction);
	end

	-- Change the type and forward the OOB msg
	msgOOB.type = OOB_MSGTYPE_PROMPTDEFENSE;
	Comm.deliverOOBMessage(msgOOB, sUser)
end

function promptDefenseRoll(rSource, rPlayer, rResult)
	-- Gets the username of the player who owns rPlayer
	local sUser = getUser(rPlayer);

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_PROMPTDEFENSE;
	msgOOB.sAttackerNode = ActorManager.getCTNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCTNodeName(rPlayer);
	msgOOB.nDifficulty = rResult.nDifficulty;
	msgOOB.sStat = rResult.sStat
	msgOOB.sAttackRange = rResult.sAttackRange;

	Comm.deliverOOBMessage(msgOOB, sUser);
	return true;
end

function handlePromptDefenseRoll(msgOOB)
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	local rSource = ActorManager.resolveActor(msgOOB.sAttackerNode);
	local rAction = getActionFromOobMsg(rTarget, rSource, msgOOB);

	local window = Interface.openWindow("prompt_defense", "")
	local aStats = { rAction.sStat }
	if window then
		-- Check to see if the actor has a CONVERT effect that lets them convert
		-- one defense roll into another
		local aConvert = EffectManagerCypher.getConversionEffect(rTarget, rAction.sStat, { "defense", "def" });
		for _, sConvert in ipairs(aConvert) do
			if sConvert ~= rAction.sStat then
				table.insert(aStats, sConvert);
			end
		end

		window.setData(rTarget, rAction, aStats);
	else
		ActionDefense.payCostAndRoll(nil, rTarget, rAction);
	end
end

function getActionFromOobMsg(rSource, rTarget, msgOOB)
	local rAction = {};
	rAction.nDifficulty = tonumber(msgOOB.nDifficulty) or 0;
	rAction.sStat = msgOOB.sStat;
	rAction.rTarget = rTarget
	rAction.nTraining, rAction.nAssets, rAction.nModifier = CharStatManager.getDefense(rSource, rAction.sStat)
	rAction.label = StringManager.capitalize(rAction.sStat);
	rAction.sAttackRange = msgOOB.sAttackRange or "";

	return rAction
end

-------------------------------------------------------------------------------
-- PLAYER INTRUSION PROMPT
-------------------------------------------------------------------------------
function promptPlayerIntrusion(nodeChar)
	local window = Interface.openWindow("prompt_pc_intrusion", "")
	if window then
		window.setData(nodeChar);
	end
end

-------------------------------------------------------------------------------
-- CHARACTER ARCS
-------------------------------------------------------------------------------
function promptCharacterArcStart(nodeArc)
	local nodeChar = DB.getChild(nodeArc, "...");
	local nCost = CharArcManager.getCostToBuyNewCharacterArc(nodeChar);

	-- If the arc is free, just add it
	if nCost == 0 then
		return true;
	end

	local data = {
		nodeChar = nodeChar,
		nodeArc = nodeArc,
		sTitleRes = "arc_start_prompt_window_title",
		sText = string.format(Interface.getString("arc_start_prompt_text"), nCost),
		fnCallback = PromptManager.handleStartCharacterArcPromptResult
	}

	local window = Interface.openWindow("dialog_yesno", nodeArc);
	if window then
		window.setData(data)

		-- Don't want to progress any further, so we terminate the stack here
		return false;
	end

	-- Failed to prompt somehow? Just give them the arc
	return true;
end
function handleStartCharacterArcPromptResult(sResult, tData)
	if sResult == "ok" then
		CharArcManager.buyNewCharacterArc(tData.nodeChar, tData.nodeArc);
	end
end

function promptCharacterArcStep(nodeStep)
	local nXp = OptionsManagerCypher.getArcStepXpReward();

	-- If the reward is nothing, then just give it to them.
	if nXp == 0 then
		return true;
	end
	
	local nodeArc = DB.getChild(nodeStep, "...");
	local nodeChar = DB.getChild(nodeArc, "...");
	local data = {
		nodeChar = nodeChar,
		nodeArc = nodeArc,
		nodeStep = nodeStep,
		sTitleRes = "arc_step_prompt_window_title",
		sText = string.format(Interface.getString("arc_step_prompt_text"), nXp),
		fnCallback = PromptManager.handleCharacterArcStepPromptResult
	}

	local window = Interface.openWindow("dialog_yesno", nodeArc);
	if window then
		window.setData(data)
		return false;
	end
	return true;
end
function handleCharacterArcStepPromptResult(sResult, tData)
	if sResult == "ok" then
		CharArcManager.completeCharacterArcStep(tData.nodeChar, tData.nodeStep);
	end
end

function promptCharacterArcProgress(nodeArc)
	local nodeChar = DB.getChild(nodeArc, "...");
	local data = {
		nodeChar = nodeChar,
		nodeArc = nodeArc,
		sTitleRes = "arc_progress_prompt_window_title",
		sTextRes = "arc_progress_prompt_text",
		fnCallback = PromptManager.handleProgressCharacterArcPromptResult
	}

	local window = Interface.openWindow("dialog_yesno", nodeArc);
	if window then
		window.setData(data)

		-- Don't want to progress any further, so we terminate the stack here
		return false;
	end
	return true;
end
function handleProgressCharacterArcPromptResult(sResult, tData)
	if sResult == "ok" then
		CharArcManager.completeCharacterArcProgress(tData.nodeChar, tData.nodeArc);
	end
end

function promptCharacterArcClimax(nodeArc)
	local nodeChar = DB.getChild(nodeArc, "...");
	local data = {
		nodeChar = nodeChar,
		nodeArc = nodeArc,
		sTitleRes = "arc_climax_prompt_window_title",
		sTextRes = "arc_climax_prompt_text",
		fnCallback = PromptManager.handleCharacterArcClimaxPromptResult
	}

	local window = Interface.openWindow("dialog_yesno", nodeArc);
	if window then
		window.setData(data)

		-- Don't want to progress any further, so we terminate the stack here
		return false;
	end
	return true;
end
function handleCharacterArcClimaxPromptResult(sResult, tData)
	if sResult == "cancel" then
		CharArcManager.completeCharacterArcClimax(tData.nodeChar, tData.nodeArc, false);
	elseif sResult == "ok" then
		CharArcManager.completeCharacterArcClimax(tData.nodeChar, tData.nodeArc, true);
	end
end

function promptCharacterArcResolution(nodeArc)
	local nodeChar = DB.getChild(nodeArc, "...");
	local data = {
		nodeChar = nodeChar,
		nodeArc = nodeArc,
		sTitleRes = "arc_resolution_prompt_window_title",
		sTextRes = "arc_resolution_prompt_text",
		fnCallback = PromptManager.handleCharacterArcResolutionPromptResult
	}

	local window = Interface.openWindow("dialog_yesno", nodeArc);
	if window then
		window.setData(data)

		-- Don't want to progress any further, so we terminate the stack here
		return false;
	end
	return true;
end
function handleCharacterArcResolutionPromptResult(sResult, tData)
	if sResult == "cancel" then
		CharArcManager.completeCharacterArcResolution(tData.nodeChar, tData.nodeArc, false);
	elseif sResult == "ok" then
		CharArcManager.completeCharacterArcResolution(tData.nodeChar, tData.nodeArc, true);
	end
end