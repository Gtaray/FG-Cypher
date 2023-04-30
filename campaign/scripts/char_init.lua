-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function actionInit()
	local nodeActor = getDatabaseNode();

	local sDesc = "[INIT] [SPEED]";
	local sStat = "speed";
	local tInfo = RollManager.buildPCRollInfo(nodeActor, sDesc, sStat);
	if not tInfo then
		return;
	end
	tInfo.nTraining = inittraining.getValue();
	tInfo.nAssets = initasset.getValue();
	tInfo.nMod = initmod.getValue();

	RollManager.resolveAdjustments(tInfo);
	if not RollManager.spendPointsForRoll(nodeActor, tInfo) then
		return;
	end

	local rActor = ActorManager.resolveActor(nodeActor);
	local rRoll = { sType = "init", sDesc = tInfo.sDesc, aDice = { "d20" }, nMod = tInfo.nMod + (tInfo.nTotalStep * 3) };
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
