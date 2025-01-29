ADVANCEMENT_COST = 4

function takeAbilityAdvancement(nodeChar)
	if not nodeChar then
		return false;
	end

	local rData = {
		nodeChar = nodeChar,
		sType = "stats",
		nFloatingStats = 4,
	};

	return CharAdvancementManager.takeAdvancement(nodeChar, "increase their stat pools", rData);
end

function takeEdgeAdvancement(nodeChar)
	if not nodeChar then
		return false;
	end

	local rData = {
		nodeChar = nodeChar,
		sType = "edge",
	};

	return CharAdvancementManager.takeAdvancement(nodeChar, "increase their edge", rData);
end

function takeEffortAdvancement(nodeChar)
	if not nodeChar then
		return false;
	end

	local rData = {
		nodeChar = nodeChar,
		sType = "effort",
	};

	return CharAdvancementManager.takeAdvancement(nodeChar, "increase their effort", rData);
end

function takeSkillAdvancement(nodeChar)
	if not nodeChar then
		return false;
	end

	local rData = {
		nodeChar = nodeChar,
		sType = "skill",
		bPlaceEmptySkill = true
	};

	return CharAdvancementManager.takeAdvancement(nodeChar, "gain training in a skill", rData);
end

function takeAdvancement(nodeChar, sMessage, rData)
	if not nodeChar then
		return false;
	end

	if not CharAdvancementManager.hasEnoughXpForAdvancement(nodeChar, ADVANCEMENT_COST) then
		return false;
	end

	-- TODO: Do this later
	-- if (sMessage or "") ~= "" then
	-- 	CharManager.sendAdvancementMessage(nodeChar, "char_message_advancement_taken", sMessage);
	-- end

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

	-- Check if all advancements have been taken, and if so, clear all the checkboxes
	-- and increment tier
	if CharAdvancementManager.checkForAllAdvancements(rData.nodeChar) then
		CharAdvancementManager.increaseTier(rData.nodeChar);
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

	CharAdvancementManager.sendAdvancementMessage(
		nodeChar, 
		"char_message_tier_increase", 
		tostring(nTier));

	CharAdvancementManager.modifyTier(nodeChar, 1);
	CharAdvancementManager.resetAdvancements(nodeChar, 1);
	CharAdvancementManager.promptAbilitiesForNextTier(nodeChar)
end

function promptAbilitiesForNextTier(nodeChar)
	local nTier = DB.getValue(nodeChar, "advancement.tier", 0);
	local _, sRecord = DB.getValue(nodeChar, "class.type.link", "");
	local typenode = DB.findNode(sRecord);

	local rData = { nodeChar = nodeChar, sSourceName = DB.getValue(nodeChar, "class.type", ""), nTier = nTier };
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

	local _, sRecord = DB.getValue(rData.nodeChar, "class.focus.link", "");
	local focusnode = DB.findNode(sRecord);

	-- This re-initializes the ability lists for the focus
	rData.sSourceName = DB.getValue(nodeChar, "class.focus", "");
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
function getTier(nodeChar)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return 0;
	end

	return DB.getValue(nodeChar, "advancement.tier", 1);
end
function setTier(nodeChar, nTier)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	DB.setValue(nodeChar, "advancement.tier", "number", nTier)
end
function modifyTier(nodeChar, nDelta)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	local nTier = CharAdvancementManager.getTier(nodeChar);
	nTier = nTier + nDelta;
	CharAdvancementManager.setTier(nodeChar, nTier);
end

function getExperience(nodeChar)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	return DB.getValue(nodeChar, "advancement.xp", 0);
end
function setExperience(nodeChar, nXP)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	DB.setValue(nodeChar, "advancement.xp", "number", nXP);
end
function modifyExperience(nodeChar, nDelta)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	local nXP = CharAdvancementManager.getExperience(nodeChar);
	nXP = nXP + nDelta;
	CharAdvancementManager.setExperience(nodeChar, nXP);
end

function hasTakenStatAdvancement(nodeChar)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	return DB.getValue(nodeChar, "advancement.stats", 0) == 1;
end
function hasTakenEdgeAdvancement(nodeChar)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	return DB.getValue(nodeChar, "advancement.edge", 0) == 1;
end
function hasTakenSkillAdvancement(nodeChar)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	return DB.getValue(nodeChar, "advancement.skill", 0) == 1;
end
function hasTakenEffortAdvancement(nodeChar)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	return DB.getValue(nodeChar, "advancement.effort", 0) == 1;
end
function resetAdvancements(nodeChar)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
		return;
	end
	DB.setValue(nodeChar, "advancement.stats", "number", 0);
	DB.setValue(nodeChar, "advancement.edge", "number", 0);
	DB.setValue(nodeChar, "advancement.effort", "number", 0);
	DB.setValue(nodeChar, "advancement.skill", "number", 0);
end

function getTotalExperienceGained(nodeChar)
	if not nodeChar or not ActorManager.isPC(nodeChar) then
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