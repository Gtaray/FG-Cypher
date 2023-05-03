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

	local nHP = 0;
	local nWounds = 0;

	local nodeCT = ActorManager.getCTNode(rActor);
	if nodeCT then
		if ActorManager.isPC(rActor) then
			nHP = 3;
		else
			nHP = DB.getValue(nodeActor, "hp", 0);
		end
		nWounds = DB.getValue(nodeCT, "wounds", 0);
	elseif ActorManager.isPC(rActor) then
		local nodePC = ActorManager.getCreatureNode(rActor);
		if nodePC then
			nHP = 3;
			nWounds = DB.getValue(nodePC, "wounds", 0);
		end
	end

	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end
	
	local sStatus;
	if sNodeType == "pc" then
		if nWounds <= 0 then
			sStatus = STATUS_HALE;
		elseif nWounds == 1 then
			sStatus = STATUS_IMPAIRED;
		elseif nWounds == 2 then
			sStatus = STATUS_DEBILITATED;
		else
			sStatus = ActorHealthManager.STATUS_DEAD;
		end
	else
		if nPercentWounded <= 0 then
			sStatus = ActorHealthManager.STATUS_HEALTHY;
		elseif nPercentWounded < .5 then
			sStatus = ActorHealthManager.STATUS_SIMPLE_WOUNDED;
		elseif nPercentWounded < 1 then
			sStatus = ActorHealthManager.STATUS_SIMPLE_HEAVY;
		else
			sStatus = ActorHealthManager.STATUS_DEAD;
		end
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

	local nCur, nMax = ActorManagerCypher.getStatPool(rActor, sStat);

	-- Shortcut. If the stat pool is already capped out, then we just return
	-- the entire value as overflow
	if nCur == nMax then
		return nValue;
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

	local sPath = "abilities." .. sStat;

	local nCur = DB.getValue(nodeActor, sPath .. ".current", 0);
	local nMax = DB.getValue(nodeActor, sPath .. ".max", 10);

	return nCur, nMax;	
end

function getMaxAssets(rActor, aFilter)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0;
	end

	return 2 + EffectManager.getEffectsBonusByType(rActor, "MAXASSETS", aFilter);
end

function getMaxEffort(rActor, sStat, aFilter)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or (sStat or "") == "" then
		return 0;
	end

	local nBase = DB.getValue(nodeActor, "effort", 0);
	local nEffectMaxEffort = EffectManager.getEffectsBonusByType(rActor, "MAXEFF", aFilter);
	
	-- clamp max effort to between 0 and 6
	return math.max(math.min(nBase + nEffectMaxEffort, 6), 0);
end

function getEdge(rActor, sStat, aFilter)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or (sStat or "") == "" then
		return 0;
	end

	local nBase = DB.getValue(nodeActor, "abilities." .. sStat .. ".edge", 0);
	local nBonus = EffectManager.getEffectsBonusByType(rActor, "EDGE", aFilter);

	return nBase + nBonus;
end

-- This only cares about creatures on the CT, since it's specifically for combat
function getArmor(rActor, rTarget, sStat)
	local node = ActorManager.getCTNode(rActor);
	local nBaseArmor = DB.getValue(node, "armor", 0);

	if not sStat then
		sStat = "might";
	end

	local nEffectArmor = EffectManager.getEffectsBonusByType(rActor, "ARMOR", { sStat }, rTarget, false);

	-- Only apply the character's base armor to Might damage.
	if sStat == "might" then
		return nBaseArmor + nEffectArmor;
	else
		return nEffectArmor;
	end
end

function getArmorSpeedCost(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nBase = DB.getValue(nodeActor, "armorspeedcost", 0);
	local nBonus = EffectManager.getEffectsBonusByType(rActor, "COST", { "armor" });

	return nBase + nBonus;
end

function getDefense(rActor, sStat)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or (sStat or "") == "" then
		return;
	end

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
-- RESIST / VULN / IMMUNE
---------------------------------------------------------------
function isImmune(rActor, rTarget, aDmgTypes)
	local tImmune = ActorManagerCypher.getImmunities(rActor, rTarget);
	local bImmune = ActorManagerCypher.resistanceCheckerHelper(tImmune, aDmgTypes);
	return bImmune;
end

function isResistant(rActor, rTarget, aDmgTypes)
	local tResist = ActorManagerCypher.getResistances(rActor, rTarget);
	local bResist, nAmount = ActorManagerCypher.resistanceCheckerHelper(tResist, aDmgTypes);
	return bResist, nAmount;
end

function isVulnerable(rActor, rTarget, aDmgTypes)
	local tVuln = ActorManagerCypher.getVulnerabilities(rActor, rTarget);
	local bVuln, nAmount = ActorManagerCypher.resistanceCheckerHelper(tVuln, aDmgTypes);
	return bVuln, nAmount;
end

function getResistances(rActor, rTarget)
	return ActorManagerCypher.getDamageMods(rActor, "RESIST", rTarget);
end

function getImmunities(rActor, rTarget)
	return ActorManagerCypher.getDamageMods(rActor, "IMMUNE", rTarget);
end

function getVulnerabilities(rActor, rTarget)
	return ActorManagerCypher.getDamageMods(rActor, "VULN", rTarget);
end

-- sFilter can be "resist", "vuln", or "immune" and it will only get those resistances
-- If it is nil, then this returns the full list
function getDamageMods(rActor, sFilter, rTarget)
	-- Only do this for CT Nodes
	local charNode = ActorManager.getCTNode(rActor);
	if not charNode then
		return nil;
	end

	local tDmgMods = {};

	-- Start by getting values from the creature node
	for _, node in ipairs(DB.getChildList(charNode, "resistances")) do
		local sType = DB.getValue(node, "type", "");
		if sType:lower() == sFilter:lower() then
			local sDamageType = DB.getValue(node, "damagetype", ""):lower();
			local nAmount = DB.getValue(node, "amount", 0);

			-- Don't care if it's assigned or not.
			-- if DamageTypeManager.isDamageType(sDamageType) then
				
			-- end

			tDmgMods[sDamageType] = nAmount;
		end
	end

	-- Then get values from effects
	local aEffects = EffectManager.getEffectsByType(rActor, sFilter, rTarget);
	for _,v in pairs(aEffects) do
		-- If there's no type specified, then set it to all
		if #(v.remainder) == 0 then
			tDmgMods["all"] = (tDmgMods["all"] or 0) + v.mod
		end
		for _,vType in pairs(v.remainder) do
			if tDmgMods[vType] then
				-- Merge the mods
				tDmgMods[vType] = tDmgMods[vType] + v.mod
			else
				tDmgMods[vType] = v.mod;	
			end
		end
	end

	return tDmgMods;
end

function resistanceCheckerHelper(tDmgMods, aDmgTypes)
	if type(aDmgTypes) == "string" then
		aDmgTypes = { aDmgTypes }
	end

	if tDmgMods["all"] then
		return true, tDmgMods["all"];
	end

	for _, sType in ipairs(aDmgTypes) do
		if tDmgMods[sType] and tDmgMods[sType] >= 0 then 
			return true, tDmgMods[sType];
		end
	end

	return false, 0;
end

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
	local nLevelBonus = EffectManager.getEffectsBonusByType(rCreature, "LEVEL", aFilter, rAttacker);

	return nBase + nLevelBonus;
end
