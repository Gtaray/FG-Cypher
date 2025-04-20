-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("DMGTYPES", update);
	update();
end

function onClose()
	OptionsManager.unregisterCallback("DMGTYPES", update);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if sClass == "item" then
			addItemToNpc(DB.findNode(sRecord));
			return true;
		end
	end
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);
	
	level.setReadOnly(bReadOnly);
	
	hp.setReadOnly(bReadOnly);
	damagestr.setReadOnly(bReadOnly);
	WindowManager.callSafeControlUpdate(self, "armor", bReadOnly);
	move.setReadOnly(bReadOnly);
	WindowManager.callSafeControlUpdate(self, "type", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "modifications", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "combat", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "intrusion", bReadOnly);

	updateActions(bReadOnly);
	resistances.update();
end

function updateActions(bReadOnly)
	-- Update all actions
	if bReadOnly then
		actions_iedit.setValue(0);
	end

	actions_iedit.setVisible(not bReadOnly);
	actions_iadd.setVisible(not bReadOnly);

	for _,w in ipairs(actions.getWindows()) do
		w.name.setReadOnly(bReadOnly);
		w.desc.setReadOnly(bReadOnly);
	end
end

-------------------------------------------------------------------------------
-- ITEM DROP HANDLING
-------------------------------------------------------------------------------

function addItemToNpc(sourcenode)
	deleteTempItemNode();
	itemnode = copyToTempItemNode(sourcenode);

	if ItemManagerCypher.isItemCypher(itemnode) then
		CypherManager.generateCypherLevel(itemnode);
	end

	local newaction = createActionFromItem(itemnode);

	-- if the item is a weapon, set up the default attack and damage actions
	if ItemManagerCypher.isItemWeapon(itemnode) then	
		addWeaponAttackActions(newaction, itemnode)
	end

	addItemActionsToPower(newaction, itemnode);
	
	deleteTempItemNode();
	return newaction;
end

function createActionFromItem(itemnode)
	local actionsnode = DB.createChild(getDatabaseNode(), "actions")
	local node = DB.createChild(actionsnode);

	-- Set name
	local sItemType = StringManager.capitalize(ItemManagerCypher.getItemType(itemnode) or "");
	local sName = ItemManagerCypher.getItemName(itemnode);
	local nCypherLevel = DB.getValue(itemnode, "level", 0);
	if sItemType ~= "" then
		sName = string.format("%s: %s", sItemType, sName);
	end
	if nCypherLevel > 0 then
		sName = string.format("%s (level %s)", sName, nCypherLevel);
	end
	DB.setValue(node, "name", "string", sName);

	-- Set descripion
	DB.setValue(node, "description", "formattedtext", DB.getValue(itemnode, "notes", ""));

	return node;
end

function addWeaponAttackActions(node, itemnode)
	-- Parameter validation
	if not ItemManagerCypher.isItemWeapon(itemnode) then
		return;
	end

	local actionsnode = DB.createChild(node, "actions");
	if not actionsnode then
		return;
	end

	-- ATTACK
	local attacknode = DB.createChild(actionsnode)
	if not attacknode then
		return;
	end
	
	DB.setValue(attacknode, "type", "string", "attack");
	DB.setValue(attacknode, "stat", "string", ItemManagerCypher.getWeaponAttackStat(itemnode));
	DB.setValue(attacknode, "defensestat", "string", ItemManagerCypher.getWeaponDefenseStat(itemnode));
	DB.setValue(attacknode, "atkrange", "string", ItemManagerCypher.getWeaponAttackRange(itemnode));
	
	local nLevel = 0;
	if ItemManagerCypher.getWeaponType(itemnode) == "light" then
		nLevel = 1;
	end
	if ItemManagerCypher.getWeaponAsset(itemnode) ~= 0 then
		nLevel = nLevel + ItemManagerCypher.getWeaponAsset(itemnode)
	end
	if ItemManagerCypher.getWeaponModifier(itemnode) ~= 0 then
		nLevel = nLevel + math.floor(ItemManagerCypher.getWeaponModifier(itemnode) / 3)
	end

	DB.setValue(attacknode, "level", "number", nLevel);
	DB.setValue(attacknode, "order", "number", 1);

	-- DAMAGE
	local damagenode = DB.createChild(actionsnode)
	if not damagenode then
		return;
	end

	DB.setValue(damagenode, "type", "string", "damage");
	DB.setValue(damagenode, "stat", "string", ItemManagerCypher.getWeaponAttackStat(itemnode));
	DB.setValue(damagenode, "damage", "number", ItemManagerCypher.getWeaponDamage(itemnode));
	DB.setValue(damagenode, "damagestat", "string", ItemManagerCypher.getWeaponDamageStat(itemnode));
	DB.setValue(damagenode, "damagetype", "string", ItemManagerCypher.getWeaponDamageType(itemnode));

	local nPiercing = ItemManagerCypher.getWeaponPiercing(itemnode);
	if nPiercing >= 0 then
		DB.setValue(damagenode, "pierce", "string", "yes");
		DB.setValue(damagenode, "pierceamount", "number", nPiercing);
	end

	DB.setValue(damagenode, "order", "number", 2);
end

function addItemActionsToPower(node, itemnode)
	-- Create the actions node within the new action (confusing, I know)
	local actionslist = DB.createChild(node, "actions");
	local itemactions = DB.getChild(itemnode, "actions");
	local nOrder = (DB.getChildCount(actionslist) or 0) + 1;

	-- Can't just copy the whole list because weapons will add actions prior to this
	for _, sourceaction in ipairs(DB.getChildList(itemactions)) do
		local destaction = DB.createChild(actionslist);

		DB.copyNode(sourceaction, destaction);
		DB.setValue(destaction, "order", "number", nOrder);

		nOrder = nOrder + 1;
	end
end

function copyToTempItemNode(itemnode)
	local tempnode = DB.createChild(getDatabaseNode(), "tempitem")
	DB.copyNode(itemnode, tempnode);
	return tempnode;
end

function deleteTempItemNode()
	DB.deleteChild(getDatabaseNode(), "tempitem");
end