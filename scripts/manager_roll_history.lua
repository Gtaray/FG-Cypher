function onInit()
	CombatManager.setCustomTurnEnd(resetAttackEffortOnTurnEnd)
end


local _lastRolls = {}
-- Saves the last roll for each character
function setLastRoll(rSource, rTarget, rRoll)
	if not Session.IsHost then
		return
	end

	-- Only save PC rolls
	if not ActorManager.isPC(rSource) then
		return
	end

	local sSourceNodeName = ActorManager.getCTNodeName(rSource);
	if not sSourceNodeName then
		return
	end

	_lastRolls[sSourceNodeName] = {
		rRoll = rRoll,
		rTarget = rTarget
	}
end

-- Gets the last roll for a character
function getLastRoll(rSource)
	if not Session.IsHost then
		return
	end

	-- Only save PC rolls
	if not ActorManager.isPC(rSource) then
		return
	end

	local sSourceNodeName = ActorManager.getCTNodeName(rSource);
	if not sSourceNodeName then
		return
	end

	return _lastRolls[sSourceNodeName]
end

local _attackEffort = {}
local _attackEdge = {}
function resetAttackEffortOnTurnEnd(nodeCT)
	local sNodeName = ActorManager.getCTNodeName(nodeCT);
	
	clearAttackEffort(sNodeName)
end

function setAttackEffort(rSource, rTarget, rRoll)
	if not Session.IsHost then
		return
	end

	-- Only save PC rolls
	if not ActorManager.isPC(rSource) then
		return
	end

	local sSourceNodeName = ActorManager.getCTNodeName(rSource);
	if not sSourceNodeName then
		return
	end
	
	_attackEffort[sSourceNodeName] = tonumber(rRoll.nEffort)
end

function getAttackEffort(rSource, rTarget)
	if not Session.IsHost then
		return 0
	end

	-- Only save PC rolls
	if not ActorManager.isPC(rSource) then
		return 0
	end

	local sSourceNodeName = ActorManager.getCTNodeName(rSource);
	if not sSourceNodeName then
		return 0
	end

	return _attackEffort[sSourceNodeName] or 0
end

function clearAttackEffort(rSource, rTarget)
	if not Session.IsHost then
		return
	end

	-- Only save PC rolls
	if not ActorManager.isPC(rSource) then
		return
	end

	local sSourceNodeName = ActorManager.getCTNodeName(rSource);
	if not sSourceNodeName then
		return
	end
	
	_attackEffort[sSourceNodeName] = nil;
end