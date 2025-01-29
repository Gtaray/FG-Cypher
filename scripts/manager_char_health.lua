function rest(nodeChar)
	CharHealthManager.setRecoveriesUsed(nodeChar, 0);
end

function isImpaired(rActor)
	rActor = ActorManager.resolveActor(rActor);
	if not ActorManager.isPC(rActor) then
		return false;
	end	

	local nWounds = CharHealthManager.getDamageTrack(rActor);
	if EffectManagerCypher.hasEffect(rActor, "IGNOREIMPAIRED", nil, false, true) then
		nWounds = nWounds - 1;
	end

	return nWounds >= 1;
end

-----------------------------------------------------------
-- SETTERS / GETTERS
-----------------------------------------------------------
function modifyDamageTrack(rActor, nIncrement)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end
	
	local nCur = ActorHealthManager.getDamageTrack(rActor);
	local nNewValue = math.max(math.min(nCur + nIncrement, 3), 0);

	ActorHealthManager.setDamageTrack(rActor, nNewValue);
end
function setDamageTrack(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	nValue = math.max(math.min(nValue, 3), 0);
	DB.setValue(nodeChar, "health.damagetrack", "number", nValue);
end
function getDamageTrack(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeChar, "health.damagetrack", 0);
end

function getRecoveriesUsed(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	return DB.getValue(nodeChar, "health.recovery.used", 0);
end
function setRecoveriesUsed(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	return DB.setValue(nodeChar, "health.recovery.used", "number", nValue);
end
function modifyRecoveriesUsed(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nUsed = CharHealthManager.getRecoveriesUsed(nodeChar)
	nUsed = math.min(math.max(nUsed + nDelta, 0), 4);

	CharHealthManager.setRecoveriesUsed(nodeChar, nUsed);
end

function setRecoveryRollMod(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "health.recovery.mod", "number", nValue);
end
function getRecoveryRollMod(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return 0;
	end

	return DB.getValue(nodeChar, "health.recovery.total", 0);
end
function modifyRecoveryRollMod(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local nMod = CharHealthManager.getRecoveryRollMod(nodeChar)
	nMod = nMod + nDelta

	CharHealthManager.setRecoveryRollMod(nodeChar, nMod);
end
