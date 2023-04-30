-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	toggleDetail();
end

function toggleDetail()
	local bShow = (activatedetail.getValue() == 1);
	
	label_atkdetail.setVisible(bShow);
	label_atkskill.setVisible(bShow);
	training.setVisible(bShow);
	label_atkasset.setVisible(bShow);
	asset.setVisible(bShow);
	label_atkmod.setVisible(bShow);
	attack.setVisible(bShow);
	label_atkstat.setVisible(bShow);
	stat.setVisible(bShow);
	label_atkcost.setVisible(bShow);
	cost.setVisible(bShow);
	
	label_dmgdetail.setVisible(bShow);
	damage.setVisible(bShow);
	label_dmgtype.setVisible(bShow);
	damagetype.setVisible(bShow);
	
	label_range.setVisible(bShow);
	range.setVisible(bShow);
	label_ammo.setVisible(bShow);
	ammo.setVisible(bShow);
end

function actionAttack(draginfo)
	local nodeActor = windowlist.window.getDatabaseNode();

	local sDesc = string.format("[ATTACK] %s", name.getValue());
	local sStat = stat.getStringValue();
	local tInfo = RollManager.buildPCRollInfo(nodeActor, sDesc, sStat);
	if not tInfo then
		return;
	end
	tInfo.nBaseCost = cost.getValue();
	tInfo.nTraining = training.getValue();
	tInfo.nAssets = asset.getValue();
	tInfo.nMod = attack.getValue();

	RollManager.resolveAdjustments(tInfo);
	if not RollManager.spendPointsForRoll(nodeActor, tInfo) then
		return;
	end

	local rActor = ActorManager.resolveActor(nodeActor);
	local rRoll = { sType = "attack", sDesc = tInfo.sDesc, aDice = { "d20" }, nMod = tInfo.nMod, nShift = tInfo.nTotalStep };
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function actionDamage(draginfo)
	local nodeActor = windowlist.window.getDatabaseNode();

	local sDesc = string.format("[DAMAGE] %s", name.getValue());
	local sStat = stat.getStringValue();
	local sDmgType = damagetype.getValue();
	if sDmgType ~= "" and sDmgType ~= "-" then
		sDesc = sDesc .. " [TYPE: " .. sDmgType .. "]";
	end
	local tInfo = RollManager.buildPCRollInfo(nodeActor, sDesc, sStat);
	if not tInfo then
		return;
	end
	tInfo.nMod = damage.getValue();

	RollManager.resolveAdjustments(tInfo);
	if not RollManager.spendPointsForRoll(nodeActor, tInfo) then
		return;
	end

	if tInfo.nEffort > 0 then
		local nExtraDamage = (tInfo.nEffort * 3);
		tInfo.nMod = tInfo.nMod + nExtraDamage;
		tInfo.sDesc = tInfo.sDesc .. string.format(" [APPLIED %d EFFORT FOR +%d DAMAGE]", tInfo.nEffort, nExtraDamage);
	end

	local rActor = ActorManager.resolveActor(nodeActor);
	local rRoll = { sType = "damage", sDesc = tInfo.sDesc, aDice = { }, sStat = tInfo.sStat, nMod = tInfo.nMod };
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
