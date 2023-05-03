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

	local sDamageDetails = rAction.sDamageStat or "";
	if (rAction.sDamageType or "") ~= "" then
		sDamageDetails = string.format("%s, %s", sDamageDetails, rAction.sDamageType)
	end
	rRoll.sDesc = string.format(
		"[DAMAGE (%s)] %s", 
		sDamageDetails, 
		rAction.label or "");

	rRoll.aDice = { };
	rRoll.nMod = rAction.nDamage or 0;

	RollManager.encodeStat(rAction.sDamageStat, rRoll); -- Encode the stat that takes damage instead of the stat that's used to attack
	RollManager.encodePiercing(rAction, rRoll);
	RollManager.encodeAmbientDamage(rAction, rRoll);
	RollManager.encodeEdge(rAction, rRoll);
	RollManager.encodeEffort(rAction, rRoll);
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = RollManager.decodeStat(rRoll, true); -- Need to persist this to the onRoll handler
	local nEffort = RollManager.decodeEffort(rRoll, true);
	local bPiercing, nPierceAmount = RollManager.decodePiercing(rRoll, true);
	local sDamageType = nil; -- This will get added later.

	-- Adjust difficulty based on effort
	nEffort = nEffort + RollManager.processEffort(rSource, rTarget, sStat, { "damage", "dmg" }, nEffort);
	if (nEffort or 0) > 0 then
		rRoll.nMod = rRoll.nMod + (nEffort * 3);
	end

	bPiercing, nPierceAmount = RollManager.processPiercing(rSource, rTarget, { }); -- Eventually the filter param here will include sDamageType

	local nDmgBonus = EffectManagerCypher.getEffectsBonusByType(rSource, { "damage", "dmg" }, { }, rTarget)
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
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rTarget ~= nil then
		rMessage.text = rMessage.text:gsub(" %[STAT: %w-%]", "");
	end

	local rResult;
	rSource, rTarget, rResult = ActionDamage.buildRollResult(rSource, rTarget, rRoll);

	if rResult.bSourceNPC and rResult.bTargetPC then
		rMessage.text = rMessage.text .. " -> " .. (ActorManager.getDisplayName(rTarget) or "")
	end
	rMessage.icon = "action_damage";
	Comm.deliverChatMessage(rMessage);

	if rTarget then
		ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll);	
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
	-- rResult.sDamageType, rResult.sDamageStat = RollManager.decodeDamageType(rRoll);
	rResult.bPiercing, rResult.nPierceAmount = RollManager.decodePiercing(rRoll, true);
	rResult.bAmbient = RollManager.decodeAmbientDamage(rRoll, true);
	
	if rRoll.nTotal  then
		rResult.nTotal = rRoll.nTotal;
	else
		rResult.nTotal = ActionsManager.total(rRoll);
	end

	return rSource, rTarget, rResult;
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
	msgOOB.nTotal = rResult.nTotal;

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
	Debug.chat('results', rResult);
	
	applyDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), rResult);
end

function applyDamage(rSource, rTarget, bSecret, rResult)
	local sStat = RollManager.decodeStat(rResult, false);
	local bPiercing, nPierceAmount = RollManager.decodePiercing(rResult, true);
	local sDamageType = nil; -- This will get added later.
	local nTotal = rResult.nTotal;

	-- Remember current health status
	local sOriginalStatus = ActorHealthManager.getHealthStatus(rTarget);

	-- Variables for applying damage and building notifications
	local aNotifications = {};

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if not nodeTarget then
		return;
	end

	-- Only calculate damage reduction if we're dealing damage, and not if we're healing
	if nTotal > 0 then
		-- Only calculate piercin
		if not bAmbient then
			local nArmorAdjust = ActorManagerCypher.calculateArmor(rSource, rTarget, sStat);

			if bPiercing then
				-- if pierce amount is 0 (but bPierce is true), then pierce all armor
				-- Otherwise it's a flat reduction
				if nPierceAmount > 0 then
					nArmorAdjust = nArmorAdjust - nPierceAmount;
				elseif nPierceAmount == 0 then
					nArmorAdjust = 0;
				end
			end
			nTotal = nTotal - nArmorAdjust;
		end
		-- This gets added with damage types
		--nTotal = ActionDamageCPP.calculateDamageResistances(rSource, rTarget, nTotal, sDamageType, sDamageStat, aNotifications);
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

function applyDamageToPc(rSource, rTarget, nDamage, sStat, sDamageType, aNotifications)
	local sTargetNodeType, nodePC = ActorManager.getTypeAndNode(rTarget);
	if not nodePC then
		return;
	end

	-- Damage
	if nDamage > 0 then
		-- Start by applying damage to the stat specified
		local nOverflow = ActorManagerCypher.addToStatPool(rSource, sStat, -nDamage);

		-- Overflow will follow the normal might -> speed -> intellect damage
		nOverflow = ActorManagerCypher.addToStatPool(rSource, "might", -nOverflow);
		nOverflow = ActorManagerCypher.addToStatPool(rSource, "speed", -nOverflow);
		nOverflow = ActorManagerCypher.addToStatPool(rSource, "intellect", -nOverflow);
	
	-- Healing?
	elseif nDamage < 0 then
		-- Start by healing the stat specified
		local nOverflow = ActorManagerCypher.addToStatPool(rSource, sStat, nDamage);

		-- Overflow will follow the opposite of damage, intellect_new -> speed -> might damage
		nOverflow = ActorManagerCypher.addToStatPool(rSource, "intellect", nOverflow);
		nOverflow = ActorManagerCypher.addToStatPool(rSource, "speed", nOverflow);
		nOverflow = ActorManagerCypher.addToStatPool(rSource, "might", nOverflow);
	end
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