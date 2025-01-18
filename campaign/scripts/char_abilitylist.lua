-- If filter property is null, we don't do any filtering
local sFilterProperty;
local sFilterValue = "";

function onInit()
	if filter and filter[1] then
		if filter[1].property and filter[1].property[1] then
			sFilterProperty = filter[1].property[1]
		end
		if filter[1].value and filter[1].value[1] then
			sFilterValue = filter[1].value[1]
		end
	end
	
	if not sFilterProperty then
		return;
	end

	local node = window.getDatabaseNode()
	DB.addHandler(DB.getPath(node, "abilitylist.*.usetype"), "onUpdate", onUseTypeUpdated)

	applyFilter();
end

function onClose()
	if not sFilterProperty then
		return;
	end
	
	local node = window.getDatabaseNode()
	DB.removeHandler(DB.getPath(node, "abilitylist.*.usetype"), "onUpdate", onUseTypeUpdated)
end

function onListChanged()
	applyFilter()
end

function onUseTypeUpdated()
	applyFilter();
end

function onFilter(w)
	if not sFilterProperty then return true end;

	local node = w.getDatabaseNode()
	local sValue = DB.getValue(node, sFilterProperty, ""):lower();
	return sValue == sFilterValue:lower();
end

function onSortCompare(w1, w2)
	local s1 = w1.type.getValue() or ""
	local s2 = w2.type.getValue() or ""

	-- Typed abilities show up first in the list, ordered alphabetically by type
	-- Then untyped abilities show up, ordered alphabetically by name.
	if s1 ~= "" and s2 == "" then
		return false;
	elseif s1 == "" and s2 ~= "" then
		return true;
	elseif s1 ~= "" and s2 ~= "" then
		return s1 > s2
	else
		return w1.name.getValue() > w2.name.getValue();
	end
end

function addEntry()
	local w = createWindow(nil, true);
	if not w then
		return;
	end

	local node = w.getDatabaseNode();
	if not node then
		return;
	end

	-- If this list has a filter property set, then we want to initialize the new 
	-- entry to have the same value so it shows up in the right list.
	if sFilterProperty then
		DB.setValue(node, sFilterProperty, "string", sFilterValue)
	end
end