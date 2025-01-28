-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit()

	DB.addHandler(DB.getPath(window.getDatabaseNode(), "health.recovery.used"), "onUpdate", onRecoveryChanged);
	onRecoveryChanged();
end

function onClose()
	super.onClose();

	DB.removeHandler(DB.getPath(window.getDatabaseNode(), "health.recovery.used"), "onUpdate", onRecoveryChanged);
end

function onRecoveryChanged()
	updateSlots();
	
	if window.recoverystatus then
		local c = self.getCurrentValue();
		if c >= 4 then
			window.recoverystatus.setValue(Interface.getString("char_label_recoveryused"));
		elseif c == 3 then
			window.recoverystatus.setValue(Interface.getString("char_label_recovery10hr"));
		elseif c == 2 then
			window.recoverystatus.setValue(Interface.getString("char_label_recovery1hr"));
		elseif c == 1 then
			window.recoverystatus.setValue(Interface.getString("char_label_recovery10min"));
		else
			window.recoverystatus.setValue(Interface.getString("char_label_recovery1action"));
		end
	end
end
