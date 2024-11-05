-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aSortTypes = { 
		["cypher"] = 1, 
		["artifact"] = 2, 
		["oddity"] = 3, 
		[""] = 4;
};

function onInit()
	super.onInit()

	onCyphersChanged();

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "*.type"), "onUpdate", onCyphersChanged);
	DB.addHandler(node, "onChildDeleted", onCyphersChanged);
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "*.type"), "onUpdate", onCyphersChanged);
	DB.removeHandler(node, "onChildDeleted", onCyphersChanged);
end

function onListChanged()
	update();
	onCyphersChanged();
end

function onCyphersChanged()
	CharManager.updateCyphers(window.getDatabaseNode());
end