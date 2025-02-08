-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerOptions();
	
	DecalManager.setDefault("images/decals/cypher_decal.png@Cypher Assets");

	-- Prevents currency manager warnings
	CharEncumbranceManager.addCustomCalc(function() end);

	OptionsManager.registerCallback("DMGTYPES", updateDamageTypeOption);
	OptionsManager.registerButton("library_recordtype_label_damagetypes", "damagetypes", "damagetypes");
end

function onClose()
	OptionsManager.unregisterCallback("DMGTYPES", updateDamageTypeOption);
end

function registerOptions()
	OptionsManager.registerOption2("GDIFF", false, "option_header_game", "option_label_GDIFF", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("GMIT", false, "option_header_game", "option_label_GMIT", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("HITMISS", false, "option_header_game", "option_lable_HITMISS", "option_entry_cycler",
		{ labels = "option_val_yes", values = "yes", baselabel = "option_val_no", baseval = "no", default = "yes" });
		
	OptionsManager.registerOption2("INITNPC", false, "option_header_combat", "option_label_INITNPC", "option_entry_cycler", 
		{ labels = "option_val_group", values = "group", baselabel = "option_val_standard", baseval = "off", default = "off" });
	OptionsManager.registerOption2("INITPC", false, "option_header_combat", "option_label_INITPC", "option_entry_cycler", 
		{ labels = "option_val_group", values = "group", baselabel = "option_val_standard", baseval = "off", default = "off" });
	OptionsManager.registerOption2("SHPC", false, "option_header_combat", "option_label_SHPC", "option_entry_cycler", 
		{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "detailed" });
	OptionsManager.registerOption2("SHNPC", false, "option_header_combat", "option_label_SHNPC", "option_entry_cycler", 
		{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "status" });
	OptionsManager.registerOption2("DEATHMARKER_ONDELETE", false, "option_header_combat", "option_label_DEATHMARKER_ONDELETE", "option_entry_cycler", 
		{ labels = "option_val_yes", values = "yes", baselabel = "option_val_no", baseval = "no", default = "yes" });
	OptionsManager.registerOption2("DEATHMARKER_ONDAMAGE", false, "option_header_combat", "option_label_DEATHMARKER_ONDAMAGE", "option_entry_cycler", 
		{ labels = "option_val_yes", values = "yes", baselabel = "option_val_no", baseval = "no", default = "no" });
	OptionsManager.registerOption2("DEATHMARKER_ONWOUND", false, "option_header_combat", "option_label_DEATHMARKER_ONWOUND", "option_entry_cycler", 
		{ labels = "option_val_yes", values = "yes", baselabel = "option_val_no", baseval = "no", default = "no" });

	OptionsManager.registerOption2("DESCRIPTOR_COUNT", false, "option_header_characters", "option_label_DESCRIPTOR_COUNT", "option_entry_cycler", 
		{ labels = "option_val_1|option_val_2", values = "1|2", baselabel = "option_val_0", baseval = "0", default = "1" });
	OptionsManager.registerOption2("FOCUS_COUNT", false, "option_header_characters", "option_label_FOCUS_COUNT", "option_entry_cycler", 
		{ labels = "option_val_1|option_val_2", values = "1|2", baselabel = "option_val_0", baseval = "0", default = "1" });
	OptionsManager.registerOption2("ANCESTRY_COUNT", false, "option_header_characters", "option_label_ANCESTRY_COUNT", "option_entry_cycler", 
		{ labels = "option_val_1|option_val_2", values = "1|2", baselabel = "option_val_0", baseval = "0", default = "1" });
		
	OptionsManager.registerOption2("ARCCOST", false, "option_header_characterarcs", "option_label_ARCCOST", "option_entry_cycler", 
		{ labels = "option_val_1|option_val_2|option_val_3|option_val_4|option_val_5", values = "1|2|3|4|5", baselabel = "option_val_0", baseval = "0", default = "1" });
	OptionsManager.registerOption2("ARCXPSTEP", false, "option_header_characterarcs", "option_label_ARCXPSTEP", "option_entry_cycler", 
		{ labels = "option_val_1|option_val_2|option_val_3|option_val_4|option_val_5", values = "1|2|3|4|5", baselabel = "option_val_0", baseval = "0", default = "2" });
	OptionsManager.registerOption2("ARCXPCLIMAX_SUCCESS", false, "option_header_characterarcs", "option_label_ARCXPCLIMAX_SUCCESS", "option_entry_cycler", 
		{ labels = "option_val_1|option_val_2|option_val_3|option_val_4|option_val_5", values = "1|2|3|4|5", baselabel = "option_val_0", baseval = "0", default = "4" });
	OptionsManager.registerOption2("ARCXPCLIMAX_FAILURE", false, "option_header_characterarcs", "option_label_ARCXPCLIMAX_FAILURE", "option_entry_cycler", 
		{ labels = "option_val_1|option_val_2|option_val_3|option_val_4|option_val_5", values = "1|2|3|4|5", baselabel = "option_val_0", baseval = "0", default = "2" });
	OptionsManager.registerOption2("ARCXPRESOLVE", false, "option_header_characterarcs", "option_label_ARCXPRESOLVE", "option_entry_cycler", 
		{ labels = "option_val_1|option_val_2|option_val_3|option_val_4|option_val_5", values = "1|2|3|4|5", baselabel = "option_val_0", baseval = "0", default = "1" });

	OptionsManager.registerOption2("MAXTARGET", false, "option_header_houserule", "option_label_MAXTARGET", "option_entry_cycler",
		{ labels = "option_val_maxtarget_15", values = "15", baselabel = "option_val_maxtarget_10", baseval = "10", default = "10" });
	OptionsManager.registerOption2("HRXP", false, "option_header_houserule", "option_label_HRXP", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("SPLITATKEFFORT", false, "option_header_houserule", "option_label_SPLITATKEFFORT", "option_entry_cycler", 
		{ labels = "option_val_yes", values = "yes", baselabel = "option_val_no", baseval = "no", default = "yes" });
end

function calcEncumbrance(nodeChar)
	local nEncumbrance = CharEncumbranceManagerCnC.calcInventoryEncumbrance(nodeChar);
	nEncumbrance = nEncumbrance + CharEncumbranceManager.calcDefaultCurrencyEncumbrance(nodeChar);
	CharEncumbranceManager.setDefaultEncumbranceValue(nodeChar, nEncumbrance);

	CharEncumbranceManagerCnC.updateEncumbranceState(nodeChar);
end

-------------------------------------------------------------------------------
-- ACCESSORS
-------------------------------------------------------------------------------
function areHeroPointsEnabled()
	return OptionsManager.getOption("HRXP") == "on"
end

function isGlobalDifficultyEnabled()
	return OptionsManager.getOption("GDIFF") == "on";
end

function isGmIntrusionTHresholdEnabled()
	return OptionsManager.getOption("GMIT") == "on";
end

function getMaxTarget()
	return tonumber(OptionsManager.getOption("MAXTARGET"));
end

function getDeathMarkerOnDelete()
	return OptionsManager.getOption("DEATHMARKER_ONDELETE") == "yes";
end

function getDeathMarkerOnDamage()
	return OptionsManager.getOption("DEATHMARKER_ONDAMAGE") == "yes";
end

function getDeathMarkerOnWound()
	return OptionsManager.getOption("DEATHMARKER_ONWOUND") == "yes";
end

function getXpCostToAddArc()
	return tonumber(OptionsManager.getOption("ARCCOST"));
end

function getArcStepXpReward()
	return tonumber(OptionsManager.getOption("ARCXPSTEP"));
end

function getArcClimaxSuccessXpReward()
	return tonumber(OptionsManager.getOption("ARCXPCLIMAX_SUCCESS"));
end

function getArcClimaxFailureXpReward()
	return tonumber(OptionsManager.getOption("ARCXPCLIMAX_FAILURE"));
end

function getArcResolutionXpReward()
	return tonumber(OptionsManager.getOption("ARCXPRESOLVE"));
end

function useHitMissInChat()
	return OptionsManager.getOption("HITMISS") == "yes"
end

function splitAttackAndDamageEffort()
	return OptionsManager.getOption("SPLITATKEFFORT") == "yes"
end