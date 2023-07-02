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

function getEffortFromDifficultyPanel(bRetain)
	if not _panelWindow then
		return 0;
	end

	local nEffort = _panelWindow.effort.getValue();

	if not bRetain then
		_panelWindow.effort.setValue(0);
	end

	return nEffort;
end

function getAssetsFromDifficultyPanel(bRetain)
	if not _panelWindow then
		return 0;
	end

	local nAssets = _panelWindow.assets.getValue();

	if not bRetain then
		_panelWindow.assets.setValue(0);
	end

	return nAssets;
end

function isEdgeDisabled(bRetain)
	if not _panelWindow then
		return false;
	end

	local bDisableEdge = (_panelWindow.disableedge.getValue() == 1);

	if not bRetain then
		_panelWindow.disableedge.setValue(0);
	end

	return bDisableEdge;
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
	-- sCostStat = string (stat used to pay for costs. might|speed|intellect. Defaults to match rAction.sStat, or might)
	-- nCost = number (cost of the ability)
	-- nArmorCost = number (cost increase due to wearing armor)
	-- bWounded = boolean (flags whether the character rolling is wounded, which increases effort cost)
	-- sDefenseStat = string (stat that PCs use when rolling defense vs an attack. might|speed|intellect)
	-- sWeaponType = string (weapon type. light|medium|heavy)
	-- sRange = string (range of an attack. immediate|short|far)
	-- nLevel = number (level modifier for NPC actions)
	-- nDamage = number (damage dealt)
	-- nDamageStat = string (stat pool that is deducted when applying damage. might|speed|intellect)
	-- bPierce = boolean (flags whether a damage roll should pierce armor)
	-- nPierceAmount = number (amount of armor a damage roll pierces. If bPierce is true and this is 0, then all armor is ignored)
	-- bAmbient = boolean (flags whether a damage roll is ambient damage)
	-- nHeal = number (amount healed)
	-- nHealStat = string (might|speed|intellect. Stat that's healed with ability)
	-- nEase = number (reduces the difficulty of the roll by x stages)
	-- nHinder = number (increases the difficulty of the roll by x stages)
-- }
-----------------------------------------------------------------------
-- ACTION ADJUSTMENTS
-----------------------------------------------------------------------
-- Applies the effort, assets, and edge flag from the desktop mod window
function applyDesktopAdjustments(rActor, rAction)
	if not _panelWindow or (rAction.sStat == "") then
		rAction.nEffort = (rAction.nEffort or 0);
		rAction.nAssets = (rAction.nAssets or 0);
		rAction.bDisableEdge = false;
		return;
	end

	-- We don't care about limiting the amount of effort or the amount of assets appplied here because
	-- we will limit them later, taking into account effects that modify max effort and max assets
	rAction.nEffort = (rAction.nEffort or 0) + _panelWindow.effort.getValue();
	rAction.nAssets = (rAction.nAssets or 0) + _panelWindow.assets.getValue();
	rAction.bDisableEdge = (_panelWindow.disableedge.getValue() == 1);

	self.resetDifficultyPanel();
end

function addMaxAssetsToAction(rActor, rAction, aFilter)
	-- If for some reason there's no actor, default to 2.
	if not rActor or not ActorManager.isPC(rActor) then
		rAction.nMaxAssets = 2;
		return;
	end

	rAction.nMaxAssets = ActorManagerCypher.getMaxAssets(rActor, aFilter);
end

function addMaxEffortToAction(rActor, rAction, aFilter)
	-- if there's no stat, then we can't apply any effort or edge (no stat pool to pull from)
	if not rActor or not ActorManager.isPC(rActor) or (rAction.sStat or "") == "" then
		return;
	end

	rAction.nMaxEffort = ActorManagerCypher.getMaxEffort(rActor, rAction.sStat, aFilter);
end

function addEdgeToAction(rActor, rAction, aFilter)
	if not rActor or not ActorManager.isPC(rActor) or (rAction.sStat or "") == "" then
		return;
	end

	rAction.nEdge = ActorManagerCypher.getEdge(rActor, rAction.sStat, aFilter);
end

function addWoundedToAction(rActor, rAction, sRollType)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or not ActorManager.isPC(rActor) then
		return;
	end

	-- Don't apply the wounded flag for damage or healing rolls
	if sRollType == "damage" or sRollType == "heal" then
		return;
	end
	rAction.bWounded = (DB.getValue(nodeActor, "wounds", 0) > 0);
end

function applyEffortToModifier(rActor, rAction)
	if not  ActorManager.isPC(rActor) then
		return;
	end
	
	if rAction.nEffort ~= 0 then
		rAction.nModifier = rAction.nModifier + (rAction.nEffort * 3);
	end
end

-- Adds the effort values to the action table
function addArmorCostToAction(rActor, rAction)
	-- if there's no stat, then we can't apply any effort or edge (no stat pool to pull from)
	if not rActor or not ActorManager.isPC(rActor) or (rAction.sStat or "") == "" then
		return;
	end

	rAction.nArmorCost = 0;
	if not RollManager.resolveStatUsedForCost(rAction) then
		return;
	end

	if rAction.sCostStat == "speed" then
		rAction.nArmorCost = ActorManagerCypher.getArmorSpeedCost(rActor);
	end
end

-- the sMisc argument here is used by rolls to further filter the COST effect
function calculateBaseEffortCost(rActor, rAction)
	if not ActorManager.isPC(rActor) then
		return;
	end

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
	if not rActor or not ActorManager.isPC(rActor) then
		return
	end
	local nCostMod = EffectManagerCypher.getEffectsBonusByType(rActor, "COST", aEffectFilter);
	rAction.nCost = (rAction.nCost or 0) + nCostMod
end

function spendPointsForRoll(rActor, rAction)
	if not ActorManager.isPC(rActor) then
		return true;
	end

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

	local nCurrentPool = ActorManagerCypher.getStatPool(rActor, rAction.sCostStat);
	if rAction.nCost > nCurrentPool then
		local rMessage = ChatManager.createBaseMessage(rActor);
		rMessage.text = rMessage.text .. " [INSUFFICIENT POINTS IN POOL]";
		Comm.deliverChatMessage(rMessage);
		return false;
	end

	rAction.label = rAction.label .. string.format(
		" [SPENT %d %s]", 
		rAction.nCost, 
		Interface.getString(rAction.sCostStat):upper());

	ActorManagerCypher.addToStatPool(rActor, rAction.sCostStat, -rAction.nCost);

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

	sTraining = (sTraining or ""):lower();
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

-- TODO: REMOVE
function resolveStatUsedForCost(rAction)
	-- if cost.sStat is already set, then don't do anything
	if (rAction.sCostStat or "") ~= "" then
		return true;
	end

	-- if cost.sStat is not set, then set it to match rAction.sStat
	if rAction.sStat ~= "" then
		rAction.sCostStat = rAction.sStat;
		return true;
	end

	return false;
end

function resolveMaximumEffort(rActor, rAction, aFilter)
	if not ActorManager.isPC(rActor) then
		return true;
	end
	RollManager.addMaxEffortToAction(rActor, rAction, aFilter);
	rAction.nEffort = math.min(rAction.nEffort or 0, rAction.nMaxEffort or 0);
end

function resolveMaximumAssets(rActor, rAction, aFilter)
	if not ActorManager.isPC(rActor) then
		return true;
	end
	RollManager.addMaxAssetsToAction(rActor, rAction, aFilter);
	rAction.nAssets = math.min(rAction.nAssets, rAction.nMaxAssets);
end

function resolveEaseHindrance(rSource, rTarget, rRoll, aFilter)
	local nEase, nHinder = 0, 0;
	local nEaseModifier, nHinderModifier = 0, 0;
	if type(aFilter) == "string" then
		aFilter = { aFilter }
	end

	bEase, bHinder = RollManager.decodeEaseHindrance(rRoll, true);

	local nEaseEffects = EffectManagerCypher.getEffectsBonusByType(rSource, "EASE", aFilter, rTarget)
	local nHinderEffects = EffectManagerCypher.getEffectsBonusByType(rSource, "HINDER", aFilter, rTarget)

	if ModifierManager.getKey("EASE") then
		nEaseModifier = 1;
	end
	if ModifierManager.getKey("HINDER") then
		nHinderModifier = 1;
	end

	return nEase + nEaseEffects + nEaseModifier, nHinder + nHinderEffects + nHinderModifier;
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

function convertTrainingStringToNumber(sTraining)
	if sTraining == "trained" then
		return 2;
	elseif sTraining == "specialized" then
		return 3;
	elseif sTraining == "inability" then
		return 0;
	end
	return 1;
end

-----------------------------------------------------------------------
-- ROLL PROCESSING
-----------------------------------------------------------------------
function getBaseRollDifficulty(rSource, rTarget, aFilter)
	if not rTarget then
		-- Get global difficulty
		return DifficultyManager.getGlobalDifficulty();
	end

	-- if the target is an NPC, return that creature's level
	if not ActorManager.isPC(rTarget) then
		return ActorManagerCypher.getCreatureLevel(rTarget, rSource, aFilter);
	end

	-- target is a PC, so set difficulty to 0.
	return 0;
end

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

	return math.min(nAssetEffect, nMaxAssets - nAssets), nMaxAssets;
end

function processEffort(rSource, rTarget, aFilter, nEffort, nMaxEffort)
	local nEffortEffect = EffectManagerCypher.getEffectsBonusByType(rSource, "EFFORT", aFilter, rTarget)

	if not nMaxEffort then
		nMaxEffort = ActorManagerCypher.getMaxEffort(rSource, aFilter);
	end

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

function processStandardConditions(rSource, rTarget, sStat)
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
		(sStat == "intellect" and EffectManager.hasCondition(rTarget, "Confused")) then
		nLevelAdjust = nLevelAdjust - 1;
	end

	return nLevelAdjust;
end

function processStandardConditionsForActor(rActor)
	-- Dazed and Stunned don't stack with the other conditions
	if EffectManager.hasCondition(rSource, "Dazed") or 
	   EffectManager.hasCondition(rSource, "Stunned") or
	   (sStat == "might" and EffectManager.hasCondition(rSource, "Staggered")) or
	   (sStat == "speed" and (EffectManager.hasCondition(rSource, "Frostbitten") or EffectManager.hasCondition(rSource, "Slowed"))) or
	   (sStat == "intellect" and EffectManager.hasCondition(rSource, "Confused")) then
		return 1;
	end
	return 0;
end

function processPiercing(rSource, rTarget, bPiercing, nPierceAmount, aFilter)
	local nPierceEffectAmount, nPierceEffectCount = EffectManagerCypher.getEffectsBonusByType(rSource, { "pierce", "piercing" }, aFilter, rTarget);
	if nPierceEffectCount > 0 then
		-- if we have pierce effects, then bPiercing is set locked to true.
		bPiercing = true;

		-- If either the effect or innate pierce is equal to 0, 
		-- it means we have global piercing for all damage, and that has precedence
		if nPierceEffectAmount == 0 or nPierceAmount == 0 then
			nPierceAmount = 0;

		-- In this case there's no innate piercing, but there is an effect amount
		-- Assign piercing value. value of -1 means there's no piercing
		elseif nPierceAmount < 0 then
			nPierceAmount = nPierceEffectAmount

		-- Innate and effect piercing are both positive.
		-- We can safely add the two together
		else
			nPierceAmount = nPierceAmount + nPierceEffectAmount;
		end
	end

	return bPiercing, nPierceAmount;
end

-- Returns: bSuccess, bAutomaticSuccess
function processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons)
	local bSuccess = false;
	local bAutomaticSuccess = false;
	local nSuccess = 0;
	local bPvP = ActorManager.isPC(rSource) and ActorManager.isPC(rTarget);

	if #(rRoll.aDice) == 1 and rRoll.aDice[1].type == "d20" then		
		local nDifficulty = tonumber(rRoll.nDifficulty) or 0;
		
		-- Calculate the total number of successes in this roll
		-- We don't account for assets or effort here becuase assets were already used to adjust the 	
		-- difficulty in the modRoll function
		local nTotal = ActionsManager.total(rRoll);
		nSuccess = math.max(0, math.min(10, math.floor(nTotal / 3)));
		
		-- Only track success flags for non pvp rolls
		if not bPvP then
			nDifficulty = math.min(math.max(nDifficulty, 0), 10);
			table.insert(aAddIcons, "task" .. nDifficulty)

			if nDifficulty == 0 then
				bAutomaticSuccess = true;
			end
			if nSuccess >= nDifficulty then
				bSuccess = true;
			end
		end
	end

	return bSuccess, bAutomaticSuccess, nSuccess;
end

function calculateDifficultyForRoll(rSource, rTarget, rRoll)
	local nMod = 0;

	-- Start by modifying the difficulty based on the PC's properties
	if rRoll.sTraining == "trained" then
		nMod = nMod - 1;
	elseif rRoll.sTraining == "specialized" then
		nMod = nMod - 2;
	elseif rRoll.sTraining == "inability" then
		nMod = nMod + 1;
	end

	nMod = nMod - (tonumber(rRoll.nEffort or "0"));
	nMod = nMod - (tonumber(rRoll.nAssets or "0"));
	nMod = nMod - (tonumber(rRoll.nEase or "0"));
	nMod = nMod + (tonumber(rRoll.nHinder or "0"));
	nMod = nMod + (tonumber(rRoll.nConditionMod or "0"));

	if rRoll.bLightWeapon then
		nMod = nMod - 1;
	end

	-- Modify based on target's conditions
	nMod = nMod - RollManager.processStandardConditionsForActor(rTarget)

	rRoll.nDifficulty = rRoll.nDifficulty + nMod;
end

function processRollResult(rSource, rTarget, rRoll)
	local bSuccess = false;
	local bAutomaticSuccess = false;
	local nSuccess = 0;
	local bPvP = ActorManager.isPC(rSource) and ActorManager.isPC(rTarget);

	local nDifficulty = tonumber(rRoll.nDifficulty) or 0;
	
	-- Calculate the total number of successes in this roll
	-- We don't account for assets or effort here because assets were already
	-- used to adjust the difficulty in the calculateDifficultyForRoll function
	local nTotal = ActionsManager.total(rRoll);
	nSuccess = math.max(0, math.min(10, math.floor(nTotal / 3)));
	
	-- Only track success flags for non pvp rolls
	if not bPvP then
		nDifficulty = math.min(math.max(nDifficulty, 0), 10);

		if nDifficulty == 0 then
			bAutomaticSuccess = true;
		end

		if nSuccess >= nDifficulty then
			bSuccess = true;
		end
	end

	return nTotal, bSuccess, bAutomaticSuccess;
end

function updateRollMessageIcons(rMessage, aAddIcons, sFirstIcon)
	-- First, convert a singular icon to a table of icons
	if type(rMessage.icon) ~= "table" then
		rMessage.icon = { rMessage.icon };
	end

	-- if the first icon needs updating, then udpate it
	-- we guarantee that rMessage.icon is a table at this point
	if (sFirstIcon or "") ~= "" then
		rMessage.icon[1] = sFirstIcon
	end

	-- Add the rest of the icons
	for _,v in ipairs(aAddIcons) do
		table.insert(rMessage.icon, v);
	end
end

function updateMessageWithConvertedTotal(rRoll, rMessage)
	if rMessage.dice and rMessage.dice[1] and rMessage.dice[1].value then
		rMessage.dice[1].value = RollManager.getConvertedTotal(rRoll)
	end
end

function getConvertedTotal(rRoll)
	return ActionsManager.total(rRoll) + RollManager.convertDifficultyAdjustmentToFlatBonus(rRoll.nDifficulty or 0)
end

-- This function simply converts a flat difficulty adjustment to the equivalent flat bonus
-- e.g. minus 1 difficulty = +3 to the roll; plus 1 difficulty = -3 to the roll
function convertDifficultyAdjustmentToFlatBonus(nDifficulty)
	return (nDifficulty or 0) * -3;
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

	-- If there's no stat found with the STAT tag
	-- Then look for it in the parenthesis in the roll type tag
	if (sStat or "") == "" then
		sStat = string.match(rRoll.sDesc, "^%[.-%s%((%w+),?%s?.-%)%]");
	end

	-- If sStat is still not found, we finally check rRoll.sLabel
	if (sStat or "") == "" and (rRoll.sLabel or "") ~= "" then
		if  rRoll.sLabel:lower() == "might" or
			rRoll.sLabel:lower() == "speed" or 
			rRoll.sLabel:lower() == "intellect" then
			sStat = rRoll.sLabel:lower();
		end
	end

	rRoll.sDesc = sText;

	return (sStat or ""):lower();
end

function encodeDefenseStat(rAction, rRoll)
	if (rAction.sDefenseStat or "") ~= "" then
		local sNewLabel = string.format(
			"%s vs %s", 
			rAction.label, 
			StringManager.capitalize(rAction.sDefenseStat));
		rRoll.sDesc = rRoll.sDesc:gsub(rAction.label, sNewLabel);
	end
end
function decodeDefenseStat(rRoll, bPersist)
	local sStat, sText = RollManager.decodeText(
		rRoll.sDesc,
		nil, -- Not needed because we always persist this data
		"^%[[^]]-][^]]- vs ([^]]-)%[",
		true
	);
	rRoll.sDesc = sText;

	return StringManager.trim(sStat or "");
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

	if bInability then
		return "inability";
	elseif bTrained then
		return "trained";
	elseif bSpecialized then
		return "specialized";
	end

	return "";
end

function encodeEdge(rAction, vRoll)
	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

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
		return sDesc;
	end

	sDesc = RollManager.addOrOverwriteText(
		sDesc,
		sMatch,
		sText
	)

	if type(vRoll) == "table" then
		vRoll.sDesc = sDesc;
	end

	return sDesc;
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

function encodeEffort(vAction, vRoll)
	local nEffort = vAction;
	
	if type(vAction) == "table" then
		nEffort = vAction.nEffort
	end

	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

	if (nEffort or 0) > 0 then
		sDesc = RollManager.addOrOverwriteText(
			sDesc, 
			"%[APPLIED %d+ EFFORT%]", 
			string.format("[APPLIED %s EFFORT]", nEffort));

		if type(vRoll) == "table" then
			vRoll.sDesc = sDesc;
		end
	end

	return sDesc;
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

function encodeSkill(rAction, rRoll)	
	if (rAction.sSkill or "") ~= "" then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[SKILL: [^]]-%]",
			string.format("[SKILL: %s]", rAction.sSkill)
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
			string.format("[WTYPE: %s]", rAction.sWeaponType)
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

function decodeDamageType(rRoll)
	local sDamageType, sText = RollManager.decodeText(
		rRoll.sDesc,
		"^%[DAMAGE %(.-, .-%)]",
		"^%[DAMAGE %(.-, (.-)%)]",
		true
	);
	
	return sDamageType;
end

function encodePiercing(rAction, rRoll)
	if rAction.bPierce then
		-- Build the text that goes in the roll description
		local sPierce = "[PIERCE";
		if (rAction.nPierceAmount or 0) > 0 then
			sPierce = string.format("%s %s", sPierce, rAction.nPierceAmount);
		end
		sPierce = string.format("%s]", sPierce);

		-- Place the text in the roll description
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[PIERCE%s?%d-%]",
			sPierce
		);
	end
end

-- This decode breaks the standard model
-- because it can either have a number or not
function decodePiercing(vRoll, bPersist)
	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

	local sPiercing = sDesc:match("%[PIERCE%s?%d-%]");
	local bPiercing = sPiercing ~= nil;
	local nPierceAmount = tonumber(sDesc:match("%[PIERCE (%d+)%]")) or -1;

	-- Dumb hack. If we want to pierce all armor, then nPierceAmount needs to be 0
	-- But it needs to be -1 if bPiercing is false
	-- And it needs to be an actual number if we have a flat pierce amount
	if bPiercing and nPierceAmount == -1 then
		nPierceAmount = 0;
	end

	if not bPersist then
		sDesc = sDesc:gsub("%[PIERCE%s?%d-%]", "");

		if type(vRoll) == "table" then
			vRoll.sDesc = sDesc;
		end
	end

	return bPiercing, nPierceAmount
end

function encodeAmbientDamage(rAction, rRoll)
	if rAction.bAmbient == true then
		-- Place the text in the roll description
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[AMBIENT%]",
			"[AMBIENT]"
		);
	end
end

function decodeAmbientDamage(vRoll, bPersist)
	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

	return RollManager.decodeTextAsBoolean(
		sDesc,
		"%[AMBIENT%]",
		nil,
		bPersist
	);
end

function encodeTarget(vTarget, rRoll)
	if not vTarget then
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
		rRoll.sDesc = RollManager.addOrOverwriteText(
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
	if not rTarget or not ActorManager.getCTNode(rTarget) then
		rTarget = ActorManager.resolveActor(sTarget);
	end

	return rTarget;
end

function encodeEaseHindrance(rRoll, nEase, nHinder)
	if nEase > 0 then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[EASE%s%d+%]",
			string.format("[EASE %s]", nEase)
		);
	end
	if nHinder > 0 then
		rRoll.sDesc = RollManager.addOrOverwriteText(
			rRoll.sDesc,
			"%[HINDER%s%d+%]",
			string.format("[HINDER %s]", nHinder)
		);
	end
end
function decodeEaseHindrance(rRoll, bPersist)
	local nEase = RollManager.decodeTextAsNumber(
		rRoll.sDesc,
		"%[EASE%s?%d+%]",
		"%[EASE%s?(%d+)%]",
		bPersist
	);
	local nHinder = RollManager.decodeTextAsNumber(
		rRoll.sDesc,
		"%[HINDER%s?%d+%]",
		"%[HINDER%s?%(d+)%]",
		bPersist
	);

	return nEase, nHinder
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
function decodeConditionMod(rRoll, bPersist)
	local nResult, sText = RollManager.decodeTextAsNumber(
		rRoll.sDesc,
		"%[EFFECTS%s-[+-]?%d+%]",
		"%[EFFECTS%s-+?([-]?d-)%]",
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