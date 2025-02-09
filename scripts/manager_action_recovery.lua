-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("recovery", modRoll)
	ActionsManager.registerResultHandler("recovery", onRoll);
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionRecovery.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "recovery";
	rRoll.aDice = DiceRollManager.getActorDice(rAction.aDice or { "d6" }, rActor);
	rRoll.nMod = CharHealthManager.getRecoveryRollTotal(rActor) + (rAction.nModifer or 0);
	rRoll.sDesc = "[RECOVERY]";
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local nRecoveryEffect = EffectManagerCypher.getRecoveryEffectBonus(rSource, { });

	-- Only continue if the recovery effect is not zero
	if nRecoveryEffect == 0 then
		return;
	end
	rRoll.nMod = rRoll.nMod + nRecoveryEffect;
	RollManager.encodeEffects(rRoll, nRecoveryEffect);
	RollManager.convertBooleansToNumbers(rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "roll_heal";
	
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rSource);
	local nTotal = ActionsManager.total(rRoll);

	sFilter = nil;
	if sNodeType == "pc" then
		local c = DB.getValue(nodeActor, "recoveryused", 0);
		if c >= 4 then
			rMessage.text = rMessage.text .. " [NO RECOVERIES REMAINING]";
			sFilter= "day"
		elseif c == 3 then
			rMessage.text = rMessage.text .. " [10 HOURS]";
			sFilter = "day"
		elseif c == 2 then
			rMessage.text = rMessage.text .. " [1 HOUR]";
			sFilter = "hour"
		elseif c == 1 then
			rMessage.text = rMessage.text .. " [10 MINUTES]";
			sFilter = "minute"
		else
			rMessage.text = rMessage.text .. " [1 ACTION]";
			sFilter = "action"
		end
		
		if c < 4 then
			DB.setValue(nodeActor, "health.recovery.used", "number", c + 1);
		end

		if EffectManagerCypher.ignoreRecovery(rSource, sFilter) then
			rMessage.text = rMessage.text .. " [NONE]";
			nTotal = 0;
		elseif EffectManagerCypher.isRecoveryHalved(rSource, sFilter) then
			rMessage.text = rMessage.text .. " [HALF]";
			nTotal = math.floor(nTotal / 2);
		end
	end
	
	Comm.deliverChatMessage(rMessage);

    -- Now open the dialog to assign the recovery points
	if nTotal > 0 then
		local wRecovery = Interface.openWindow("recovery", DB.getPath(nodeActor));
		wRecovery.setRecoveryAmount(nTotal);
	end
end

function applyRecovery(nodeChar, nMightNew, nSpeedNew, nIntellectNew, nRemainder)
    local rActor = ActorManager.resolveActor(nodeChar);
	local nWoundTrackCurrent = CharHealthManager.getDamageTrack(rActor);
    local nWoundTrackAdjust = 0; -- This is tracked as a negative amount
    local rMessage = ChatManager.createBaseMessage(rActor, User.getUsername());
    rMessage.text = "[RECOVERY]";

    local nMightCurrent = CharStatManager.getStatPool(rActor, "might");
    if nMightCurrent < nMightNew then
        if nMightCurrent == 0 then
            nWoundTrackAdjust = nWoundTrackAdjust - 1;
        end

        rMessage.text = string.format("%s [APPLIED %s to MIGHT]", rMessage.text, tostring(nMightNew - nMightCurrent));
		CharStatManager.setStatPool(rActor, "might", nMightNew);
    end

    local nSpeedCurrent = CharStatManager.getStatPool(rActor, "speed");
    if nSpeedCurrent < nSpeedNew then
        if nSpeedCurrent == 0 then
            nWoundTrackAdjust = nWoundTrackAdjust - 1;
        end

		rMessage.text = string.format("%s [APPLIED %s to SPEED]", rMessage.text, tostring(nSpeedNew - nSpeedCurrent));
        CharStatManager.setStatPool(rActor, "speed", nSpeedNew);
    end

    local nIntellectCurrent = CharStatManager.getStatPool(rActor, "intellect");
    if nIntellectCurrent < nIntellectNew then
        if nIntellectCurrent == 0 then
			nWoundTrackAdjust = nWoundTrackAdjust - 1;
        end

		rMessage.text = string.format("%s [APPLIED %s to INTELLECT]", rMessage.text, tostring(nIntellectNew - nIntellectCurrent));
        CharStatManager.setStatPool(rActor, "intellect", nIntellectNew);
    end

    if nRemainder > 0 then
		rMessage.text = string.format("%s Remainder %s", rMessage.text, tostring(nRemainder))
    end

	-- Get the actual amount the wound track was modified by
	local nActualWoundTrackAdjust = math.max(math.min(math.abs(nWoundTrackAdjust), nWoundTrackCurrent), 0);
    if nActualWoundTrackAdjust > 0 then
		-- No need to adjust the damage track here because the setStatPool functions in the
		-- actor manager will adjust the damage track levels as the pools are changed
		rMessage.text = string.format(
			"%s [DAMAGE TRACK RECOVERED BY %s]", 
			rMessage.text, 
			tostring(nActualWoundTrackAdjust))
    end

    Comm.deliverChatMessage(rMessage);

	local nRecoveryUsed = DB.getValue(nodeChar, "health.recovery.used", 0);

	-- Handle recharging powers
	for _, abilityNode in ipairs(DB.getChildList(nodeChar, "abilitylist")) do
		local sPeriod = DB.getValue(abilityNode, "period", "");
		local bRecharge = (sPeriod == "first" and nRecoveryUsed == 1) or 
						  (sPeriod == "last" and nRecoveryUsed == 4) or
						  (sPeriod == "any");

		if bRecharge then
			DB.setValue(abilityNode, "used", "number", 0);
		end
	end

	-- Handle advancing and expiring effects
	for _,nodeEffect in pairs(DB.getChildList(ActorManager.getCTNode(nodeChar), "effects")) do
		ActionRecovery.adjustEffectDuration(nodeEffect, nRecoveryUsed);
	end
end

function adjustEffectDuration(nodeEffect, nRecoveryUsed)
	local nDur = DB.getValue(nodeEffect, "duration", 0);

	-- effects with no duration get ignored
	if nDur == 0 then
		return;
	end

	-- just took 10 minute recovery
	if nRecoveryUsed == 2 then
		nDur = nDur - 600; -- 600 rounds per 10 minutes
		
	-- just took 1 hour recovery
	elseif nRecoveryUsed == 3 then
		nDur = nDur - 3600

	-- just took 10 hour recovery
	elseif nRecoveryUsed == 4 then
		nDur = nDur - 36000
	end

	if nDur <= 0 then
		EffectManager.notifyExpire(nodeEffect, 0, true);
		return;
	end

	DB.setValue(nodeEffect, "duration", "number", nDur);
end
