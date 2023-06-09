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

	-- Add the name and link to the character sheet
	DB.setValue(rAdd.nodeChar, "class.descriptor", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "class.descriptorlink", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));
end