-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler(getDatabaseNode(), "onChildAdded", onChildAdded);
	
	onModeChanged();
end

function onClose()
	DB.removeHandler(getDatabaseNode(), "onChildAdded", onChildAdded);
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
	-- In edit mode, display all weapons no matter what
	local sEditMode = WindowManager.getEditMode(window, "actions_iedit");
	if sEditMode then
		return true;
	end

	-- If not in edit mode, then only display non-carried weapons if the display mode is set to preparation
	local sDisplayMode = DB.getValue(window.getDatabaseNode(), "powermode", "");
	if sDisplayMode ~= "preparation" and w.carried.getValue() == 0 then
		return false;
	end

	return true;
end
