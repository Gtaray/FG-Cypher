function onInit()
	ActionsManager.registerModHandler("heal", modRoll);
	ActionsManager.registerResultHandler("heal", onRoll);
end

function performRoll(draginfo, rActor, rAction)
	local aFilter = { "heal" };

	RollManager.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addWoundedToAction(rActor, rAction, aFilter);
	RollManager.addArmorCostToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rActor, rAction);
	RollManager.resolveMaximumEffort(rActor, rAction, aFilter);
	RollManager.resolveMaximumAssets(rActor, rAction, aFilter);
	RollManager.calculateBaseEffortCost(rActor, rAction);
	RollManager.adjustEffortCostWithEffects(rActor, rAction, aFilter);
	RollManager.applyEffortToModifier(rActor, rAction);

	local bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);

	if bCanRoll then
		local rRoll = ActionHeal.getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end


function getRoll(rActor, rAction)
	local rRoll = {};
	-- rRoll.sType = "heal";
	-- rRoll.aDice = { };
	-- rRoll.nMod = rAction.nModifier or 0;
	
	-- rRoll.sDesc = string.format("[HEAL (%s)] %s", rAction.sStatHeal, rAction.label);

	-- -- Handle self-targeting
	-- if rAction.sTargeting == "self" then
	-- 	rRoll.bSelfTarget = true;
	-- end

	-- RollManager.encodeStat(rAction, rRoll)
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	-- local sStat = RollManagerCPP.decodeStat(rRoll, true);
	-- local nHealBonus, nHealEffectCount = EffectManagerCPP.getEffectsBonusByType(rSource, "HEAL", { sStat }, rTarget)

	-- rRoll.nMod = rRoll.nMod + nHealBonus;

	-- if nHealEffectCount > 0 then
	-- 	if nHealBonus < 0 then
	-- 		rRoll.sDesc = rRoll.sDesc  .. " " .. nHealBonus .. "]";
	-- 	elseif nEffects > 0 then
	-- 		rRoll.sDesc = rRoll.sDesc  .. " +" .. nHealBonus .. "]";
	-- 	else
	-- 		rRoll.sDesc = rRoll.sDesc .. "]";
	-- 	end
	-- end
end

function onRoll(rSource, rTarget, rRoll)
	-- local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- rMessage.icon = "action_heal";
	-- if rTarget ~= nil then
	-- 	rMessage.text = rMessage.text:gsub(" %[STAT: %w-%]", "");
	-- end

	-- Comm.deliverChatMessage(rMessage);

	-- -- Apply damage to the PC or CT entry referenced
	-- local nTotal = ActionsManager.total(rRoll) * -1;
	-- if nTotal ~= 0 then
	-- 	ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, nTotal);
	-- end
end