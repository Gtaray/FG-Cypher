-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addAbilityDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

    -- if for some reason we don't have a source node, then bail
    if not rAdd.nodeSource then
        return;
    end

	-- Notification
	CharManager.outputUserMessage("char_message_add_ability", rAdd.sSourceName, rAdd.sCharName);

    -- Add ability (via the character modification system)
	CharModManager.addModificationToChar(nodeChar, {
		sProperty = "ability",
		sLinkRecord = DB.getPath(rAdd.nodeSource),
		sLinkClass = "ability",
		sSource = "Manual"
	});
end

function addTrainingToAbility(nodeChar, nodeAbility)
	for _, actionnode in ipairs(DB.getChildList(nodeAbility, "actions")) do
		-- Only include abilities with stat or attack actions
		local sType = DB.getValue(actionnode, "type", "");

		if sType == "attack" or sType == "stat" then
			CharAbilityManager.addTrainingToAbilityAction(actionnode)
		end
	end
end

function addTrainingToAbilityAction(nodeAction)
	sTraining = DB.getValue(nodeAction, "training", "");
	if sTraining == "specialized" then
		return;
	end

	local nTraining = RollManager.convertTrainingStringToNumber(sTraining) + 1;
	nTraining = math.max(math.min(nTraining, 3), 0);
	sTraining = RollManager.resolveTraining(nTraining)

	DB.setValue(nodeAction, "training", "string", sTraining);
end