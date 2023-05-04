-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
function onInit()	
	local nodeActor = window.getDatabaseNode();

	if stat and stat[1] then
		DB.addHandler(DB.getPath(nodeActor, "abilities", stat[1], "max"), "onUpdate", onMaxUpdated);
		onMaxUpdated();
	end
end

function onClose()
	local nodeActor = window.getDatabaseNode();
	if stat and stat[1] then
		DB.removeHandler(DB.getPath(nodeActor, "abilities", stat[1], "max"), "onUpdate", onMaxUpdated);
	end
end

function onMaxUpdated()
	local nodeActor = window.getDatabaseNode();
	if stat and stat[1] then
		local _, nMax = ActorManagerCypher.getStatPool(nodeActor, stat[1])
		setMaxValue(nMax);
	end
end

function action(draginfo)
	local sStat = stat[1];
	if (sStat or "") == "" then
		return;
	end

	local rAction = {
		label = StringManager.capitalize(sStat),
		sStat = sStat
	}
	
	local rActor = ActorManager.resolveActor(window.getDatabaseNode())
	ActionStat.performRoll(draginfo, rActor, rAction);
end

function onDoubleClick(x, y)
	action();
	return true;
end
function onDragStart(button, x, y, draginfo)
	action(draginfo);
	return true;
end

function getActorNode()
	return DB.getChild(getDatabaseNode(), "....");
end

---------------------------------------------
-- HANDLE HEALING ON DROP
---------------------------------------------
function onDrop(x, y, draginfo)
	if draginfo.isType("recovery") then
		self.handleRecoveryDrop(draginfo);
		return true;
	end
end
function handleRecoveryDrop(draginfo)
	local aDice = draginfo.getDiceData();
	if aDice then
		return;
	end
	local nApplied = draginfo.getNumberData();
	local nRemainder = 0;
    local bRemoveWound = false;

    if getValue() == 0 and nApplied > 0 then
        bRemoveWound = true;
    end

	local nPool = getValue() + nApplied;
	local nMax = DB.getValue(getDatabaseNode(), "..max", 10);
	
	if nPool > nMax then
		nRemainder = nPool - nMax;
		nApplied = nApplied - nRemainder;
		nPool = nMax;
	end
	
	if nApplied > 0 then
		setValue(nPool);
	
		local sName = StringManager.capitalize(DB.getName(DB.getParent(getDatabaseNode())));
		
		if nRemainder > 0 then
			local rRoll = { sType = "recovery", aDice = {}, nMod = nRemainder };
			rRoll.sDesc = string.format("[RECOVERY] [APPLIED %d TO %s] Remainder", nApplied, sName);
			local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
			Comm.deliverChatMessage(rMessage);
		else
			local rRoll = {};
			rRoll.sDesc = string.format("[RECOVERY] [APPLIED %d TO %s]", nApplied, sName);
			local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
			Comm.deliverChatMessage(rMessage);
		end
	end

    if bRemoveWound then
        local nCurrentWound = DB.getValue(window.getDatabaseNode(), "wounds", 0);
        DB.setValue(window.getDatabaseNode(), "wounds", "number", math.max(0, nCurrentWound - 1));
    end
end
