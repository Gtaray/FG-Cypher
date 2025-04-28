--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
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

	self.onLinkUpdated();
	DB.addHandler(DB.getPath(getDatabaseNode(), "link"), "onUpdate", self.onLinkUpdated)
end
function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "link"), "onUpdate", self.onLinkUpdated)
	self.removeLinkDbHandler();
end

local sLastLinkedDbRecord;
function addLinkDbHandler(sRecord)
	if sLastLinkedDbRecord then
		removeLinkDbHandler();
	end

	DB.addHandler(DB.getPath(sRecord, "name"), "onUpdate", self.onNameUpdated); 
	sLastLinkedDbRecord = sRecord;
	self.onNameUpdated();
end
function removeLinkDbHandler()
	if not sLastLinkedDbRecord then
		return;
	end
	
	DB.removeHandler(DB.getPath(sLastLinkedDbRecord, "name"), "onUpdate", self.onNameUpdated);
	sLastLinkedDbRecord = nil;
end

function onLinkUpdated()
	local _, sRecord = link.getValue();
	local abilitynode = DB.findNode(sRecord)
	if not abilitynode then
		return;
	end
	self.addLinkDbHandler(sRecord);
end
function onNameUpdated()
	local _, sRecord = link.getValue();
	local abilitynode = DB.findNode(sRecord)
	if not abilitynode then
		return;
	end

	name.setValue(DB.getValue(abilitynode, "name", ""));
end

function update(bReadOnly)
	tier.setReadOnly(bReadOnly);
	given.setReadOnly(bReadOnly);
end
