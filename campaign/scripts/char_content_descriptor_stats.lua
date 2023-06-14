function onInit()
	update();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if sClass == "ability" then
			--abilities.addEntry(sClass, sRecord)
			return true;
		end
	end
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	features.update(bReadOnly);
	features_iedit.setVisibility(not bReadOnly);
	features_iadd.setVisible(not bReadOnly);
end