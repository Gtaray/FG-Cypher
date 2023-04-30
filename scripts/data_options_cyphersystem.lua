-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerOptions();
	
	DecalManager.setDefault("images/decals/cypher_decal.png@Cypher Assets");

	-- Prevents currency manager warnings
	CharEncumbranceManager.addCustomCalc(function() end);
end

function registerOptions()
	OptionsManager.registerOption2("INITNPC", false, "option_header_combat", "option_label_INITNPC", "option_entry_cycler", 
			{ labels = "option_val_group", values = "group", baselabel = "option_val_standard", baseval = "off", default = "off" });
	OptionsManager.registerOption2("INITPC", false, "option_header_combat", "option_label_INITPC", "option_entry_cycler", 
			{ labels = "option_val_group", values = "group", baselabel = "option_val_standard", baseval = "off", default = "off" });
	OptionsManager.registerOption2("SHPC", false, "option_header_combat", "option_label_SHPC", "option_entry_cycler", 
			{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "detailed" });
	OptionsManager.registerOption2("SHNPC", false, "option_header_combat", "option_label_SHNPC", "option_entry_cycler", 
			{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "status" });

	OptionsManager.registerOption2("HRXP", false, "option_header_houserule", "option_label_HRXP", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
end

function calcEncumbrance(nodeChar)
	local nEncumbrance = CharEncumbranceManagerCnC.calcInventoryEncumbrance(nodeChar);
	nEncumbrance = nEncumbrance + CharEncumbranceManager.calcDefaultCurrencyEncumbrance(nodeChar);
	CharEncumbranceManager.setDefaultEncumbranceValue(nodeChar, nEncumbrance);

	CharEncumbranceManagerCnC.updateEncumbranceState(nodeChar);
end
