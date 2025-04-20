-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManagerCypher.migrateArmorAndWeaponItemTypes(getDatabaseNode());
	update();
end

-- This is needed to handle updating cyclers, which callSafeControlUpdate doesn't work with
-- because cyclers don't implement the correct update function
function updateControl(sControlName, bReadOnly, bHide)
	if (sControlName or "") == "" then
		return;
	end

	if self[sControlName] then
		self[sControlName].setReadOnly(bReadOnly);
		self[sControlName].setVisible(not bHide);
	end
	if self[sControlName .. "_label"] then
		self[sControlName .. "_label"].setVisible(not bHide);
	end
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("item", nodeRecord);
	local bHost = Session.IsHost;
	
	if (bHost or not bID) then
		WindowManager.callSafeControlUpdate(self, "nonid_notes", bReadOnly);
	else
		WindowManager.callSafeControlUpdate(self, "nonid_notes", bReadOnly, true);
	end
	updateControl("cost", bReadOnly, not bID);
	updateControl("subtype", bReadOnly, false);
	
	type.setVisible(bID);
	type.setReadOnly(bReadOnly);
	type_label.setVisible(bID);
	local sType = ItemManagerCypher.getItemType(nodeRecord);
	
	local bArmor = ItemManagerCypher.isItemArmor(nodeRecord)
	local bWeapon = ItemManagerCypher.isItemWeapon(nodeRecord);
	local bCypher = ItemManagerCypher.isItemCypher(nodeRecord)
	local bArtifact = ItemManagerCypher.isItemArtifact(nodeRecord)

	-- WEAPON PROPERTIES
	local bPierce = ItemManagerCypher.getWeaponPiercing(getDatabaseNode()) >= 0;
	updateControl("weapontype", bReadOnly, not bWeapon);
	updateControl("header_attack", true, not (bID and bWeapon)); -- Always readonly
	updateControl("attackstat", bReadOnly, not (bID and bWeapon));
	updateControl("defensestat", bReadOnly, not (bID and bWeapon));
	updateControl("atkrange", bReadOnly, not (bID and bWeapon));
	updateControl("asset", bReadOnly, not (bID and bWeapon));
	updateControl("modifier", bReadOnly, not (bID and bWeapon));
	updateControl("header_damage", true, not (bID and bWeapon)); -- Always readonly
	updateControl("damagestat", bReadOnly, not (bID and bWeapon));
	updateControl("damage", bReadOnly, not (bID and bWeapon));
	updateControl("pierce", bReadOnly, not (bID and bWeapon));
	updateControl("pierceamount", bReadOnly, not (bID and bWeapon and bPierce));
	WindowManager.callSafeControlUpdate(self, "damagetype", bReadOnly, not (bID and bWeapon));

	updateControl("attackstat_custom", bReadOnly, not (bID and bWeapon and attackstat.getValue() == "CUSTOM"));
	updateControl("defensestat_custom", bReadOnly, not (bID and bWeapon and defensestat.getValue() == "CUSTOM"));
	updateControl("damagestat_custom", bReadOnly, not (bID and bWeapon and damagestat.getValue() == "CUSTOM"));

	-- ARMOR PROPERTIES
	local bShield = ItemManagerCypher.getArmorType(nodeRecord) == "shield";
	updateControl("armortype", bReadOnly, not bArmor);
	updateControl("shieldbonus", bReadOnly, not (bID and bArmor and bShield));
	updateControl("armor", bReadOnly, not (bID and bArmor and not bShield));
	updateControl("speedpenalty", bReadOnly, not bArmor);

	-- CYPHER PROPERTIES
	WindowManager.callSafeControlUpdate(self, "levelroll", bReadOnly, not (bCypher or bArtifact) or not Session.IsHost);
	WindowManager.callSafeControlUpdate(self, "level", bReadOnly, not (bID and (bCypher or bArtifact)));

	-- ARTIFACT PROPERTIES
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

function updateArmorValue()
	local node = getDatabaseNode();
	if not ItemManagerCypher.isItemArmor(node) then
		return;
	end

	local sType = ItemManagerCypher.getArmorType(node);

	-- if speed penalty is set to 0 or the default value for its type
	-- then we update the value
	local nPenalty = speedpenalty.getValue();
	if sType == "light" and (nPenalty == 0 or nPenalty == 3 or nPenalty == 4) then
		speedpenalty.setValue(2);
	elseif sType == "medium" and (nPenalty == 0 or nPenalty == 2 or nPenalty == 4) then
		speedpenalty.setValue(3);
	elseif sType == "heavy" and (nPenalty == 0 or nPenalty == 2 or nPenalty == 3) then
		speedpenalty.setValue(4);
	else
		speedpenalty.setValue(0);
	end

	if sType == "shield" then
		return;
	end

	-- Guaranteed to be an armor that's not a shield
	local nArmor = armor.getValue();
	-- if armor is set to 0 or the default armor value for its type
	-- then we update the armor value
	if sType == "light" and (nArmor == 0 or nArmor == 2 or nArmor == 3) then
		armor.setValue(1);
	elseif sType == "medium" and (nArmor == 0 or nArmor == 1 or nArmor == 3) then
		armor.setValue(2);
	elseif sType == "heavy" and (nArmor == 0 or nArmor == 1 or nArmor == 2) then
		armor.setValue(3);
	elseif sType == "" and (nArmor == 1 or nArmor == 2 or nArmor == 3) then
		armor.setValue(0);
	end	
end

function updateDamageValue()
	local node = getDatabaseNode();
	if not ItemManagerCypher.isItemWeapon(node) then
		return;
	end
	
	local sType = ItemManagerCypher.getWeaponType(node);

	-- Guaranteed to be an armor that's not a shield
	local nDamage = damage.getValue();
	-- if armor is set to 0 or the default armor value for its type
	-- then we update the armor value
	if sType == "light" and (nDamage == 0 or nDamage == 4 or nDamage == 6) then
		damage.setValue(2);
	elseif sType == "medium" and (nDamage == 0 or nDamage == 2 or nDamage == 6) then
		damage.setValue(4);
	elseif sType == "heavy" and (nDamage == 0 or nDamage == 2 or nDamage == 4) then
		damage.setValue(6);
	elseif sType =="" and (nDamage == 2 or nDamage == 4 or nDamage == 6) then
		damage.setValue(0);
	end
end

function onPierceChanged()
	local bPierce = ItemManagerCypher.getWeaponPiercing(getDatabaseNode()) >= 0;
	pierceamount.setVisible(bPierce);
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
