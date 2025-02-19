-- Checks if the rewards for a specific part of an arc have been given already
-- if sStage is present, then vNode is considered to be the stage of an arc
-- if sStage is nil, then vNode is treated as a progress step node
function hasArcRewardAlreadyBeenGained(vNode, sStage)
	-- sStage is either "climax" or "resolution"
	if (sStage or "") ~= "" then
		return DB.getValue(DB.getPath(vNode, sStage, "rewardGained"), 0) == 1;
	end

	-- vNode is a progress step node, so we simply look in that node.
	return DB.getValue(vNode, "rewardGained", 0) == 1;
end

function hasArcAlreadyBeenPaidFor(arcNode)
	return DB.getValue(arcNode, "paid", 0) == 1;
end

function getCostToBuyNewCharacterArc(nodeChar)
	local nCost = OptionsManagerCypher.getXpCostToAddArc();
	
	-- Only the first character arc is free
	for _, node in ipairs(DB.getChildList(nodeChar, "characterarcs")) do
		if DB.getValue(node, "stage", 1) > 1 then
			return nCost;
		end
	end
	return 0;
end

function buyNewCharacterArc(nodeChar, nodeArc)
	if not nodeChar or not nodeArc then
		return false;
	end

	local nCost = CharArcManager.getCostToBuyNewCharacterArc(nodeChar);
	if CharArcManager.hasArcAlreadyBeenPaidFor(nodeArc) then
		CharArcManager.sendAlreadyPaidXpMessage()
		nCost = 0;
	end

	-- Check to see if character has enough XP
	local nXP = DB.getValue(nodeChar, "xp", 0);
	if nXP < nCost then
		local rMessage = {
			text = Interface.getString("char_message_not_enough_xp_for_arc"),
			font = "msgfont"
		};
		Comm.addChatMessage(rMessage);
		return false;
	end

	-- Deduct XP and set the stage of the arc to "progress"
	DB.setValue(nodeChar, "xp", "number", math.max(nXP - nCost, 0));
	DB.setValue(nodeArc, "stage", "number", 2);
	DB.setValue(nodeArc, "paid", "number", 1);
	
	-- Notify chat
	CharArcManager.sendCharacterArcMessage(nodeChar, "char_message_add_arc", nCost)
	return true;
end

function completeCharacterArcStep(nodeChar, nodeStep)
	local nReward = OptionsManagerCypher.getArcStepXpReward();
	CharArcManager.sendCharacterArcMessage(nodeChar, "char_message_arc_complete_step", nReward)

	if not CharArcManager.hasArcRewardAlreadyBeenGained(nodeStep) then
		local nXP = DB.getValue(nodeChar, "xp", 0);
		DB.setValue(nodeChar, "xp", "number", math.max(nXP + nReward, 0));
		DB.setValue(nodeStep, "rewardGained", "number", 1);
	else
		CharArcManager.sendAlreadyGainedXpMessage();
	end
	
	DB.setValue(nodeStep, "done", "number", 1);
end

function completeCharacterArcProgress(nodeChar, nodeArc)
	CharArcManager.sendCharacterArcMessage(nodeChar, "char_message_arc_complete_progress")
	DB.setValue(nodeArc, "stage", "number", 3);
end

function completeCharacterArcClimax(nodeChar, nodeArc, bSuccess)
	local nReward = 0;
	if bSuccess then
		nReward = OptionsManagerCypher.getArcClimaxSuccessXpReward();
		CharArcManager.sendCharacterArcMessage(nodeChar, "char_message_arc_climax_success", nReward)
		DB.setValue(nodeArc, "climax.done", "number", 1);
	else
		nReward = OptionsManagerCypher.getArcClimaxFailureXpReward();
		CharArcManager.sendCharacterArcMessage(nodeChar, "char_message_arc_climax_failure", nReward)
		DB.setValue(nodeArc, "climax.done", "number", 2);
	end

	if not CharArcManager.hasArcRewardAlreadyBeenGained(nodeArc, "climax") then
		local nXP = DB.getValue(nodeChar, "xp", 0);
		DB.setValue(nodeChar, "xp", "number", math.max(nXP + nReward, 0));
		DB.setValue(nodeArc, "climax.rewardGained", "number", 1);
	else
		CharArcManager.sendAlreadyGainedXpMessage();
	end

	DB.setValue(nodeArc, "stage", "number", 4);
end

function completeCharacterArcResolution(nodeChar, nodeArc, bSuccess)
	local nReward = 0;
	if bSuccess then
		nReward = OptionsManagerCypher.getArcResolutionXpReward();
		CharArcManager.sendCharacterArcMessage(nodeChar, "char_message_arc_resolution_success", nReward)
		DB.setValue(nodeArc, "resolution.done", "number", 1);
	else
		CharArcManager.sendCharacterArcMessage(nodeChar, "char_message_arc_resolution_failure", nReward)
		DB.setValue(nodeArc, "resolution.done", "number", 2);
	end

	if not CharArcManager.hasArcRewardAlreadyBeenGained(nodeArc, "resolution") then
		local nXP = DB.getValue(nodeChar, "xp", 0);
		DB.setValue(nodeChar, "xp", "number", math.max(nXP + nReward, 0));
		DB.setValue(nodeArc, "resolution.rewardGained", "number", 1);
	else
		CharArcManager.sendAlreadyGainedXpMessage();
	end
	
	DB.setValue(nodeArc, "stage", "number", 5);
end

function sendCharacterArcMessage(nodeChar, sMessageResource, nXp)
	local sName = DB.getValue(nodeChar, "name", "");
	if sName == "" then
		return;
	end

	local rMessage = {
		font = "msgfont"
	}
	if nXp then
		rMessage = {
			text = string.format(
				Interface.getString(sMessageResource), 
				sName, 
				nXp),
			font = "msgfont"
		};
	else
		rMessage = {
			text = string.format(
				Interface.getString(sMessageResource), 
				sName),
			font = "msgfont"
		};
	end

	Comm.deliverChatMessage(rMessage);
end

function sendAlreadyPaidXpMessage()
	local rMessage = {
		font = "msgfont",
		text = Interface.getString("char_message_arc_already_paid_for")
	};
	Comm.addChatMessage(rMessage);
end

function sendAlreadyGainedXpMessage()
	local rMessage = {
		font = "msgfont",
		text = Interface.getString("char_message_arc_xp_already_gained")
	};
	Comm.addChatMessage(rMessage);
end