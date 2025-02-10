-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = window.getDatabaseNode()
	DB.addHandler(DB.getPath(node, "attacklist"), "onChildAdded", onChildAdded);
	
	onModeChanged();
end

function onClose()
	local node = window.getDatabaseNode()
	DB.removeHandler(DB.getPath(node, "attacklist"), "onChildAdded", onChildAdded);
end

function onChildAdded()
	onModeChanged();
end

function onModeChanged()
	for _,w in pairs(getWindows()) do
		w.onModeChanged();
	end
	applyFilter();
end

function onFilter(w)
	-- First check if the ability is from an item
	-- If that item is a cypher and it's not equipped, then we hide this ability
	local itemnode = getLinkedItemNode(w)
	if itemnode and ItemManagerCypher.isItemCypher(itemnode) then
		if not ItemManagerCypher.isEquipped(itemnode) then
			return false;
		end
	end

	-- In edit mode, display all weapons (except unused cyphers)
	local sEditMode = WindowManager.getEditMode(window, "actions_iedit");
	if sEditMode then
		return true;
	end

	-- If an attack has no linked item, then always display it
	local itemnode = CharInventoryManager.getItemLinkedToRecord(w.getDatabaseNode());
	if not itemnode then
		return true;
	end

	-- If not in edit mode, then only display non-carried weapons if the display mode is set to standard
	local sDisplayMode = DB.getValue(window.getDatabaseNode(), "powermode", "");
	if sDisplayMode ~= "" and w.carried.getValue() == 0 then
		return false;
	end

	return true;
end

function getLinkedItemNode(w)
	local _, sRecord = w.itemlink.getValue()
	return DB.findNode(sRecord);
end
