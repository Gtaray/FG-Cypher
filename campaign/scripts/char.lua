-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		registerMenuItem(Interface.getString("menu_rest"), "lockvisibilityon", 7);
		registerMenuItem(Interface.getString("menu_restovernight"), "pointer_circle", 7, 6);
	end

	-- I'm not entirely where else to put this, so it goes here.
	DB.addHandler(DB.getPath(getDatabaseNode(), "abilitylist.*"), "onDelete", onAbilityDeleted)
	DB.addHandler(DB.getPath(getDatabaseNode(), "attacklist.*"), "onDelete", onAttackDeleted)

	self.migrateAttackTraining();

	WindowTabManager.populate(self);
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "abilitylist.*"), "onDelete", onAbilityDeleted)
	DB.removeHandler(DB.getPath(getDatabaseNode(), "attacklist.*"), "onDelete", onAttackDeleted)
end

function onMenuSelection(selection, subselection)
	if selection == 7 then
		if subselection == 6 then
			local nodeChar = getDatabaseNode();
			ChatManager.Message(Interface.getString("message_restovernight"), true, ActorManager.resolveActor(nodeChar));
			CharHealthManager.rest(nodeChar);
		end
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if StringManager.contains({"ability", "type", "descriptor", "focus", "flavor", "ancestry"}, sClass) then
			CharManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
			return true;
		end
	end
end

function onAbilityDeleted(abilitynode)
	CharInventoryManager.getEquippedWeapon(abilitynode);
end

function onAttackDeleted(attacknode)
	CharInventoryManager.getEquippedWeapon(attacknode);
end

function migrateAttackTraining()
	for _, attacknode in ipairs(DB.getChildList(getDatabaseNode(), "attacklist")) do
		local vTraining = DB.getValue(attacknode, "training");
		if type(vTraining) == "number" then
			DB.deleteChild(attacknode, "training");

			if vTraining == 2 then
				DB.setValue(attacknode, "training", "string", "trained");
			elseif vTraining == 3 then
				DB.setValue(attacknode, "training", "string", "specialized");
			elseif vTraining == 0 then
				DB.setValue(attacknode, "training", "string", "inability");
			end
		end
	end
end