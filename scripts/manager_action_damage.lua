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

function performRoll(draginfo, rActor, rAction)
	local aFilter = { "damage", "dmg" };

	RollManager.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addArmorCostToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rActor, rAction);
	RollManager.resolveMaximumEffort(rActor, rAction, aFilter);
	RollManager.calculateBaseEffortCost(rActor, rAction);
	RollManager.adjustEffortCostWithEffects(rActor, rAction, aFilter);
	
	local bCanRoll = true; -- NPCs can always roll
	if ActorManager.isPC(rActor) then
		bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);
	end

	if bCanRoll then
		local rRoll = getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function getRoll(rActor, rAction)
	local rRoll = {}
	rRoll.sType = "damage"

	local sDamageDetails = StringManager.capitalize(rAction.sDamageStat or "");
	if (rAction.sDamageType or "") ~= "" then
		sDamageDetails = string.format("%s, %s", sDamageDetails, rAction.sDamageType)
	end
	rRoll.sDesc = string.format(
		"[DAMAGE (%s)] %s", 
		sDamageDetails, 
		rAction.label or "");

	rRoll.aDice = { };
	rRoll.nMod = rAction.nDamage or 0;

	RollManager.encodeStat(rAction, rRoll); -- Encode the stat that takes damage instead of the stat that's used to attack
	RollManager.encodePiercing(rAction, rRoll);
	RollManager.encodeAmbientDamage(rAction, rRoll);
	RollManager.encodeEdge(rAction, rRoll);
	RollManager.encodeEffort(rAction, rRoll);
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	 -- We want to get rid of the [STAT: %s] tag here, because the onRoll handler
	 -- will decode the [DAMAGE (%s)] stat tag (which is the stat that's being damaged)
	 -- We only need the source's stat to handle effects
	local sStat = RollManager.decodeStat(rRoll, false);
	local nEffort = RollManager.decodeEffort(rRoll, true);
	local bPiercing, nPierceAmount = RollManager.decodePiercing(rRoll, true);
	local sDamageType = RollManager.decodeDamageType(rRoll);

	-- Adjust mod based on effort
	nEffort = nEffort + RollManager.processEffort(rSource, rTarget, { "damage", "dmg" }, nEffort);
	if (nEffort or 0) > 0 then
		rRoll.nMod = rRoll.nMod + (nEffort * 3);
	end

	bPiercing, nPierceAmount = RollManager.processPiercing(rSource, rTarget, bPiercing, nPierceAmount, { }); -- Eventually the filter param here will include sDamageType

	local nDmgBonus = EffectManagerCypher.getEffectsBonusByType(rSource, { "damage", "dmg" }, { sStat, sDamageType }, rTarget)
	if nDmgBonus ~= 0 then
		rRoll.nMod = rRoll.nMod + nDmgBonus;
	end

	-- We fake the action object here when encoding piercing
	-- Because it requires two variables as an input
	-- instead of just the single that most encodes have
	RollManager.encodePiercing({ bPierce = bPiercing, nPierceAmount = nPierceAmount }, rRoll);
	RollManager.encodeEffort(nEffort, rRoll)
	RollManager.encodeEffects(rRoll, nDmgBonus);
end

function onRoll(rSource, rTarget, rRoll)
	local rResult = ActionDamage.buildRollResult(rSource, rTarget, rRoll);

	RollManager.decodeStat(rRoll, false); -- We no longer need the stat in the text once we've built the result table
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
	rResult.sStat = RollManager.decodeStat(rRoll, true);
	rResult.sDamageType = RollManager.decodeDamageType(rRoll);
	rResult.bPiercing, rResult.nPierceAmount = RollManager.decodePiercing(rRoll, true);
	rResult.bAmbient = RollManager.decodeAmbientDamage(rRoll, true);
	
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
	
	if rRoll.bTower then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.nTargetOrder = rTarget.nOrder;
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	msgOOB.nTotal = rResult.nTotal or 0;

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
		nTotal = tonumber(msgOOB.nTotal)
	}
	local rResult = ActionDamage.buildRollResult(rSource, rTarget, rRoll);
	
	applyDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), rResult);
end

function applyDamage(rSource, rTarget, bSecret, rResult)
	local sStat = RollManager.decodeStat(rResult, false);
	local bPiercing, nPierceAmount = RollManager.decodePiercing(rResult, true);
	local sDamageType = rResult.sDamageType;
	local nTotal = rResult.nTotal;
	local bUseDamageTypes = OptionsManagerCypher.replaceArmorWithDamageTypes()

	-- Remember current health status
	local sOriginalStatus = ActorHealthManager.getHealthStatus(rTarget);

	-- Variables for applying damage and building notifications
	local aNotifications = {};

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if not nodeTarget then
		return;
	end

	if not bAmbient then
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
		msgLong.text = string.format("[%s healing", nTotal)
		if (sStat or "") ~= "" then
			msgLong.text = string.format("%s %s", msgLong.text, sStat)
		end
		msgLong.text = string.format("%s]", msgLong.text)
		
	else
		msgShort.icon = "roll_damage";
		msgLong.icon = "roll_damage";

		if sDamageType then
			msgLong.text = string.format("[%s %s damage]", nTotal, sDamageType);
		else
			msgLong.text = string.format("[%s damage]", nTotal);
		end
	end

	msgLong.text = string.format("%s ->", msgLong.text);
	if rTarget then
		msgLong.text = string.format("%s [to %s", msgLong.text, ActorManager.getDisplayName(rTarget));
	end

	if ActorManager.isPC(rTarget) and (sStat or "") ~= "" then
		msgLong.text = string.format("%s's %s", msgLong.text, sStat);
	end
	msgLong.text = msgLong.text .. "]";
	msgShort.text = msgLong.text;
	
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

	-- if damage type is not specified, then we make sure it has
	-- the untyped value here. This makes all of the calcs easier
	if not sDamageType then
		sDamageType = "untyped";
	end
	
	if ActorManagerCypher.isImmune(rTarget, rSource, { sDamageType, sDamageStat }) then
		table.insert(aNotifications, "[IMMUNE]");
		return 0;
	end

	local nArmorAdjust = ActorManagerCypher.getArmor(rTarget, rSource, sStat);

	if bPiercing then
		-- if pierce amount is 0 (but bPierce is true), then pierce all armor
		-- Otherwise it's a flat reduction
		if nPierceAmount > 0 then
			nArmorAdjust = nArmorAdjust - nPierceAmount;
		elseif nPierceAmount == 0 then
			nArmorAdjust = 0;
		end
	end

	-- if the adjusted armor is reduced to below 0
	-- then we return all the damage
	if nArmorAdjust <= 0 then
		return nTotal;
	end

	-- Apply the adjusted armor value to the total damage
	nTotal = nTotal - nArmorAdjust;

	-- If any amount of armor was applied, then we add a notification
	if nTotal <= 0 then
		table.insert(aNotifications, "[RESISTED]");
	else
		table.insert(aNotifications, "[PARTIALLY RESISTED]");
	end

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