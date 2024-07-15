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

function onXPOptionChanged()
	local bSeparateXP = OptionsManager.isOption("HRXP", "on");
	
	hero.setVisible(bSeparateXP);
	hero_label.setVisible(bSeparateXP);
end
