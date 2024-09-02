-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addAncestryDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	-- Notification
	ChatManager.SystemMessageResource("char_message_add_ancestry", rAdd.sSourceName, rAdd.sCharName);

	CharTrackerManager.addToTracker(
		rAdd.nodeChar, 
		string.format("Ancestry: %s", StringManager.capitalize(rAdd.sSourceName)), 
		"Manual");

	-- Add the name and link to the character sheet
	DB.setValue(rAdd.nodeChar, "class.ancestry", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "class.ancestrylink", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));

	for _, modnode in ipairs(DB.getChildList(rAdd.nodeSource, "features")) do
		local rMod = CharModManager.getModificationData(modnode)
		rMod.sSource = string.format("%s (Ancestry)", StringManager.capitalize(rAdd.sSourceName));
		CharModManager.addModificationToChar(rAdd.nodeChar, rMod, rAdd);
	end

	if (rAdd.nFloatingStats or 0) > 0 or #(rAdd.aEdgeOptions or {}) > 0 then
		-- Prompt player for the data
		rAdd.nMight = ActorManagerCypher.getStatPool(rAdd.nodeChar, "might");
		rAdd.nSpeed = ActorManagerCypher.getStatPool(rAdd.nodeChar, "speed");
		rAdd.nIntellect = ActorManagerCypher.getStatPool(rAdd.nodeChar, "intellect");
		rAdd.sSource = string.format("%s (Ancestry)", StringManager.capitalize(rAdd.sSourceName));
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rAdd, CharModManager.applyFloatingStatsAndEdge);
	end
end