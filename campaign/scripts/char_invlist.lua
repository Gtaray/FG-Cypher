-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aSortTypes = { 
		["cypher"] = 1, 
		["artifact"] = 2, 
		["oddity"] = 3, 
		["weapon"] = 4, 
		["armor"] = 5,
		[""] = 6;
};

function onInit()
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

function onSortCompare(w1, w2)
	local n1 = w1.getDatabaseNode();
	local n2 = w2.getDatabaseNode();
	
	-- Sort by name first
	local sName1 = ItemManager.getSortName(n1);
	local sName2 = ItemManager.getSortName(n2);
	
	-- Check for empty name (sort to end of list)
	if sName1 == "" then
		if sName2 == "" then
			return nil;
		end
		return true;
	elseif sName2 == "" then
		return false;
	end
	
	if sName1 ~= sName2 then
		return sName1 > sName2;
	end
	
	-- If same name, then sort by type
	local sType1 = DB.getValue(n1, "type", "");
	local sType2 = DB.getValue(n2, "type", "");
	local nType1 = aSortTypes[sType1] or aSortTypes[""];
	local nType2 = aSortTypes[sType2] or aSortTypes[""];
	if nType1 ~= nType2 then
		return nType1 > nType2;
	end
end
