function onInit()
	onAttackTypeChanged();
	onPierceChanged();
	onItemLinkNameChanged();

	addItemLinkNameHandler()
end

function onClose()
	removeItemLinkNameHandler()
end

function addItemLinkNameHandler()
	local itemnode = getLinkedItemNode()
	if not itemnode then
		return
	end

	DB.addHandler(DB.getPath(itemnode, "name"), "onUpdate", onItemLinkNameChanged)
end

function removeItemLinkNameHandler()
	local itemnode = getLinkedItemNode()
	if not itemnode then
		return
	end

	DB.removeHandler(DB.getPath(itemnode, "name"), "onUpdate", onItemLinkNameChanged)
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if sClass == "item" then
			local newItemNode = DB.findNode(sRecord)
			if newItemNode then
				-- If there's already a linked item, remove the handler for that link
				-- And remove the links between that item and this attack
				local oldItemNode = getLinkedItemNode()
				if oldItemNode then
					ItemManagerCypher.clearWeaponAttackNode(oldItemNode);
					removeItemLinkNameHandler()
				end

				-- Set the attack's item link to the item
				-- and set the item's attack link to this attack
				ItemManagerCypher.linkWeaponAndAttack(newItemNode, getDatabaseNode())
				onItemLinkNameChanged();
			end			
			return true;
		end
	end
end

function onAttackTypeChanged()
	local bWeapon = DB.getValue(getDatabaseNode(), "type", "") == "";
	weapontype_label.setVisible(bWeapon);
	weapontype.setVisible(bWeapon);
end

function onPierceChanged()
	local bPierce = DB.getValue(getDatabaseNode(), "pierce", "") == "yes";
	pierceamount.setVisible(bPierce);
end

function onItemLinkNameChanged()
	local node = getLinkedItemNode()
	if not node then
		return;
	end

	itemname.setValue(DB.getValue(node, "name", ""));
end

function getLinkedItemNode()
	local _, sRecord = itemlink.getValue()
	return DB.findNode(sRecord);
end