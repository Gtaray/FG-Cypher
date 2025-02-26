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
	ChatManager.SystemMessageResource("char_message_add_ability", rAdd.sSourceName, rAdd.sCharName);

    -- Add ability (via the character modification system)	
	local rPromptData = CharModManager.addModificationToChar(nodeChar, {
		sProperty = "ability",
		sLinkRecord = DB.getPath(rAdd.nodeSource),
		sLinkClass = "ability",
		sSource = "Manual"
	});

	if (rPromptData.nFloatingStats or 0) > 0 or #(rPromptData.aEdgeOptions or {}) > 0 then
		-- Prompt player for the data
		rPromptData.nodeSource = rAdd.nodeSource;
		rPromptData.sSourceName = rAdd.sSourceName;
		rPromptData.sSourceType = rAdd.sSourceType;
		rPromptData.sSourceClass = rAdd.sSourceClass;
		rPromptData.nodeChar = rAdd.nodeChar;
		rPromptData.sCharName = rAdd.sCharName;
		rPromptData.nMight = CharStatManager.getStatPool(rAdd.nodeChar, "might");
		rPromptData.nSpeed = CharStatManager.getStatPool(rAdd.nodeChar, "speed");
		rPromptData.nIntellect = CharStatManager.getStatPool(rAdd.nodeChar, "intellect");
		rPromptData.sSource = string.format("%s (%s)", 
			StringManager.capitalize(rPromptData.sSourceName), 
			StringManager.capitalize(rPromptData.sSourceType))

		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rPromptData, CharModManager.applyFloatingStatsAndEdge);
	end
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
	local nTraining = DB.getValue(nodeAction, "training", 1);
	if nTraining == 2 then
		return;
	end

	nTraining = TrainingManager.modifyTraining(nTraining, 1);

	DB.setValue(nodeAction, "training", "number", nTraining);
end

function addAbility(nodeChar, sAbilityRecord, sSourceName, sSourceType, rPromptData)
	local rActor = ActorManager.resolveActor(nodeChar);

	local rMod = {
		sLinkRecord = sAbilityRecord,
		sSource = string.format("%s (%s)", 
			StringManager.capitalize(sSourceName), 
			StringManager.capitalize(sSourceType))
	}
	rMod.sSummary = CharModManager.getAbilityModSummary(rMod)

	local nodeAbility = DB.findNode(sAbilityRecord);
	if nodeAbility then
		return CharModManager.applyAbilityModification(rActor, rMod, rPromptData);
	end
end