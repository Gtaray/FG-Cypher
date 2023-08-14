-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManager.setCustomCharAdd(onCharItemAdd);
	-- Overriding char_invitem.onDelete instead of this, because this throws errors
	-- ItemManager.setCustomCharRemove(onCharItemRemoved);
end

function outputUserMessage(sResource, ...)
	local sFormat = Interface.getString(sResource);
	local sMsg = string.format(sFormat, ...);
	ChatManager.SystemMessage(sMsg);
end

-------------------------------------------------------------------------------
-- Character sheet drops
-------------------------------------------------------------------------------
function addInfoDB(nodeChar, sClass, sRecord)
	-- Validate parameters
	if not nodeChar then
		return false;
	end
	
	if sClass == "ability" then
		CharAbilityManager.addAbilityDrop(nodeChar, sClass, sRecord);
	elseif sClass == "type" then
		CharTypeManager.addTypeDrop(nodeChar, sClass, sRecord);
	elseif sClass == "descriptor" then
		CharDescriptorManager.addDescriptorDrop(nodeChar, sClass, sRecord);
	elseif sClass == "focus" then
		CharFocusManager.addFocusDrop(nodeChar, sClass, sRecord);
	elseif sClass == "ancestry" then
		CharAncestryManager.addAncestryDrop(nodeChar, sClass, sRecord);
	elseif sClass ==  "flavor" then
		CharFlavorManager.addFlavorDrop(nodeChar, sClass, sRecord);
	else
		return false;
	end
	
	return true;
end

function helperBuildAddStructure(nodeChar, sClass, sRecord)
	if not nodeChar or ((sClass or "") == "") or ((sRecord or "") == "") then
		return nil;
	end

	local rAdd = { };
	rAdd.nodeSource = DB.findNode(sRecord);
	if not rAdd.nodeSource then
		return nil;
	end

	rAdd.sSourceClass = sClass;
	rAdd.sSourceName = StringManager.trim(DB.getValue(rAdd.nodeSource, "name", ""));
	rAdd.nodeChar = nodeChar;
	rAdd.sCharName = StringManager.trim(DB.getValue(nodeChar, "name", ""));

	rAdd.sSourceType = StringManager.simplify(rAdd.sSourceName);
	if rAdd.sSourceType == "" then
		rAdd.sSourceType = DB.getName(rAdd.nodeSource);
	end

	return rAdd;
end

-------------------------------------------------------------------------------
-- ADVANCEMENTS
-------------------------------------------------------------------------------
function takeAbilityAdvancement(nodeChar)
	if not nodeChar then
		return false;
	end

	local rData = {
		nodeChar = nodeChar,
		sType = "stats",
		nFloatingStats = 4,
	};

	return CharManager.takeAdvancement(nodeChar, "increase their stat pools", rData);
end

function takeEdgeAdvancement(nodeChar)
	if not nodeChar then
		return false;
	end

	local rData = {
		nodeChar = nodeChar,
		sType = "edge",
	};

	return CharManager.takeAdvancement(nodeChar, "increase their edge", rData);
end

function takeEffortAdvancement(nodeChar)
	if not nodeChar then
		return false;
	end

	local rData = {
		nodeChar = nodeChar,
		sType = "effort",
	};

	return CharManager.takeAdvancement(nodeChar, "increase their effort", rData);
end

function takeSkillAdvancement(nodeChar)
	if not nodeChar then
		return false;
	end

	local rData = {
		nodeChar = nodeChar,
		sType = "skill",
	};

	return CharManager.takeAdvancement(nodeChar, "gain training in a skill", rData);
end

function takeAdvancement(nodeChar, sMessage, rData)
	if not nodeChar then
		return false;
	end

	if not CharManager.deductXpForAdvancement(nodeChar, 4) then
		return false;
	end

	if (sMessage or "") ~= "" then
		CharManager.sendAdvancementMessage(nodeChar, "char_message_advancement_taken", sMessage);
	end

	local w = Interface.openWindow("select_dialog_advancement", "");
	w.setData(rData, CharManager.completeAdvancement);

	return true;
end

function deductXpForAdvancement(nodeChar, nCost)
	local nXP = DB.getValue(nodeChar, "xp", 0);

	if nXP < nCost then
		local rMessage = {
			text = Interface.getString("char_message_not_enough_xp"),
			font = "msgfont"
		};
		Comm.addChatMessage(rMessage);
		return false;
	end

	DB.setValue(nodeChar, "xp", "number", math.max(nXP - nCost, 0));
	return true;
end

function completeAdvancement(rData)
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
	if CharManager.checkForAllAdvancements(rData.nodeChar) then
		CharManager.increaseTier(rData.nodeChar);
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
	local bAbilities = DB.getValue(nodeChar, "advancement.abilities", 0) == 1;
	local bEdge = DB.getValue(nodeChar, "advancement.edge", 0) == 1;
	local bEffort = DB.getValue(nodeChar, "advancement.effort", 0) == 1;
	local bSkill = DB.getValue(nodeChar, "advancement.skill", 0) == 1;

	return bAbilities and bEdge and bEffort and bSkill;
end

function increaseTier(nodeChar)
	local nTier = DB.getValue(nodeChar, "tier", 0);
	nTier = nTier + 1;

	CharManager.sendAdvancementMessage(
		nodeChar, 
		"char_message_tier_increase", 
		tostring(nTier));

	DB.setValue(nodeChar, "tier", "number", nTier);
	DB.setValue(nodeChar, "advancement.abilities", "number", 0);
	DB.setValue(nodeChar, "advancement.edge", "number", 0);
	DB.setValue(nodeChar, "advancement.effort", "number", 0);
	DB.setValue(nodeChar, "advancement.skill", "number", 0);

	CharManager.promptAbilitiesForNextTier(nodeChar)
end

function promptAbilitiesForNextTier(nodeChar)
	local nTier = DB.getValue(nodeChar, "tier", 0);
	local _, sRecord = DB.getValue(nodeChar, "class.typelink", "");
	local typenode = DB.findNode(sRecord);

	local rData = { nodeChar = nodeChar, sSourceName = DB.getValue(nodeChar, "class.type", ""), nTier = nTier };
	CharTypeManager.buildAbilityPromptTable(nodeChar, typenode, nTier, rData);

	if #(rData.aAbilityOptions) > 0 then
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rData, CharManager.applyTypeAbilitiesAndPromptFocusAbilities);
		return;
	end

	CharManager.applyTypeAbilitiesAndPromptFocusAbilities(rData);
end

function applyTypeAbilitiesAndPromptFocusAbilities(rData)
	CharTypeManager.applyTier(rData);

	local _, sRecord = DB.getValue(rData.nodeChar, "class.focuslink", "");
	local focusnode = DB.findNode(sRecord);

	-- This re-initializes the ability lists for the focus
	rData.sSourceName = DB.getValue(nodeChar, "class.focus", "");
	CharFocusManager.buildAbilityPromptTable(rData.nodeChar, focusnode, rData.nTier, rData);
	if #(rData.aAbilityOptions) > 0 then
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rData, CharManager.applyFocusAbilities);
		return true; -- Return true to keep the window open
	end

	CharManager.applyFocusAbilities(rData);
end

function applyFocusAbilities(rData)
	CharFocusManager.addAbilities(rData);
end

-------------------------------------------------------------------------------
-- ITEM MANAGEMENT
-------------------------------------------------------------------------------
function onCharItemAdd(nodeItem)
	if ItemManagerCypher.isItemWeapon(nodeItem) then
		CharManager.addItemAsWeapon(nodeItem);
	end

	-- If the item being added to the PC's inventory has actions, create
	-- an entry in the ability list for it
	if DB.getChildCount(nodeItem, "actions") > 0 then
		CharManager.addItemAsAbility(nodeItem)
	end
end

function onCharItemRemoved(nodeItem)
	CharManager.removeAbilityLinkedToRecord(nodeItem);
	CharManager.removeAttackLinkedToRecord(nodeItem);
end

-- Adds a item (that is a weapon) to the character's attacklist
function addItemAsWeapon(itemnode)
	-- Parameter validation
	if not ItemManagerCypher.isItemWeapon(itemnode) then
		return;
	end
	
	-- Get the weapon list we are going to add to
	local nodeChar = DB.getChild(itemnode, "...");
	local nodeAttacks = DB.createChild(nodeChar, "attacklist");
	if not nodeAttacks then
		return;
	end

	local attacknode = DB.createChild(nodeAttacks);
	if not attacknode then
		return;
	end

	DB.setValue(attacknode, "name", "string", ItemManagerCypher.getItemName(itemnode));
	DB.setValue(attacknode, "weapontype", "string", ItemManagerCypher.getWeaponType(itemnode));
	DB.setValue(attacknode, "stat", "string", ItemManagerCypher.getWeaponAttackStat(itemnode));
	DB.setValue(attacknode, "defensestat", "string", ItemManagerCypher.getWeaponDefenseStat(itemnode));
	DB.setValue(attacknode, "atkrange", "string", ItemManagerCypher.getWeaponAttackRange(itemnode));
	DB.setValue(attacknode, "asset", "number", ItemManagerCypher.getWeaponAsset(itemnode));
	DB.setValue(attacknode, "modifier", "number", ItemManagerCypher.getWeaponModifier(itemnode));
	DB.setValue(attacknode, "damage", "number", ItemManagerCypher.getWeaponDamage(itemnode));
	DB.setValue(attacknode, "damagestat", "string", ItemManagerCypher.getWeaponDamageStat(itemnode));
	DB.setValue(attacknode, "damagetype", "string", ItemManagerCypher.getWeaponDamageType(itemnode));

	local nPiercing = ItemManagerCypher.getWeaponPiercing(itemnode);
	if nPiercing >= 0 then
		DB.setValue(attacknode, "pierce", "string", "yes");
		DB.setValue(attacknode, "pierceamount", "number", nPiercing);
	end

	DB.setValue(attacknode, "itemlink", "windowreference", "item", DB.getPath(itemnode));
	DB.setValue(itemnode, "attacklink", "windowreference", "attack", DB.getPath(attacknode));

	return attacknode;
end

function addItemAsAbility(itemnode)
	-- Get the weapon list we are going to add to
	local nodeChar = DB.getChild(itemnode, "...");
	local nodeAbilities = DB.createChild(nodeChar, "abilitylist");
	if not nodeAbilities then
		return;
	end

	local abilitynode = DB.createChild(nodeAbilities);
	if not abilitynode then
		return;
	end

	local sItemType = StringManager.capitalize(ItemManagerCypher.getItemType(itemnode) or "");
	local sName = ItemManagerCypher.getItemName(itemnode);
	if sItemType ~= "" then
		sName = string.format("%s: %s", sItemType, sName);
		DB.setValue(abilitynode, "type", "string", sItemType);
	end

	DB.setValue(abilitynode, "name", "string", sName);
	if ItemManagerCypher.isItemWeapon(itemnode) then
		DB.setValue(abilitynode, "useequipped", "string", "yes");
	end

	local actions = DB.getChild(itemnode, "actions");
	if actions then
		DB.copyNode(actions, DB.createChild(abilitynode, "actions"));
	end

	-- Save links between the item and ability
	-- These are used so that if one is deleted, so is the other.
	DB.setValue(abilitynode, "itemlink", "windowreference", "item", DB.getPath(itemnode));
	DB.setValue(itemnode, "abilitylink", "windowreference", "ability", DB.getPath(abilitynode));

	return abilitynode;
end

function removeAttackLinkedToRecord(noderecord)
	CharManager.removeLinkedRecord(noderecord, "attacklink");
end

function removeAbilityLinkedToRecord(noderecord)
	CharManager.removeLinkedRecord(noderecord, "abilitylink");	
end

function removeItemLinkedToRecord(noderecord)
	CharManager.removeLinkedRecord(noderecord, "itemlink");
end

function removeLinkedRecord(sourcenode, sPath)
	-- For some reason when an item is moved to the party sheet the onRemove event
	-- fires twice, but by the time we get here the sourcnode is already deleted
	-- (due to async processing I think), so we just need to check that sourcenode is
	-- valid before running this.
	if not sourcenode or type(sourcenode) ~= "databasenode" then
		return;
	end

	local _, sRecord = DB.getValue(sourcenode, sPath);
	if (sRecord or "") == "" then
		return;
	end

	local linkednode = DB.findNode(sRecord);
	if linkednode then
		DB.deleteNode(linkednode);
	end
end

function updateCyphers(nodeChar)
	local nCypherTotal = 0;

	for _,vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "type", "") == "cypher" then
			nCypherTotal = nCypherTotal + 1;
		end
	end

	DB.setValue(nodeChar, "cypherload", "number", nCypherTotal);
end

-------------------------------------------------------------------------------
-- RESTING
-------------------------------------------------------------------------------

function rest(nodeChar)
	DB.setValue(nodeChar, "recoveryused", "number", 0);
end

-------------------------------------------------------------------------------
-- CHARACTER ARCS
-------------------------------------------------------------------------------

function getCostToBuyNewCharacterArc(nodeChar)
	local nCost = 0;
	-- Only the first character arc is free
	if DB.getChildCount(nodeChar, "characterarcs") > 0 then
		nCost = OptionsManagerCypher.getXpCostToAddArc();
	end
	return nCost;
end

function buyNewCharacterArc(nodeChar)
	local nCost = CharManager.getCostToBuyNewCharacterArc(nodeChar);

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

	DB.setValue(nodeChar, "xp", "number", math.max(nXP - nCost, 0));
	
	-- Notify chat
	CharManager.sendCharacterArcMessage(nodeChar, "char_message_add_arc", nCost)
	return true;
end

function completeCharacterArcStep(nodeChar)
	local nReward = OptionsManagerCypher.getArcStepXpReward();
	CharManager.sendCharacterArcMessage(nodeChar, "char_message_arc_complete_step", nReward)

	local nXP = DB.getValue(nodeChar, "xp", 0);
	DB.setValue(nodeChar, "xp", "number", math.max(nXP + nReward, 0));
end

function completeCharacterArcClimax(nodeChar, nodeArc, bSuccess)
	local nReward = 0;
	if bSuccess then
		nReward = OptionsManagerCypher.getArcClimaxSuccessXpReward();
		CharManager.sendCharacterArcMessage(nodeChar, "char_message_arc_climax_success", nReward)
		DB.setValue(nodeArc, "success", "string", "Yes");
	else
		nReward = OptionsManagerCypher.getArcClimaxFailureXpReward();
		CharManager.sendCharacterArcMessage(nodeChar, "char_message_arc_climax_failure", nReward)
		DB.setValue(nodeArc, "success", "string", "No");
	end

	local nXP = DB.getValue(nodeChar, "xp", 0);
	DB.setValue(nodeChar, "xp", "number", math.max(nXP + nReward, 0));
end

function completeCharacterArcResolution(nodeChar, nodeArc, bSuccess)
	local nReward = 0;
	if bSuccess then
		nReward = OptionsManagerCypher.getArcResolutionXpReward();
		CharManager.sendCharacterArcMessage(nodeChar, "char_message_arc_resolution_success", nReward)
		DB.setValue(nodeArc, "resolved", "string", "Yes");
	else
		CharManager.sendCharacterArcMessage(nodeChar, "char_message_arc_resolution_failure", nReward)
		DB.setValue(nodeArc, "resolved", "string", "No");
	end
	
	local nXP = DB.getValue(nodeChar, "xp", 0);
	DB.setValue(nodeChar, "xp", "number", math.max(nXP + nReward, 0));
end

function sendCharacterArcMessage(nodeChar, sMessageResource, nXp)
	local sName = DB.getValue(nodeChar, "name", "");
	if sName == "" then
		return;
	end

	local rMessage = {
		text = string.format(
			Interface.getString(sMessageResource), 
			sName, 
			nXp),
		font = "msgfont"
	};

	Comm.deliverChatMessage(rMessage);
end

-------------------------------------------------------------------------------
-- HEALTH
-------------------------------------------------------------------------------
function isImpaired(rActor)
	rActor = ActorManager.resolveActor(rActor);
	if not ActorManager.isPC(rActor) then
		return false;
	end	

	local nWounds = ActorManagerCypher.getDamageTrack(rActor);
	if EffectManagerCypher.hasEffect(rActor, "IGNOREIMPAIRED", nil, false, true) then
		nWounds = nWounds - 1;
	end

	return nWounds >= 1;
end

-------------------------------------------------------------------------------
-- STAT CONVERSIONS
-------------------------------------------------------------------------------
function canConvertStat(rActor, sConversionType, aFilter)
end