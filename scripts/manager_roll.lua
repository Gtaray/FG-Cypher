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

-----------------------------------------------------------------------
-- rAction Definition
-- rAction = {
	-- label = string (name of the roll. Displayed after the [ROLLTYPE] tag at the beginning of the roll's message text)
	-- nModifier = number (flat modifier to apply to the roll)
	-- sStat = string (might|speed|intellect. Defaults to might)
	-- sTraining = string (flag for the roll's level of training. trained|specialized|inability. Defaults to nil)
	-- nAssets = number (number of Assets applied to this roll. Defaults to 0)
	-- nMaxAssets = numbert (maximum number of assets that can be applied to this roll. Defaults to 2)
	-- nEdge = number (amount of edge applied to the roll. defaults to 0)
	-- bUsedEdge = boolean (flags whether edge was used when paying stat costs)
	-- bDisableEdge = boolean (flags whether edge should be applied to the cost of the roll)
	-- nEffort = number (number of effort levels applied to this roll)
	-- nMaxEffort = number (maximum effort that can be applied to this roll)
	-- sStatUsedForCost = string (stat used to pay for costs. might|speed|intellect. Defaults to match rAction.sStat, or might)
	-- nCost = number (cost of the ability)
	-- nArmorCost = number (cost increase due to wearing armor)
	-- bWounded = boolean (flags whether the character rolling is wounded, which increases effort cost)
	-- sDefenseStat = string (stat that PCs use when rolling defense vs an attack. might|speed|intellect)
	-- sWeaponType = string (weapon type. light|medium|heavy)
	-- sRange = string (range of an attack. immediate|short|far)
	-- nLevel = number (level modifier for NPC actions)
	-- bPierce = boolean (flags whether a damage roll should pierce armor)
	-- nPierceAmount = number (amount of armor a damage roll pierces. If bPierce is true and this is 0, then all armor is ignored)
	-- bAmbient = boolean (flags whether a damage roll is ambient damage)
-- }
-----------------------------------------------------------------------
-- ACTION ADJUSTMENTS
-----------------------------------------------------------------------
-- Applies the effort, assets, and edge flag from the desktop mod window
function applyDesktopAdjustments(rActor, rAction)
	if not _panelWindow or (rAction.sStat == "") then
		rAction.nEffort = 0;
		rAction.nAssets = (rAction.nAssets or 0);
		rAction.bDisableEdge = false;
		return;
	end

	-- We don't care about limiting the amount of effort or the amount of assets appplied here because
	-- we will limit them later, taking into account effects that modify max effort and max assets
	rAction.nEffort = _panelWindow.effort.getValue();
	rAction.nAssets = (rAction.nAssets or 0) + _panelWindow.assets.getValue();
	rAction.bDisableEdge = (_panelWindow.disableedge.getValue() == 1);
	self.resetDifficultyPanel();
end

function addMaxAssetsToAction(rActor, rAction, aFilter)
	-- if there's no stat, then we can't apply any effort or edge (no stat pool to pull from)
	if not rActor or (rAction.sStat or "") == "" then
		return;
	end

	rAction.nMaxAssets = ActorManagerCypher.getMaxAssets(rActor, aFilter);
end

function addMaxEffortToAction(rActor, rAction, aFilter)
	-- if there's no stat, then we can't apply any effort or edge (no stat pool to pull from)
	if not rActor or (rAction.sStat or "") == "" then
		return;
	end

	rAction.nMaxEffort = ActorManagerCypher.getMaxEffort(rActor, rAction.sStat, aFilter);
end

function addEdgeToAction(rActor, rAction, aFilter)
	if not rActor or (rAction.sStat or "") == "" then
		return;
	end

	rAction.nEdge = ActorManagerCypher.getEdge(rActor, rAction.sStat, aFilter);
end

function addWoundedToAction(rActor, rAction, sRollType)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return;
	end

	-- Don't apply the wounded flag for damage or healing rolls
	if sRollType == "damage" or sRollType == "heal" then
		return;
	end
	rAction.bWounded = (DB.getValue(nodeActor, "wounds", 0) > 0);
end

function applyEffortToModifier(rActor, rAction)
	if rAction.nEffort ~= 0 then
		rAction.nModifier = rAction.nModifier + (rAction.nEffort * 3);
	end
end

-- Adds the effort values to the action table
function addArmorCostToAction(rActor, rAction)
	-- if there's no stat, then we can't apply any effort or edge (no stat pool to pull from)
	if not rActor or (rAction.sStat or "") == "" then
		return;
	end

	rAction.nArmorCost = 0;
	if not RollManager.resolveStatUsedForCost(rAction) then
		return;
	end

	if rAction.sStatUsedForCost == "speed" then
		rAction.nArmorCost = ActorManagerCypher.getArmorSpeedCost(rActor);
	end
end

-- the sMisc argument here is used by rolls to further filter the COST effect
function calculateBaseEffortCost(rActor, rAction)
	rAction.bUsedEdge = false;
	
	local nWounded = 0;
	if rAction.bWounded then
		nWounded = 1;
	end

	local nEffortCost = 0;
	if (rAction.nEffort or 0) > 0 then
		nEffortCost = 3 + ((rAction.nEffort - 1) * 2) + (rAction.nEffort * nWounded) + (rAction.nEffort * rAction.nArmorCost);
	end

	rAction.nCost = (rAction.nCost or 0) + nEffortCost;

	if ((rAction.nCost or 0) > 0) and ((rAction.nEdge or 0) > 0) then
		if not rAction.bDisableEdge then
			rAction.nCost = rAction.nCost - rAction.nEdge;
			rAction.bUsedEdge = true;
		end
	end

	rAction.nCost = math.max(rAction.nCost, 0);
end

function adjustEffortCostWithEffects(rActor, rAction, aEffectFilter)
	if not rActor then
		return
	end
	local nCostMod = EffectManagerCypher.getEffectsBonusByType(rActor, "COST", aEffectFilter);
	rAction.nCost = (rAction.nCost or 0) + nCostMod
end

function spendPointsForRoll(rActor, rAction)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or not rAction then
		return false;
	end
	
	if (rAction.nCost or 0) <= 0 then
		return true;
	end

	-- In case cost.sStat isn't set, we resolve it here.
	if not RollManager.resolveStatUsedForCost(rAction) then
		local rMessage = ChatManager.createBaseMessage(rActor);
		rMessage.text = rMessage.text .. " [STAT NOT SPECIFIED FOR POINT SPEND]";
		Comm.deliverChatMessage(rMessage);
		return false;
	end

	local nCurrentPool = ActorManagerCypher.getStatPool(rActor, rAction.sStatUsedForCost);
	if rAction.nCost > nCurrentPool then
		local rMessage = ChatManager.createBaseMessage(rActor);
		rMessage.text = rMessage.text .. " [INSUFFICIENT POINTS IN POOL]";
		Comm.deliverChatMessage(rMessage);
		return false;
	end

	rAction.label = rAction.label .. string.format(
		" [SPENT %d %s]", 
		rAction.nCost, 
		Interface.getString(rAction.sStatUsedForCost):upper());

	ActorManagerCypher.addToStatPool(rActor, rAction.sStatUsedForCost, -rAction.nCost);

	return true;
end

-----------------------------------------------------------------------
-- RESOLVE DATA
-----------------------------------------------------------------------
-- Resolves a stat to either speed, intellect, or might
function resolveStat(sStat, sDefault)
	if not sDefault then
		sDefault = "might";
	end

	sStat = (sStat or ""):lower();
	if sStat == "" then
		sStat = sDefault:lower();
	end
	return sStat;
end

-- Returns a number representing of how the difficulty of an NPC is modified
-- based on training, assets, and modifier
function resolveDifficultyModifier(sTraining, nAssets, nLevel, nMod)
	local nDifficulty = nLevel or 0;

	sTraining = sTraining:lower();
	if sTraining == "trained" then
		nDifficulty = -1;
	elseif sTraining == "specialized" then
		nDifficulty = -2;
	elseif sTraining == "inability" then
		nDifficulty = 1;
	end

	local nDiffMod = math.floor(nMod / 3);
	local nFinalMod = nMod % 3;

	nDifficulty = nDifficulty - nDiffMod - nAssets;

	return nDifficulty, nFinalMod;
end

function resolveStatUsedForCost(rAction)
	-- if cost.sStat is already set, then don't do anything
	if (rAction.sStatUsedForCost or "") ~= "" then
		return true;
	end

	-- if cost.sStat is not set, then set it to match rAction.sStat
	if rAction.sStat ~= "" then
		rAction.sStatUsedForCost = rAction.sStat;
		return true;
	end

	return false;
end

function resolveMaximumEffort(rActor, rAction, aFilter)
	RollManager.addMaxEffortToAction(rActor, rAction, aFilter);
	rAction.nEffort = math.min(rAction.nEffort, rAction.nMaxEffort);
end

function resolveMaximumAssets(rActor, rAction, aFilter)
	RollManager.addMaxAssetsToAction(rActor, rAction, aFilter);
	rAction.nAssets = math.min(rAction.nAssets, rAction.nMaxAssets);
end

function resolveEaseHindrance(rSource, rTarget, aFilter)
	local bEase, bHinder = false, false;
	if type(aFilter) == "string" then
		aFilter = { aFilter }
	end

	local aEaseEffects = EffectManager.getEffectsByType(rSource, "EASE", aFilter, rTarget)
	local aHinderEffects = EffectManager.getEffectsByType(rSource, "HINDER", aFilter, rTarget)

	bEase = #aEaseEffects > 0 or ModifierManager.getKey("EASE");
	bHinder = #aHinderEffects > 0 or ModifierManager.getKey("HINDER");

	return bEase, bHinder;
end

-- Converts a training cycler's value (a number) to a string that's used by the action rollers
function resolveTraining(nTraining)
	if nTraining == 2 then
		return "trained";
	elseif nTraining == 3 then
		return "specialized";
	elseif nTraining == 0 then
		return "inability";
	end
end

-----------------------------------------------------------------------
-- ROLL PROCESSING
-----------------------------------------------------------------------
function processFlatModifiers(rSource, rTarget, rRoll, aEffects, aFilter)
	if not rRoll.nMod then
		rRoll.nMod = 0;
	end

	local nEffectMod = EffectManagerCypher.getEffectsBonusByType(rSource, aEffects, aFilter, rTarget);
	rRoll.nMod = rRoll.nMod + nEffectMod;
	local nAssets = math.floor(rRoll.nMod / 3); -- For every +3 to the roll, add an asset
	rRoll.nMod = rRoll.nMod % 3; -- Reduce the modifier to only 0 to 2

	-- Return the number of assets the modifiers were converted to
	return nAssets, nEffectMod;
end

function processAssets(rSource, rTarget, aFilter, nAssets)
	local nAssetEffect = EffectManagerCypher.getEffectsBonusByType(rSource, "ASSET", aFilter, rTarget)
	local nMaxAssets = ActorManagerCypher.getMaxAssets(rSource, aFilter);
	return math.min(nAssetEffect, nMaxAssets - nAssets);
end

function processEffort(rSource, rTarget, sStat, aFilter, nEffort)
	local nEffortEffect = EffectManagerCypher.getEffectsBonusByType(rSource, "EFFORT", aFilter, rTarget)
	local nMaxEffort = ActorManagerCypher.getMaxEffort(rSource, sStat, aFilter);
	return math.min(nEffortEffect, nMaxEffort - nEffort);
end

function processTraining(bInability, bTrained, bSpecialized)
	-- negative for the inability and positive for the training
	-- because it makes modifying rRoll.nDifficulty read better
	if bInability then return -1
	elseif bTrained then return 1
	elseif bSpecialized then return 2
	else return 0 end
end

function processStandardConditions(rSource, rTarget)
	local nLevelAdjust = 0;
	-- Dazed doesn't stack with the other conditions
	if EffectManager.hasCondition(rSource, "Dazed") or 
	   (sStat == "might" and EffectManager.hasCondition(rSource, "Staggered")) or
	   (sStat == "speed" and EffectManager.hasCondition(rSource, "Frostbitten")) or
	   (sStat == "intellect" and EffectManager.hasCondition(rSource, "Confused")) then
		nLevelAdjust = nLevelAdjust + 1;
	end
	if EffectManager.hasCondition(rTarget, "Dazed") or 
		(sStat == "might" and EffectManager.hasCondition(rTarget, "Staggered")) or
		(sStat == "speed" and EffectManager.hasCondition(rTarget, "Frostbitten")) or
		(sStat == "intellect" and EffectManager.hasCondition(rTarget, "Confused"))then
		nLevelAdjust = nLevelAdjust - 1;
	end

	return nLevelAdjust;
end

function processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons)
	if #(rRoll.aDice) == 1 and rRoll.aDice[1].type == "d20" then		
		local nDifficulty = tonumber(rRoll.nDifficulty) or 0;
		
		-- Calculate the total number of successes in this roll
		-- We don't account for assets or effort here becuase assets were already used to adjust the 	
		-- difficulty in the modRoll function
		local nTotal = ActionsManager.total(rRoll);
		local nSuccess = math.floor(nTotal / 3);
		nSuccess = math.max(0, math.min(10, nSuccess));
		
		-- A bit of jank, but if there's no target, then we need to display the actual difficulty we 
		-- beat. There's no nDifficulty to reduce, so we invert the difficulty mod and use that as our 
		-- bonus
		if rTarget then
			if ActorManager.isPC(rTarget) then
				-- For PC vs PC, we need to invert any difficulty adjustments
				-- This converts every difficulty reduction into a +3, and difficulty increase to a -3
				nSuccesses = nTotal + RollManager.convertDifficultyAdjustmentToFlatBonus(nDifficulty);
			else
				-- If we have a target, then we want the icon to display the difficulty
				-- of the target after all of the calc
				nDifficulty = math.min(math.max(nDifficulty, 0), 10);
				table.insert(aAddIcons, "task" .. nDifficulty)
			end
		else
			-- For rolls without targets, we subtract the difficulty of the roll
			-- since difficulty bonuses for the PC are negative, this inverts it so nSuccesses
			-- Will show what difficulty our roll would have beat
			nSuccess = math.min(math.max(nSuccess - nDifficulty, 0), 10);
			table.insert(aAddIcons, "task" .. nSuccess);
		end
		
		if #aAddIcons > 0 then
			rMessage.icon = { rMessage.icon };
			for _,v in ipairs(aAddIcons) do
				table.insert(rMessage.icon, v);
			end
		end

		if rTarget and nDifficulty >= 0 then
			if nDifficulty == 0 then
				return true, true;
			elseif nSuccess >= nDifficulty then
				return true, false;
			end
		end
	end

	return false, false;
end

-- This function simply converts a flat difficulty adjustment to the equivalent flat bonus
-- e.g. minus 1 difficulty = +3 to the roll; plus 1 difficulty = -3 to the roll
function convertDifficultyAdjustmentToFlatBonus(nDifficulty)
	return nDifficulty * -3;
end

-----------------------------------------------------------------------
-- ROLL TEXT ENCODING / DECODING
-----------------------------------------------------------------------
function addOrOverwriteText(sText, sMatch, sReplace)
	if string.find(sText, sMatch) then
		-- Only replace if the replacement text is not null and different than sMatch
		if sReplace ~= nil and sMatch ~= sReplace then
			sText = string.gsub(sText, sMatch, sReplace)
		end
	else
		sText = string.format("%s %s", sText, sReplace)
	end

	return sText;
end
function addOrMoveTextToEndOfString(sText, sMatch, sReplace)
	-- Remove existing text
	_, sText = RollManager.decodeText(sText, sMatch, nil, false);
	-- Re-add text to the end
	sText = RollManager.addOrOverwriteText(sText, sMatch, sReplace);

	return sText;
end
function decodeText(sText, sMatch, sValue, bPersist)
	if sValue == nil then
		sValue = sMatch;
	end

	local sResult = string.match(sText, sValue);
	if not bPersist then
		return sResult, sText:gsub(" " .. sMatch, "")
	end

	return sResult, sText;
end
function decodeTextAsNumber(sText, sMatch, sValue, bPersist)
	local sResult;
	sResult, sText = RollManager.decodeText(sText, sMatch, sValue, bPersist)

	return tonumber(sResult) or 0, sText;
end
function decodeTextAsBoolean(sText, sMatch, sValue, bPersist)
	local sResult;
	sResult, sText = RollManager.decodeText(sText, sMatch, sValue, bPersist)

	return (sResult or "") ~= "", sText;
end

function encodeStat(vAction, rRoll)
	local sStat = vAction;
	
	if type(vAction) == "table" then
		sStat = vAction.sStat;
	end

	if (sStat or "") ~= "" then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[STAT: %w-%]",
			string.format("[STAT: %s]", sStat)
		)
	end
end
function decodeStat(rRoll, bPersist)
	local sStat, sText = RollManager.decodeText(
		rRoll.sDesc,
		"%[STAT: %w-%]",
		"%[STAT: (%w-)%]",
		bPersist
	);
	rRoll.sDesc = sText;

	return sStat;
end

function encodeDefenseStat(vAction, rRoll)
	local sStat = vAction;
	
	if type(vAction) == "table" then
		sStat = vAction.sDefenseStat;
	end

	if (sStat or "") ~= "" then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[DEFSTAT: %w-%]",
			string.format("[DEFSTAT: %s]", sStat)
		)
	end
end
function decodeDefenseStat(rRoll, bPersist)
	local sStat, sText = RollManager.decodeText(
		rRoll.sDesc,
		"%[DEFSTAT: %w-%]",
		"%[DEFSTAT: (%w-)%]",
		bPersist
	);
	rRoll.sDesc = sText;

	return sStat;
end

function encodeTraining(vAction, rRoll)
	local sTraining = vAction;
	
	if type(vAction) == "table" then
		sTraining = vAction.sTraining;
	end

	local sText, sMatch;
	if sTraining == "trained" then
		sText = "[TRAINED]";
		sMatch = "(%[TRAINED%])"
	elseif sTraining == "specialized" then
		sText = "[SPECIALIZED]";
		sMatch = "(%[SPECIALIZED%])"
	elseif sTraining == "inability" then
		sText = "[INABILITY]";
		sMatch = "(%[SPECIALIZED%])"
	end

	if (sText or "") ~= "" then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			sMatch,
			sText
		)
	end
end
function decodeTraining(rRoll, bPersist)
	local bInability = RollManager.decodeTextAsBoolean(
		rRoll.sDesc, 
		"%[INABILITY%]",
		"(%[INABILITY%])",
		bPersist
	);
	local bTrained = RollManager.decodeTextAsBoolean(
		rRoll.sDesc, 
		"%[TRAINED%]",
		"(%[TRAINED%])",
		bPersist
	);
	local bSpecialized = RollManager.decodeTextAsBoolean(
		rRoll.sDesc, 
		"%[SPECIALIZED%]",
		"(%[SPECIALIZED%])",
		bPersist
	);

	return bInability, bTrained, bSpecialized;
end

function encodeEdge(rAction, rRoll)
	local sText = "";
	local sMatch = "";
	if rAction.bDisableEdge then
		sText = "[EDGE DISABLED]";
		sMatch = "%[EDGE DISABLED%]";
	elseif rAction.bUsedEdge then
		sText = string.format("[APPLIED %s EDGE]", rAction.nEdge);
		sMatch = "%[APPLIED %d+ EDGE%]"
	end

	if sText == "" or sMatch == "" then
		return;
	end

	rRoll.sDesc = RollManager.addOrOverwriteText(
		rRoll.sDesc,
		sMatch,
		sText
	)
end
function decodeEdge(rRoll, bPersist)
	local nEdge, sText = RollManager.decodeTextAsNumber(
		rRoll.sDesc,
		"[%APPLIED %d+ EDGE%]",
		"[%APPLIED (%d+) EDGE%]",
		bPersist
	);
	rRoll.sDesc = sText;
	return nEdge;
end

function encodeEffort(vAction, rRoll)
	local nEffort = vAction;
	
	if type(vAction) == "table" then
		nEffort = vAction.nEffort
	end

	if (nEffort or 0) > 0 then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc, 
			"%[APPLIED %d+ EFFORT%]", 
			string.format("[APPLIED %s EFFORT]", nEffort));
	end
end
function decodeEffort(rRoll, bPersist)
	local nEffort, sText = RollManager.decodeTextAsNumber(
		rRoll.sDesc, 
		"%[APPLIED %d- EFFORT%]",
		"%[APPLIED (%d-) EFFORT%]",
		bPersist
	);
	rRoll.sDesc = sText;

	return nEffort;
end

function encodeAssets(vAction, rRoll)
	local nAssets = vAction;
	
	if type(vAction) == "table" then
		nAssets = vAction.nAssets
	end

	if (nAssets or 0) ~= 0 then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc, 
			"%[ASSET %d+%]", 
			string.format("[ASSET %s]", nAssets));
	end
end
function decodeAssets(rRoll, bPersist)
	local nAssets, sText = RollManager.decodeTextAsNumber(
		rRoll.sDesc, 
		"%[ASSET %-?%d+%]",
		"%[ASSET (-?%d+)%]",
		bPersist
	);
	rRoll.sDesc = sText;

	return nAssets;
end

function encodeSkill(sSkill, rRoll)	
	if (sSkill or "") ~= "" then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[SKILL: [^]]-%]",
			string.format("[SKILL: %s]", sSkill)
		)
	end
end
function decodeSkill(rRoll, bPersist)
	local sSkill, sText = RollManager.decodeText(
		rRoll.sDesc,
		"%[SKILL: [^]]-%]",
		"%[SKILL: ([^]]-)%]",
		bPersist
	);
	rRoll.sDesc = sText;

	return sSkill;
end

function encodeWeaponType(rAction, rRoll)
	if (rAction.sWeaponType or "") ~= "" then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[WTYPE: [^]]-%]",
			string.format("[SKILL: %s]", rAction.sWeaponType)
		);
	end
end
function decodeWeaponType(rRoll, bPersist)
	local sWeaponType, sText = RollManager.decodeText(
		rRoll.sDesc,
		"%[WTYPE: [^]]-%]",
		"%[WTYPE: ([^]]-)%]",
		bPersist
	);
	rRoll.sDesc = sText;

	return sWeaponType;
end

function encodeTarget(vTarget, rRoll)
	if (vTarget or "") ~= "" then
		return;
	end

	local sTargetNode;
	if type(vTarget) == "table" then
		-- vTarget is the rTarget table
		sTargetNode = ActorManager.getCTNodeName(vTarget)
	elseif type(vTarget) == "databasenode" then
		sTargetNode = DB.getNodeName(vTarget);
	elseif type(vTarget) == "string" then
		sTargetNode = vTarget;
	end

	if (sTargetNode or "") ~= "" then
		RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[TARGET: [^]]+%]",
			string.format("[TARGET: %s]", sTargetNode)
		)
	end
end
function decodeTarget(rRoll, rTarget, bPersist)
	local sTarget, sText = RollManager.decodeText(
		rRoll.sDesc,
		"%[TARGET: [^]]+%]",
		"%[TARGET: ([^]]+)%]",
		bPersist
	);
	rRoll.sDesc = sText;

	-- Don't overwrite rTarget unless rTarget is null
	if not rTarget or not rTarget.sCTNode then
		rTarget = ActorManager.resolveActor(sTarget);
	end

	return sTarget;
end

function encodeEaseHindrance(rRoll, bEase, bHinder)
	if bEase then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[EASED%]",
			"[EASED]"
		);
	end
	if bHinder then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[HINDERED%]",
			"[HINDERED]"
		);
	end
end
function decodeEaseHindrance(rRoll, bPersist)
	local bEase = RollManager.decodeTextAsBoolean(
		rRoll.sDesc,
		"%[EASED%]",
		nil,
		bPersist
	);
	local bHinder = RollManager.decodeTextAsBoolean(
		rRoll.sDesc,
		"%[HINDERED%]",
		nil,
		bPersist
	);

	return bEase, bHinder
end

function encodeEffects(rRoll, nRollMod)
	if nRollMod ~= 0 then
		local sText = "[EFFECTS: ";

		if nRollMod > 0 then
			sText = string.format("%s +%s]", sText, nRollMod);
		elseif nRollMod < 0 then
			sText = string.format("%s %s]", sText, nRollMod);
		end

		rRoll.sDesc = RollManager.addOrMoveTextToEndOfString(
			rRoll.sDesc, 
			"%[EFFECTS:%s-[+-]?%d+%]",
			sText
		);
	end
end
function decodeEffects(rRoll, bPersist)
	local nResult, sText = RollManager.decodeTextAsNumber(
		rRoll.sDesc,
		"%[EFFECTS:%s-[+-]?%d+%]",
		"%[EFFECTS:%s-+?([-]?d-)%]",
		bPersist
	);

	return nResult;
end

-- encode/decode level might not be needed. Potentially only NPCs need it.
function encodeLevel(rAction, rRoll)
	if (rAction.nLevel or 0) ~= 0 then
		RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[LEVEL: %-?%d+%]",
			string.format("[LEVEL: %s]", rAction.nLevel)
		)
	end
end
function decodeLevel(vRoll, bPersist)
	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

	local nLevel, sText = RollManager.decodeTextAsNumber(
		rRoll.sDesc,
		"%[LEVEL: %-?%d+%]",
		"%[LEVEL: (%-?%d+)%]",
		bPersist
	)

	rRoll.sDesc = sText;

	return nLevel;
end