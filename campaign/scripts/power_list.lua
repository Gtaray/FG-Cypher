-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aFilters = {};

function onInit()
	local sPath = getDatabaseNode();
	DB.addHandler(sPath, "onChildAdded", onChildListChanged);
	DB.addHandler(sPath, "onChildDeleted", onChildListChanged);
end
function onClose()
	local sPath = getDatabaseNode();
	DB.removeHandler(sPath, "onChildAdded", onChildListChanged);
	DB.removeHandler(sPath, "onChildDeleted", onChildListChanged);
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

	-- Check to see if this category is hidden
	local sGroup = window.getWindowSort(w);
	if aFilters[sGroup] then
		return false;
	end
	
	return w.getFilter();
end
