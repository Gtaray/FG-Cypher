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

	WindowTabManager.populate(self);
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "abilitylist.*"), "onDelete", onAbilityDeleted)
	DB.removeHandler(DB.getPath(getDatabaseNode(), "attacklist.*"), "onDelete", onAttackDeleted)
end

function getWindowMenuHelpLink()
	if tabs then
		local sTab = tabs.getActiveTabName();
		if sTab == "skills" then
			return Interface.getString("help_charsheet_skills");
		elseif sTab == "inventory" then
			return Interface.getString("help_charsheet_inventory");
		elseif sTab == "abilities" then
			return Interface.getString("help_charsheet_abilities");
		elseif sTab == "arcs" then
			return Interface.getString("help_charsheet_arcs");
		elseif sTab == "notes" then
			return Interface.getString("help_charsheet_notes");
		elseif sTab == "actions" then
			return Interface.getString("help_charsheet_actions");
		end
	end

	return Interface.getString("help_charsheet_main");
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