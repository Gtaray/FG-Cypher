-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = window.getDatabaseNode()
	DB.addHandler(DB.getPath(node, "attacklist"), "onChildAdded", onChildAdded);
	DB.addHandler(DB.getPath(node, "inventorylist.*.carried"), "onUpdate", onInventoryListUpdate);
	DB.addHandler(DB.getPath(node, "inventorylist.*.type"), "onUpdate", onInventoryListUpdate);
	
	onModeChanged();
end

function onClose()
	local node = window.getDatabaseNode()
	DB.removeHandler(DB.getPath(node, "attacklist"), "onChildAdded", onChildAdded);
	DB.removeHandler(DB.getPath(node, "inventorylist.*.carried"), "onUpdate", onInventoryListUpdate);
	DB.removeHandler(DB.getPath(node, "inventorylist.*.type"), "onUpdate", onInventoryListUpdate);
end

function onChildAdded()
	onModeChanged();
end

function onInventoryListUpdate()
	applyFilter();
end

function onModeChanged()
	for _,w in pairs(getWindows()) do
		w.onModeChanged();
	end
	applyFilter();
end

function onFilter(w)
	-- If an attack has no linked item, then always display it
	local itemnode = CharInventoryManager.getItemLinkedToRecord(w.getDatabaseNode());
	if not itemnode then
		return true;
	end

	-- If a linked  item is a cypher and it's not equipped, then we hide this ability
	local itemnode = getLinkedItemNode(w)
	if itemnode and ItemManagerCypher.isItemCypher(itemnode) then
		if not ItemManagerCypher.isEquipped(itemnode) then
			return false;
		end
	end

	-- If a linked item is not carried or equipped, always hide
	if w.carried.getValue() == 0 then
		return false;
	end

	return true;
end

function getLinkedItemNode(w)
	local _, sRecord = w.itemlink.getValue()
	return DB.findNode(sRecord);
end
