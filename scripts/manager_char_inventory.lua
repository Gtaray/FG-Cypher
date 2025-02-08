function onInit()
	ItemManager.setCustomCharAdd(onCharItemAdd);
	-- Overriding char_invitem.onDelete instead of this, because this throws errors
	ItemManager.setCustomCharRemove(onCharItemRemoved);

	if Session.IsHost then
		DB.addHandler(DB.getPath("charsheet.*.inventorylist.*"), "onDelete", onItemDeleted);
		DB.addHandler(DB.getPath("charsheet.*.abilitylist.*"), "onDelete", onAbilityDeleted);
		DB.addHandler(DB.getPath("charsheet.*.attacklist.*"), "onDelete", onAttackDeleted);
	end
end

function onClose()
	if Session.IsHost then
		if Session.IsHost then
			DB.removeHandler(DB.getPath("charsheet.*.inventorylist.*"), "onDelete", onItemDeleted);
			DB.removeHandler(DB.getPath("charsheet.*.abilitylist.*"), "onDelete", onAbilityDeleted);
			DB.removeHandler(DB.getPath("charsheet.*.attacklist.*"), "onDelete", onAttackDeleted);
		end
	end
end

local _aDeleting = {}
function onItemDeleted(node)
	if not Session.IsHost then
		return;
	end

	-- To prevent recursive events
	local sCharNode = DB.getPath(DB.getChild(node, "..."));
	if _aDeleting[sCharNode] then
		return;
	end

	_aDeleting[sCharNode] = true;

	CharInventoryManager.removeAttackLinkedToRecord(node);
	CharInventoryManager.removeAbilityLinkedToRecord(node);

	_aDeleting[sCharNode] = false;
end

function onAbilityDeleted(node)
	if not Session.IsHost then
		return;
	end
	
	-- To prevent recursive events
	local sCharNode = DB.getPath(DB.getChild(node, "..."));
	if _aDeleting[sCharNode] then
		return;
	end

	_aDeleting[sCharNode] = true;

	local itemnode = CharInventoryManager.getItemLinkedToRecord(node)
	CharInventoryManager.removeAttackLinkedToRecord(itemnode)
	CharInventoryManager.removeItemLinkedToRecord(node);

	_aDeleting[sCharNode] = false;
end

function onAttackDeleted(node)
	if not Session.IsHost then
		return;
	end
	
	-- To prevent recursive events
	local sCharNode = DB.getPath(DB.getChild(node, "..."));
	if _aDeleting[sCharNode] then
		return;
	end

	_aDeleting[sCharNode] = true;

	local itemnode = CharInventoryManager.getItemLinkedToRecord(node)
	CharInventoryManager.removeAbilityLinkedToRecord(itemnode)
	CharInventoryManager.removeItemLinkedToRecord(node);

	_aDeleting[sCharNode] = false;
end

function onCharItemAdd(nodeItem)
	if ItemManagerCypher.isItemWeapon(nodeItem) then
		CharInventoryManager.addItemAsWeapon(nodeItem);
	end

	-- If the item being added to the PC's inventory has actions, create
	-- an entry in the ability list for it
	if DB.getChildCount(nodeItem, "actions") > 0 then
		CharInventoryManager.addItemAsAbility(nodeItem)
	end
end

function onCharItemRemoved(nodeItem)
	CharInventoryManager.removeAbilityLinkedToRecord(nodeItem);
	CharInventoryManager.removeAttackLinkedToRecord(nodeItem);
end

function updateCyphers(nodeChar)
	local nCypherTotal = 0;

	for _,vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "type", "") == "cypher" then
			if DB.getValue(vNode, "carried", 0) ~= 0 then
				nCypherTotal = nCypherTotal + DB.getValue(vNode, "count", 0);
			end
		end
	end

	DB.setValue(nodeChar, "cypherload", "number", nCypherTotal);
	CharInventoryManager.onCypherLoadChanged(nodeChar);
end

function onCypherLoadChanged(nodeChar)
	WindowManager.callInnerWindowFunction(Interface.findWindow("charsheet", nodeChar), "onCypherLoadChanged");
end

-------------------------------------------------------------------------------
--- GENERIC GETTERS
-------------------------------------------------------------------------------
function getItemsOfTypeInInventory(rActor, sType)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end

	local nodes = {};
	for _,vNode in ipairs(DB.getChildList(nodeActor, "inventorylist")) do
		if ItemManagerCypher.getItemType(vNode) == sType then
			table.insert(nodes, vNode);
		end
	end

	return nodes;
end

function getArmorInInventory(rActor)
	return CharInventoryManager.getItemsOfTypeInInventory(rActor, "armor");
end

-------------------------------------------------------------------------------
--- EQUIPPED ARMOR
-------------------------------------------------------------------------------
function calculateEquippedArmor(rActor)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end

	local nArmor = 0;
	for _, node in ipairs(DB.getChildList(nodeActor, "inventorylist")) do
		if ItemManagerCypher.isEquipped(node) and ItemManagerCypher.isItemArmor(node) and not ItemManagerCypher.isItemShield(node) then
			nArmor = nArmor + ItemManagerCypher.getArmorBonus(node);
		end
	end
	return nArmor;
end

function calculateEquippedSpeedEffortPenalties(rActor)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end

	local nSpeedPenalty = 0;
	for _, node in ipairs(DB.getChildList(nodeActor, "inventorylist")) do
		if ItemManagerCypher.isEquipped(node) and ItemManagerCypher.isItemArmor(node) then
			nSpeedPenalty = nSpeedPenalty + ItemManagerCypher.getSpeedEffortPenalty(node);
		end
	end
	return nSpeedPenalty;
end

-------------------------------------------------------------------------------
--- EQUIPPED WEAPON
-------------------------------------------------------------------------------
function getEquippedWeaponNode(nodeActor)
	for _, node in ipairs(DB.getChildList(nodeActor, "attacklist")) do
		if DB.getValue(node, "equipped", 0) == 1 then
			return node;
		end
	end
end

function getEquippedWeapon(nodeActor)
	local node = CharInventoryManager.getEquippedWeaponNode(nodeActor);
	if not node then
		return {};
	end

	local rWeapon = {};
	rWeapon.sLabel = DB.getValue(node, "name", "");
	rWeapon.sStat = RollManager.resolveStat(DB.getValue(node, "stat", ""));
	rWeapon.sDefenseStat = RollManager.resolveStat(DB.getValue(node, "defensestat", ""), "speed");
	rWeapon.sAttackRange = DB.getValue(node, "atkrange", "");
	rWeapon.nTraining = DB.getValue(node, "training", 1);
	rWeapon.nAssets = DB.getValue(node, "asset", 0);
	rWeapon.nModifier = DB.getValue(node, "modifier", 0);

	rWeapon.nDamage = DB.getValue(node, "damage", 0);
	rWeapon.sDamageStat = RollManager.resolveStat(DB.getValue(node, "damagestat", ""));
	--rWeapon.sDamageType = DB.getValue(node, "damagetype", "");
	rWeapon.bPierce = DB.getValue(node, "pierce", "") == "yes";
	rWeapon.sWeaponType = DB.getValue(node, "weapontype", "");

	if rWeapon.bPierce then
		rWeapon.nPierceAmount = DB.getValue(node, "pierceamount", 0);	
	end

	return rWeapon;
end

function setEquippedWeapon(nodeActor, nodeWeapon)
	local sWeaponNode = DB.getName(nodeWeapon)
	for _, node in ipairs(DB.getChildList(nodeActor, "attacklist")) do
		local itemnode = CharInventoryManager.getItemLinkedToRecord(node);
		local nEquipped = DB.getValue(itemnode, "carried", 0);

		-- Set every weapon other than the specified one to unequipped
		-- skipping any weapons that aren't equipped or carried
		if nEquipped ~= 0 and DB.getName(node) ~= sWeaponNode then
			DB.setValue(node, "equipped", "number", 0);
		end
	end
end

-------------------------------------------------------------------------------
--- ITEM LINKING
-------------------------------------------------------------------------------
-- Adds a item (that is a weapon) to the character's attacklist
function addItemAsWeapon(itemnode)
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
	DB.setValue(attacknode, "damagetype", "string", ItemManagerCypher.getWeaponDamageType(itemnode));

	local nPiercing = ItemManagerCypher.getWeaponPiercing(itemnode);
	if nPiercing >= 0 then
		DB.setValue(attacknode, "pierce", "string", "yes");
		DB.setValue(attacknode, "pierceamount", "number", nPiercing);
	end

	CharInventoryManager.linkAttackAndItem(itemnode, attacknode);

	return attacknode;
end

function addItemAsAbility(itemnode)
	-- Get the weapon list we are going to add to
	local nodeChar = DB.getChild(itemnode, "...");
	local nodeAbilities = DB.createChild(nodeChar, "abilitylist");
	if not nodeAbilities then
		return;
	end

	local abilitynode = DB.createChild(nodeAbilities);
	if not abilitynode then
		return;
	end

	DB.setValue(abilitynode, "name", "string", ItemManagerCypher.getItemName(itemnode));

	local sItemType = StringManager.capitalize(ItemManagerCypher.getItemType(itemnode) or "");
	if sItemType ~= "" then
		DB.setValue(abilitynode, "type", "string", sItemType);
	end

	if ItemManagerCypher.isItemWeapon(itemnode) then
		DB.setValue(abilitynode, "useequipped", "string", "yes");
	end

	local actions = DB.getChild(itemnode, "actions");
	if actions then
		DB.copyNode(actions, DB.createChild(abilitynode, "actions"));
	end

	local sDesc = DB.getValue(itemnode, "notes", "")
	if sDesc ~= "" then
		DB.setValue(abilitynode, "ftdesc", "formattedtext", sDesc)
	end

	-- Set the ability's group so it shows up in its own section on the actions tab
	DB.setValue(abilitynode, "group", "string", "Items");

	-- Save links between the item and ability
	-- These are used so that if one is deleted, so is the other.
	CharInventoryManager.linkAbilityAndItem(itemnode, abilitynode);

	return abilitynode;
end

function linkAttackAndItem(nodeitem, nodeattack)
	if not nodeitem then
		return
	end
	if not nodeattack then
		return
	end
	if not ItemManagerCypher.isItemWeapon(nodeitem) then
		return;
	end

	-- Ensure that the attack and item are both on the same character sheet
	-- Otherwise we could link to an item not owned by the player, which will break things
	-- when we delete it
	local s1 = DB.getName(DB.getChild(nodeitem, "..."));
	local s2 = DB.getName(DB.getChild(nodeattack, "..."));
	if s1 ~= s2 then
		return
	end

	DB.setValue(nodeitem, "attacklink", "windowreference", "char_weapon", DB.getPath(nodeattack));
	DB.setValue(nodeattack, "itemlink", "windowreference", "item", DB.getPath(nodeitem));
end
function linkAbilityAndItem(nodeitem, nodeability)
	if not nodeitem then
		return
	end
	if not nodeability then
		return
	end

	-- Ensure that the attack and item are both on the same character sheet
	-- Otherwise we could link to an item not owned by the player, which will break things
	-- when we delete it
	local s1 = DB.getName(DB.getChild(nodeitem, "..."));
	local s2 = DB.getName(DB.getChild(nodeability, "..."));
	if s1 ~= s2 then
		return
	end

	DB.setValue(nodeitem, "abilitylink", "windowreference", "ability", DB.getPath(nodeability));
	DB.setValue(nodeability, "itemlink", "windowreference", "item", DB.getPath(nodeitem));
end

function getAttackLinkedToRecord(noderecord)
	local _, sRecord = DB.getValue(noderecord, "attacklink", "", "");
	return DB.findNode(sRecord)
end
function clearAttackLinkedToRecord(noderecord)
	if not noderecord then
		return
	end
	if not ItemManagerCypher.isItemWeapon(noderecord) then
		return;
	end
	DB.setValue(noderecord, "attacklink", "windowreference", "", "");
end
function removeAttackLinkedToRecord(noderecord)
	CharInventoryManager.removeLinkedRecord(noderecord, "attacklink");
end

function getAbilityLinkedToRecord(noderecord)
	local _, sRecord = DB.getValue(noderecord, "abilitylink", "", "");
	return DB.findNode(sRecord)
end
function clearAbilityLinkedToRecord(noderecord)
	if not noderecord then
		return
	end
	DB.setValue(noderecord, "abilitylink", "windowreference", "", "");
end
function removeAbilityLinkedToRecord(noderecord)
	CharInventoryManager.removeLinkedRecord(noderecord, "abilitylink");
end

function getItemLinkedToRecord(noderecord)
	local _, sRecord = DB.getValue(noderecord, "itemlink", "", "");
	return DB.findNode(sRecord)
end
function clearItemLinkedToRecord(noderecord)
	if not noderecord then
		return
	end
	DB.setValue(noderecord, "itemlink", "windowreference", "", "");
end
function removeItemLinkedToRecord(noderecord)
	CharInventoryManager.removeLinkedRecord(noderecord, "itemlink");
end

function removeLinkedRecord(sourcenode, sPath)
	-- For some reason when an item is moved to the party sheet the onRemove event
	-- fires twice, but by the time we get here the sourcenode is already deleted
	-- (due to async processing I think), so we just need to check that sourcenode is
	-- valid before running this.
	if not sourcenode or type(sourcenode) ~= "databasenode" then
		return;
	end

	local _, sRecord = DB.getValue(sourcenode, sPath);
	if (sRecord or "") == "" then
		return;
	end

	local linkednode = DB.findNode(sRecord);
	if linkednode then
		DB.deleteNode(linkednode);
	end
end

-------------------------------------------------------------------------------
--- GETTERS & SETTERS
-------------------------------------------------------------------------------
function getCypherLoad(rActor)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end

	if not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeActor, "cypherload", 0);
end

function getCypherLimit(rActor)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end

	if not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeActor, "cypherlimit", 0);
end
function setCypherLimit(rActor, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end

	if not ActorManager.isPC(rActor) then
		return;
	end

	return DB.setValue(nodeActor, "cypherlimit", "number", nValue);
end
function modifyCypherLimit(rActor, nDelta)
	local nLimit = CharInventoryManager.getCypherLimit(rActor)
	CharInventoryManager.setCypherLimit(rActor, nLimit + nDelta)
end