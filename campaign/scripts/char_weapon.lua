function onInit()
	local node = getDatabaseNode();
	DB.addHandler(node, "onChildUpdate", onDataChanged);

	self.onDataChanged();
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(node, "onChildUpdate", onDataChanged);
end

function onModeChanged()
	
end

function onDataChanged()
	self.onLinkChanged();
	self.onAttackTypeUpdated();
	self.onAttackChanged();
	self.onDamageChanged();
	
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

function onEquippedChanged()
	local bEquipped = equipped.getValue() == 1;

	if bEquipped then
		local nodeActor = windowlist.window.getDatabaseNode();
		ActorManagerCypher.setEquippedWeapon(nodeActor, getDatabaseNode())
	end
end

function onLinkChanged()
	local node = getDatabaseNode();
	local sClass, sRecord = DB.getValue(node, "itemlink", "", "");
	if sClass ~= m_sClass or sRecord ~= m_sRecord then
		m_sClass = sClass;
		m_sRecord = sRecord;
		
		local sInvList = DB.getPath(DB.getChild(node, "..."), "inventorylist") .. ".";
		if sRecord:sub(1, #sInvList) == sInvList then
			carried.setLink(DB.findNode(DB.getPath(sRecord, "carried")));
		end
	end
end

function onAttackChanged()
	local rAction = self.getAttackAction();
	local nBonus = RollManager.convertToFlatBonus(rAction.sTraining, rAction.nAssets, rAction.nModifier)

	local bWeapon = DB.getValue(nodeAction, "type", "") == ""
	if bWeapon and rAction.sWeaponType == "light" then
		nBonus = nBonus + 3	
	end
	local sAttack = StringManager.convertDiceToString({}, nBonus);
	attackview.setValue(sAttack)
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

function onAttackAction(draginfo)
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
		return false;
	end

	if ActionAttack.payCostAndRoll(draginfo, rActor, rAction) then
		-- decrement ammo
		self.useAmmo();
	end
	return true;
end

function onDamageChanged()
	local rAction = self.getDamageAction();
	local s = ""
	if rAction.sDamageType ~= "" then
		s = string.format("%s %s damage", rAction.nDamage, rAction.sDamageType)
	else
		s = string.format("%s damage", rAction.nDamage)
	end
	damageview.setValue(s)
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

function onDamageAction(draginfo)
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);
	local rAction = self.getDamageAction();	
	
	ActionDamage.payCostAndRoll(draginfo, rActor, rAction);
	return true;
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