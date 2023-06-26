-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addDescriptorDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	-- Notification
	CharManager.outputUserMessage("char_message_add_descriptor", rAdd.sSourceName, rAdd.sCharName);

	CharTrackerManager.addToTracker(
		rAdd.nodeChar, 
		string.format("Descriptor: %s", StringManager.capitalize(rAdd.sSourceName)), 
		"Manual");

	-- Add the name and link to the character sheet
	DB.setValue(rAdd.nodeChar, "class.descriptor", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "class.descriptorlink", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));

	for _, modnode in ipairs(DB.getChildList(rAdd.nodeSource, "features")) do
		local rMod = CharModManager.getModificationData(modnode)
		rMod.sSource = string.format("%s (Descriptor)", StringManager.capitalize(rAdd.sSourceName));
		CharModManager.addModificationToChar(rAdd.nodeChar, rMod);
	end
end