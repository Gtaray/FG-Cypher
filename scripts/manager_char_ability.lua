-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addAbilityDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

    -- if for some reason we don't have a source node, then bail
    if not rAdd.nodeSource then
        return;
    end

	-- Notification
	CharManager.outputUserMessage("char_message_add_ability", rAdd.sSourceName, rAdd.sCharName);

    -- Add ability (via the character modification system)
	CharModManager.addModificationToChar(nodeChar, {
		sProperty = "ability",
		sLinkRecord = DB.getPath(rAdd.nodeSource),
		sLinkClass = "ability",
		sSource = "Manual"
	});
end