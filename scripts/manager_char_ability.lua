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

    -- Add ability to list
    local abilitylist = DB.createChild(nodeChar, "abilitylist");
    local abilitynode = DB.createChild(abilitylist);
    DB.copy(rAdd.nodeSource, abilitynode);

	-- Notification
	CharManager.outputUserMessage("char_message_add_ability", rAdd.sSourceName, rAdd.sCharName);

    -- Add to tracker
    local rActor = ActorManager.resolveActor(nodeChar);
    local rMod = {
        sProperty = "ability",
        sLinkClass = rAdd.sSourceClass,
        sLinkRecord = DB.getPath(rAdd.nodeSource)
    }
    CharTrackerManager.addToTracker(rActor, rMod);

    -- Add any modifications attached to this ability to the character as well
    for _, modnode in ipairs(DB.getChildList(rAdd.nodeSource, "features")) do
        local rData = CharModManager.getModificationData(modnode)
        rData.sSourceClass = rAdd.sSourceClass;
        CharModManager.addModificationToChar(rActor, modnode);
    end
end