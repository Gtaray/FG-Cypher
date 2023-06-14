-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onXPOptionChanged();
	OptionsManager.registerCallback("HRXP", onXPOptionChanged);
end

function onClose()
	OptionsManager.unregisterCallback("HRXP", onXPOptionChanged);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if StringManager.contains({"type", "descriptor", "focus", "flavor", "ancestry"}, sClass) then
			CharManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
			return true;
		end
	end
end

function onXPOptionChanged()
	local bSeparateXP = OptionsManager.isOption("HRXP", "on");
	
	hero.setVisible(bSeparateXP);
	hero_label.setVisible(bSeparateXP);
end
