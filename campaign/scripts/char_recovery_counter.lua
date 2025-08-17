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
	if window.recoverystatus then
		local nCurr = self.getCurrentValue();
		if nCurr >= 4 then
			window.recoverystatus.setValue(Interface.getString("char_label_recoveryused"));
		elseif nCurr == 3 then
			window.recoverystatus.setValue(Interface.getString("char_label_recovery10hr"));
		elseif nCurr == 2 then
			window.recoverystatus.setValue(Interface.getString("char_label_recovery1hr"));
		elseif nCurr == 1 then
			window.recoverystatus.setValue(Interface.getString("char_label_recovery10min"));
		else
			window.recoverystatus.setValue(Interface.getString("char_label_recovery1action"));
		end
	end
end
