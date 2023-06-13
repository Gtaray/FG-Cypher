local sLastLinkedDbRecord;

function onInit()
	DB.addHandler(DB.getPath(getDatabaseNode(), "link"), "onUpdate", onLinkUpdated)

	local _, sRecord = link.getValue();
	if sRecord then
		addLinkDbHandler(sRecord);
	end
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "link"), "onUpdate", onLinkUpdated)
	removeLinkDbHandler();
end

function addLinkDbHandler(sRecord)
	if sLastLinkedDbRecord then
		removeLinkDbHandler();
	end

	DB.addHandler(DB.getPath(sRecord, "name"), "onUpdate", onLinkUpdated); 
	sLastLinkedDbRecord = sRecord;
end

function removeLinkDbHandler()
	if not sLastLinkedDbRecord then
		return;
	end
	
	DB.removeHandler(DB.getPath(sLastLinkedDbRecord, "name"), "onUpdate", onLinkUpdated);
	sLastLinkedDbRecord = nil;
end

function onLinkUpdated()
	local _, sRecord = link.getValue();
	local abilitynode = DB.findNode(sRecord)
	if not abilitynode then
		return;
	end

	name.setValue(DB.getValue(abilitynode, "name", ""));
	addLinkDbHandler(sRecord);
end