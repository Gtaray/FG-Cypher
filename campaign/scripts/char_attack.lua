function onInit()
	local node = getDatabaseNode();
	DB.addHandler(node, "onChildUpdate", self.onDataChanged);
	update();
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(node, "onChildUpdate", self.onDataChanged);
end

function onDataChanged()
	update();
end

function update()
	button_attack.updateTooltip();
	button_damage.updateTooltip();
	onAttackTypeUpdated();

	-- Update ammo display
	local bUseAmmo = DB.getValue(getDatabaseNode(), "useammo", "no") == "yes";
	label_ammo.setVisible(bUseAmmo);
	maxammo.setVisible(bUseAmmo);
	ammocounter.setVisible(bUseAmmo);
end

function onAttackTypeUpdated()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	equipped.setVisible(sType ~= "magic");
end

function toggleDetail()
	Interface.openWindow("attack_editor", getDatabaseNode());
end

function onEquippedChanged()
	local bEquipped = equipped.getValue() == 1;

	if bEquipped then
		local nodeActor = windowlist.window.getDatabaseNode();
		ActorManagerCypher.setEquippedWeapon(nodeActor, getDatabaseNode())
	end
end

function getAttackAction()
	local nodeAction = getDatabaseNode();
	local rAction = {};
	rAction.sType = "attack";
	rAction.label = DB.getValue(nodeAction, "name", "");
	rAction.sAttackRange = DB.getValue(nodeAction, "atkrange", "");
	rAction.sStat = RollManager.resolveStat(DB.getValue(nodeAction, "stat", ""));
	rAction.sDefenseStat = RollManager.resolveStat(DB.getValue(nodeAction, "defensestat", ""), "speed");
	rAction.sTraining = DB.getValue(nodeAction, "training", "");
	rAction.nAssets = DB.getValue(nodeAction, "asset", 0);
	rAction.nModifier = DB.getValue(nodeAction, "modifier", 0);
	rAction.nLevel = DB.getValue(nodeAction, "level", 0);
	rAction.nCost = DB.getValue(nodeAction, "cost", 0);
	rAction.sCostStat = DB.getValue(nodeAction, "coststat", "");

	-- If there's a cost but no cost stat specified, use the stat.
	-- otherwise we use the cost stat
	if rAction.nCost > 0 and rAction.sCostStat == "" then
		rAction.sCostStat = rAction.sStat;
	end

	-- If the attack type is set to weapon, add the weapon type
	if DB.getValue(nodeAction, "type", "") == "" then
		rAction.sWeaponType = DB.getValue(nodeAction, "weapontype", "");
	end

	return rAction;
end

function getDamageAction()
	local nodeAction = getDatabaseNode();
	local rAction = {};
	rAction.sType = "damage";
	rAction.label = DB.getValue(nodeAction, "name", "");
	rAction.nDamage = DB.getValue(nodeAction, "damage", 0);
	rAction.sStat = RollManager.resolveStat(DB.getValue(nodeAction, "stat", ""));
	rAction.sDamageStat = RollManager.resolveStat(DB.getValue(nodeAction, "damagestat", ""));
	rAction.sDamageType = DB.getValue(nodeAction, "damagetype", "");
	rAction.nCost = 0;

	rAction.bPiercing = DB.getValue(nodeAction, "pierce", "") == "yes";
	if rAction.bPiercing then
		rAction.nPierceAmount = DB.getValue(nodeAction, "pierceamount", 0);	
	end

	return rAction;
end

function actionAttack(draginfo)
	local nodeAction = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);
	local rAction = self.getAttackAction();

	if not self.hasAmmo() then
		local rMessage = {
			text = string.format(
				Interface.getString("char_message_not_enough_ammo"),
				rAction.label
			),
			font = "msgfont"
		};
		Comm.addChatMessage(rMessage);
		return;
	end

	if ActionAttack.payCostAndRoll(draginfo, rActor, rAction) then
		-- decrement ammo
		self.useAmmo();
	end
end

function actionDamage(draginfo)
	local nodeAction = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);
	local rAction = self.getDamageAction();	
	
	ActionDamage.payCostAndRoll(draginfo, rActor, rAction);
end

-- Ammo Functions
function getAmmo()
	local nodeAction = getDatabaseNode();
	local nCur = DB.getValue(nodeAction, "ammo", 0);
	local nMax = DB.getValue(nodeAction, "maxammo", 0);

	return nCur, nMax;
end

function hasAmmo()
	if not self.usesAmmo() then
		return true
	end

	local nCur, nMax = self.getAmmo();
	return nCur < nMax;
end

function usesAmmo()
	return DB.getValue(getDatabaseNode(), "useammo", "no") == "yes";
end

function useAmmo()
	if not self.usesAmmo() then
		return;
	end

	local nodeAction = getDatabaseNode();
	local nCur, nMax = self.getAmmo();
	nCur = math.max(math.min(nCur + 1, nMax), 0);
	DB.setValue(nodeAction, "ammo", "number", nCur)
end