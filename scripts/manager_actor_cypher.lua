-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	initActorHealth();
end

--
--	HEALTH
-- 

STATUS_HALE = "Hale";
STATUS_IMPAIRED = "Impaired";
STATUS_DEBILITATED = "Debilitated";

function initActorHealth()
	ActorHealthManager.getWoundPercent = getWoundPercent;
end

function getWoundPercent(v)
	local rActor = ActorManager.resolveActor(v);

	if ActorManager.isPC(rActor) then
		return ActorManagerCypher.getPCWoundPercent(rActor);
	end

	-- Guaranteed to be NPC after this point
	local nodeCT = ActorManager.getCTNode(rActor);
	local nHP = DB.getValue(nodeCT, "hp", 0);
	local nWounds = DB.getValue(nodeCT, "wounds", 0);
	local nPercentWounded = 0;

	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end
	
	local sStatus;
	if nPercentWounded <= 0 then
		sStatus = ActorHealthManager.STATUS_HEALTHY;
	elseif nPercentWounded < .5 then
		sStatus = ActorHealthManager.STATUS_SIMPLE_WOUNDED;
	elseif nPercentWounded < 1 then
		sStatus = ActorHealthManager.STATUS_SIMPLE_HEAVY;
	else
		sStatus = ActorHealthManager.STATUS_DEAD;
	end

	return nPercentWounded, sStatus;
end

function getPCWoundPercent(rActor)
	-- Wound percentage is tracked with the overall loss of stats from all 3 pools
	local nMightCur, nMightMax = ActorManagerCypher.getStatPool(rActor, "might");
	local nSpeedCur, nSpeedMax = ActorManagerCypher.getStatPool(rActor, "speed");
	local nIntCur, nIntMax = ActorManagerCypher.getStatPool(rActor, "intellect");
	local nCur = nMightCur + nSpeedCur + nIntCur;
	local nMax = nMightMax + nSpeedMax + nIntMax;

	local nPercentWounded = 0;
	if nMax > 0 then
		nPercentWounded = 1 - (nCur / nMax);
	end
	
	-- Track status based on the number of wounds the PC has
	local nWounds = DB.getValue(nodePC, "wounds", 0);
	local sStatus;
	if nWounds <= 0 then
		sStatus = STATUS_HALE;
	elseif nWounds == 1 then
		sStatus = STATUS_IMPAIRED;
	elseif nWounds == 2 then
		sStatus = STATUS_DEBILITATED;
	else
		sStatus = ActorHealthManager.STATUS_DEAD;
	end

	return nPercentWounded, sStatus;
end

---------------------------------------------------------------
-- CHARACTER STAT ACCESSORS AND SETTERS
---------------------------------------------------------------
function getTier(rActor)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or not ActorManager.isPC(rActor) then
		return;
	end

	return DB.getValue(nodeActor, "tier", 1);
end

function moveDamageTrack(rActor, nIncrement)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or not ActorManager.isPC(rActor) then
		return;
	end
	
	local nCur = ActorManagerCypher.getDamageTrack(rActor);
	local nNewValue = math.max(math.min(nCur + nIncrement, 3), 0);

	ActorManagerCypher.setDamageTrack(rActor, nNewValue);
end
function setDamageTrack(rActor, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or not ActorManager.isPC(rActor) then
		return;
	end

	nValue = math.max(math.min(nValue, 3), 0);

	DB.setValue(nodeActor, "wounds", "number", nValue);
end
function getDamageTrack(rActor)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeActor, "wounds", 0);
end

function setStatMax(rActor, sStat, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" or nValue == 0 then
		return 0;
	end
	
	local sPath = string.format("abilities.%s.max", sStat:lower());
	DB.setValue(nodeActor, sPath, "number", nValue);

	ActorManagerCypher.setStatPool(rActor, sStat, nValue);
end

function addToStatMax(rActor, sStat, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" or nValue == 0 then
		return 0;
	end

	sStat = sStat:lower();
	local _, nMax = ActorManagerCypher.getStatPool(rActor, sStat)

	-- New stat pool maximum
	nMax = nMax + nValue;
	ActorManagerCypher.setStatMax(rActor, sStat, nMax);

	-- Modify the current amount by the same amount
	ActorManagerCypher.addToStatPool(rActor, sStat, nValue);
end

function addToStatPool(rActor, sStat, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" or nValue == 0 then
		return 0;
	end

	sStat = sStat:lower();

	local nCur, nMax = ActorManagerCypher.getStatPool(rActor, sStat);

	-- Shortcut. If the stat pool is already capped out, then we just return
	-- the entire value as overflow
	if (nCur == nMax and nValue > 0) or (nCur == 0 and nValue < 0) then
		return math.abs(nValue);
	end

	local nNewValue = nCur + nValue;
	local nOverflow = 0;
	-- Return overflow healing
	if nNewValue > nMax then
		nOverflow = nNewValue - nMax;

	-- Return overflow damage
	elseif nNewValue < 0 then
		nOverflow = math.abs(nNewValue);
	end

	-- Clamp nNewValue between 0 and the pool's max
	nNewValue = math.max(math.min(nNewValue, nMax), 0);
	ActorManagerCypher.setStatPool(rActor, sStat, nNewValue);
	return nOverflow;
end
function setStatPool(rActor, sStat, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" then
		return 0;
	end

	sStat = sStat:lower();

	local sPath = "abilities." .. sStat;
	local nCur, nMax = ActorManagerCypher.getStatPool(rActor, sStat)

	nValue = math.max(math.min(nValue, nMax), 0);
	DB.setValue(nodeActor, sPath .. ".current", "number", nValue);

	-- If the character was above 0 in the stat pool and is now at 0, 
	-- we need to increment the damage track
	if nCur > 0 and nValue == 0 then
		ActorManagerCypher.moveDamageTrack(rActor, 1);
	
	-- Or if the character was at 0 in the pool, but is now above 0,
	-- decrement the damage track
	elseif nCur == 0 and nValue > 0 then
		ActorManagerCypher.moveDamageTrack(rActor, -1);
	end
end
function getStatPool(rActor, sStat)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" then
		return 0, 0;
	end

	sStat = sStat:lower();

	local sPath = "abilities." .. sStat;

	local nCur = DB.getValue(nodeActor, sPath .. ".current", 0);
	local nMax = DB.getValue(nodeActor, sPath .. ".max", 10);

	return nCur, nMax;	
end

function getMaxAssets(rActor, aFilter)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or not ActorManager.isPC(rActor) then
		return 0;
	end

	return 2 + EffectManagerCypher.getMaxAssetsEffectBonus(rActor, aFilter);
end

function getMaxEffort(rActor, aFilter)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or not ActorManager.isPC(rActor) then
		return 0;
	end

	local nBase = DB.getValue(nodeActor, "effort", 1);
	local nEffectMaxEffort = EffectManagerCypher.getMaxEffortEffectBonus(rActor, aFilter);
	
	-- clamp max effort to between 0 and 6
	return math.max(math.min(nBase + nEffectMaxEffort, 6), 1);
end

function getEdge(rActor, sStat, aFilter)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or not ActorManager.isPC(rActor) or (sStat or "") == "" then
		return 0;
	end

	sStat = sStat:lower();

	local nBase = DB.getValue(nodeActor, "abilities." .. sStat .. ".edge", 0);
	local nBonus = EffectManagerCypher.getEdgeEffectBonus(rActor, aFilter);

	return nBase + nBonus;
end

function getShieldBonus(rActor)
	local items = ActorManagerCypher.getArmorInInventory(rActor);
	local nMax = 0;
	for _, item in ipairs(items) do
		local nShieldBonus = ItemManagerCypher.getArmorSpeedAsset(item);
		if nShieldBonus > nMax then
			nMax = nShieldBonus;
		end
	end
	return nMax;
end

function getArmorSpeedCost(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nBase = DB.getValue(nodeActor, "ArmorSpeedPenalty.total", 0);
	local nBonus = EffectManagerCypher.getCostEffectBonus(rActor, { "armor" });

	-- This value can never be lower than 0, because 0 means there's no penalty
	return math.max(nBase + nBonus, 0);
end

function getDefense(rActor, sStat)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or (sStat or "") == "" then
		return;
	end

	sStat = sStat:lower();

	local sTraining = RollManager.resolveTraining(DB.getValue(nodeActor, "abilities." .. sStat .. ".def.training", 1));
	local nAssets = DB.getValue(nodeActor, "abilities." .. sStat .. ".def.asset", 0);
	local nModifier = DB.getValue(nodeActor, "abilities." .. sStat .. ".def.misc", 0);

	return sTraining, nAssets, nModifier
end

function getInitiative(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return;
	end

	local sTraining = RollManager.resolveTraining(DB.getValue(nodeActor, "inittraining", 1))
	local nAssets = DB.getValue(nodeActor, "initasset", 0);
	local nModifier = DB.getValue(nodeActor, "initmod", 0);

	return sTraining, nAssets, nModifier;
end

function getRecoveryRollMod(rActor)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or not ActorManager.isPC(rActor) then
		return;
	end

	return DB.getValue(nodeActor, "recoveryrollmod", 0);
end

---------------------------------------------------------------
-- INVENTORY
---------------------------------------------------------------
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
	return ActorManagerCypher.getItemsOfTypeInInventory(rActor, "armor");
end

---------------------------------------------------------------
-- ARMOR
---------------------------------------------------------------
-- This only cares about creatures on the CT, since it's specifically for combat
function getArmor(rActor, rTarget, sStat, sDamageType)
	local _, node = ActorManager.getTypeAndNode(rActor);

	if not node then
		return 0, 0;
	end

	-- Default to might, since that's the default for damage dealt
	if not sStat then
		sStat = "might";
	end

	-- if for some reason damage type isn't specified, default to untyped
	if (sDamageType or "") == "" then
		sDamageType = "untyped";
	end

	-- Get ARMOR effects
	-- This can modify both untyped and typed damage
	-- Do this before checking for damage type so that we can correctly apply this
	-- if the damage type is untyped, and thus only applies if the stat is Might
	local nArmorEffects = EffectManagerCypher.getArmorEffectBonus(rActor, sStat, sDamageType, rTarget)

	-- Only apply the character's base armor to Might damage.
	if sDamageType == "untyped" and sStat == "might" then
		return nArmorEffects + DB.getValue(node, "Armor.total", 0);
	end

	local nArmor = 0;

	-- Start by getting special armor values from the creature node
	-- This list does NOT include untyped armor, 
	-- that's handled above with the base armor
	for _, resist in ipairs(DB.getChildList(node, "resistances")) do
		local sType = DB.getValue(resist, "damagetype", ""):lower();
		local nAmount = DB.getValue(resist, "armor", 0);

		if sType ~= "untyped" and sDamageType == sType and nAmount > 0 then
			nArmor = nArmor + nAmount;
		end
	end

	return nArmor + nArmorEffects;
end

function getSuperArmor(rActor, rTarget, sStat, sDamageType)
	local _, node = ActorManager.getTypeAndNode(rActor);

	if not node then
		return 0, 0;
	end

	-- Default to might, since that's the default for damage dealt
	if not sStat then
		sStat = "might";
	end

	-- if for some reason damage type isn't specified, default to untyped
	if (sDamageType or "") == "" then
		sDamageType = "untyped";
	end

	-- Base super armor only applies to untyped damage, which only applies
	-- to Might damage
	local nSuperArmor = 0
	if sStat == "might" and sDamageType == "untyped" then
		nSuperArmor = DB.getValue(node, "Armor.superarmor", 0);
	end
	
	local nSuperArmorEffects = EffectManagerCypher.getSuperArmorEffectBonus(rActor, sStat, sDamageType, rTarget)

	return nSuperArmor + nSuperArmorEffects;
end

function isImmune(rActor, rTarget, aDmgTypes)
	local tImmune = ActorManagerCypher.getImmunities(rActor, rTarget);
	local bImmune = ActorManagerCypher.resistanceCheckerHelper(tImmune, aDmgTypes);
	return bImmune;
end

function getImmunities(rActor, rTarget)
	-- Only do this for CT Nodes
	local _, charNode = ActorManager.getTypeAndNode(rActor);
	if not charNode then
		return nil;
	end

	local tDmgMods = {};

	-- Start by getting values from the creature node
	for _, node in ipairs(DB.getChildList(charNode, "resistances")) do
		local sDamageType = DB.getValue(node, "damagetype", ""):lower();
		local nAmount = DB.getValue(node, "armor", 0);

		-- Only add to the list if the filter is nil OR if the filter matches the 
		-- damage mod amount
		if nAmount == 0 then
			tDmgMods[sDamageType] = nAmount;
		end
	end

	-- Then get values from effects
	local aEffects = EffectManagerCypher.getImmunityEffects(rActor, rTarget);
	for _,v in pairs(aEffects) do
		if #(v.filters) == 0 then
			tDmgMods["untyped"] = 0;
		end
		for _,vType in pairs(v.filters) do
			if vType ~= "untyped" then
				tDmgMods[vType] = 0;
			end
		end
	end

	return tDmgMods;
end


function resistanceCheckerHelper(tDmgMods, aDmgTypes)
	if aDmgTypes == nil then
		return false, 0;
	end

	if type(aDmgTypes) == "string" then
		aDmgTypes = { aDmgTypes }
	end

	if tDmgMods["all"] then
		return true, tDmgMods["all"];
	end

	for _, sType in ipairs(aDmgTypes) do
		if tDmgMods[sType] then 
			return true, tDmgMods[sType];
		end
	end

	return false, 0;
end

---------------------------------------------------------------
-- SHIELD (Temporary HP)
---------------------------------------------------------------

---------------------------------------------------------------
-- EQUIPPED WEAPONS
---------------------------------------------------------------
function getEquippedWeaponNode(nodeActor)
	for _, node in ipairs(DB.getChildList(nodeActor, "attacklist")) do
		if DB.getValue(node, "equipped", 0) == 1 then
			return node;
		end
	end
end

function getEquippedWeapon(nodeActor)
	local node = ActorManagerCypher.getEquippedWeaponNode(nodeActor);
	if not node then
		return {};
	end

	local rWeapon = {};
	rWeapon.sLabel = DB.getValue(node, "name", "");
	rWeapon.sStat = RollManager.resolveStat(DB.getValue(node, "stat", ""));
	rWeapon.sDefenseStat = RollManager.resolveStat(DB.getValue(node, "defensestat", ""), "speed");
	rWeapon.sAttackRange = DB.getValue(node, "atkrange", "");
	rWeapon.sTraining = DB.getValue(node, "training", "");
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
		-- Set every weapon other than the specified one to unequipped
		if DB.getName(node) ~= sWeaponNode then
			DB.setValue(node, "equipped", "number", 0);
		end
	end
end

---------------------------------------------------------------
-- NPCs
---------------------------------------------------------------
function getCreatureLevel(rCreature, rAttacker, aFilter)
	if not aFilter then
		aFilter = {};
	end

	local creatureNode = rCreature;
	if type(rCreature) ~= "databasenode" then
		creatureNode = ActorManager.getCTNode(rCreature);
		if not creatureNode then
			creatureNode = ActorManager.getCreatureNode(rCreature);
		end
	end

	if not creatureNode then
		return 0;
	end

	local nBase = DB.getValue(creatureNode, "level", 0);
	local nLevelBonus = EffectManagerCypher.getLevelEffectBonus(rCreature, aFilter, rAttacker);

	return nBase + nLevelBonus;
end
