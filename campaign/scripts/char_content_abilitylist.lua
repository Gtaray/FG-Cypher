function onInit()
	update();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if sClass == "ability" then
			list.addEntry(sClass, sRecord)
			return true;
		end
	end
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	list.update(bReadOnly);
end