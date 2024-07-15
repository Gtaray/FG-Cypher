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

		if sClass == "item" then
			features.addEntry(sClass, sRecord)
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
	WindowManager.callSafeControlUpdate(self, "cypherlimit", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "t1_abilities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "t2_abilities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "t3_abilities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "t4_abilities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "t5_abilities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "t6_abilities", bReadOnly);
	abilities.update(bReadOnly);

	features_iedit.setVisibility(not bReadOnly);
	features_iadd.setVisible(not bReadOnly);
	features.update(bReadOnly);

	edge_iedit.setVisibility(not bReadOnly);
	edge_iadd.setVisible(not bReadOnly);
	edge.update(bReadOnly);
end