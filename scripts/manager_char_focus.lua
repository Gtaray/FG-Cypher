-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addFocusDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	CharFocusManager.buildTier1AddTable(rAdd);

	if #(rAdd.aAbilityOptions) > 0 then
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rAdd, CharFocusManager.applyTier1);
		return;
	end

	CharFocusManager.applyTier1(rAdd)
end

function buildTier1AddTable(rAdd)
	rAdd.nAbilityChoices = 1; -- This might end up needing to be configurable
	rAdd.aAbilitiesGiven = {};
	rAdd.aAbilityOptions = {};
	for _, nodeability in ipairs(DB.getChildList(rAdd.nodeSource, "abilities")) do
		if DB.getValue(nodeability, "tier", 0) == 1 then
			local sClass, sRecord = DB.getValue(nodeability, "link");
			if DB.getValue(nodeability, "given", 0) == 1 then
				table.insert(rAdd.aAbilitiesGiven, sRecord);
			else	
				table.insert(rAdd.aAbilityOptions, sRecord);
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
	CharTypeManager.addStartingAbilities(rData);
end

function addStartingAbilities(rData)
	local rActor = ActorManager.resolveActor(rData.nodeChar);

	for _, sAbility in ipairs(rData.aAbilitiesGiven) do
		local rMod = {
			sLinkRecord = sAbility,
			sSource = string.format("%s (Focus)", StringManager.capitalize(rData.sSourceName))
		}
		rMod.sSummary = CharModManager.getAbilityModSummary(rMod)

		local nodeAbility = DB.findNode(sAbility);
		if nodeAbility then
			CharModManager.applyAbilityModification(rActor, rMod);
		end
	end
end