-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManager.setCustomCharAdd(onCharItemAdd);
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
	if not OptionsManagerCypher.areExperimentalFeaturesEnabled() then
		return;
	end
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
	self.addWeaponToAttackList(nodeItem);
end

-- Adds a item (that is a weapon) to the character's attacklist
function addWeaponToAttackList(itemnode)
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

	local nPiercing = ItemManagerCypher.getWeaponPiercing(itemnode);
	if nPiercing >= 0 then
		DB.setValue(attacknode, "pierce", "string", "yes");
		DB.setValue(attacknode, "pierceamount", "number", nPiercing);
	end

	DB.setValue(attacknode, "source", "windowreference", "item", DB.getPath(itemnode));
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
-- TYPE, DESCRIPTOR, FOCUS, ABILITIES
-------------------------------------------------------------------------------
function addTypeToCharater(nodeChar, nodeType)
	if not nodeChar then return false end
	if not nodeType then return false end

	local sTypeName = DB.getValue(nodeType, "name", "");
	
	DB.setValue(nodeChar, "class.type", "string", sTypeName);
	DB.setValue(nodeChar, "class.typelink", "windowreference", "type", DB.getPath(nodeType));
end

function addDescriptorToCharater(nodeChar, nodeDescriptor)
	if not nodeChar then return false end
	if not nodeDescriptor then return false end

	local sDescName = DB.getValue(nodeDescriptor, "name", "");
	
	DB.setValue(nodeChar, "class.descriptor", "string", sDescName);
	DB.setValue(nodeChar, "class.descriptorlink", "windowreference", "descriptor", DB.getPath(nodeDescriptor));
end

function addFocusToCharater(nodeChar, nodeFocus)
	if not nodeChar then return false end
	if not nodeFocus then return false end

	local sFocusName = DB.getValue(nodeFocus, "name", "");
	
	DB.setValue(nodeChar, "class.descriptor", "string", sFocusName);
	DB.setValue(nodeChar, "class.descriptorlink", "windowreference", "focus", DB.getPath(nodeFocus));
end

function addAbilityToCharacter(nodeChar, nodeAbility)
	if not nodeChar then return false end
	if not nodeAbility then return false end

	local abilityList = DB.getChild(nodeChar, "abilitylist");
	if not abilityList then return false end;

	local newNode = DB.createChild(abilityList);
	DB.copyNode(nodeAbility, newNode);

	return true;
end

-------------------------------------------------------------------------------
-- RESTING
-------------------------------------------------------------------------------

function rest(nodeChar)
	DB.setValue(nodeChar, "recoveryused", "number", 0);
end
