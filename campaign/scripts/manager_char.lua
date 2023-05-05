-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManager.setCustomCharAdd(onCharItemAdd);
end

function onCharItemAdd(nodeItem)
	self.addWeaponToAttackList(nodeItem);
end

-- Adds a item (that is a weapon) to the character's attacklist
function addWeaponToAttackList(itemnode)
	-- Parameter validation
	if not ItemManagerCypher.isItemWeapon(itemnode) then
		return;
	end
	
	-- Get the weapon list we are going to add to
	local nodeChar = DB.getChild(itemnode, "...");
	local nodeAttacks = DB.createChild(nodeChar, "attacklist");
	if not nodeAttacks then
		return;
	end

	local attacknode = DB.createChild(nodeAttacks);
	if not attacknode then
		return;
	end

	DB.setValue(attacknode, "name", "string", ItemManagerCypher.getItemName(itemnode));
	DB.setValue(attacknode, "weapontype", "string", ItemManagerCypher.getWeaponType(itemnode));
	DB.setValue(attacknode, "stat", "string", ItemManagerCypher.getWeaponAttackStat(itemnode));
	DB.setValue(attacknode, "defensestat", "string", ItemManagerCypher.getWeaponDefenseStat(itemnode));
	DB.setValue(attacknode, "atkrange", "string", ItemManagerCypher.getWeaponAttackRange(itemnode));
	DB.setValue(attacknode, "asset", "number", ItemManagerCypher.getWeaponAsset(itemnode));
	DB.setValue(attacknode, "modifier", "number", ItemManagerCypher.getWeaponModifier(itemnode));
	DB.setValue(attacknode, "damage", "number", ItemManagerCypher.getWeaponDamage(itemnode));
	DB.setValue(attacknode, "damagestat", "string", ItemManagerCypher.getWeaponDamageStat(itemnode));

	local nPiercing = ItemManagerCypher.getWeaponPiercing(itemnode);
	if nPiercing >= 0 then
		DB.setValue(attacknode, "pierce", "string", "yes");
		DB.setValue(attacknode, "pierceamount", "number", nPiercing);
	end

	Debug.chat(DB.getPath(itemnode));
	DB.setValue(attacknode, "source", "windowreference", "item", DB.getPath(itemnode));
end

function updateCyphers(nodeChar)
	local nCypherTotal = 0;

	for _,vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "type", "") == "cypher" then
			nCypherTotal = nCypherTotal + 1;
		end
	end

	DB.setValue(nodeChar, "cypherload", "number", nCypherTotal);
end

--
-- ACTIONS
--

function rest(nodeChar)
	DB.setValue(nodeChar, "recoveryused", "number", 0);
end
