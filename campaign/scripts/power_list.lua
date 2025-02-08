-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aFilters = {};

function onInit()
	local sPath = getDatabaseNode();
	DB.addHandler(sPath, "onChildAdded", onChildListChanged);
	DB.addHandler(sPath, "onChildDeleted", onChildListChanged);

	local charnode = window.getDatabaseNode()
	DB.addHandler(DB.getPath(charnode, "inventorylist.*.carried"), "onUpdate", onInventoryUpdated);
	DB.addHandler(DB.getPath(charnode, "inventorylist.*.type"), "onUpdate", onInventoryUpdated);

	applyFilter();
end
function onClose()
	local sPath = getDatabaseNode();
	DB.removeHandler(sPath, "onChildAdded", onChildListChanged);
	DB.removeHandler(sPath, "onChildDeleted", onChildListChanged);

	local charnode = window.getDatabaseNode()
	DB.removeHandler(DB.getPath(charnode, "inventorylist.*.carried"), "onUpdate", onInventoryUpdated);
	DB.removeHandler(DB.getPath(charnode, "inventorylist.*.type"), "onUpdate", onInventoryUpdated);
end

function addEntry(bFocus)
	local w = createWindow();
	if w then
		if bFocus then
			w.header.subwindow.name.setFocus();
		end
	end
	return w;
end

function onChildListChanged()
	window.onPowerListChanged();
end
function onChildWindowAdded(w)
	window.onPowerWindowAdded(w);
end
function onInventoryUpdated()
	applyFilter();
end

function onEnter()
	if Input.isShiftPressed() then
		createWindow(nil, true);
		return true;
	end
	
	return false;
end

function onSortCompare(w1, w2)
	return window.onSortCompare(w1, w2);
end

function onHeaderToggle(wh)
	local sCategory = window.getWindowSort(wh);
	if aFilters[sCategory] then
		aFilters[sCategory] = nil;
		wh.name.setFont("subwindowsmalltitle");
	else
		aFilters[sCategory] = true; 
		wh.name.setFont("subwindowsmalltitle_disabled");
	end
	applyFilter();
end

function onFilter(w)
	if w.getClass() == "power_group_header" then
		return w.getFilter();
	end

	-- First check if the ability is from an item
	-- If that item is a cypher and it's not equipped, then we hide this ability
	local itemnode = getLinkedItemNode(w)
	if itemnode and ItemManagerCypher.isItemCypher(itemnode) then
		if not ItemManagerCypher.isEquipped(itemnode) then
			return false;
		end
	end

	-- Check to see if this category is hidden
	local sGroup = window.getWindowSort(w);
	if aFilters[sGroup] then
		return false;
	end
	
	return w.getFilter();
end

function getLinkedItemNode(w)
	local _, sRecord = w.shortcut.getValue()
	return DB.findNode(sRecord);
end