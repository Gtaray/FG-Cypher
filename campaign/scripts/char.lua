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
			CharManager.rest(nodeChar);
		end
	end
end

function onDrop(x, y, draginfo)
	if not draginfo.isType("shortcut") then
		return;
	end

	local sClass, sNodeName = draginfo.getShortcutData();
	local node = draginfo.getDatabaseNode();

	if not node then
		return;
	end
	if sClass == "ability" then
		return CharManager.addAbilityToCharacter(getDatabaseNode(), node);
	elseif sClass == "type" then
		return CharManager.addTypeToCharater(getDatabaseNode(), node);
	elseif sClass == "descriptor" then
		return CharManager.addDescriptorToCharater(getDatabaseNode(), node);
	elseif sClass == "focus" then
		return CharManager.addFocusToCharater(getDatabaseNode(), node);
	end
end

function onAbilityDeleted(abilitynode)
	CharManager.removeItemLinkedToRecord(abilitynode);
end

function onAttackDeleted(attacknode)
	CharManager.removeItemLinkedToRecord(attacknode);
end