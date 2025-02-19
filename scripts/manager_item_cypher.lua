function onInit()
	ItemManager.registerCleanupTransferHandler(onItemTransfer);
end

function onItemTransfer(rSource, rTemp, rTarget)
	-- Handle automatically rolling levels for cyphers
	if rSource.sClass == "item" and (rTarget.sType == "treasureparcel" or rTarget.sType == "charsheet" or rTarget.sType == "partysheet") then
		CypherManager.generateCypherLevel(rTemp.node, false);
	end

	if rSource.sClass == "item" then
		local _tCustomStatFields = {
			"coststat",
			"stat",
			"attackstat",
			"defensestat",
			"damagestat",
			"healstat",
		}

		if rTarget.sType == "charsheet" then
			-- Migrate the attack/defense/damage stats if necessary
			if DB.getValue(rSource.node, "attackstat", "") == "custom" then
				local sCustomStat = DB.getValue(rSource.node, "attackstat_custom", "");
				DB.setValue(rTemp.node, "attackstat", "string", sCustomStat:lower());
			end
			if DB.getValue(rSource.node, "defensestat", "") == "custom" then
				local sCustomStat = DB.getValue(rSource.node, "defensestat_custom", "");
				DB.setValue(rTemp.node, "defensestat", "string", sCustomStat:lower());
			end
			if DB.getValue(rSource.node, "damagestat", "") == "custom" then
				local sCustomStat = DB.getValue(rSource.node, "damagestat_custom", "");
				DB.setValue(rTemp.node, "damagestat", "string", sCustomStat:lower());
			end

			-- Migrate all custom stats used by actions
			for _, actionnode in ipairs(DB.getChildList(rTemp.node, "actions")) do		
				for _, sField in ipairs(_tCustomStatFields) do
					if DB.getValue(actionnode, sField, "") == "custom" then
						DB.setValue(actionnode, sField, "string", DB.getValue(actionnode, sField .. "_custom"):lower());
					end
				end
			end
		else
			local aNonCustomValues = { "", "might", "speed", "intellect" };

			-- If the item uses custom stats, we need to set the cyclers back to "custom"
			if not StringManager.contains(aNonCustomValues, DB.getValue(rSource.node, "attackstat", "")) then
				DB.setValue(rTemp.node, "attackstat", "string", "custom");
			end
			if not StringManager.contains(aNonCustomValues, DB.getValue(rSource.node, "defensestat", "")) then
				DB.setValue(rTemp.node, "defensestat", "string", "custom");
			end
			if not StringManager.contains(aNonCustomValues, DB.getValue(rSource.node, "damagestat", "")) then
				DB.setValue(rTemp.node, "damagestat", "string", "custom");
			end

			-- Migrate all custom stats used by actions
			for _, actionnode in ipairs(DB.getChildList(rTemp.node, "actions")) do		
				for _, sField in ipairs(_tCustomStatFields) do
					if not StringManager.contains(aNonCustomValues, DB.getValue(actionnode, sField, "")) then
						DB.setValue(actionnode, sField, "string", "custom");
					end
				end
			end
		end
	end
end

----------------------------------------------------------------------
-- DATA MIGRATION
----------------------------------------------------------------------
function migrateArmorAndWeaponItemTypes(nodeItem)
	local sType = ItemManagerCypher.getItemType(nodeItem);

	if sType == "weapon" then
		DB.setValue(nodeItem, "type", "string", "")
		DB.setValue(nodeItem, "subtype", "string", "weapon")
	end

	if sType == "armor" then
		DB.setValue(nodeItem, "type", "string", "")
		DB.setValue(nodeItem, "subtype", "string", "armor")
	end
end

-------------------------------------------------------------------------
-- ACCESSORS
----------------------------------------------------------------------
function isCarried(itemnode)
	return DB.getValue(itemnode, "carried", 0) >= 1;
end

function isEquipped(itemnode)
	return DB.getValue(itemnode, "carried", 0) == 2;
end

function hasActions(itemnode)
	return (DB.getChildCount(itemnode, "actions") or 0) > 0;
end

function getItemType(itemNode)
	return DB.getValue(itemNode, "type", "");
end

function getItemSubtype(itemNode)
	return DB.getValue(itemNode, "subtype", "");
end

function isItemCypher(itemNode)
	return ItemManagerCypher.getItemType(itemNode) == "cypher";
end

function isItemArtifact(itemNode)
	return ItemManagerCypher.getItemType(itemNode) == "artifact";
end

function getItemName(itemNode)
	return DB.getValue(itemNode, "name", "");
end

----------------------------------------------------------------------
-- ARMOR
----------------------------------------------------------------------

function isItemArmor(itemNode)
	return ItemManagerCypher.getItemSubtype(itemNode) == "armor";
end

function isItemShield(itemNode)
	return DB.getValue(itemNode, "armortype", "") == "shield"
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

function getSpeedEffortPenalty(itemNode)
	if not itemNode then
		return 0;
	end

	if not ItemManagerCypher.isItemArmor(itemNode) then
		return 0;
	end

	return DB.getValue(itemNode, "speedpenalty", 0);
end

----------------------------------------------------------------------
-- WEAPON
----------------------------------------------------------------------

function isItemWeapon(itemNode)
	return ItemManagerCypher.getItemSubtype(itemNode) == "weapon";
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

function getWeaponDamageType(itemNode)
	if not ItemManagerCypher.isItemWeapon(itemNode) then
		return "";
	end

	return DB.getValue(itemNode, "damagetype", "");
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