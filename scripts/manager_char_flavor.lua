-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addFlavorDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	-- Notification
	CharManager.outputUserMessage("char_message_add_flavor", rAdd.sSourceName, rAdd.sCharName);

	CharTrackerManager.addToTracker(
		rAdd.nodeChar, 
		string.format("Flavor: %s", StringManager.capitalize(rAdd.sSourceName)), 
		"Manual");

	-- Add the name and link to the character sheet
	DB.setValue(rAdd.nodeChar, "class.flavor", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "class.flavorlink", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));
end