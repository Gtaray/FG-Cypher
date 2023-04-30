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
	if rAction.aDice then
		rRoll.aDice = rAction.aDice;
	else
		rRoll.aDice = { "d6" };
	end
	rRoll.nMod = ActorManagerCypher.getTier(rActor) + ActorManagerCypher.getRecoveryRollMod(rActor) + (rAction.nModifer or 0);
	rRoll.sDesc = "[RECOVERY]";
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local nRecoveryEffect = EffectManager.getEffectsBonusByType(rSource, { "RECOVERY", "REC" }, { });

	-- Only continue if the recovery effect is not zero
	if nRecoveryEffect == 0 then
		return;
	end
	rRoll.nMod = rRoll.nMod + nRecoveryEffect;
	RollManager.encodeEffects(rRoll, nRecoveryEffect);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rSource);

	if sNodeType == "pc" then
		local c = DB.getValue(nodeActor, "recoveryused", 0);
		if c >= 4 then
			rMessage.text = rMessage.text .. " [NO RECOVERIES REMAINING]";
		elseif c == 3 then
			rMessage.text = rMessage.text .. " [10 HOURS]";
		elseif c == 2 then
			rMessage.text = rMessage.text .. " [1 HOUR]";
		elseif c == 1 then
			rMessage.text = rMessage.text .. " [10 MINUTES]";
		else
			rMessage.text = rMessage.text .. " [1 ACTION]";
		end
		if c < 4 then
			DB.setValue(nodeActor, "recoveryused", "number", c + 1);
		end
	end
	
	Comm.deliverChatMessage(rMessage);

    -- Now open the dialog to assign the recovery points
    local wRecovery = Interface.openWindow("recovery", DB.getPath(nodeActor));
    wRecovery.recovery_remaining.setValue(ActionsManager.total(rRoll));
end

function applyRecovery(nodeChar, nMightNew, nSpeedNew, nIntellectNew, nRemainder)
    local rActor = ActorManager.resolveActor(nodeChar);
	local nWoundTrackCurrent = ActorManagerCypher.getDamageTrack(rActor);
    local nWoundTrackAdjust = 0; -- This is tracked as a negative amount
    local rMessage = ChatManager.createBaseMessage(rActor, User.getUsername());
    rMessage.text = "[RECOVERY]";

    local nMightCurrent = ActorManagerCypher.getStatPool(rActor, "might");
    if nMightCurrent < nMightNew then
        if nMightCurrent == 0 then
            nWoundTrackAdjust = nWoundTrackAdjust - 1;
        end

        rMessage.text = string.format("%s [APPLIED %s to MIGHT]", rMessage.text, tostring(nMightNew - nMightCurrent));
		ActorManagerCypher.setStatPool(rActor, "might", nMightNew);
    end

    local nSpeedCurrent = ActorManagerCypher.getStatPool(rActor, "speed");
    if nSpeedCurrent < nSpeedNew then
        if nSpeedCurrent == 0 then
            nWoundTrackAdjust = nWoundTrackAdjust - 1;
        end

		rMessage.text = string.format("%s [APPLIED %s to SPEED]", rMessage.text, tostring(nSpeedNew - nSpeedCurrent));
        ActorManagerCypher.setStatPool(rActor, "speed", nSpeedNew);
    end

    local nIntellectCurrent = ActorManagerCypher.getStatPool(rActor, "intellect");
    if nIntellectCurrent < nIntellectNew then
        if nIntellectCurrent == 0 then
			nWoundTrackAdjust = nWoundTrackAdjust - 1;
        end

		rMessage.text = string.format("%s [APPLIED %s to INTELLECT]", rMessage.text, tostring(nIntellectNew - nIntellectCurrent));
        ActorManagerCypher.setStatPool(rActor, "intellect", nIntellectNew);
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
end
