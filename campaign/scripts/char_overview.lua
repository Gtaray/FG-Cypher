-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	onXPOptionChanged();
	OptionsManager.registerCallback("HRXP", onXPOptionChanged);
end

function onClose()
	if super and super.onClose then
		super.onClose();
	end
	OptionsManager.unregisterCallback("HRXP", onXPOptionChanged);
end

function onXPOptionChanged()
	local bSeparateXP = OptionsManager.isOption("HRXP", "on");
	
	hero.setVisible(bSeparateXP);
	hero_label.setVisible(bSeparateXP);
end
