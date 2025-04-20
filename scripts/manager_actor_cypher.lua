-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	initActorHealth();
end

function getCreatureType(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return nil;
	end

	local sField;
	if ActorManager.isPC(rActor) then
		sField = "class.ancestry.name";
	else
		sField = "type";
	end
	local sType = DB.getValue(nodeActor, sField, "");
	return sType:lower();
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
	local nMightCur, nMightMax = CharStatManager.getStatPool(rActor, "might");
	local nSpeedCur, nSpeedMax = CharStatManager.getStatPool(rActor, "speed");
	local nIntCur, nIntMax = CharStatManager.getStatPool(rActor, "intellect");
	local nCur = nMightCur + nSpeedCur + nIntCur;
	local nMax = nMightMax + nSpeedMax + nIntMax;

	local nPercentWounded = 0;
	if nMax > 0 then
		nPercentWounded = 1 - (nCur / nMax);
	end
	
	-- Track status based on the number of wounds the PC has
	local nWounds = CharHealthManager.getDamageTrack(rActor);
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

function isHale(rActor)
	if ActorManager.isPC(rActor) then
		return CharHealthManager.getDamageTrack(rActor) == 0;
	end

	return ActorManagerCypher.getWoundPercent(rActor) < 0.33
end

function isWounded(rActor)
	return ActorManagerCypher.getWoundPercent(rActor) > 0;
end

function isImpaired(rActor)
	if ActorManager.isPC(rActor) then
		local charNode = ActorManager.getCreatureNode(rActor)
		return CharHealthManager.getDamageTrack(charNode) >= 1;
	end

	local nPercentWounded = ActorManagerCypher.getWoundPercent(rActor)
	return nPercentWounded >= 0.33 and nPercentWounded < 0.66;
end

function isDebilitated(rActor)
	if ActorManager.isPC(rActor) then
		local charNode = ActorManager.getCreatureNode(rActor)
		return CharHealthManager.getDamageTrack(charNode) >= 2;
	end

	return ActorManagerCypher.getWoundPercent(rActor) >= 0.66
end

---------------------------------------------------------------
-- ARMOR HELPERS
---------------------------------------------------------------
-- Returns data objects for every armor that matches stat and damage type
function getArmorData(rActor, sStat, aDamageTypes)
	local node = ActorManager.getCreatureNode(rActor);
	if not node then
		return {};
	end

	if type(aDamageTypes) == "string" then
		aDamageTypes = { aDamageTypes }
	end

	-- Default to might, since that's the default for damage dealt
	if not sStat then
		sStat = "might";
	end

	local aArmor = {};

	for _, sDamageType in ipairs(aDamageTypes) do
		-- if for some reason damage type isn't specified, default to untyped
		if (sDamageType or "") == "" then
			sDamageType = "untyped";
		end	

		-- Only apply the character's base armor to Might damage.
		if sDamageType == "untyped" and sStat == "might" then
			local tDefault = {
				sArmorType = "armor",
				sDamageType = "untyped",
				nArmor = 0,
				nSuperArmor = 0,
				sSuperArmor = "inclusive",
				sAmbient = ""
			}

			if ActorManager.isPC(rActor) then
				tDefault.nArmor, tDefault.nSuperArmor = CharArmorManager.getDefaultArmor(rActor);
			else
				tDefault.nArmor = DB.getValue(node, "armor", 0);
			end

			-- Only add this entry if it actually has a value.
			if tDefault.nArmor > 0 then
				table.insert(aArmor, tDefault)
			end
		end

		local aResistances = {};
		if ActorManager.isPC(rActor) then
			aResistances = DB.getChildList(node, "defenses.resistances")
		else
			aResistances = DB.getChildList(node, "resistances")
		end
		-- Start by getting special armor values from the creature node
		for _, resist in ipairs(aResistances) do
			local sBehavior = DB.getValue(resist, "behavior", ""):lower();
			local sType = DB.getValue(resist, "damagetype", ""):lower();
			local bInverted = DB.getValue(resist, "invert", "") == "yes";

			-- The default value for special defenses is as Armor (as opposed to a damage threshold or damage limit)
			if sBehavior == "" then
				sBehavior = "armor"
			end

			-- This ensures that untyped damage works even if its in the 'special defenses' list
			if sType == "" then 
				sType = "untyped";
			end

			-- In order, checking these things:
			-- Damage type is "any" or "all" with no inversion (which would make no sense)
			-- Damage type does NOT match, but we're inverted
			-- Damage type DOES match, and we're not inverted
			if (((sType == "all" or sType == "any") and not bInverted) or 
				(bInverted and sDamageType ~= sType) or 
				(not bInverted and sDamageType == sType)) then

				local tArmor = {
					sArmorType = sBehavior,
					sDamageType = sType,
					nArmor = DB.getValue(resist, "armor", 0),
					sSuperArmor = DB.getValue(resist, "superarmor", ""),
					sAmbient = DB.getValue(resist, "ambient", "")
				}

				table.insert(aArmor, tArmor)
			end
		end
	end
	
	return aArmor;
end

-- This only cares about creatures on the CT, since it's specifically for combat
function getArmor(rActor, rTarget, sStat, sDamageType, bAmbientDamage, bPierceDamage)
	local node = ActorManager.getCreatureNode(rActor);
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

	-- Initialize these flags to false if they weren't passed in
	if bAmbientDamage == nil then
		bAmbientDamage = false;
	end
	if bPierceDamage == nil then
		bPierceDamage = false;
	end

	local aArmor = ActorManagerCypher.getArmorData(rActor, sStat, sDamageType);
	local nArmor = 0;
	local nSuperArmor = 0;

	-- Go through every armor object and add them up
	for _, armor in ipairs(aArmor) do
		-- Only care about special defense entries that are Armor
		-- Not damage threshold or limit
		if armor.sArmorType == "armor" then
			local bPassesAmbientCheck = 
				(armor.sAmbient == "" and not bAmbientDamage) or 
				(armor.sAmbient == "exclusive" and bAmbientDamage) or 
				(armor.sAmbient == "inclusive")
			local bPassesSuperArmorCheck = 
				(armor.sSuperArmor ~= "exclusive") or 
				(armor.sSuperArmor == "exclusive" and bPierceDamage)
			
			-- If we pass both checks, then we add it to the armor total
			if bPassesAmbientCheck and bPassesSuperArmorCheck then
				nArmor = nArmor + armor.nArmor;
			end

			-- If this armor should be pierce-proof, and we passed the normal checks,
			-- we can add it to the superarmor total
			if bPassesSuperArmorCheck and armor.sSuperArmor ~= "" then
				-- If there's a specific super armor value, use that
				-- otherwise, use the raw armor value
				if armor.nSuperArmor then
					nSuperArmor = nSuperArmor + armor.nSuperArmor
				else
					nSuperArmor = nSuperArmor + armor.nArmor;
				end
			end
		end
	end

	-- Get ARMOR effects
	local nArmorEffects = EffectManagerCypher.getArmorEffectBonus(rActor, sStat, sDamageType, bAmbientDamage, rTarget)
	nSuperArmor = nSuperArmor + EffectManagerCypher.getSuperArmorEffectBonus(rActor, sStat, sDamageType, bAmbientDamage, rTarget)

	-- ARMOR: -X cannot make an actor go below 0 armor, as that means its a vulnerability which the armor effect should not do.
	-- If armor is already below 0, then we simply do not want the Armor: -X effect to drop the armor from its already low value
	nArmor = math.max(nArmor + nArmorEffects, math.min(0, nArmor));

	return nArmor, nSuperArmor;
end

function getArmorThreshold(rActor, rTarget, sStat, sDamageType, bAmbientDamage, bPierceDamage)
	local node = ActorManager.getCreatureNode(rActor);
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

	-- Initialize these flags to false if they weren't passed in
	if bAmbientDamage == nil then
		bAmbientDamage = false;
	end
	if bPierceDamage == nil then
		bPierceDamage = false;
	end

	local aArmor = ActorManagerCypher.getArmorData(rActor, sStat, sDamageType);
	local nThreshold = 0;
	local nSuperThreshold =  0; -- Threshold that ignores damage piercing effects.

	-- Go through every armor object and add them up
	for _, armor in ipairs(aArmor) do
		if armor.sArmorType == "threshold" then
			local bPassesAmbientCheck = 
				(armor.sAmbient == "" and not bAmbientDamage) or 
				(armor.sAmbient == "exclusive" and bAmbientDamage) or 
				(armor.sAmbient == "inclusive")
			local bPassesSuperArmorCheck = 
				(armor.sSuperArmor ~= "exclusive") or 
				(armor.sSuperArmor == "exclusive" and bPierceDamage)
			
			-- If we pass both checks, then we add it to the armor total
			if bPassesAmbientCheck and bPassesSuperArmorCheck then
				nThreshold = math.max(nThreshold, armor.nArmor);
			end

			-- If this armor should be pierce-proof, and we passed the normal checks,
			-- we can add it to the superarmor total
			if bPassesSuperArmorCheck and armor.sSuperArmor ~= "" then
				nSuperThreshold = math.max(nSuperThreshold, armor.nArmor);
			end
		end
	end

	local nThresholdEffects = EffectManagerCypher.getArmorThresholdEffectBonus(rActor, sStat, sDamageType, bAmbientDamage, rTarget)

	-- Damage threshold only ever returns the highest number, rather than adding them up.
	return math.max(nThreshold, nThresholdEffects), nSuperThreshold;
end

-- Armor Cap is a limit on how much damage can be taken from a single hit
function getDamageLimit(rActor, rTarget, sStat, sDamageType, bAmbientDamage, bPierceDamage)
	local node = ActorManager.getCreatureNode(rActor);
	if not node then
		return 9999, 9999;
	end

	-- Default to might, since that's the default for damage dealt
	if not sStat then
		sStat = "might";
	end

	-- if for some reason damage type isn't specified, default to untyped
	if (sDamageType or "") == "" then
		sDamageType = "untyped";
	end

	-- Initialize these flags to false if they weren't passed in
	if bAmbientDamage == nil then
		bAmbientDamage = false;
	end
	if bPierceDamage == nil then
		bPierceDamage = false;
	end

	local aArmor = ActorManagerCypher.getArmorData(rActor, sStat, sDamageType);
	local nLimit = 9999; -- This limit can be negated with damage piercing
	local nSuperLimit = 9999; -- This is the hard limit that damage cannot go over no matter what

	-- Go through every armor object and add them up
	for _, armor in ipairs(aArmor) do
		if armor.sArmorType == "limit" and armor.nArmor > 0 then
			local bPassesAmbientCheck = 
				(armor.sAmbient == "" and not bAmbientDamage) or 
				(armor.sAmbient == "exclusive" and bAmbientDamage) or 
				(armor.sAmbient == "inclusive")
			local bPassesSuperArmorCheck = 
				(armor.sSuperArmor ~= "exclusive") or 
				(armor.sSuperArmor == "exclusive" and bPierceDamage)
			
			-- If we pass both checks, then we apply the amount
			-- Limits always take the lowest possible number
			if bPassesAmbientCheck and bPassesSuperArmorCheck then
				nLimit = math.min(nLimit, armor.nArmor);
			end

			-- This limit is immune to all pierce effects
			if bPassesSuperArmorCheck and armor.sSuperArmor ~= "" then
				nSuperLimit = math.min(nSuperLimit, armor.nArmor);
			end
		end
	end

	local nLimitEffects = EffectManagerCypher.getDamageLimitEffectBonus(rActor, sStat, sDamageType, bAmbientDamage, rTarget)
	if nLimitEffects > 0 then
		nLimit = math.min(nLimit, nLimitEffects)
	end

	return nLimit, nSuperLimit;
end

function isImmune(rActor, rTarget, aDamageTypes, bAmbientDamage, bPierceDamage)
	local node = ActorManager.getCreatureNode(rActor);
	if not node then
		return 0;
	end

	-- Initialize these flags to false if they weren't passed in
	if bAmbientDamage == nil then
		bAmbientDamage = false;
	end
	if bPierceDamage == nil then
		bPierceDamage = false;
	end

	local bImmune = false;
	local bSuperImmune = false;

	-- First check effects
	local tEffectImmunities = EffectManagerCypher.getImmunityEffects(rActor, rTarget)
	for _,v in pairs(tEffectImmunities) do
		-- If there's no damage type specified in the effect, then we match 
		-- against untyped damage
		if #(v.filters) == 0 and ActorManagerCypher.matchDamageTypes(aDamageTypes, "untyped") then
			bImmune = true
		end		

		for _,vType in pairs(v.filters) do
			local bInverted = StringManager.startsWith(vType, "!");
			if bInverted then
				vType = vType:sub(2);
			end
			if ActorManagerCypher.matchDamageTypes(aDamageTypes, vType) then
				if not bInverted then
					bImmune = true
				end
			end
		end
	end

	local aArmor = ActorManagerCypher.getArmorData(rActor, sStat, aDamageTypes);

	for _, armor in ipairs(aArmor) do
		-- Immunity is denoted by a defense type of 'armor' with a value of 0
		if armor.sArmorType == "armor" and armor.nArmor == 0 then
			local bPassesAmbientCheck = 
				(armor.sAmbient == "" and not bAmbientDamage) or 
				(armor.sAmbient == "exclusive" and bAmbientDamage) or 
				(armor.sAmbient == "inclusive")
			local bPassesSuperArmorCheck = 
				(armor.sSuperArmor ~= "exclusive") or 
				(armor.sSuperArmor == "exclusive" and bPierceDamage)
			
			-- If we pass both checks, then we apply the amount
			-- Limits always take the lowest possible number
			if bPassesAmbientCheck and bPassesSuperArmorCheck then
				bImmune = true;
			end

			-- This limit is immune to all pierce effects
			if bPassesSuperArmorCheck and armor.sSuperArmor ~= "" then
				bSuperImmune = true;
			end
		end
	end

	return bImmune, bSuperImmune;
end

function matchDamageTypes(aDamageTypes, sMatchedType)
	if sMatchedType == "" then
		sMatchedType = "untyped"
	end

	if sMatchedType == "any" or sMatchedType == "all" then
		return true;
	end

	for _, sDamageType in ipairs(aDamageTypes) do
		if sDamageType == "" then
			sDamageType = "untyped"
		end
		
		if sDamageType == sMatchedType then
			return true;
		end
	end
	return false;
end

function getCreatureLevel(rCreature, rAttacker, aFilter, aIgnore)
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
	local nLevelBonus = EffectManagerCypher.getLevelEffectBonus(rCreature, aFilter, rAttacker, aIgnore);

	return nBase + nLevelBonus;
end
