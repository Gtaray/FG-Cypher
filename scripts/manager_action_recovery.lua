-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerResultHandler("recovery", onRoll);
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

function applyRecovery(nodeActor, nMightNew, nSpeedNew, nIntellectNew, nRemainder)
    local rActor = ActorManager.resolveActor(nodeActor);
    local nRemoveWounded = 0;
    local rMessage = ChatManager.createBaseMessage(rActor, User.getUsername());
    rMessage.text = "[RECOVERY]";

    local nMightCurrent = DB.getValue(nodeActor, "abilities.might.current", 0);    
    if nMightCurrent < nMightNew then
        if nMightCurrent == 0 then
            nRemoveWounded = nRemoveWounded + 1;
        end

        rMessage.text = rMessage.text .. " [APPLIED " .. tostring(nMightNew - nMightCurrent) .. " to MIGHT]";

        DB.setValue(nodeActor, "abilities.might.current", "number", nMightNew);
    end

    local nSpeedCurrent = DB.getValue(nodeActor, "abilities.speed.current", 0);
    if nSpeedCurrent < nSpeedNew then
        if nSpeedCurrent == 0 then
            nRemoveWounded = nRemoveWounded + 1;
        end

        rMessage.text = rMessage.text .. " [APPLIED " .. tostring(nSpeedNew - nSpeedCurrent) .. " to SPEED]";

        DB.setValue(nodeActor, "abilities.speed.current", "number", nSpeedNew);
    end

    local nIntellectCurrent = DB.getValue(nodeActor, "abilities.intellect.current", 0);
    if nIntellectCurrent < nIntellectNew then
        if nIntellectCurrent == 0 then
            nRemoveWounded = nRemoveWounded + 1;
        end

        rMessage.text = rMessage.text .. " [APPLIED " .. tostring(nIntellectNew - nIntellectCurrent) .. " to INTELLECT]";

        DB.setValue(nodeActor, "abilities.intellect.current", "number", nIntellectNew);
    end

    if nRemainder > 0 then
        rMessage.text = rMessage.text .. " Remainder " .. tostring(nRemainder);
    end

    if nRemoveWounded > 0 then
        local nCurrentWounded = DB.getValue(nodeActor, "wounds", 0);
        local nNewWounded = math.max(nCurrentWounded - nRemoveWounded, 0);
        DB.setValue(nodeActor, "wounds", "number", nNewWounded);

        rMessage.text = rMessage.text .. " [DAMAGE TRACK RECOVERED BY " .. tostring(nCurrentWounded - nNewWounded) .. "]";
    end

    Comm.deliverChatMessage(rMessage);
end
