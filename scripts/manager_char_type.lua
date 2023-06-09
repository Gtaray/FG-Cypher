-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addTypeDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	-- Notification
	CharManager.outputUserMessage("char_message_add_type", rAdd.sSourceName, rAdd.sCharName);

	-- Add the name and link to the character sheet
	DB.setValue(rAdd.nodeChar, "class.type", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "class.typelink", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));
end