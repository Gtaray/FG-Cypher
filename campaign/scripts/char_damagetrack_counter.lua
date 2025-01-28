-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

slots = {};
local nMaxSlotRow = 3;
local nDefaultSpacing = 34;
local nSpacing = nDefaultSpacing;

function onInit()
	super.onInit();

	DB.addHandler(DB.getPath(window.getDatabaseNode(), "health.damagetrack"), "onUpdate", onWoundsChanged);
	onWoundsChanged();
end

function onClose()
	DB.removeHandler(DB.getPath(window.getDatabaseNode(), "health.damagetrack"), "onUpdate", onWoundsChanged);
end

function onWoundsChanged()
	updateSlots();
	
	if window.damagestatus then
		local c = getCurrentValue();
		if c >= 3 then
			window.damagestatus.setValue(Interface.getString("status_dead"));
		elseif c == 2 then
			window.damagestatus.setValue(Interface.getString("status_debilitated"));
		elseif c == 1 then
			window.damagestatus.setValue(Interface.getString("status_impaired"));
		else
			window.damagestatus.setValue(Interface.getString("status_hale"));
		end
	end
end