function getDefense(rActor, sStat)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or (sStat or "") == "" then
		return;
	end

	sStat = sStat:lower();

	if not StringManager.contains({ "might", "speed", "intellect" }, sStat) then
		return getCustomStatDefense(rActor, sStat)
	end

	local sTraining = RollManager.resolveTraining(DB.getValue(nodeActor, "stats." .. sStat .. ".def.training", 1));
	local nAssets = DB.getValue(nodeActor, "stats." .. sStat .. ".def.asset", 0);
	local nModifier = DB.getValue(nodeActor, "stats." .. sStat .. ".def.misc", 0);

	return sTraining, nAssets, nModifier
end

---------------------------------------------------------------
-- INITIATIVE GETTERS AND SETTERS
---------------------------------------------------------------
function getInitiative(rActor)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return "", 0, 0;
	end

	local sTraining = RollManager.resolveTraining(DB.getValue(nodeChar, "initiative.training", 1))
	local nAssets = DB.getValue(nodeChar, "initiative.assets", 0);
	local nModifier = DB.getValue(nodeChar, "initiative.mod", 0);

	return sTraining, nAssets, nModifier;
end

function setInitiativeMod(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	DB.setValue(nodeChar, "initiative.mod", "number", nValue);
end
function modifyInitiativeMod(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local _, _, nMod = CharStatManager.getInitiative(rActor);
	CharStatManager.setInitiative(rActor, nMod + nDelta);
end

function setInitiativeAssets(rActor, nValue)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	-- Lock the value to between 0 and 2
	nValue = math.max(math.min(nValue, 2), 0);
	DB.setValue(nodeChar, "initiative.assets", "number", nValue);
end
function modifyInitiativeAssets(rActor, nDelta)
	local nodeChar;
	if type(rActor) == "databasenode" then
		nodeChar = rActor;
	else
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if not nodeChar or not ActorManager.isPC(rActor) then
		return;
	end

	local _, nAssets = CharStatManager.getInitiative(rActor);
	CharStatManager.setInitiativeAssets(rActor, nAssets + nDelta);
end

---------------------------------------------------------------
-- EDGE GETTERS AND SETTERS
---------------------------------------------------------------

function getEdgeWithEffects(rActor, sStat, aFilter)
	local nBase = CharStatManager.getEdge(rActor, sStat);
	local nBonus = EffectManagerCypher.getEdgeEffectBonus(rActor, aFilter);

	return nBase + nBonus;
end

function getEdge(rActor, sStat)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" then
		return 0;
	end

	sStat = sStat:lower();

	-- Look for a custom stat pool
	if not StringManager.contains({ "might", "speed", "intellect" }, sStat) then
		local _, _, nCustomEdge = CharStatManager.getCustomStatPool(rActor, sStat);
		return nCustomEdge;
	end

	return DB.getValue(nodeActor, "stats." .. sStat .. ".edge", 0);
end

---------------------------------------------------------------
-- STAT POOL GETTERS AND SETTERS
---------------------------------------------------------------
function getStatPool(rActor, sStat)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" then
		return 0, 0;
	end

	sStat = sStat:lower();
	local nCur = 0;
	local nMax = 0;

	-- Look for a custom stat pool
	if not StringManager.contains({ "might", "speed", "intellect" }, sStat) then
		nCur, nMax = CharStatManager.getCustomStatPool(rActor, sStat);
	else 
		local sPath = "stats." .. sStat;
		nCur = DB.getValue(nodeActor, sPath .. ".current", 0);
		nMax = DB.getValue(nodeActor, sPath .. ".max", 10);
	end

	return nCur, nMax;
end

function setStatMax(rActor, sStat, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" or nValue == 0 then
		return 0;
	end

	-- Look for a custom stat pool
	if not StringManager.contains({ "might", "speed", "intellect" }, sStat) then
		CharStatManager.setCustomStatPoolMax(rActor, sStat, nValue);
		return
	end
	
	local sPath = string.format("stats.%s.maxbase", sStat:lower());
	DB.setValue(nodeActor, sPath, "number", nValue);
end
function modifyStatMax(rActor, sStat, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" or nValue == 0 then
		return 0;
	end

	sStat = sStat:lower();
	local _, nMax = CharStatManager.getStatPool(rActor, sStat)

	-- New stat pool maximum
	nMax = nMax + nValue;
	CharStatManager.setStatMax(rActor, sStat, nMax);

	-- Modify the current amount by the same amount
	CharStatManager.addToStatPool(rActor, sStat, nValue);
end

function addToStatPool(rActor, sStat, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" or nValue == 0 then
		return 0;
	end

	sStat = sStat:lower();

	local nCur, nMax = CharStatManager.getStatPool(rActor, sStat);

	-- Shortcut. If the stat pool is already capped out, then we just return
	-- the entire value as overflow
	if (nCur == nMax and nValue > 0) or (nCur == 0 and nValue < 0) then
		return math.abs(nValue);
	end

	local nNewValue = nCur + nValue;
	local nOverflow = 0;

	-- Return overflow healing
	if nNewValue > nMax then
		nOverflow = nNewValue - nMax;

	-- Return overflow damage
	elseif nNewValue < 0 then
		nOverflow = math.abs(nNewValue);
	end

	-- Clamp nNewValue between 0 and the pool's max
	nNewValue = math.max(math.min(nNewValue, nMax), 0);
	CharStatManager.setStatPool(rActor, sStat, nNewValue);
	return nOverflow;
end
function setStatPool(rActor, sStat, nValue)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	if not nodeActor or (sStat or "") == "" then
		return 0;
	end

	sStat = sStat:lower();

	local nCur, nMax = CharStatManager.getStatPool(rActor, sStat)

	-- Look for a custom stat pool
	if not StringManager.contains({ "might", "speed", "intellect" }, sStat) then
		nValue = math.max(math.min(nValue, nMax), 0);
		CharStatManager.setCustomStatPool(rActor, sStat, nValue);
		return
	end

	local sPath = "stats." .. sStat;
	nValue = math.max(math.min(nValue, nMax), 0);
	DB.setValue(nodeActor, sPath .. ".current", "number", nValue);

	-- If the character was above 0 in the stat pool and is now at 0, 
	-- we need to increment the damage track
	if nCur > 0 and nValue == 0 then
		CharHealthManager.modifyDamageTrack(rActor, 1);
	
	-- Or if the character was at 0 in the pool, but is now above 0,
	-- decrement the damage track
	elseif nCur == 0 and nValue > 0 then
		CharHealthManager.modifyDamageTrack(rActor, -1);
	end
end

---------------------------------------------------------------
-- CUSTOM STAT POOLS
---------------------------------------------------------------
function getCustomStatPools(rActor)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end

	if not nodeActor then
		return {}
	end
	
	local aPools = {}
	for _, node in ipairs(DB.getChildList(nodeActor, "custom_pools")) do
		local tPool = {
			sName = DB.getValue(node, "name", ""),
			nCurrent = DB.getValue(node, "current", 0),
			nMax = DB.getValue(node, "max", 0),
			nEdge = DB.getValue(node, "edge", 0),
		}
		
		table.insert(aPools, tPool)
	end

	return aPools
end

function hasCustomStatPool(rActor, sStat)
	local node = CharStatManager.getCustomStatPoolNode(rActor, sStat);
	return node ~= nil;
end

function getCustomStatPool(rActor, sStat)
	local node = CharStatManager.getCustomStatPoolNode(rActor, sStat);
	if not node then
		return 0, 0, 0;
	end
	
	return DB.getValue(node, "current", 0), DB.getValue(node, "max", 0), DB.getValue(node, "edge", 0);
end

function setCustomStatPool(rActor, sStat, nValue)
	local node = CharStatManager.getCustomStatPoolNode(rActor, sStat);
	if not node then
		return;
	end
	
	DB.setValue(node, "current", "number", nValue);
end

function setCustomStatPoolMax(rActor, sStat, nValue)
	local node = CharStatManager.getCustomStatPoolNode(rActor, sStat);
	if not node then
		return;
	end
	
	DB.setValue(node, "max", "number", nValue);
end

function setCustomStatPoolEdge(rActor, sStat, nValue)
	local node = CharStatManager.getCustomStatPoolNode(rActor, sStat);
	if not node then
		return;
	end
	
	DB.setValue(node, "edge", "number", nValue);
end

function getCustomStatDefense(rActor, sStat)
	local node = CharStatManager.getCustomStatPoolNode(rActor, sStat);
	if not node then
		return "", 0, 0;
	end

	return DB.getValue(node, "training", ""), DB.getValue(node, "assets", 0), DB.getValue(node, "mod", 0)
end

function getCustomStatPoolNode(rActor, sStat, bCreateIfDoesNotExist)
	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end
	
	for _, node in ipairs(DB.getChildList(nodeActor, "custom_pools")) do
		local sName = DB.getValue(node, "name", "");
		if sStat:lower() == sName:lower() then
			return node;
		end
	end

	if not bCreateIfDoesNotExist then
		return;
	end

	-- Create the node then return it.
	return CharStatManager.createCustomStatPool(rActor, sStat)
end

function createCustomStatPool(rActor, sStat, nCur, nMax, nEdge)
	if not nCur then nCur = 0 end;
	if not nMax then nMax = 0 end;
	if not nEdge then nEdge = 0 end;

	local nodeActor;
	if type(rActor) == "databasenode" then
		nodeActor = rActor;
	else
		nodeActor = ActorManager.getCreatureNode(rActor);
	end

	if not nodeActor then
		return;
	end

	local listnode = DB.createChild(nodeActor, "custom_pools");
	if not listnode then
		return;
	end

	local poolnode = DB.createChild(listnode);
	if not poolnode then
		return;
	end

	DB.setValue(poolnode, "name", "string", StringManager.capitalize(sStat))
	DB.setValue(poolnode, "current", "number", nCur);
	DB.setValue(poolnode, "max", "number", nMax);
	DB.setValue(poolnode, "edge", "number", nEdge);
	return poolnode;
end