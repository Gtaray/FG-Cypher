-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManager.setCustomCharAdd(onCharItemAdd);
	ItemManager.setCustomCharRemove(onCharItemRemoved);
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
		return;
	end

	CharManager.takeAdvancement(nodeChar, "increase their stat pools");
end

function takeEdgeAdvancement(nodeChar)
	if not nodeChar then
		return;
	end

	CharManager.takeAdvancement(nodeChar, "increase their edge");
end

function takeEffortAdvancement(nodeChar)
	if not nodeChar then
		return;
	end

	CharManager.takeAdvancement(nodeChar, "increase their effort");
end

function takeSkillAdvancement(nodeChar)
	if not nodeChar then
		return;
	end

	CharManager.takeAdvancement(nodeChar, "gain training in a skill");
end

function takeAdvancement(nodeChar, sMessage)
	if not nodeChar then
		return;
	end

	if not CharManager.deductXpForAdvancement(nodeChar, 4) then
		return;
	end

	if (sMessage or "") ~= "" then
		CharManager.sendAdvancementMessage(nodeChar, "char_message_advancement_taken", sMessage);
	end

	-- Check if all advancements have been taken, and if so, clear all the checkboxes
	-- and increment tier
	
	if CharManager.checkForAllAdvancements(nodeChar) then
		CharManager.increaseTier(nodeChar);
	end
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
		font = "msgfont",
		sender = User.getIdentityLabel(sSender)
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

-- This threw an error during the game (invalid argument #1)
function removeLinkedRecord(sourcenode, sPath)
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
