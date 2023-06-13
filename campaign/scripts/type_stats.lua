function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if sClass == "ability" then
			abilities.addEntry(sClass, sRecord)
			return true;
		end
	end
end