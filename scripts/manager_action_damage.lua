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

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		ActionDamage.performRoll(draginfo, rActor, rAction);
	end
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
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

	rRoll.sDesc = string.format("[DAMAGE (%s", StringManager.capitalize(rRoll.sDamageStat));

	if (rAction.sDamageType or "") ~= "" then
		rRoll.sDesc = string.format("%s, %s", rRoll.sDesc, rAction.sDamageType)
	end
	rRoll.sDesc = string.format(
		"%s)] %s", 
		rRoll.sDesc, 
		rRoll.sLabel);

	rRoll.bOngoing = rAction.bOngoing;
	rRoll.bAmbient = rAction.bAmbient or false;
	rRoll.bPiercing = rAction.bPiercing or false;
	if rRoll.bPiercing then
		rRoll.nPierceAmount = rAction.nPierceAmount;
	end

	if rAction.bSecret then
		rRoll.bSecret = true;
	end
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	if ActionDamage.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	local aFilter = { "damage", "dmg" };

	-- Adjust mod based on effort
	rRoll.nEffort = (rRoll.nEffort or 0) + RollManager.processEffort(rSource, rTarget, aFilter, rRoll.nEffort);
	if (rRoll.nEffort or 0) > 0 then
		rRoll.nMod = rRoll.nMod + (rRoll.nEffort * 3);
	end

	rRoll.bPiercing, rRoll.nPierceAmount = RollManager.processPiercing(rSource, rTarget, rRoll.bPiercing, rRoll.nPierceAmount, rRoll.sDamageType, rRoll.sStat);

	local nDmgBonus = EffectManagerCypher.getDamageEffectBonus(rSource, rRoll.sDamageType, rRoll.sStat, rTarget)
	if nDmgBonus ~= 0 then
		rRoll.nMod = rRoll.nMod + nDmgBonus;
	end

	-- We fake the action object here when encoding piercing
	-- Because it requires two variables as an input
	-- instead of just the single that most encodes have
	RollManager.encodeOngoingDamage({ bOngoing = rRoll.bOngoing }, rRoll)
	RollManager.encodeAmbientDamage({ bAmbient = rRoll.bAmbient }, rRoll);
	RollManager.encodePiercing({ bPierce = rRoll.bPiercing, nPierceAmount = rRoll.nPierceAmount }, rRoll);
	RollManager.encodeEffort(nEffort, rRoll)
	RollManager.encodeEffects(rRoll, nDmgBonus);
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

	rRoll.bRebuilt = bRebuilt;
	return bRebuilt;
end

function onRoll(rSource, rTarget, rRoll)
	local rResult = ActionDamage.buildRollResult(rSource, rTarget, rRoll);
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rResult.bSourceNPC and rResult.bTargetPC then
		rMessage.text = rMessage.text .. " -> " .. (ActorManager.getDisplayName(rTarget) or "")
	end
	rMessage.icon = "action_damage";
	Comm.deliverChatMessage(rMessage);

	if rTarget then
		ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll, rResult);	
	end	
end

function buildRollResult(rSource, rTarget, rRoll)
	local rResult = {};

	rResult.sDesc = rRoll.sDesc;
	rResult.bSourcePC = (rSource and ActorManager.isPC(rSource)) or false;
	rResult.bTargetPC = (rTarget and ActorManager.isPC(rTarget)) or false;
	rResult.bSourceNPC = (rSource and not ActorManager.isPC(rSource)) or false;
	rResult.bTargetNPC = (rTarget and not ActorManager.isPC(rTarget)) or false;
	rResult.sDamageStat = rRoll.sDamageStat
	rResult.sDamageType = (rRoll.sDamageType or ""):lower()
	rResult.bPiercing = rRoll.bPiercing;
	rResult.nPierceAmount = rRoll.nPierceAmount
	rResult.bAmbient = rRoll.bAmbient
	rResult.bOngoing = rRoll.bOngoing;
	
	if rRoll.nTotal  then
		rResult.nTotal = rRoll.nTotal;
	else
		rResult.nTotal = ActionsManager.total(rRoll);
	end
	
	return rResult;
end

function notifyApplyDamage(rSource, rTarget, rRoll, rResult)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMG;
	
	if rRoll.bTower or rRoll.bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.nTargetOrder = rTarget.nOrder;
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	msgOOB.nTotal = rResult.nTotal or 0;
	msgOOB.sDamageStat = rResult.sDamageStat
	msgOOB.sDamageType = rResult.sDamageType

	msgOOB.bPiercing = "false";
	if rRoll.bPiercing then
		msgOOB.bPiercing = "true";
	end
	msgOOB.nPierceAmount = rRoll.nPierceAmount

	msgOOB.bAmbient = "false";
	if rRoll.bAmbient then
		msgOOB.bAmbient = "true";
	end

	msgOOB.bOngoing = "false";
	if rRoll.bOngoing then
		msgOOB.bOngoing = "true";
	end

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
		bPiercing = msgOOB.bPiercing == "true",
		nPierceAmount = msgOOB.nPierceAmount,
		bAmbient = msgOOB.bAmbient == "true",
		bOngoing = msgOOB.bOngoing == "true"
	}
	local rResult = ActionDamage.buildRollResult(rSource, rTarget, rRoll);
	applyDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), rResult);
end

function applyDamage(rSource, rTarget, bSecret, rResult)
	local sStat = RollManager.decodeStat(rResult, false);
	local bPiercing, nPierceAmount = RollManager.decodePiercing(rResult, true);
	local bOngoing = RollManager.decodeOngoingDamage(rResult, true);
	local sDamageType = rResult.sDamageType;
	local nTotal = rResult.nTotal;

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
	if (sDamageType or "") == "" then
		sDamageType = "untyped";
	end

	if not bAmbient and (bOngoing and sDamageType ~= "untyped") then
		nTotal = ActionDamage.applyArmor(
			rSource, 
			rTarget, 
			nTotal, 
			sStat, 
			sDamageType,
			bPiercing, 
			nPierceAmount, 
			aNotifications);
	end

	if sTargetNodeType == "pc" then
		ActionDamage.applyDamageToPc(rSource, rTarget, nTotal, sStat, sDamageType, aNotifications);
	elseif sTargetNodeType == "ct" then
		ActionDamage.applyDamageToNpc(rSource, rTarget, nTotal, sStat, sDamageType, aNotifications);
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

	-- Output
	if not (rTarget or sExtraResult ~= "") then
		return;
	end
	
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgLong.text = "";
	if nTotal < 0 then
		msgShort.icon = "roll_heal";
		msgLong.icon = "roll_heal";

		-- Report positive values only
		nTotal = math.abs(nTotal);
		msgShort.text = string.format("[heal %s]", nTotal);
		msgLong.text = string.format("[heal %s]", nTotal);
		
	else
		msgShort.icon = "roll_damage";
		msgLong.icon = "roll_damage";

		if sDamageType ~= "untyped" then
			msgShort.text = string.format("[%s %s damage]", nTotal, sDamageType);
			msgLong.text = string.format("[%s %s damage]", nTotal, sDamageType);
		else
			msgShort.text = string.format("[%s damage]", nTotal);
			msgLong.text = string.format("[%s damage]", nTotal);
		end
	end

	if rTarget then
		msgShort.text = string.format("%s -> [to %s", msgShort.text, ActorManager.getDisplayName(rTarget));
		msgLong.text = string.format("%s -> [to %s", msgLong.text, ActorManager.getDisplayName(rTarget));
	end

	if ActorManager.isPC(rTarget) and (sStat or "") ~= "" then
		msgShort.text = string.format("%s's %s", msgShort.text, sStat);
		msgLong.text = string.format("%s's %s", msgLong.text, sStat);
	end

	msgShort.text = msgShort.text .. "]";
	msgLong.text = msgLong.text .. "]";
	
	if #aNotifications > 0 then
		msgLong.text = string.format("%s %s", msgLong.text, table.concat(aNotifications, " "));
	end
	
	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

function applyArmor(rSource, rTarget, nTotal, sStat, sDamageType, bPiercing, nPierceAmount, aNotifications)
	-- If for some reason the amount of damage is negative, then we don't need to do any processing
	-- Because it's handling as healing
	if nTotal < 0 then
		return nTotal;
	end
	
	if ActorManagerCypher.isImmune(rTarget, rSource, { sDamageType, sDamageStat }) then
		table.insert(aNotifications, "[IMMUNE]");
		return 0;
	end

	local nArmorAdjust = ActorManagerCypher.getArmor(rTarget, rSource, sStat, sDamageType);

	-- only apply piercing if the armor adjustment is positive. 
	-- negative armor adjust means there's a vulnerability to a dmg type
	if bPiercing and nArmorAdjust > 0 then
		-- if pierce amount is 0 (but bPierce is true), then pierce all armor
		-- Otherwise it's a flat reduction
		if nPierceAmount > 0 then
			nArmorAdjust = nArmorAdjust - nPierceAmount;
		elseif nPierceAmount == 0 then
			nArmorAdjust = 0;
		end

		-- If piercing reduces the amount of armor below super armor value
		-- then the math.max() function will bring armor adjust back up to the 
		-- super armor value
		local nSuperArmor = ActorManagerCypher.getSuperArmor(rTarget, rSource, sStat, sDamageType);
		nArmorAdjust = math.max(nArmorAdjust, nSuperArmor);
	end

	-- Apply VULN effect
	local nVuln = EffectManagerCypher.getVulnerabilityEffectBonus(rTarget, sDamageType, sStat, rSource)
	if nVuln > 0 then
		nArmorAdjust = nArmorAdjust - nVuln;
	end

	-- If any amount of armor was applied, then we add a notification
	if nVuln > 0 or nArmorAdjust < 0 then -- Less than 0
		table.insert(aNotifications, "[VULNERABLE]");
	elseif nArmorAdjust == 0 then -- Equal to 0
		-- Do nothing
	elseif nArmorAdjust < nTotal then -- Greater than 0 but less than damage
		table.insert(aNotifications, "[PARTIALLY RESISTED]");
	elseif nArmorAdjust >= 0 then -- Equal or greater than damage
		table.insert(aNotifications, "[RESISTED]");
	end

	-- Apply the adjusted armor value to the total damage
	-- Damage cannot fall below 0 though, otherwise that's healing
	nTotal = math.max(nTotal - nArmorAdjust, 0);

	return nTotal 
end

function applyDamageToPc(rSource, rTarget, nDamage, sStat, sDamageType, aNotifications)
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
	local nOverflow = ActorManagerCypher.addToStatPool(rTarget, sStat, -nDamage);

	-- the return overflow value that addToStatPool returns is always positive
	-- which means we need to apply an inversion depending on if we're healing or damaging
	-- Overflow will follow the normal might -> speed -> intellect damage
	if sStat ~= "might" then
		nOverflow = ActorManagerCypher.addToStatPool(rTarget, "might", nOverflow * nNegativeIfDamage);
	end
	if sStat ~= "speed" then
		nOverflow = ActorManagerCypher.addToStatPool(rTarget, "speed", nOverflow * nNegativeIfDamage);
	end
	if sStat ~= "intellect" then
		nOverflow = ActorManagerCypher.addToStatPool(rTarget, "intellect", nOverflow * nNegativeIfDamage);
	end

	-- Lastly, the addToStatPool function handles updating the character damage track
	-- as the stat pools change to or from 0. This means we don't need to do any of that
	-- tracking here
end

function applyDamageToNpc(rSource, rTarget, nDamage, sDamageStat, sDamageType, aNotifications)
	local sTargetNodeType, nodeNPC = ActorManager.getTypeAndNode(rTarget);
	if not nodeNPC then
		return;
	end

	local nWounds = DB.getValue(nodeNPC, "wounds", 0);
	local nHP = DB.getValue(nodeNPC, "hp", 0);

	nWounds = math.max(math.min(nWounds + nDamage, nHP), 0);
	DB.setValue(nodeNPC, "wounds", "number", nWounds);
end