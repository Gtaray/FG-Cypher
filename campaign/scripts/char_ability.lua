-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onCostChanged();
end

function onCostChanged()
	local bShow = (statcost.getValue() ~= 0);
	statroll.setVisible(bShow);
	statcostview.setVisible(bShow);
				
	local sStatView = "" .. statcost.getValue();
	local sStat = stat.getValue();
	if sStat ~= "" then
		sStatView = sStatView .. " " .. StringManager.capitalize(sStat:sub(1,2));
	end
	statcostview.setValue(sStatView);
end

-- Check constraints and set up for an ability roll.
function actionAbility(draginfo)
	local nodeActor = windowlist.window.getDatabaseNode();

	local sDesc = string.format("[ABILITY] %s [COST: %s]", name.getValue(), statcostview.getValue());
	local sStat = stat.getValue();
	local tInfo = RollManager.buildPCRollInfo(nodeActor, sDesc, sStat);
	if not tInfo then
		return;
	end
	tInfo.nBaseCost = statcost.getValue();
	tInfo.nTraining = training.getValue();
	tInfo.nAssets = asset.getValue();
	tInfo.nMod = modifier.getValue();

	RollManager.resolveAdjustments(tInfo);
	if not RollManager.spendPointsForRoll(nodeActor, tInfo) then
		return;
	end

	local rActor = ActorManager.resolveActor(nodeActor);

    if has_roll.getValue() == 1 then
        local rRoll = { sType = "dice", sDesc = tInfo.sDesc, aDice = { "d20" }, nMod = tInfo.nMod, nShift = tInfo.nTotalStep };
        ActionsManager.performAction(draginfo, rActor, rRoll);
    else
        local rMessage = ChatManager.createBaseMessage(rActor);
		rMessage.text = tInfo.sDesc;
		Comm.deliverChatMessage(rMessage);
    end
end
