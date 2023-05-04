-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);
	
	local bSection1 = false;
	if Session.IsHost then
		if WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly, true);
	end
	divider.setVisible(bSection1);
	
	level.setReadOnly(bReadOnly);
	
	hp.setReadOnly(bReadOnly);
	damagestr.setReadOnly(bReadOnly);
	WindowManager.callSafeControlUpdate(self, "armor", bReadOnly);
	move.setReadOnly(bReadOnly);
	WindowManager.callSafeControlUpdate(self, "modifications", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "combat", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "intrusion", bReadOnly);

	updateActions(bReadOnly);
end

function updateActions(bReadOnly)
	-- Update all actions
	if bReadOnly then
		actions_iedit.setValue(0);
	end

	actions_iedit.setVisible(not bReadOnly);
	actions_iadd.setVisible(not bReadOnly);

	for _,w in ipairs(actions.getWindows()) do
		w.name.setReadOnly(bReadOnly);
		w.desc.setReadOnly(bReadOnly);
	end
end

function updateResistances(bReadOnly)
	local bShowResistances = (resistances.getWindowCount() ~= 0);

	-- Update the edit and add buttons
	if bReadOnly then
		resistances_iedit.setValue(0);
	end

	resistances_iedit.setVisible(not bReadOnly);
	resistances_iadd.setVisible(not bReadOnly);
	-- Only show this section if we're in edit mode OR if the list isn't empty
	header_resistances.setVisible((not bReadOnly) or bShowResistances);
	resistances.setVisible((not bReadOnly) or bShowResistances);

	-- Update all resistance subwindows
	for _,w in ipairs(resistances.getWindows()) do
		w.damagetype.setReadOnly(bReadOnly);
		w.type.setReadOnly(bReadOnly);
		w.amount.setReadOnly(bReadOnly);
	end
end