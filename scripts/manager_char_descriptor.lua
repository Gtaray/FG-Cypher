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
	ChatManager.SystemMessageResource("char_message_add_descriptor", rAdd.sSourceName, rAdd.sCharName);

	CharTrackerManager.addToTracker(
		rAdd.nodeChar, 
		string.format("Descriptor: %s", StringManager.capitalize(rAdd.sSourceName)), 
		"Manual");

	local sPath = "class.descriptor";
	local nOption = tonumber(OptionsManager.getOption("DESCRIPTOR_COUNT"));

	-- if we already have a first descriptor, and we're allowed 2, then pick the second
	if CharDescriptorManager.hasDescriptor(nodeChar) and nOption == 2 then
		sPath = "class.descriptor2";
	end
	DB.setValue(rAdd.nodeChar, sPath .. ".name", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, sPath .. ".link", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));

	for _, modnode in ipairs(DB.getChildList(rAdd.nodeSource, "features")) do
		local rMod = CharModManager.getModificationData(modnode)
		rMod.sSource = string.format("%s (Descriptor)", StringManager.capitalize(rAdd.sSourceName));
		CharModManager.addModificationToChar(rAdd.nodeChar, rMod, rAdd);
	end

	if (rAdd.nFloatingStats or 0) > 0 or #(rAdd.aEdgeOptions or {}) > 0 then
		-- Prompt player for the data
		rAdd.nMight = CharStatManager.getStatPool(rAdd.nodeChar, "might");
		rAdd.nSpeed = CharStatManager.getStatPool(rAdd.nodeChar, "speed");
		rAdd.nIntellect = CharStatManager.getStatPool(rAdd.nodeChar, "intellect");
		rAdd.sSource = string.format("%s (Descriptor)", StringManager.capitalize(rAdd.sSourceName));
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rAdd, CharModManager.applyFloatingStatsAndEdge);
	end
end

function hasDescriptor(nodeChar)
	return DB.getValue(nodeChar, "class.descriptor.name", "") ~= "";
end
function getDescriptorNode(nodeChar)
	local _, sRecord = DB.getValue(nodeChar, "class.descriptor.link");
	if sRecord then
		return DB.findNode(sRecord);
	end
end
function getDescriptorName(nodeChar)
	return DB.getValue(nodeChar, "class.descriptor.name")
end

function hasSecondDescriptor(nodeChar)
	return DB.getValue(nodeChar, "class.descriptor2.name", "") ~= "";
end
function getSecondDescriptorNode(nodeChar)
	local _, sRecord = DB.getValue(nodeChar, "class.descriptor2.link");
	if sRecord then
		return DB.findNode(sRecord);
	end
end
function getSecondDescriptorName(nodeChar)
	return DB.getValue(nodeChar, "class.descriptor2.name")
end