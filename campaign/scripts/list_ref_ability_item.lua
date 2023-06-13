local sLastLinkedDbRecord;

function onInit()
	DB.addHandler(DB.getPath(getDatabaseNode(), "link"), "onUpdate", onLinkUpdated)

	local _, sRecord = link.getValue();
	if sRecord then
		addLinkDbHandler(sRecord);
	end

	-- Hide 'tier' and 'given' controls based on windowlist properties
	-- If tiers are hidden, we fore the value to 0 so that it doesn't affect
	-- future automation
	if windowlist.hidetier then
		tier.setValue(0);
		tier.setVisible(false);
	end

	if windowlist.hidegiven then
		given.setVisible(false)
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

function update(bReadOnly)
	tier.setReadOnly(bReadOnly);
	given.setReadOnly(bReadOnly);
end