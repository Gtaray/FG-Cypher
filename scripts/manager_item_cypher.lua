function onInit()
	ItemManager.registerCleanupTransferHandler(onItemTransfer);
end

function onItemTransfer(rSource, rTemp, rTarget)
	-- Handle automatically rolling levels for cyphers
	if rSource.sType == "item" and (rTarget.sType == "treasureparcel" or rTarget.sType == "charsheet" or rTarget.sType == "partysheet") then
		ItemManagerCypher.generateCypherLevel(rTemp.node, false);
	end
end

function getItemType(itemNode)
	return DB.getValue(itemNode, "type", "");
end

function isItemCypher(itemNode)
	return ItemManagerCypher.getItemType(itemNode) == "cypher";
end

function getItemName(itemNode)
	return DB.getValue(itemNode, "name", "");
end

----------------------------------------------------------------------
-- ARMOR
----------------------------------------------------------------------

function isItemArmor(itemNode)
	return ItemManagerCypher.getItemType(itemNode) == "armor";
end

function getArmorType(itemNode)
	if not ItemManagerCypher.isItemArmor(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "armortype", "");
end

function getArmorBonus(itemNode)
	if not itemNode then
		return 0;
	end

	if not ItemManagerCypher.isItemArmor(itemNode) then
		return 0;
	end

	return DB.getValue(itemNode, "armor", 0);
end

function getArmorSpeedAsset(itemNode)
	if not itemNode then
		return 0;
	end

	if ItemManagerCypher.getArmorType(itemNode) ~= "shield" then
		return 0;
	end

	return tonumber(DB.getValue(itemNode, "shieldbonus", "0")) or 0;
end

----------------------------------------------------------------------
-- WEAPON
----------------------------------------------------------------------

function isItemWeapon(itemNode)
	return ItemManagerCypher.getItemType(itemNode) == "weapon";
end

function getWeaponType(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "weapontype", "");
end

function getWeaponAttackStat(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "attackstat", "");
end

function getWeaponDefenseStat(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "defensestat", "");
end

function getWeaponAttackRange(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "atkrange", "");
end

function getWeaponAsset(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "asset", 0);
end

function getWeaponModifier(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "modifier", 0);
end

function getWeaponDamageStat(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "damagestat", "");
end

function getWeaponDamage(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "damage", 0);
end

function getWeaponPiercing(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return -1;
	end

	local bUsePiercing = DB.getValue(itemNode, "pierce", "") == "yes";
	if bUsePiercing then
		return DB.getValue(itemNode, "pierceamount", -1);
	end

	-- If piercing is disabled, then we return a negative value
	-- because a 0 means ignore all armor
	return -1;
end

----------------------------------------------------------------------
-- CYPHER
----------------------------------------------------------------------

function generateCypherLevel(itemNode, bOverrideLevel)
	-- No matter what, we don't do this for non-cyphers
	if not ItemManagerCypher.isItemCypher(itemNode) then
		return 0;
	end

	-- Only set the level if nLevel is 0 OR if bOverrideLevel is true
	-- This tests the negative case of that
	local nLevel = DB.getValue(itemNode, "level", 0);
	if not bOverrideLevel and nLevel ~= 0 then
		return nLevel;
	end

	-- We can only roll the level if the levelroll value is actually a dice string
	local sLevelRoll = DB.getValue(itemNode, "levelroll", "");
	if not StringManager.isDiceString(sLevelRoll) then
		return nLevel;
	end

	nLevel = StringManager.evalDiceString(sLevelRoll, true);
	DB.setValue(itemNode, "level", "number", nLevel);

	return nLevel;
end