ADVANCEMENT_COST = 4

function takeAdvancement(nodeChar, sMessage, rData)
	if not nodeChar then
		return false;
	end

	if not CharAdvancementManager.hasEnoughXpForAdvancement(nodeChar, ADVANCEMENT_COST) then
		return false;
	end

	local w = Interface.openWindow("select_dialog_advancement", "");
	w.setData(rData, CharAdvancementManager.completeAdvancement);

	return true;
end

function hasEnoughXpForAdvancement(nodeChar, nCost)
	local nXP = CharAdvancementManager.getExperience(nodeChar);

	if nXP < nCost then
		local rMessage = {
			text = Interface.getString("char_message_not_enough_xp"),
			font = "msgfont"
		};
		Comm.addChatMessage(rMessage);
		return false;
	end
	return true;
end

function deductXpForAdvancement(nodeChar, nCost)
	local nXP = CharAdvancementManager.getExperience(nodeChar);

	if nXP < nCost then
		return false;
	end

	CharAdvancementManager.modifyExperience(nodeChar, -nCost);
	return true;
end

function completeAdvancement(rData)
	-- This should not be possible, but if for some reason we get here and the char doesn't have the XP for the advancement, bail
	if not CharAdvancementManager.deductXpForAdvancement(rData.nodeChar, ADVANCEMENT_COST) then
		return
	end
	
	local rActor = ActorManager.resolveActor(rData.nodeChar);
	rData.sSource = "Advancement"

	if rData.sType == "stats" then
		CharModManager.applyFloatingStatsAndEdge(rData);
		
	elseif rData.sType == "edge" then
		for sStat, nEdge in pairs(rData.aEdgeGiven) do
			if nEdge > 0 then
				local rEdge = { sStat = sStat, nMod = nEdge, sSource = rData.sSource };
				rEdge.sSummary = CharModManager.getEdgeModSummary(rEdge);
				CharModManager.applyEdgeModification(rActor, rEdge)
			end
		end

	elseif rData.sType == "effort" then
		rData.sSummary = CharModManager.getEffortModSummary(rData)
		CharModManager.applyEffortModification(rActor, rData);

	elseif rData.sType == "skill" then
		if rData.sSkill then
			rData.sSummary = CharModManager.getSkillModSummary(rData)
			CharModManager.applySkillModification(rActor, rData)
		elseif rData.sAbility then
			CharAbilityManager.addTrainingToAbility(rData.nodeChar, rData.abilitynode)
		end

	elseif rData.sType == "ability" or rData.sType == "focus" then
		for _, rAbility in ipairs(rData.aAbilitiesGiven) do
			CharAbilityManager.addAbility(
				rData.nodeChar, 
				rAbility.sRecord, 
				"Advancement",
				rAbility.sSourceType)
		end

	elseif rData.sType == "recovery" then
		rData.sSummary = CharModManager.getRecoveryModSummary(rData);
		CharModManager.applyRecoveryModification(rActor, rData)

	elseif rData.sType == "armor" then
		rData.sSummary = CharModManager.getArmorEffortPenaltySummary(rData);
		CharModManager.applyArmorEffortPenaltyModification(rActor, rData)
	end

	if rData.sAdvancement == "stats" then
		CharAdvancementManager.takeStatAdvancement(rData.nodeChar);
	elseif rData.sAdvancement == "edge" then
		CharAdvancementManager.takeEdgeAdvancement(rData.nodeChar);
	elseif rData.sAdvancement == "effort" then
		CharAdvancementManager.takeEffortAdvancement(rData.nodeChar);
	elseif rData.sAdvancement == "skill" then
		CharAdvancementManager.takeSkillAdvancement(rData.nodeChar);
	end

	if (rData.sMessage or "") ~= "" then
		CharAdvancementManager.sendAdvancementMessage(rData.nodeChar, "char_message_advancement_taken", rData.sMessage);
	end
end

function sendAdvancementMessage(nodeChar, sMessageResource, sMessage)
	local sName = DB.getValue(nodeChar, "name", "");
	if sName == "" then
		return;
	end

	local sSender = "";
	if not Session.IsHost then
		sSender = User.getCurrentIdentity();
	end

	local rMessage = {
		text = string.format(
			Interface.getString(
				sMessageResource), 
				sName, 
				sMessage),
		font = "msgfont"
	};

	Comm.deliverChatMessage(rMessage);
end

function checkForAllAdvancements(nodeChar)
	return hasTakenStatAdvancement(nodeChar) and 
		hasTakenEdgeAdvancement(nodeChar) and
		hasTakenEffortAdvancement(nodeChar) and
		hasTakenSkillAdvancement(nodeChar);
end

function increaseTier(nodeChar)
	local nTier = CharAdvancementManager.getTier(nodeChar);

	CharAdvancementManager.modifyTier(nodeChar, 1);
	CharAdvancementManager.resetAdvancements(nodeChar, 1);
	CharAdvancementManager.promptAbilitiesForNextTier(nodeChar);

	CharAdvancementManager.sendAdvancementMessage(
		nodeChar, 
		"char_message_tier_increase", 
		tostring(nTier + 1));
end

function promptAbilitiesForNextTier(nodeChar)
	local nTier = CharAdvancementManager.getTier(nodeChar);
	local typenode = CharTypeManager.getTypeNode(nodeChar);

	local rData = { nodeChar = nodeChar, sSourceName = CharTypeManager.getTypeName(nodeChar), nTier = nTier };
	CharTypeManager.buildAbilityPromptTable(nodeChar, typenode, nTier, rData);

	if #(rData.aAbilityOptions) > 0 then
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rData, CharAdvancementManager.applyTypeAbilitiesAndPromptFocusAbilities);
		return;
	end

	CharAdvancementManager.applyTypeAbilitiesAndPromptFocusAbilities(rData);
end

function applyTypeAbilitiesAndPromptFocusAbilities(rData)
	CharTypeManager.applyTier(rData);

	local focusnode = CharFocusManager.getFocusNode(rData.nodeChar);

	-- This re-initializes the ability lists for the focus
	rData.sSourceName = CharFocusManager.getFocusName(rData.nodeChar);
	CharFocusManager.buildAbilityPromptTable(rData.nodeChar, focusnode, rData.nTier, rData);
	if #(rData.aAbilityOptions) > 0 then
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rData, CharManager.applyFocusAbilities);
		return true; -- Return true to keep the window open
	end

	CharAdvancementManager.applyFocusAbilities(rData);
end

function applyFocusAbilities(rData)
	CharFocusManager.addAbilities(rData);
end

-----------------------------------------------------------
-- SETTERS / GETTERS
-----------------------------------------------------------
function getTier(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 1;
	end

	return DB.getValue(nodeChar, "advancement.tier", 1);
end
function setTier(rActor, nTier)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "advancement.tier", "number", nTier)
end
function modifyTier(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nTier = CharAdvancementManager.getTier(nodeChar);
	nTier = nTier + nDelta;
	CharAdvancementManager.setTier(nodeChar, nTier);
end

function getExperience(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	return DB.getValue(nodeChar, "advancement.xp", 0);
end
function setExperience(rActor, nXP)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "advancement.xp", "number", nXP);
end
function modifyExperience(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nXP = CharAdvancementManager.getExperience(nodeChar);
	nXP = nXP + nDelta;
	CharAdvancementManager.setExperience(nodeChar, nXP);
end

function hasTakenStatAdvancement(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	return DB.getValue(nodeChar, "advancement.stats", 0) == 1;
end
function takeStatAdvancement(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "advancement.stats", "number", 1);
end

function hasTakenEdgeAdvancement(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	return DB.getValue(nodeChar, "advancement.edge", 0) == 1;
end
function takeEdgeAdvancement(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "advancement.edge", "number", 1);
end

function hasTakenSkillAdvancement(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	return DB.getValue(nodeChar, "advancement.skill", 0) == 1;
end
function takeSkillAdvancement(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "advancement.skill", "number", 1);
end

function hasTakenEffortAdvancement(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end
	
	return DB.getValue(nodeChar, "advancement.effort", 0) == 1;
end
function takeEffortAdvancement(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "advancement.effort", "number", 1);
end

function resetAdvancements(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "advancement.stats", "number", 0);
	DB.setValue(nodeChar, "advancement.edge", "number", 0);
	DB.setValue(nodeChar, "advancement.effort", "number", 0);
	DB.setValue(nodeChar, "advancement.skill", "number", 0);
end

function getTotalExperienceGained(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nTier = CharAdvancementManager.getTier();
	local nExp = CharAdvancementManager.getExperience();
	if CharAdvancementManager.hasTakenStatAdvancement(nodeChar) then
		nExp = nExp + 4;
	end
	if CharAdvancementManager.hasTakenEdgeAdvancement(nodeChar) then
		nExp = nExp + 4;
	end
	if CharAdvancementManager.hasTakenSkillAdvancement(nodeChar) then
		nExp = nExp + 4;
	end
	if CharAdvancementManager.hasTakenEffortAdvancement(nodeChar) then
		nExp = nExp + 4;
	end

	return ((nTier - 1) * 16) + nExp
end