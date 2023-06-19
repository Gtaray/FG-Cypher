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
	rAction.sCostStat = rAction.sStat; -- Might be a limitation, but right now the attack/damage all uses the same stat

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

	rAction.bPierce = DB.getValue(nodeAction, "pierce", "") == "yes";
	if rAction.bPierce then
		rAction.nPierceAmount = DB.getValue(nodeAction, "pierceamount", 0);	
	end

	return rAction;
end

function actionAttack(draginfo)
	local nodeAction = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);
	local rAction = self.getAttackAction();

	ActionAttack.payCostAndRoll(draginfo, rActor, rAction)
end

function actionDamage(draginfo)
	local nodeAction = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);
	local rAction = self.getDamageAction();	
	
	ActionDamage.performRoll(draginfo, rActor, rAction);
end