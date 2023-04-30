-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	initActorHealth();
end

--
--	HEALTH
-- 

STATUS_HALE = "Hale";
STATUS_IMPAIRED = "Impaired";
STATUS_DEBILITATED = "Debilitated";

function initActorHealth()
	ActorHealthManager.getWoundPercent = getWoundPercent;
end

function getWoundPercent(v)
	local rActor = ActorManager.resolveActor(v);

	local nHP = 0;
	local nWounds = 0;

	local nodeCT = ActorManager.getCTNode(rActor);
	if nodeCT then
		if ActorManager.isPC(rActor) then
			nHP = 3;
		else
			nHP = DB.getValue(nodeActor, "hp", 0);
		end
		nWounds = DB.getValue(nodeCT, "wounds", 0);
	elseif ActorManager.isPC(rActor) then
		local nodePC = ActorManager.getCreatureNode(rActor);
		if nodePC then
			nHP = 3;
			nWounds = DB.getValue(nodePC, "wounds", 0);
		end
	end

	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end
	
	local sStatus;
	if sNodeType == "pc" then
		if nWounds <= 0 then
			sStatus = STATUS_HALE;
		elseif nWounds == 1 then
			sStatus = STATUS_IMPAIRED;
		elseif nWounds == 2 then
			sStatus = STATUS_DEBILITATED;
		else
			sStatus = ActorHealthManager.STATUS_DEAD;
		end
	else
		if nPercentWounded <= 0 then
			sStatus = ActorHealthManager.STATUS_HEALTHY;
		elseif nPercentWounded < .5 then
			sStatus = ActorHealthManager.STATUS_SIMPLE_WOUNDED;
		elseif nPercentWounded < 1 then
			sStatus = ActorHealthManager.STATUS_SIMPLE_HEAVY;
		else
			sStatus = ActorHealthManager.STATUS_DEAD;
		end
	end

	return nPercentWounded, sStatus;
end
