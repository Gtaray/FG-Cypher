function onInit()
	local node = getDatabaseNode();
	local charnode = WindowManager.getTopWindow(window).getDatabaseNode();

	DB.addHandler(DB.getPath(node, "*"), "onChildUpdate", onAbilityDataChanged)
	DB.addHandler(DB.getPath(charnode, "inventorylist.*.isidentified"), "onUpdate", onItemIdUpdated)
end

function onClose()
	local node = getDatabaseNode();
	local charnode = WindowManager.getTopWindow(window).getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "*"), "onChildUpdate", onAbilityDataChanged)
	DB.removeHandler(DB.getPath(charnode, "inventorylist.*.isidentified"), "onUpdate", onItemIdUpdated)
end

function addEntry(bFocus)
	local w = createWindow();
	if w then
		local node = w.getDatabaseNode();
		if node then
			DB.setValue(node, "actionTabVisibility", "string", "show")
		end

		if bFocus then
			w.name.setFocus();
		end
	end
	return w;
end

function onAbilityDataChanged()
	applyFilter();
end

function onItemIdUpdated()
	applyFilter();
end

function onFilter(w)
	local abilitynode = w.getDatabaseNode();

	local _, sRecord = DB.getValue(abilitynode, "itemlink");
	local itemnode = DB.findNode(sRecord or "");

	-- if this ability is tied to an item, and that item is unidentified, then do not display this.
	if itemnode then
		if DB.getValue(itemnode, "isidentified", 1) ~= 1 then
			return false;
		end
	end

	if DB.getValue(abilitynode, "actionTabVisibility", "") == "show" then
		return true;
	elseif DB.getChildCount(abilitynode, "actions") > 0 then
		return true;
	elseif DB.getValue(abilitynode, "usetype", "") == "Action" then
		return true;
	elseif DB.getValue(abilitynode, "cost", 0) > 0 then
		return true;
	elseif DB.getValue(abilitynode, "period", "") ~= "" then
		return true;
	elseif DB.getValue(abilitynode, "useequipped", "") == "yes" then
		return true;
	end

	return false;
end