function onInit()
	local tPowerHandlers = {
		fnGetActorNode = PowerManager.getPowerActorNode
	}
	PowerManagerCore.registerPowerHandlers(tPowerHandlers);
	
	local tPowerActionHandlers = {
		fnGetButtonIcons = PowerManager.getActionButtonIcons,
		fnGetText = PowerManager.getActionText,
		fnGetTooltip = PowerManager.getActionTooltip,
		fnPerform = PowerManager.performAction,
	}
	PowerActionManagerCore.registerActionType("", tPowerActionHandlers)
	PowerActionManagerCore.registerActionType("stat", {})
	PowerActionManagerCore.registerActionType("attack", {})
	PowerActionManagerCore.registerActionType("damage", {})
	PowerActionManagerCore.registerActionType("heal", {})
	PowerActionManagerCore.registerActionType("effect", {})
end

function getPowerActorNode(node)
	return DB.getChild(node, "...");
end

-------------------------
-- POWER ACTIONS
-------------------------
function getActionButtonIcons(node, tData)
	if tData.sType == "stat" then
		return "button_roll", "button_roll_down";
	elseif tData.sType == "attack" then
		return "button_action_attack", "button_action_attack_down";
	elseif tData.sType == "damage" then
		return "button_action_damage", "button_action_damage_down";
	elseif tData.sType == "heal" then
		return "button_action_heal", "button_action_heal_down";
	elseif tData.sType == "effect" then
		return "button_action_effect", "button_action_effect_down";
	end
	return "", "";
end
function getActionText(node, tData)
	if tData.sType == "stat" then
		return PowerManager.getPCPowerStatActionText(node);
	elseif tData.sType == "attack" then
		return PowerManager.getPCPowerAttackActionText(node);
	elseif tData.sType == "damage" then
		return PowerManager.getPCPowerDamageActionText(node);
	elseif tData.sType == "heal" then
		return PowerManager.getPCPowerHealActionText(node);
	elseif tData.sType == "effect" then
		return PowerActionManagerCore.getActionEffectText(node, tData);
	end
	return "";
end
function getActionTooltip(node, tData)
	if tData.sType == "stat" then
		return string.format("%s: %s", Interface.getString("power_tooltip_stat"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "attack" then
		return string.format("%s: %s", Interface.getString("power_tooltip_attack"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "damage" then
		return string.format("%s: %s", Interface.getString("power_tooltip_damage"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "heal" then
		return string.format("%s: %s", Interface.getString("power_tooltip_heal"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "effect" then
		return PowerActionManagerCore.getActionEffectTooltip(node, tData);
	end
	return "";
end

function getPCPowerStatActionText(nodeAction)
	local sText = "";

	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then
		local nDiff, nMod = RollManager.resolveDifficultyModifier(rAction.sTraining, rAction.nAssets, rAction.nLevel, rAction.nModifier);
		local sDice = StringManager.convertDiceToString({ "d20" }, nMod);

		sText = string.format("%s: %s", StringManager.capitalize(rAction.sStat), sDice)

		if nDiff < 0 then
			sText = string.format("%s [Diff: %s]", sText, nDiff);
		elseif nDiff > 0 then
			sText = string.format("%s [Diff: +%s]", sText, nDiff);
		end

		if rAction.nCost > 0 then
			sText = string.format("%s [Cost: %s]", sText, rAction.nCost);
		end
	end

	return sText;
end

function getPCPowerAttackActionText(nodeAction)
	local sAttack = "";

	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then		
		local nDiff, nMod = RollManager.resolveDifficultyModifier(rAction.sTraining, rAction.nAssets, rAction.nLevel, rAction.nModifier);
		local sDice = StringManager.convertDiceToString({ "d20" }, nMod);

		if rAction.sAttackRange ~= "" then
			sAttack = string.format("%s (%s): %s", StringManager.capitalize(rAction.sStat), rAction.sAttackRange, sDice)
		else
			sAttack = string.format("%s: %s", StringManager.capitalize(), sDice)
		end

		if nDiff < 0 then
			sAttack = string.format("%s [Diff: %s]", sAttack, nDiff);
		elseif nDiff > 0 then
			sAttack = string.format("%s [Diff: +%s]", sAttack, nDiff);
		end

		if rAction.nCost > 0 then
			sAttack = string.format("%s [Cost: %s]", sAttack, rAction.nCost);
		end
	end

	return sAttack;
end

function getPCPowerDamageActionText(nodeAction)
	local sDamage = "";
	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then
		if (rAction.sDamageType or "" ~= "") then
			sDamage = string.format(
				"%s %s damage", 
				rAction.nDamage, 
				rAction.sDamageType);
		else
			sDamage = string.format(
				"%s damage", 
				rAction.nDamage);
		end

		if (rAction.sDamageStat or "") ~= "" then
			sDamage = string.format("%s -> %s", sDamage, StringManager.capitalize(rAction.sDamageStat));
		end

		if rAction.bPierce then
			local sPierceAmount = "";
			if rAction.nPierceAmount > 0 then
				sPierceAmount = string.format(": %s", rAction.nPierceAmount);
			end

			sDamage = string.format("%s [PIERCE%s]", sDamage, sPierceAmount);
		end

		if rAction.bAmbient then
			sDamage = string.format("%s [AMBIENT]", sDamage);
		end

		if rAction.nCost > 0 then
			sDamage = string.format("%s [Cost: %s]", sDamage, rAction.nCost);
		end
	end
	return sDamage;
end

function getPCPowerHealActionText(nodeAction)
	local sHeal = "";
	
	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then		
		sHeal = string.format("%s %s", rAction.nHeal, StringManager.capitalize(rAction.sStatHeal));

		if DB.getValue(nodeAction, "healtargeting", "") == "self" then
			sHeal = sHeal .. " [SELF]";
		end

		if rAction.nCost > 0 then
			sHeal = string.format("%s [Cost: %s]", sHeal, rAction.nCost);
		end
	end
	
	return sHeal;
end

function getPCPowerActionOutputOrder(nodeAction)
	if not nodeAction then
		return 1;
	end
	local nodeActionList = DB.getParent(nodeAction);
	if not nodeActionList then
		return 1;
	end
	
	-- First, pull some ability attributes
	local sType = DB.getValue(nodeAction, "type", "");
	local nOrder = DB.getValue(nodeAction, "order", 0);
	
	-- Iterate through list node
	local nOutputOrder = 1;
	for _, v in ipairs(DB.getChildList(nodeActionList)) do
		if DB.getValue(v, "type", "") == sType then
			if DB.getValue(v, "order", 0) < nOrder then
				nOutputOrder = nOutputOrder + 1;
			end
		end
	end
	
	return nOutputOrder;
end

function getPCPowerAction(nodeAction)
	if not nodeAction then
		return;
	end

	local nodePower = DB.getChild(nodeAction, "...");
	local nodeActor = PowerManagerCore.getPowerActorNode(nodePower);
	local rActor = ActorManager.resolveActor(nodeActor);

	-- if not rActor then
	-- 	return;
	-- end

	local rAction = {};
	rAction.type = DB.getValue(nodeAction, "type", "");
	rAction.label = DB.getValue(nodeAction, "...name", "");
	rAction.order = PowerManager.getPCPowerActionOutputOrder(nodeAction);

	if rAction.type == "stat" then
		rAction.sStat = RollManager.resolveStat(DB.getValue(nodeAction, "stat", ""));
		rAction.sTraining = DB.getValue(nodeAction, "training", "");
		rAction.nAssets = DB.getValue(nodeAction, "asset", 0);
		rAction.nModifier = DB.getValue(nodeAction, "modifier", 0);
		
	elseif rAction.type == "attack" then
		rAction.sStat = RollManager.resolveStat(DB.getValue(nodeAction, "stat", ""));
		rAction.sDefenseStat = RollManager.resolveStat(DB.getValue(nodeAction, "defensestat", ""), "speed");
		rAction.sAttackRange = DB.getValue(nodeAction, "atkrange", "");

		-- Only for PCs
		rAction.sTraining = DB.getValue(nodeAction, "training", "");
		rAction.nAssets = DB.getValue(nodeAction, "asset", 0);
		rAction.nModifier = DB.getValue(nodeAction, "modifier", 0);

		-- Only for NPCs
		rAction.nLevel = DB.getValue(nodeAction, "level", 0);

		-- For PCs, we try to apply an equipped weapon
		if ActorManager.isPC(rActor) then
			PowerManager.applyWeaponPropertiesToAttack(rAction, nodePower);
		end

	elseif rAction.type == "damage" then
		rAction.nDamage = DB.getValue(nodeAction, "damage", 0);
		rAction.sDamageStat = RollManager.resolveStat(DB.getValue(nodeAction, "damagestat", ""));

		--rAction.sDamageType = DB.getValue(nodeAction, "damagetype", "");
		rAction.bPierce = DB.getValue(nodeAction, "pierce", "") == "yes";

		-- Only for NPCs
		rAction.bAmbient = DB.getValue(nodeAction, "ambient", "") == "yes";

		if rAction.bPierce then
			rAction.nPierceAmount = DB.getValue(nodeAction, "pierceamount", 0);	
		end

		-- For PCs, we try to apply an equipped weapon
		-- for NPCs, we double check that stat isn't empty
		if ActorManager.isPC(rActor) then
			PowerManager.applyWeaponPropertiesToDamage(rAction, nodePower);
		end

	elseif rAction.type == "heal" then
		rAction.sTargeting = DB.getValue(nodeAction, "healtargeting", "");
		rAction.nHeal = DB.getValue(nodeAction, "heal", 0);
		rAction.sStatHeal = RollManager.resolveStat(DB.getValue(nodeAction, "healstat", ""));

	elseif rAction.type == "effect" then
		rAction.sName = DB.getValue(nodeAction, "label", "");
		rAction.sApply = DB.getValue(nodeAction, "apply", "");
		rAction.sTargeting = DB.getValue(nodeAction, "targeting", "");
		rAction.nDuration = DB.getValue(nodeAction, "durmod", 0);
		rAction.sUnits = DB.getValue(nodeAction, "durunit", "");
	end

	-- Resolve cost of the ability
	rAction.nCost = rAction.nCost or 0;
	local sCostType = DB.getValue(nodeAction, "costtype", "");
	local costnode = nil;

	if sCostType == "ability" then
		costnode = nodePower;
	elseif sCostType == "fixed" then
		costnode = nodeAction;
	end
	if costnode then
		rAction.nCost = DB.getValue(costnode, "cost", 0);
		rAction.sCostStat = DB.getValue(costnode, "coststat", "");
	end

	return rAction, rActor
end

function applyWeaponPropertiesToAttack(rAttack, nodeAbility)
	local nodeActor = PowerManagerCore.getPowerActorNode(nodeAbility);

	local rWeapon = {};
	local bUseEquipped = DB.getValue(nodeAbility, "useequipped", "") == "yes";
	if bUseEquipped then
		rWeapon = ActorManagerCypher.getEquippedWeapon(nodeActor)
	end

	if (rAttack.sAttackRange or "") == "" then
		rAttack.sAttackRange = rWeapon.sAttackRange or "";
	end
	if (rAttack.sStat or "") == "" then
		rAttack.sStat = rWeapon.sStat;
	end
	if (rAttack.sDefenseStat or "") == "" then
		rAttack.sDefenseStat = rWeapon.sDefenseStat;
	end
	if (rAttack.sTraining or "") == "" then
		rAttack.sTraining = rWeapon.sTraining;
	end

	rAttack.nAssets = rAttack.nAssets + (rWeapon.nAssets or 0)
	rAttack.nModifier = rAttack.nModifier + (rWeapon.nModifier or 0)
	rAttack.sWeaponType = rWeapon.sWeaponType or ""; -- Add the weapon type if it exists

	if (rWeapon.sLabel or "") ~= "" then
		rAttack.label = rAttack.label .. " with " .. rWeapon.sLabel;
	end
end

function applyWeaponPropertiesToDamage(rDamage, nodeAbility)
	local nodeActor = PowerManagerCore.getPowerActorNode(nodeAbility);

	local rWeapon = {};
	local bUseEquipped = DB.getValue(nodeAbility, "useequipped", "") == "yes";
	if bUseEquipped then
		rWeapon = ActorManagerCypher.getEquippedWeapon(nodeActor)
	end

	if (rDamage.sStatDamage or "") == "" then
		rDamage.sStatDamage = rWeapon.sStatDamage;
	end
	-- if (rDamage.sDamageType or "") == "" then
	-- 	rDamage.sDamageType = rWeapon.sDamageType;
	-- end

	rDamage.nDamage = rDamage.nDamage + (rWeapon.nDamage or 0)
	rDamage.bPierce = rDamage.bPierce or rWeapon.bPierce;
	if rDamage.bPierce then
		rDamage.nPierceAmount = (rDamage.nPierceAmount or 0) + (rWeapon.nPierceAmount or 0);
	end

	if (rWeapon.sLabel or "") ~= "" then
		rDamage.label = rDamage.label .. " with " .. rWeapon.sLabel;
	end
end

-------------------------
-- POWER USAGE
-------------------------
function performAction(node, tData)
	local draginfo = tData.draginfo;
	local rAction, rActor = PowerManager.getPCPowerAction(node);

	if not rActor or not rAction then
		return false;
	end

	local bPC = ActorManager.isPC(rActor);

	if rAction.type == "stat" then
		if bPC then
			ActionStat.performRoll(draginfo, rActor, rAction);
		else
			Comm.addChatMessage({ text = "This action is not available for NPCs.", font = "systemfont" });
		end

	elseif rAction.type == "attack" then
		if bPC then
			ActionAttack.performRoll(draginfo, rActor, rAction);
		else
			ActionDefenseVs.performRoll(draginfo, rActor, rAction);
		end
		
	elseif rAction.type == "damage" then
		ActionDamage.performRoll(draginfo, rActor, rAction);
		
	elseif rAction.type == "heal" then
		ActionHeal.performRoll(draginfo, rActor, rAction);
		
	elseif rAction.type == "effect" then
		ActionEffect.performRoll(draginfo, rActor, rAction);
	end

	return true;
end