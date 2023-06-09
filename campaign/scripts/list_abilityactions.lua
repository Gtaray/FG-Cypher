function onInit()
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "*"), "onChildUpdate", onAbilityDataChanged)
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "*"), "onChildUpdate", onAbilityDataChanged)
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

function onFilter(w)
	local abilitynode = w.getDatabaseNode();

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