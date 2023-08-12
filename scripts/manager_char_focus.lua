-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addFocusDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	CharFocusManager.buildAbilityPromptTable(rAdd.nodeChar, rAdd.nodeSource, 1, rAdd);

	if #(rAdd.aAbilityOptions) > 0 then
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rAdd, CharFocusManager.applyTier1);
		return;
	end

	CharFocusManager.applyTier1(rAdd)
end

function buildAbilityPromptTable(nodeChar, nodeFocus, nTier, rData)
	rData.nAbilityChoices = 1;
	rData.aAbilitiesGiven = {};
	rData.aAbilityOptions = {};

	for _, nodeability in ipairs(DB.getChildList(nodeFocus, "abilities")) do
		if DB.getValue(nodeability, "tier", 0) == nTier then
			local _, sRecord = DB.getValue(nodeability, "link");
			if DB.getValue(nodeability, "given", 0) == 1 then
				table.insert(rData.aAbilitiesGiven, sRecord);
			else	
				table.insert(rData.aAbilityOptions, {
					nTier = nTier,
					sRecord = sRecord
				});
			end
		end
	end
end

function applyTier1(rData)
	-- Notification
	CharManager.outputUserMessage("char_message_add_focus", rData.sSourceName, rData.sCharName);

	CharTrackerManager.addToTracker(
		rData.nodeChar, 
		string.format("Focus: %s", StringManager.capitalize(rData.sSourceName)), 
		"Manual");

	-- Add the name and link to the character sheet
	DB.setValue(rData.nodeChar, "class.focus", "string", rData.sSourceName);
	DB.setValue(rData.nodeChar, "class.focuslink", "windowreference", rData.sSourceClass, DB.getPath(rData.nodeSource));

	-- Give starting abilities
	CharFocusManager.addAbilities(rData);
end

function addAbilities(rData)
	for _, sAbility in ipairs(rData.aAbilitiesGiven) do
		CharAbilityManager.addAbility(rData.nodeChar, sAbility, rData.sSourceName, "Focus");
	end
end