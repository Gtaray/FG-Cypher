function onInit()
	local tPowerHandlers = {
		fnGetActorNode = PowerManager.getPowerActorNode,
		fnUpdateDisplay = CharPowerManager.updatePowerDisplay
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

function getPowerNodeFromActionNode(nodeAction)
	return DB.getChild(nodeAction, "...");
end

-- Gets the source of an action node, which can exist on a PC, NPC, item, or ability
function getActionNodeSource(actionNode)
	if type(actionNode) == "string" then
		actionNode = DB.findNode(actionNode);
	end
	if not actionNode then
		return;
	end

	-- This will return if the action is innately on a PC or NPC
	-- As well as if the action is on an item that a PC holds
	-- It works for NPCs that are either on the CT or reference entries
	local rActor = ActorManager.resolveActor(DB.getChild(actionNode, "....."));
	if rActor then
		return ActorManager.getRecordType(rActor);
	end

	-- Since we've already ruled out that this action comes from a PC or NPC
	-- As well as any of the items they may hold
	-- Then all that's left for this to be is a reference object
	return "ref";
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
		return PowerManager.getPowerStatActionText(node);
	elseif tData.sType == "attack" then
		return PowerManager.getPowerAttackActionText(node, tData);
	elseif tData.sType == "damage" then
		return PowerManager.getPowerDamageActionText(node, tData);
	elseif tData.sType == "heal" then
		return PowerManager.getPowerHealActionText(node);
	elseif tData.sType == "effect" then
		return PowerManager.getActionEffectText(node, tData);
	end
	return "";
end
function getActionTooltip(node, tData)
	-- We have to get this so we can get the Notes for each action
	local rAction = PowerManager.getPowerAction(node)
	local sNotes = rAction.sNotes or "";
	local sLabel = "";

	if rAction.type == "stat" then
		sLabel = Interface.getString("power_tooltip_stat");
	elseif rAction.type == "skill" then
		sLabel = Interface.getString("power_tooltip_skill");
	elseif rAction.type == "attack" then
		sLabel = Interface.getString("power_tooltip_attack");
	elseif rAction.type == "damage" then
		sLabel = Interface.getString("power_tooltip_damage");
	elseif rAction.type == "heal" then
		sLabel = Interface.getString("power_tooltip_heal");
	elseif rAction.type == "effect" then
		if tData and tData.sSubRoll == "duration" then
			sLabel = Interface.getString("power_tooltip_duration");
		else
			sLabel = Interface.getString("power_tooltip_effect");
		end
	end

	if sNotes ~= "" then
		sLabel = string.format("%s\n%s", sNotes, sLabel);
	end
	return string.format("%s: %s", sLabel, PowerActionManagerCore.getActionText(node, tData));
end

function getPowerStatActionText(nodeAction)
	local sText = "";

	local rAction, rActor = PowerManager.getPowerAction(nodeAction);
	if rAction then
		local nFlatBonus = RollManager.convertToFlatBonus(rAction.nTraining, rAction.nAssets, rAction.nModifier, rAction.nEase, rAction.nHinder)
		nFlatBonus = nFlatBonus + (rAction.nLevel * 3)

		local sDice = StringManager.convertDiceToString({ "d20" }, nFlatBonus);

		if rAction.type == "skill" and (rAction.sSkill or "") ~= "" then
			sText = string.format("%s (%s): %s", StringManager.capitalize(rAction.sSkill), StringManager.capitalize(rAction.sStat), sDice)
		else
			sText = string.format("%s: %s", StringManager.capitalize(rAction.sStat), sDice)
		end

		if rAction.nDifficulty and rAction.nDifficulty > 0 then
			sText = string.format("%s vs difficulty %s (%s)", sText, rAction.nDifficulty, rAction.nDifficulty * 3)
		end

		if rAction.nCost > 0 then
			sText = string.format("%s [Cost: %s]", sText, rAction.nCost);
		end
	end

	return sText;
end

function getPowerAttackActionText(nodeAction)
	local sAttack = "";
	local rAction, rActor = PowerManager.getPowerAction(nodeAction);

	-- A little migration work to force far/very far ranges to long/very long
	-- Normally I would put this migration code at the source, but because
	-- attack text is displayed separate from its source, we need to update it here
	if rAction.sAttackRange == "Far" then
		DB.setValue(nodeAction, "atkrange", "string", "Long")
		rAction.sAttackRange = "Long"
	elseif rAction.sAttackRange == "Very Far" then
		DB.setValue(nodeAction, "atkrange", "string", "Very Long")
		rAction.sAttackRange = "Very Long"
	end

	if rAction then		
		sAttack = PowerManager.getPCAttackText(rAction);
	end

	return sAttack;
end

function getPCAttackText(rAction)
	local sAttack = ""
	local nFlatBonus = RollManager.convertToFlatBonus(rAction.nTraining, rAction.nAssets, rAction.nModifier, rAction.nEase, rAction.nHinder)
	nFlatBonus = nFlatBonus + (rAction.nLevel * 3)

	local sDice = StringManager.convertDiceToString({ "d20" }, nFlatBonus);

	if rAction.sAttackRange ~= "" then
		sAttack = string.format("%s (%s): %s", StringManager.capitalize(rAction.sStat), rAction.sAttackRange, sDice)
	else
		sAttack = string.format("%s: %s", StringManager.capitalize(rAction.sStat), sDice)
	end

	if rAction.nDifficulty and rAction.nDifficulty > 0 then
		sAttack = string.format("%s vs difficulty %s (%s)", sAttack, rAction.nDifficulty, rAction.nDifficulty * 3)
	end

	if rAction.nCost > 0 then
		sAttack = string.format("%s [Cost: %s]", sAttack, rAction.nCost);
	end

	return sAttack;
end

function getPowerDamageActionText(nodeAction)
	local sDamage = "";
	local rAction, rActor = PowerManager.getPowerAction(nodeAction);

	if rAction then
		sDamage = PowerManager.getPCDamageText(rAction);
	end
	return sDamage;
end

function getPCDamageText(rAction)
	local sDamage = "";

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

	return sDamage;
end

function getPowerHealActionText(nodeAction)
	local sHeal = "";
	
	local rAction, rActor = PowerManager.getPowerAction(nodeAction);
	if rAction then
		local sDice = StringManager.convertDiceToString(rAction.aDice or {}, rAction.nHeal);
		sHeal = string.format("%s %s", sDice, StringManager.capitalize(rAction.sHealStat));

		if rAction.bNoOverflow then
			sHeal = sHeal .. " [SINGLE STAT]"
		end

		if DB.getValue(nodeAction, "healtargeting", "") == "self" then
			sHeal = sHeal .. " [SELF]";
		end

		if rAction.nCost > 0 then
			sHeal = string.format("%s [Cost: %s]", sHeal, rAction.nCost);
		end
	end
	
	return sHeal;
end

function getActionEffectText(node, tData)
	local tOutput = {};

	if tData and tData.sSubRoll == "duration" then
		local nDuration = DB.getValue(node, "durmod", 0);
		local aDice = DB.getValue(node, "durationdice", {});
		if nDuration ~= 0 or #aDice > 0 then
			local sDice = StringManager.convertDiceToString(aDice, nDuration);
			table.insert(tOutput, sDice or "");

			local sUnits = DB.getValue(node, "durunit", "");
			if sUnits == "minute" then
				table.insert(tOutput, "min");
			elseif sUnits == "hour" then
				table.insert(tOutput, "hr");
			elseif sUnits == "day" then
				table.insert(tOutput, "dy");
			else
				table.insert(tOutput, "rd");
			end
		end
		return table.concat(tOutput, " ");
	end

	local sLabel = DB.getValue(node, "label", "");
	if sLabel ~= "" then
		table.insert(tOutput, sLabel);

		local sApply = DB.getValue(node, "apply", "");
		if sApply == "action" then
			table.insert(tOutput, "[ACTION]");
		elseif sApply == "roll" then
			table.insert(tOutput, "[ROLL]");
		elseif sApply == "single" then
			table.insert(tOutput, "[SINGLE]");
		end
		
		local sTargeting = DB.getValue(node, "targeting", "");
		if sTargeting == "self" then
			table.insert(tOutput, "[SELF]");
		end
	end

	return table.concat(tOutput, "; ");
end

function getPowerActionOutputOrder(nodeAction)
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

function getPowerAction(nodeAction)
	if not nodeAction then
		return;
	end

	local nodePower = PowerManager.getPowerNodeFromActionNode(nodeAction)
	local nodeActor = PowerManagerCore.getPowerActorNode(nodePower);
	local rActor = ActorManager.resolveActor(nodeActor);

	-- if not rActor then
	-- 	return;
	-- end

	local rAction = {};
	rAction.type = DB.getValue(nodeAction, "type", "");
	rAction.label = DB.getValue(nodeAction, "...name", "");
	rAction.order = PowerManager.getPowerActionOutputOrder(nodeAction);
	rAction.sNotes = DB.getValue(nodeAction, "notes", "");

	if rAction.type == "stat" then
		rAction.sStat = RollManager.resolveStat(DB.getValue(nodeAction, "stat", ""));
		rAction.sSkill = DB.getValue(nodeAction, "skill", "");
		rAction.nTraining = DB.getValue(nodeAction, "training", 1);
		rAction.nAssets = DB.getValue(nodeAction, "asset", 0);
		rAction.nModifier = DB.getValue(nodeAction, "modifier", 0);
		rAction.nEase = DB.getValue(nodeAction, "ease", 0);
		rAction.nHinder = DB.getValue(nodeAction, "hinder", 0);

		-- Only for NPCs
		rAction.nLevel = DB.getValue(nodeAction, "level", 0);

		-- If a skill value is present, then treat this action as a skill roll
		-- from here on out		
		if rAction.sSkill ~= "" then
			rAction.type = "skill"
		end

		-- Don't add difficulty values less than 1
		local nDiff = DB.getValue(nodeAction, "difficulty", 0)
		if nDiff > 0 then
			rAction.nDifficulty = nDiff;
		end

		-- For NPCs, we want to use the custom stat field instead of the cycler
		if not ActorManager.isPC(rActor) then
			rAction.sStat = resolveCustomStats(nodeAction, rAction.sStat, "stat_custom", "might");
		end
		
	elseif rAction.type == "attack" then
		rAction.sStat = RollManager.resolveStat(DB.getValue(nodeAction, "stat", ""));
		rAction.sDefenseStat = RollManager.resolveStat(DB.getValue(nodeAction, "defensestat", ""), "speed");
		rAction.sAttackRange = DB.getValue(nodeAction, "atkrange", "");

		-- Don't add difficulty values less than 1
		local nDiff = DB.getValue(nodeAction, "difficulty", 0)
		if nDiff > 0 then
			rAction.nDifficulty = nDiff;
		end

		-- Only for PCs
		rAction.nTraining = DB.getValue(nodeAction, "training", 1);
		rAction.nAssets = DB.getValue(nodeAction, "asset", 0);
		rAction.nModifier = DB.getValue(nodeAction, "modifier", 0);
		rAction.nEase = DB.getValue(nodeAction, "ease", 0);
		rAction.nHinder = DB.getValue(nodeAction, "hinder", 0);

		-- Only for NPCs
		rAction.nLevel = DB.getValue(nodeAction, "level", 0);

		-- For PCs, we try to apply an equipped weapon
		if ActorManager.isPC(rActor) then
			PowerManager.applyWeaponPropertiesToAttack(rAction, nodePower);
		else
			-- These only matter for NPCs
			rAction.sStat = resolveCustomStats(nodeAction, rAction.sStat, "stat_custom", "might");
			rAction.sDefenseStat = resolveCustomStats(nodeAction, rAction.sDefenseStat, "defensestat_custom", "speed");
		end

	elseif rAction.type == "damage" then
		rAction.sStat = DB.getValue(nodeAction, "stat", "");
		rAction.nDamage = DB.getValue(nodeAction, "damage", 0);
		rAction.sDamageStat = RollManager.resolveStat(DB.getValue(nodeAction, "damagestat", ""));
		rAction.sDamageType = DB.getValue(nodeAction, "damagetype", "");

		--rAction.sDamageType = DB.getValue(nodeAction, "damagetype", "");
		rAction.bPiercing = DB.getValue(nodeAction, "pierce", "") == "yes";

		-- Only for NPCs
		rAction.bAmbient = DB.getValue(nodeAction, "ambient", "") == "yes";

		if rAction.bPiercing then
			rAction.nPierceAmount = DB.getValue(nodeAction, "pierceamount", 0);	
		end

		-- For PCs, we try to apply an equipped weapon
		-- for NPCs, we double check that stat isn't empty
		if ActorManager.isPC(rActor) then
			PowerManager.applyWeaponPropertiesToDamage(rAction, nodePower);
		else
			rAction.sStat = resolveCustomStats(nodeAction, rAction.sStat, "stat_custom", "might");
			rAction.sDamageStat = resolveCustomStats(nodeAction, rAction.sDamageStat, "damagestat_custom", "might");
		end

	elseif rAction.type == "heal" then
		rAction.sStat = DB.getValue(nodeAction, "stat", "");
		rAction.sTargeting = DB.getValue(nodeAction, "healtargeting", "");
		rAction.aDice = DB.getValue(nodeAction, "dice");
		rAction.nHeal = DB.getValue(nodeAction, "heal", 0);
		rAction.sHealStat = RollManager.resolveStat(DB.getValue(nodeAction, "healstat", ""));
		rAction.bNoOverflow = DB.getValue(nodeAction, "overflow", "") ~= "yes";

		if not ActorManager.isPC(rActor) then
			rAction.sStat = resolveCustomStats(nodeAction, rAction.sStat, "stat_custom", "might");
			rAction.sHealStat = resolveCustomStats(nodeAction, rAction.sHealStat, "healstat_custom", "might");
		end

	elseif rAction.type == "effect" then
		rAction.sName = DB.getValue(nodeAction, "label", "");
		rAction.sApply = DB.getValue(nodeAction, "apply", "");
		rAction.sTargeting = DB.getValue(nodeAction, "targeting", "");
		rAction.aDice = DB.getValue(nodeAction, "durationdice", {})
		rAction.nDuration = DB.getValue(nodeAction, "durmod", 0)
		rAction.sUnits = DB.getValue(nodeAction, "durunit", "");

		rAction.rEffectScaling = {
			nBase = DB.getValue(nodeAction, "scaling_effect_base", 0),
			nMod = DB.getValue(nodeAction, "scaling_effect_mod", 0),
			sModMult = DB.getValue(nodeAction, "scaling_effect_mod_mult", ""),
		};
		rAction.rDurationScaling = {
			nMod = DB.getValue(nodeAction, "scaling_duration_mod", 0),
			sModMult = DB.getValue(nodeAction, "scaling_duration_mod_mult", ""),
			aDice = DB.getValue(nodeAction, "scaling_duration_dice", {}),
			sDiceMult = DB.getValue(nodeAction, "scaling_duration_dice_mult", "")
		};
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

	-- Very specific fix for items. Because items also have a 'cost', but 
	-- in that case its the price of the item and is a string
	if type(rAction.nCost) == "string" then
		rAction.nCost = 0;
	end

	return rAction, rActor
end

function applyWeaponPropertiesToAttack(rAttack, nodeAbility)
	local nodeActor = PowerManagerCore.getPowerActorNode(nodeAbility);

	local rWeapon = {};
	local bUseEquipped = DB.getValue(nodeAbility, "useequipped", "") == "yes";
	if bUseEquipped then
		rWeapon = CharInventoryManager.getEquippedWeapon(nodeActor)
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
	
	-- We have to apply -1 so the difficulty adjustment is flipped
	-- We want to ADD for trained/specialized, and SUBTRACT for inability
	local nWeaponAdjust = -1 * TrainingManager.getDifficultyModifier(rWeapon.nTraining or 1);
	rAttack.nTraining = TrainingManager.modifyTraining(rAttack.nTraining, nWeaponAdjust)

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
		rWeapon = CharInventoryManager.getEquippedWeapon(nodeActor)
	end

	if (rDamage.sStatDamage or "") == "" then
		rDamage.sStatDamage = rWeapon.sStatDamage;
	end
	-- if (rDamage.sDamageType or "") == "" then
	-- 	rDamage.sDamageType = rWeapon.sDamageType;
	-- end

	rDamage.nDamage = math.max(rDamage.nDamage + (rWeapon.nDamage or 0), 0);
	rDamage.bPierce = rDamage.bPierce or rWeapon.bPierce;
	if rDamage.bPierce then
		rDamage.nPierceAmount = (rDamage.nPierceAmount or 0) + (rWeapon.nPierceAmount or 0);
	end

	if (rWeapon.sLabel or "") ~= "" then
		rDamage.label = rDamage.label .. " with " .. rWeapon.sLabel;
	end
end

function resolveCustomStats(nodeAction, sStat, sPath, sDefault)
	if sStat == "custom" then
		local sCustomStat = DB.getValue(nodeAction, sPath, "")
		if (sCustomStat or "") ~= "" then
			return sCustomStat;
		end
		return sDefault;
	end
	return sStat;
end

-------------------------
-- POWER USAGE
-------------------------
function performAction(node, tData)
	local draginfo = tData.draginfo;
	local rAction, rActor = PowerManager.getPowerAction(node);

	if not rActor or not rAction then
		return false;
	end

	local bPC = ActorManager.isPC(rActor);

	if rAction.type == "stat" then
		if bPC then
			ActionStat.payCostAndRoll(draginfo, rActor, rAction);
		else
			Comm.addChatMessage({ text = "This action is not available for NPCs.", font = "systemfont" });
		end

	elseif rAction.type == "skill" then
		if bPC then
			ActionSkill.payCostAndRoll(draginfo, rActor, rAction);
		else
			Comm.addChatMessage({ text = "This action is not available for NPCs.", font = "systemfont" });
		end

	elseif rAction.type == "attack" then
		if bPC then
			ActionAttack.payCostAndRoll(draginfo, rActor, rAction);
		else
			ActionDefenseVs.performRoll(draginfo, rActor, rAction);
		end
		
	elseif rAction.type == "damage" then
		ActionDamage.payCostAndRoll(draginfo, rActor, rAction);
		
	elseif rAction.type == "heal" then
		ActionHeal.payCostAndRoll(draginfo, rActor, rAction);
		
	elseif rAction.type == "effect" then
		ActionEffectCypher.payCostAndRoll(draginfo, rActor, rAction);
	end

	return true;
end