-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local sStat = stat[1];
	if (sStat or "") == "" then
		return;
	end

	local nodeActor = window.getDatabaseNode();
	local sDesc = string.format("[SKILL] %s Defense", Interface.getString(sStat));
	local tInfo = RollManager.buildPCRollInfo(nodeActor, sDesc, sStat);
	if not tInfo then
		return;
	end
	tInfo.nTraining = DB.getValue(nodeActor, "abilities." .. tInfo.sStat .. ".def.training", 1);
	tInfo.nAssets = DB.getValue(nodeActor, "abilities." .. tInfo.sStat .. ".def.asset", 0);
	tInfo.nMod = DB.getValue(nodeActor, "abilities." .. tInfo.sStat .. ".def.misc", 0);

	RollManager.resolveAdjustments(tInfo);
	if not RollManager.spendPointsForRoll(nodeActor, tInfo) then
		return;
	end

	local rActor = ActorManager.resolveActor(nodeActor);
	local rRoll = { sType = "dice", sDesc = tInfo.sDesc, aDice = { "d20" }, nMod = tInfo.nMod, nShift = tInfo.nTotalStep };
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onButtonPress()
	action();
	return true;
end
function onDragStart(button, x, y, draginfo)
	action(draginfo);
	return true;
end
