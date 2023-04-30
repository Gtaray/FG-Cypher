-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--	Difficulty Panel Management
--

local _panelWindow = nil;
function registerDifficultyPanel(w)
	_panelWindow = w;
	self.resetDifficultyPanel();
end
function resetDifficultyPanel()
	if not _panelWindow then
		return;
	end
	_panelWindow.effort.setValue(0);
	_panelWindow.assets.setValue(0);
	_panelWindow.disableedge.setValue(0);
end

--
--  Basic Roll Management
--

function buildPCRollInfo(nodeActor, sDesc, sStat)
	if not nodeActor then
		return nil;
	end

	local tOutput = { sDesc or "" };

	-- BASIC ROLL INFORMATION
	local tInfo = {};
	tInfo.nBaseCost = 0;
	tInfo.nTraining = 1;
	tInfo.nAssets = 0;
	tInfo.nMod = 0;

	-- STAT INFORMATION
	tInfo.sStat = sStat or "";
	if tInfo.sStat ~= "" then
		tInfo.nEdge = DB.getValue(nodeActor, "abilities." .. sStat .. ".edge");
	else
		tInfo.nEdge = 0;
	end

	-- EFFORT INFORMATION
	tInfo.nMaxEffort = DB.getValue(nodeActor, "effort");
	if tInfo.sStat == "speed" then
		tInfo.nArmorEffortCost = DB.getValue(nodeActor, "armorspeedcost", 0);
	else
		tInfo.nArmorEffortCost = 0;
	end
	tInfo.bWounded = (DB.getValue(nodeActor, "wounds", 0) > 0);
	if tInfo.bWounded then
		table.insert(tOutput, "[WOUNDED]");
	end

	-- MISC DIFFICULTY ADJ
	tInfo.nMiscStep = 0;
	if EffectManager.hasCondition(nodeActor, "Dazed") then
		tInfo.nMiscStep = tInfo.nMiscStep - 1;
		table.insert(tOutput, "[DAZED]");
	end

	tInfo.sDesc = table.concat(tOutput, " ");

	return tInfo;
end

function applyDesktopAdjustments(tInfo)
	if not _panelWindow or (tInfo.sStat == "") then
		tInfo.nEffort = 0;
		tInfo.nAssets = (tInfo.nAssets or 0);
		tInfo.bDisableEdge = false;
		return;
	end

	tInfo.nEffort = math.min(_panelWindow.effort.getValue(), tInfo.nMaxEffort or 1);
	tInfo.nAssets = math.max(math.min((tInfo.nAssets or 0) + _panelWindow.assets.getValue(), 2), 0);
	tInfo.bDisableEdge = (_panelWindow.disableedge.getValue() == 1);
	self.resetDifficultyPanel();
end

function resolveAdjustments(tInfo)
	self.applyDesktopAdjustments(tInfo);

	local tOutput = { tInfo.sDesc };

	tInfo.nTotalStep = tInfo.nMiscStep or 0;

	if tInfo.nTraining == 0 then
		table.insert(tOutput, "[INABILITY]");
		tInfo.nTotalStep = tInfo.nTotalStep - 1;
	elseif tInfo.nTraining == 2 then
		table.insert(tOutput, "[TRAINED]");
		tInfo.nTotalStep = tInfo.nTotalStep + 1;
	elseif tInfo.nTraining == 3 then
		table.insert(tOutput, "[SPECIALIZED]");
		tInfo.nTotalStep = tInfo.nTotalStep + 2;
	end
					
	if tInfo.nAssets > 0 then
		table.insert(tOutput, string.format("[ASSET %+d]", tInfo.nAssets));
		tInfo.nTotalStep = tInfo.nTotalStep + tInfo.nAssets;
	end

	if tInfo.nEffort > 0 then
		table.insert(tOutput, string.format("[APPLIED %s EFFORT]", tInfo.nEffort));
		tInfo.nTotalStep = tInfo.nTotalStep + tInfo.nEffort;
	end

	-- If the pc is down the damage track Effort costs more.
	local nWounded = 0;
	if tInfo.bWounded then
		nWounded = 1;
	end

	local nEffortCost = 0;
	if tInfo.nEffort > 0 then
		nEffortCost = 3 + ((tInfo.nEffort - 1) * 2) + (tInfo.nEffort * nWounded) + (tInfo.nEffort * tInfo.nArmorEffortCost);
	end

	tInfo.nTotalCost = (tInfo.nBaseCost or 0) + nEffortCost;
	if (tInfo.nTotalCost > 0) and (tInfo.nEdge > 0) then
		if tInfo.bDisableEdge then
			table.insert(tOutput, "[EDGE DISABLED]");
		else
			table.insert(tOutput, string.format("[APPLIED %s EDGE]", tInfo.nEdge));
			tInfo.nTotalCost = tInfo.nTotalCost - tInfo.nEdge;
		end
	end
	tInfo.nTotalCost = math.max(tInfo.nTotalCost, 0);

	tInfo.sDesc = table.concat(tOutput, " ");
end

function spendPointsForRoll(nodeActor, tInfo)
	if not nodeActor or not tInfo then
		return false;
	end
	
	if tInfo.nTotalCost <= 0 then
		return true;
	end

	if tInfo.sStat == "" then
		local rActor = ActorManager.resolveActor(nodeActor);
		local rMessage = ChatManager.createBaseMessage(rActor);
		rMessage.text = rMessage.text .. " [STAT NOT SPECIFIED FOR POINT SPEND]";
		Comm.deliverChatMessage(rMessage);
		return false;
	end

	local nCurrentPool = DB.getValue(nodeActor, "abilities." .. tInfo.sStat .. ".current", 0);
	if tInfo.nTotalCost > nCurrentPool then
		local rActor = ActorManager.resolveActor(nodeActor);
		local rMessage = ChatManager.createBaseMessage(rActor);
		rMessage.text = rMessage.text .. " [INSUFFICIENT POINTS IN POOL]";
		Comm.deliverChatMessage(rMessage);
		return false;
	end

	tInfo.sDesc = tInfo.sDesc .. string.format(" [SPENT %d FROM %s POOL]", tInfo.nTotalCost, Interface.getString(tInfo.sStat):upper());
    local nNewPool = nCurrentPool - tInfo.nTotalCost;
	DB.setValue(nodeActor, "abilities." .. tInfo.sStat .. ".current", "number", nNewPool);
    
    if nNewPool == 0 then
        local nCurrentWounds = DB.getValue(nodeActor, "wounds", 0);
        DB.setValue(nodeActor, "wounds", "number", nCurrentWounds + 1);
    end

	return true;
end
