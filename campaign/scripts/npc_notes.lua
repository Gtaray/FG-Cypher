-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());

	WindowManager.callSafeControlUpdate(self, "motive", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "environment", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "interaction", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "use", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "loot", bReadOnly);
	
	WindowManager.callSafeControlUpdate(self, "text", bReadOnly);
end
