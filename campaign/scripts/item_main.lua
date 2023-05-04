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
	local bID = LibraryData.getIDState("item", nodeRecord);
	local bHost = Session.IsHost;
	
	if bHost then
		WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly);
	else
		WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly, true);
	end
	if (bHost or not bID) then
		WindowManager.callSafeControlUpdate(self, "nonid_notes", bReadOnly);
	else
		WindowManager.callSafeControlUpdate(self, "nonid_notes", bReadOnly, true);
	end
	
	type.setVisible(bID);
	type.setReadOnly(bReadOnly);
	type_label.setVisible(bID);
	local sType = ItemManagerCypher.getItemType(nodeRecord);
	
	local bArmor = (sType == "armor");
	local bWeapon = (sType == "weapon");
	local bCypher = (sType == "cypher");
	local bArtifact = (sType == "artifact");
	local bEquipment = (sType == "");
	
	WindowManager.callSafeControlUpdate(self, "subtype", bReadOnly, not (bID and (bArmor or bWeapon)));
	WindowManager.callSafeControlUpdate(self, "cost", bReadOnly, not (bID and (bArmor or bWeapon or bEquipment)));
	WindowManager.callSafeControlUpdate(self, "armor", bReadOnly, not (bID and bArmor));
	WindowManager.callSafeControlUpdate(self, "damage", bReadOnly, not (bID and bWeapon));
	WindowManager.callSafeControlUpdate(self, "levelroll", bReadOnly, not bCypher or (not (bID or Sesion.IsHost)));
	WindowManager.callSafeControlUpdate(self, "level", bReadOnly, not (bID and (bCypher or bArtifact)));

	depletion.setVisible(bID and bArtifact);
	depletion_label.setVisible(bID and bArtifact);
	depletion.setReadOnly(bReadOnly);
	depletiondie.setVisible(bID and bArtifact);
	depletiondie_label.setVisible(bID and bArtifact);
	depletiondie.setReadOnly(bReadOnly);

	notes.setVisible(bID);
	notes.setReadOnly(bReadOnly);
		
	divider.setVisible(bHost);
	divider2.setVisible(bID);
end

function actionDepletion(draginfo)
	local node = getDatabaseNode();
	local sName = DB.getValue(node, "name", "");
	local sDepletionDie = DB.getValue(node, "depletiondie", "");
	local nDepletion = DB.getValue(node, "depletion", 0);
	
	local rRoll = {};
	rRoll.sDesc = string.format("[%s] %s", Interface.getString("depletion_tag"), sName);
	rRoll.sType = "depletion";
	rRoll.aDice = {};
	rRoll.nMod = 0;

	if sDepletionDie ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " (" .. nDepletion .. " " .. Interface.getString("item_label_depletionin") .. " 1" .. sDepletionDie .. ")";
		table.insert(rRoll.aDice, sDepletionDie);
	elseif draginfo then
		draginfo.setType("number");
		draginfo.setDescription(rRoll.sDesc);
		draginfo.setNumberData(nDepletion);
		return;
	else
		rRoll.nMod = nDepletion;
	end
	
	ActionsManager.performAction(draginfo, nil, rRoll);
end
