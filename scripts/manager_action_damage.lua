-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYDMG = "applydmg";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMG, handleApplyDamage);

	ActionsManager.registerModHandler("damage", modRoll);
	ActionsManager.registerResultHandler("damage", onRoll);
end

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "damage";

	-- Only get the attack effort if the setting to pay for them separately is enabled
	if OptionsManagerCypher.splitAttackAndDamageEffort() then
		rAction.nAttackEffort = RollHistoryManager.getAttackEffort(rActor)
	end

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		ActionDamage.performRoll(draginfo, rActor, rAction);
	end
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	RollManager.convertBooleansToNumbers(rRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {}
	rRoll.sType = "damage"
	rRoll.aDice = rAction.aDice or { };
	rRoll.nMod = rAction.nDamage or 0;

	rRoll.sLabel = rAction.label or "";
	rRoll.sStat = rAction.sStat;
	rRoll.sDamageStat = rAction.sDamageStat;
	rRoll.sDamageType = rAction.sDamageType;
	rRoll.nEffort = rAction.nEffort or 0;

	rRoll.sDesc = ActionDamage.getRollLabel(rActor, rAction, rRoll)

	rRoll.bOngoing = rAction.bOngoing;
	rRoll.bAmbient = rAction.bAmbient or false;
	rRoll.bPiercing = rAction.bPiercing or false;
	if rRoll.bPiercing then
		rRoll.nPierceAmount = rAction.nPierceAmount;
	end

	if rAction.bSecret then
		rRoll.bSecret = true;
	end

	RollManager.encodeTarget(rAction.rTarget, rRoll);
	
	return rRoll;
end

function getRollLabel(rActor, rAction, rRoll)
	local sLabel = string.format("[DAMAGE (%s", StringManager.capitalize(rRoll.sDamageStat));

	if (rAction.sDamageType or "") ~= "" then
		sLabel = string.format("%s, %s", sLabel, rAction.sDamageType)
	end
	sLabel = string.format(
		"%s)] %s", 
		sLabel, 
		rRoll.sLabel);

	return sLabel
end

function getEffectFilter(rRoll)
	return { "damage", "dmg", rRoll.sStat };
end

function modRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	if ActionDamage.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	local aFilter = ActionDamage.getEffectFilter(rRoll)

	rTarget = RollManager.decodeTarget(rRoll, rTarget, true);

	local sConvertedDmgType = EffectManagerCypher.getDamageTypeConversionEffect(rSource, rRoll.sDamageType, aFilter)
	if (sConvertedDmgType or "") ~= "" then
		rRoll.sDamageType = sConvertedDmgType
		RollManager.encodeDamageType(rRoll)
	end

	-- Adjust mod based on effort
	rRoll.nEffort = (rRoll.nEffort or 0) + RollManager.processEffort(rSource, rTarget, aFilter, rRoll.nEffort);
	if (rRoll.nEffort or 0) > 0 then
		rRoll.nMod = rRoll.nMod + (rRoll.nEffort * 3);
	end

	rRoll.bPiercing, rRoll.nPierceAmount = RollManager.processPiercing(rSource, rTarget, rRoll.bPiercing, rRoll.nPierceAmount, rRoll.sDamageType, aFilter);

	local nDmgBonus = EffectManagerCypher.getDamageEffectBonus(rSource, rRoll.sDamageType, aFilter, rTarget)
	if nDmgBonus ~= 0 then
		rRoll.nMod = rRoll.nMod + nDmgBonus;
	end

	rRoll.nMult = EffectManagerCypher.getDamageMultiplierEffectBonus(rSource, rRoll.sDamageType, aFilter, rTarget)

	-- We fake the action object here when encoding piercing
	-- Because it requires two variables as an input
	-- instead of just the single that most encodes have
	RollManager.encodeOngoingDamage({ bOngoing = rRoll.bOngoing }, rRoll)
	RollManager.encodeAmbientDamage({ bAmbient = rRoll.bAmbient }, rRoll);
	RollManager.encodePiercing({ bPierce = rRoll.bPiercing, nPierceAmount = rRoll.nPierceAmount }, rRoll);
	RollManager.encodeMultiplier(rRoll.nMult, rRoll)
	RollManager.encodeEffort(rRoll.nEffort, rRoll)
	RollManager.encodeEffects(rRoll, nDmgBonus);
	RollManager.convertBooleansToNumbers(rRoll);
end

-- Returns boolean determining whether the roll was rebuilt from a chat message
-- It's important to note here that we do not need to rebuild the stat that the PC
-- used, because that stat is only ever used to get modifiers in the modRoll()
-- function. Since that function has already been called when the roll was first made
-- (this function only applies when drag/dropping chat messages), the effects
-- are already baked in
function rebuildRoll(rSource, rTarget, rRoll)
	local bRebuilt = false;

	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[DAMAGE.*%]([^%[]+)"));
		bRebuilt = true;
	end
	if not rRoll.sDamageStat then
		rRoll.sDamageStat = RollManager.decodeStat(rRoll, true);
	end
	if not rRoll.nEffort then
		rRoll.nEffort = RollManager.decodeEffort(rRoll, true);
	end
	if rRoll.bPiercing == nil then
		rRoll.bPiercing, rRoll.nPierceAmount = RollManager.decodePiercing(rRoll, true);
	end
	if rRoll.bAmbient == nil then
		rRoll.bAmbient = RollManager.decodeAmbientDamage(rRoll, true);
	end
	if rRoll.bOngoing == nil then
		rRoll.bOngoing = RollManager.decodeOngoingDamage(rRoll, true);
	end
	if rRoll.nMult == nil then
		rRoll.nMult = RollManager.decodeMultiplier(rRoll, true)
	end

	rRoll.bRebuilt = bRebuilt;
	return bRebuilt;
end

function onRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);

	rTarget = RollManager.decodeTarget(rRoll, rTarget, false);

	ActionDamage.buildRollResult(rSource, rTarget, rRoll);
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rRoll.bSourceNPC and rRoll.bTargetPC then
		rMessage.text = rMessage.text .. " -> " .. (ActorManager.getDisplayName(rTarget) or "")
	end
	rMessage.icon = "action_damage";
	Comm.deliverChatMessage(rMessage);

	if rTarget then
		ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll);
	end	

	RollHistoryManager.setLastRoll(rSource, rTarget, rRoll)
	RollHistoryManager.clearAttackEffort(rSource)
end

function buildRollResult(rSource, rTarget, rRoll)
	rRoll.bSourcePC = (rSource and ActorManager.isPC(rSource)) or false;
	rRoll.bTargetPC = (rTarget and ActorManager.isPC(rTarget)) or false;
	rRoll.bSourceNPC = (rSource and not ActorManager.isPC(rSource)) or false;
	rRoll.bTargetNPC = (rTarget and not ActorManager.isPC(rTarget)) or false;
	rRoll.sDamageType = (rRoll.sDamageType or ""):lower()
	
	if not rRoll.nTotal  then
		rRoll.nTotal = ActionsManager.total(rRoll);
	end
end

function notifyApplyDamage(rSource, rTarget, rRoll)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMG;
	
	msgOOB.bSecret = rRoll.bTower or rRoll.bSecret;
	msgOOB.nTargetOrder = rTarget.nOrder;
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	msgOOB.nTotal = rRoll.nTotal or 0;
	msgOOB.sDamageStat = rRoll.sDamageStat
	msgOOB.sHealStat = rRoll.sHealStat
	msgOOB.sDamageType = rRoll.sDamageType

	msgOOB.bPiercing = rRoll.bPiercing;
	msgOOB.nPierceAmount = rRoll.nPierceAmount

	msgOOB.nMult = rRoll.nMult

	msgOOB.bAmbient = rRoll.bAmbient;
	msgOOB.bOngoing = rRoll.bOngoing;
	msgOOB.bNoOverflow = rRoll.bNoOverflow;

	RollManager.convertBooleansToNumbers(msgOOB)

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyDamage(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	if rTarget then
		rTarget.nOrder = msgOOB.nTargetOrder;
	end

	local rRoll = {
		sDesc = msgOOB.sDesc,
		nTotal = tonumber(msgOOB.nTotal),
		sDamageStat = msgOOB.sDamageStat,
		sDamageType = msgOOB.sDamageType,
		sHealStat = msgOOB.sHealStat,
		bPiercing = msgOOB.bPiercing,
		nPierceAmount = tonumber(msgOOB.nPierceAmount),
		nMult = msgOOB.nMult,
		bAmbient = msgOOB.bAmbient,
		bOngoing = msgOOB.bOngoing,
		bNoOverflow = msgOOB.bNoOverflow,
		bSecret = msgOOB.bSecret
	}
	ActionDamage.buildRollResult(rSource, rTarget, rRoll);
	RollManager.convertNumbersToBooleans(rRoll);
	applyDamage(rSource, rTarget, rRoll);
end

function applyDamage(rSource, rTarget, rRoll)
	-- Remember current health status
	local sOriginalStatus = ActorHealthManager.getHealthStatus(rTarget);

	-- Variables for applying damage and building notifications
	local aNotifications = {};

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if not nodeTarget then
		return;
	end

	-- if damage type is not specified, then we make sure it has
	-- the untyped value here. This makes all of the calcs easier
	if (rRoll.sDamageType or "") == "" then
		rRoll.sDamageType = "untyped";
	end

	rRoll.nTotal = rRoll.nTotal * (rRoll.nMult or 1)

	ActionDamage.applyArmor(rSource, rTarget, rRoll, aNotifications);
	ActionDamage.applyThreshold(rSource, rTarget, rRoll, aNotifications);
	ActionDamage.applyDamageLimit(rSource, rTarget, rRoll,aNotifications);

	local nShieldAdjust = ActionDamage.handleShield(
		rTarget, 
		rRoll.nTotal, 
		{ rRoll.sDamageType, rRoll.sDamageStat }, 
		aNotifications)

	rRoll.nTotal = rRoll.nTotal - nShieldAdjust;

	local sStat = rRoll.sDamageStat;
	if rRoll.nTotal < 0 then
		sStat = rRoll.sHealStat;
	end

	if sTargetNodeType == "pc" then
		ActionDamage.applyDamageToPc(
			rSource, 
			rTarget, 
			rRoll.nTotal, 
			sStat,  
			rRoll.bNoOverflow,
			aNotifications);
	elseif sTargetNodeType == "ct" then
		ActionDamage.applyDamageToNpc(
			rSource, 
			rTarget, 
			rRoll.nTotal, 
			aNotifications);
	else
		return;
	end

	-- Check for status change
	local bShowStatus = false;
	if ActorManager.isFaction(rTarget, "friend") then
		bShowStatus = not OptionsManager.isOption("SHPC", "off");
	else
		bShowStatus = not OptionsManager.isOption("SHNPC", "off");
	end

	if bShowStatus then
		local sNewStatus = ActorHealthManager.getHealthStatus(rTarget);
		if sOriginalStatus ~= sNewStatus then
			table.insert(aNotifications, string.format("[%s: %s]", Interface.getString("combat_tag_status"), sNewStatus));
		end
	end

	ActionDamage.outputResult(rSource, rTarget, rRoll, aNotifications)
end

function outputResult(rSource, rTarget, rRoll, aNotifications)
	-- Output	
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgLong.text = "";
	if rRoll.nTotal < 0 then
		msgShort.icon = "roll_heal";
		msgLong.icon = "roll_heal";

		-- Report positive values only
		rRoll.nTotal = math.abs(rRoll.nTotal);
		msgShort.text = string.format("[heal %s]", rRoll.nTotal);
		msgLong.text = string.format("[heal %s]", rRoll.nTotal);
		
	else
		msgShort.icon = "roll_damage";
		msgLong.icon = "roll_damage";

		if rRoll.sDamageType ~= "untyped" then
			msgShort.text = string.format("[%s %s damage]", rRoll.nTotal, rRoll.sDamageType);
			msgLong.text = string.format("[%s %s damage]", rRoll.nTotal, rRoll.sDamageType);
		else
			msgShort.text = string.format("[%s damage]", rRoll.nTotal);
			msgLong.text = string.format("[%s damage]", rRoll.nTotal);
		end
	end

	if rTarget then
		msgShort.text = string.format("%s -> [to %s", msgShort.text, ActorManager.getDisplayName(rTarget));
		msgLong.text = string.format("%s -> [to %s", msgLong.text, ActorManager.getDisplayName(rTarget));
	end

	local sAffectedStat = rRoll.sDamageStat or rRoll.sHealStat
	if ActorManager.isPC(rTarget) and (sAffectedStat or "") ~= "" then
		msgShort.text = string.format("%s's %s", msgShort.text, sAffectedStat);
		msgLong.text = string.format("%s's %s", msgLong.text, sAffectedStat);
	end

	msgShort.text = msgShort.text .. "]";
	msgLong.text = msgLong.text .. "]";
	
	if #aNotifications > 0 then
		msgLong.text = string.format("%s %s", msgLong.text, table.concat(aNotifications, " "));
	end
	
	ActionsManager.outputResult(rRoll.bSecret, rSource, rTarget, msgLong, msgShort);
end

function applyThreshold(rSource, rTarget, rRoll, aNotifications)
	-- If for some reason the amount of damage is negative, then we don't need to do any processing
	-- Because it's handled as healing
	if rRoll.nTotal <= 0 then
		return rRoll.nTotal;
	end

	-- Check if we have any thresholds we need to beat
	local nThreshold, nSuperThreshold = ActorManagerCypher.getArmorThreshold(rTarget, rSource, rRoll.sDamageStat, rRoll.sDamageType, rRoll.bAmbient, rRoll.bPiercing);

	if nThreshold <= 0 or rRoll.nTotal >= nThreshold then
		return rRoll.nTotal
	end

	-- Down here we're guaranteed that Threshold is greater than 0 and 
	-- the damage is less than the threshold
	-- If the damage doesn't pierce armor, we can return early with 0 damage
	if not rRoll.bPiercing then
		table.insert(aNotifications, "[IGNORED]");
		rRoll.nTotal = 0;
		return 0;
	end

	-- Here we know the threshold hasn't been reached, but the damage does pierce armor
	-- This means we should pierce all damage, but we have to do one more check against the super threshold
	-- to see if we beat that as well.
	if rRoll.nPierceAmount == 0 then
		if rRoll.nTotal < nSuperThreshold then
			table.insert(aNotifications, "[IGNORED]");
			rRoll.nTotal = 0;
		end
	end
	
	-- If we pierce SOME armor, then we deal damage equal to the pierce amount
	-- We then check one more time to see if the pierce amount is above the super threshold
	-- and if it is, deal that damgae
	-- if it's not, deal no damage.
	if rRoll.nPierceAmount > 0 then
		if rRoll.nPierceAmount < nSuperThreshold then
			table.insert(aNotifications, "[IGNORED]");
			rRoll.nTotal = 0;
		else
			rRoll.nTotal = rRoll.nPierceAmount
			table.insert(aNotifications, "[PARTIALLY IGNORED]");
		end
	end

	return rRoll.nTotal
end

function applyDamageLimit(rSource, rTarget, rRoll, aNotifications)
	-- If for some reason the amount of damage is negative, then we don't need to do any processing
	-- Because it's handled as healing
	if rRoll.nTotal <= 0 then
		return rRoll.nTotal;
	end

	local nLimit, nSuperLimit = ActorManagerCypher.getDamageLimit(rTarget, rSource, rRoll.sDamageStat, rRoll.sDamageType, rRoll.bAmbient, rRoll.bPiercing);

	-- If the damage is beneath our damage limit, we don't need to do anything
	if rRoll.nTotal <= nLimit then
		return rRoll.nTotal;
	end

	if not rRoll.bPiercing then
		table.insert(aNotifications, "[LIMITED]");
		rRoll.nTotal = math.min(rRoll.nTotal, nLimit);
		return rRoll.nTotal;
	end

	if rRoll.nPierceAmount == 0 then
		if rRoll.nTotal > nSuperLimit then
			table.insert(aNotifications, "[LIMITED]");
			rRoll.nTotal = nSuperLimit;
		end
	end

	if rRoll.nPierceAmount > 0 then
		if rRoll.nPierceAmount > nSuperLimit then
			table.insert(aNotifications, "[LIMITED]");
			rRoll.nTotal = nSuperLimit;
		else
			rRoll.nTotal = rRoll.nPierceAmount
			table.insert(aNotifications, "[PARTIALLY LIMITED]");
		end
	end

	return rRoll.nTotal;
end

function applyArmor(rSource, rTarget, rRoll, aNotifications)
	-- If for some reason the amount of damage is negative, then we don't need to do any processing
	-- Because it's handled as healing
	if rRoll.nTotal <= 0 then
		return rRoll.nTotal;
	end
	
	local bImmune, bSuperImmune = ActorManagerCypher.isImmune(rTarget, rSource, { rRoll.sDamageType, rRoll.sDamageStat }, rRoll.bAmbient, rRoll.bPiercing)
	if bImmune or bSuperImmune then
		table.insert(aNotifications, "[IMMUNE]");

		-- Only apply piercing if the defender is not super immune (immune to damage and armor piercing effects)
		if rRoll.bPiercing and not bSuperImmune then
			-- if pierce amount is 0 (but bPierce is true), then pierce all armor
			-- Otherwise it's a flat reduction
			if rRoll.nPierceAmount > 0 then
				rRoll.nTotal = rRoll.nPierceAmount;
			end

			-- If the pierce value is 0, you do full damage
			-- but we don't need to change nTotal for that to happen.
		else
			-- Unless there's some amount of armor pierce, we set the total 0
			rRoll.nTotal = 0;
		end

		return rRoll.nTotal;
	end

	local nArmor, nSuperArmor = ActorManagerCypher.getArmor(rTarget, rSource, rRoll.sDamageStat, rRoll.sDamageType, rRoll.bAmbient, rRoll.bPiercing);

	-- only apply piercing if the armor adjustment is positive. 
	-- negative armor adjust means there's a vulnerability to a dmg type
	if rRoll.bPiercing and nArmor > 0 then
		-- if pierce amount is 0 (but bPierce is true), then pierce all armor
		-- Otherwise it's a flat reduction
		if rRoll.nPierceAmount > 0 then
			nArmor = nArmor - rRoll.nPierceAmount;
		elseif rRoll.nPierceAmount == 0 then
			nArmor = 0;
		end

		-- If piercing reduces the amount of armor below super armor value
		-- then the math.max() function will bring armor adjust back up to the 
		-- super armor value
		nArmor = math.max(nArmor, nSuperArmor);
	end

	-- Apply VULN effect
	local nVuln = EffectManagerCypher.getVulnerabilityEffectBonus(rTarget, rRoll.sDamageStat, rRoll.sDamageType, rRoll.bAmbient, rSource)
	if nVuln > 0 then
		nArmor = nArmor - nVuln;
	end

	-- If any amount of armor was applied, then we add a notification
	if nVuln > 0 or nArmor < 0 then -- Less than 0
		table.insert(aNotifications, "[VULNERABLE]");
	elseif nArmor == 0 then -- Equal to 0
		-- Do nothing
	elseif nArmor < rRoll.nTotal then -- Greater than 0 but less than damage
		table.insert(aNotifications, "[PARTIALLY RESISTED]");
	elseif nArmor >= 0 then -- Equal or greater than damage
		table.insert(aNotifications, "[RESISTED]");
	end

	-- Apply the adjusted armor value to the total damage
	-- Damage cannot fall below 0 though, otherwise that's healing
	rRoll.nTotal = math.max(rRoll.nTotal - nArmor, 0);

	return rRoll.nTotal
end

function applyDamageToPc(rSource, rTarget, nDamage, sStat, bNoOverflow, aNotifications)
	local sTargetNodeType, nodePC = ActorManager.getTypeAndNode(rTarget);
	if not nodePC then
		return;
	end

	if nDamage == 0 then
		return;
	end

	-- Because addToStatPool always returns a positive overflow, we need to 
	-- modify that overflow to always have the correct sign
	-- Positive for healing, and Negative for damage.
	-- So we use a coefficient here. This avoids having to write if/else for healing and damage
	local nNegativeIfDamage = 1;
	if nDamage > 0 then
		nNegativeIfDamage = -1;
	end

	-- Damage is always given as the amount of damage a character takes
	-- But it is handled opposite that. Positive damage causes a negative change of health
	-- and Negative damage (healing) causes a positive change of health
	-- Which is why we invert nDamage here.
	-- Start by applying damage to the stat specified
	local nOverflow = CharStatManager.addToStatPool(rTarget, sStat, -nDamage);

	-- if there's overflow to the damage, then that means a stat was reduced to 0
	-- in which case we want to drop a blood marker.
	if OptionsManagerCypher.getDeathMarkerOnWound() and (nOverflow * nNegativeIfDamage) < 0 then
		ImageDeathMarkerManager.addMarker(ActorManager.getCTNode(rTarget));
	end

	-- if we shouldn't handle overflowing damage or healing to other stats
	-- then exit here
	if bNoOverflow then
		return;
	end

	-- the return overflow value that addToStatPool returns is always positive
	-- which means we need to apply an inversion depending on if we're healing or damaging
	-- Overflow will follow the normal might -> speed -> intellect damage
	if sStat ~= "might" then
		nOverflow = CharStatManager.addToStatPool(rTarget, "might", nOverflow * nNegativeIfDamage);
	end
	if sStat ~= "speed" then
		nOverflow = CharStatManager.addToStatPool(rTarget, "speed", nOverflow * nNegativeIfDamage);
	end
	if sStat ~= "intellect" then
		nOverflow = CharStatManager.addToStatPool(rTarget, "intellect", nOverflow * nNegativeIfDamage);
	end

	-- Lastly, the addToStatPool function handles updating the character damage track
	-- as the stat pools change to or from 0. This means we don't need to do any of that
	-- tracking here
end

function applyDamageToNpc(rSource, rTarget, nDamage, aNotifications)
	local sTargetNodeType, nodeNPC = ActorManager.getTypeAndNode(rTarget);
	if not nodeNPC then
		return;
	end

	local nWounds = DB.getValue(nodeNPC, "wounds", 0);
	local nHP = DB.getValue(nodeNPC, "hp", 0);

	nWounds = math.max(math.min(nWounds + nDamage, nHP), 0);
	DB.setValue(nodeNPC, "wounds", "number", nWounds);

	-- If the NPC was reduced to 0 HP, add a death marker
	if OptionsManagerCypher.getDeathMarkerOnDamage() and nWounds >= nHP then
		ImageDeathMarkerManager.addMarker(ActorManager.getCTNode(rTarget));
	end
end

-------------------------------------------------------------------------------
-- SHIELD (Temporary HP)
-------------------------------------------------------------------------------
function handleShield(rActor, nDmg, aFilters, aNotifications)
    if not rActor or nDmg == 0 then
        return 0;
    end
    local aEffects, nShield = getShield(rActor, aFilters);
    
    if nShield == 0 then 
        return 0; 
    end

    local nAdjust = deductShield(rActor, nDmg, aEffects);
	if nAdjust >= nDmg then
		table.insert(aNotifications, "[ABSORBED]");
	elseif nAdjust > 0 then
		table.insert(aNotifications, "[PARTIALLY ABSORBED]");
	end
	return nAdjust;
end

-- This gets an ordered list of data for shield effects, as well as the total
-- shield effect bonus
function getShield(rActor, aFilter)
    if not rActor then
        return {}, 0;
    end
    local aEffects = {};
    local nTotal = 0;
    local nMaxPriority = 0;
    local rEffectComps, rEffectData = EffectManagerCypher.getShieldEffects(rActor, aFilter)    

	for i, rEffectComp in ipairs(rEffectComps) do
		nTotal = nTotal + rEffectComp.mod;

		-- These counts are used to determine the effect's priority
		-- The more specific a SHIELD effect is, the higher priority it is
		local nStatFilterCount = 0;
		local nDmgTypeFilterCount = 0;
		for _, sFilter in ipairs(rEffectComp.filters) do
			if StringManager.contains({ "might", "speed", "intellect"}, sFilter) then
				nStatFilterCount = nStatFilterCount + 1;
			else
				nDmgTypeFilterCount = nDmgTypeFilterCount + 1;
			end
		end

		local nPriority = 0;
		if nDmgTypeFilterCount > 0 then
			-- The more damage types it matches with, the lower priority
			nPriority = nPriority + nDmgTypeFilterCount;
		end
		if nStatFilterCount > 0 then
			-- The more stat types it matches with, the lower priority
			-- The x2 here is to weight the priority in favor of stats
			-- so that damage types are generally prioritized first
			nPriority = nPriority + (nStatFilterCount * 2);

		end
		-- At this point, if both filter counts are 0, priority is 0, which is a
		-- Special case. This effect matches ANY damage, so it is always prioritized last.

		if nPriority > nMaxPriority then
			nMaxPriority = nPriority;
		end

		if not aEffects[nPriority] then
			aEffects[nPriority] = {};
		end
		table.insert(aEffects[nPriority], { 
			node = rEffectData[i].node, 
			index = rEffectData[i].index,
			comp = rEffectComp
		});
	end
    
    -- -- Flatten effects table
	local aFlatten = {};
    for i = 1, nMaxPriority do
        if aEffects[i] then
            for _, v in ipairs(aEffects[i]) do
                table.insert(aFlatten, v)
            end
        end
    end
    if aEffects[0] then
        for _, v in ipairs(aEffects[0]) do
            table.insert(aFlatten, v)
        end
    end

    return aFlatten, nTotal
end

-- Handles adjusting shield effects as damage is taken
-- Returns the amount of damage that shields absorbed
function deductShield(rActor, nVal, aEffects)
    if not rActor or nVal == 0 then
        return 0;
    end

    local nAdjust = 0;
    local nRemainder = nVal;
    for _,v in ipairs(aEffects) do
        local rEffectComp = v.comp;
        -- Only continue parsing if we have more damage to deduct
        if nRemainder > 0 then
            local nShield = rEffectComp.mod;
            local nOrigShield = nShield;    -- Save original value for gsub later
            if nShield > 0 then
				-- Either we take the rest of the damage, 
				-- or we take all of the shield effect's value
                local nLocalAdjust = math.min(nShield, nRemainder);

                nShield = math.max(nShield - nLocalAdjust, 0);  -- determine what this effect's new shield value should be
                nRemainder = nRemainder - nLocalAdjust; -- keep track of how much damage we have left to block
                nAdjust = nAdjust + nLocalAdjust;   -- keep track of total dmg adjustment
            end

            if nShield <= 0 then
                ActionDamage.expireShield(rActor, v.node, v.index);
            else
                ActionDamage.setShield(rActor, nOrigShield, nShield, v.node);
            end
        end
    end

    return nAdjust;
end

function setShield(rActor, nOrigShield, nShield, effectNode)
    if not rActor or not nShield or not effectNode then
        return;
    end

    local sLabel = DB.getValue(effectNode, "label", "");
    local sOrigComp = "SHIELD: " .. nOrigShield;
    local sNewComp = "SHIELD: " .. nShield;

    sLabel = sLabel:gsub(sOrigComp, sNewComp);
    DB.setValue(effectNode, "label", "string",  sLabel);
end

function expireShield(rActor, effectNode, compIndex)
    if not rActor or not effectNode or not compIndex then
        return;
    end

    EffectManager.notifyExpire(effectNode, compIndex);
end