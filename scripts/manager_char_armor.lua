function getShieldBonus(rActor)
	local items = CharInventoryManager.getArmorInInventory(rActor);
	local nMax = 0;
	for _, item in ipairs(items) do
		local nShieldBonus = ItemManagerCypher.getArmorSpeedAsset(item);
		if nShieldBonus > nMax then
			nMax = nShieldBonus;
		end
	end
	return nMax;
end

---------------------------------------------------------------
-- ARMOR GETTERS / SETTERS
---------------------------------------------------------------
-- Specifically gets the default, untyped, basic armor
function getDefaultArmor(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeChar, "defenses.armor.total", 0), CharArmorManager.getSuperArmor(rActor)
end

function getArmorBase(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeChar, "defenses.armor.base", 0);
end
function setArmorBase(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "defenses.armor.base", "number", nValue);
end
function modifyArmorBase(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nArmor = CharArmorManager.getArmorBase(rActor);
	CharArmorManager.setArmorBase(rActor, nArmor + nDelta)
end

function getArmorMod(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeChar, "defenses.armor.mod", 0);
end
function setArmorMod(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "defenses.armor.mod", "number", nValue);
end
function modifyArmorMod(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nArmor = CharArmorManager.getArmorMod(rActor);
	CharArmorManager.setArmorMod(rActor, nArmor + nDelta)
end

function getSuperArmor(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeChar, "defenses.armor.superarmor", 0);
end
function setSuperArmor(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "defenses.armor.superarmor", "number", nValue);
end
function modifySuperArmor(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nSuper = CharArmorManager.getSuperArmor(rActor);
	CharArmorManager.setSuperArmor(rActor, nSuper + nDelta)
end

---------------------------------------------------------------
-- EFFORT PENALTY GETTERS / SETTERS
---------------------------------------------------------------
function getEffortPenalty(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeChar, "effort.armorpenalty.total", 0)
end

function getEffortPenaltyBase(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeChar, "effort.armorpenalty.base", 0);
end
function setEffortPenaltyBase(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "effort.armorpenalty.base", nValue);
end
function modifyEffortPenaltyBase(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nPenalty = CharArmorManager.getEffortPenaltyBase(rActor);
	CharArmorManager.setEffortPenaltyBase(rActor, nPenalty + nDelta)
end

function getEffortPenaltyMod(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeChar, "effort.armorpenalty.mod", 0);
end
function setEffortPenaltyMod(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "effort.armorpenalty.mod", "number", nValue);
end
function modifyEffortPenaltyMod(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nPenalty = CharArmorManager.getEffortPenaltyMod(rActor);
	CharArmorManager.setEffortPenaltyMod(rActor, nPenalty + nDelta)
end