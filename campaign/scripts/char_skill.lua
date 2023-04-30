-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Check constraints and set up for an ability roll.
function actionSkill(draginfo)
	local nodeActor = windowlist.window.getDatabaseNode();

	local sDesc = string.format("[SKILL] %s", name.getValue());
	local sStat = stat.getStringValue();
	if sStat ~= "" then
		sDesc = sDesc .. string.format(" [%s]", Interface.getString(sStat):upper());
	end
	local tInfo = RollManager.buildPCRollInfo(nodeActor, sDesc, sStat);
	if not tInfo then
		return;
	end
	tInfo.nTraining = training.getValue();
	tInfo.nAssets = asset.getValue();
	tInfo.nMod = misc.getValue();

	RollManager.resolveAdjustments(tInfo);
	if not RollManager.spendPointsForRoll(nodeActor, tInfo) then
		return;
	end

	local rActor = ActorManager.resolveActor(nodeActor);
	local rRoll = { sType = "dice", sDesc = tInfo.sDesc, aDice = { "d20" }, nMod = tInfo.nMod, nShift = tInfo.nTotalStep };
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
