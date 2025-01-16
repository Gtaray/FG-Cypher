-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


function onInit()
	if super and super.onInit then
		super.onInit()
	end

	onCyphersChanged();

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "*.type"), "onUpdate", onCyphersChanged);
	DB.addHandler(DB.getPath(node, "*.count"), "onUpdate", onCyphersChanged);
	DB.addHandler(DB.getPath(node, "*.carried"), "onUpdate", onCyphersChanged);
	DB.addHandler(node, "onChildDeleted", onCyphersChanged);
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "*.type"), "onUpdate", onCyphersChanged);
	DB.removeHandler(DB.getPath(node, "*.count"), "onUpdate", onCyphersChanged);
	DB.removeHandler(DB.getPath(node, "*.carried"), "onUpdate", onCyphersChanged);
	DB.removeHandler(node, "onChildDeleted", onCyphersChanged);
end

function onListChanged()
	self.updateContainers();
	self.onCyphersChanged();
	
	if self.update then
		self.update();
	end
end
function onChildWindowCreated(w)
	w.count.setValue(1);
end

local _sortLocked = false;
function setSortLock(isLocked)
	_sortLocked = isLocked;
end
function onSortCompare(w1, w2)
	if _sortLocked then
		return false;
	end
	return ItemManager.onInventorySortCompare(w1, w2);
end

function updateContainers()
	ItemManager.onInventorySortUpdate(self);
end

function onDrop(x, y, draginfo)
	return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
end

function onCyphersChanged()
	CharManager.updateCyphers(window.getDatabaseNode());
end