function onInit()
	update();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if sClass == "ability" then
			abilities.addEntry(sClass, sRecord)
			return true;
		end
	end
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	WindowManager.callSafeControlUpdate(self, "mightpool", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "speedpool", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "intellectpool", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "floatingstats", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "effort", bReadOnly);
	abilities.update(bReadOnly);

	edge_iedit.setVisibility(not bReadOnly);
	edge_iadd.setVisible(not bReadOnly);
	edge.update(bReadOnly);
end