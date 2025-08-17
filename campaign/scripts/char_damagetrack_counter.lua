-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	self.updateStatus();
end
function onValueChanged()
	self.updateStatus();
end
function updateStatus()
	if window.damagestatus then
		local nCurr = self.getCurrentValue();
		if nCurr >= 3 then
			window.damagestatus.setValue(Interface.getString("status_dead"));
		elseif nCurr == 2 then
			window.damagestatus.setValue(Interface.getString("status_debilitated"));
		elseif nCurr == 1 then
			window.damagestatus.setValue(Interface.getString("status_impaired"));
		else
			window.damagestatus.setValue(Interface.getString("status_hale"));
		end
	end
end
