function onInit()
	update();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if not (sClass =="ability" or sClass == "item") then
			return;
		end

		features.addEntry(sClass, sRecord)
		return true;
	end
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	features.update(bReadOnly);
	features_iedit.setVisibility(not bReadOnly);
	features_iadd.setVisible(not bReadOnly);
end