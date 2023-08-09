function onInit()
	EffectManager.registerEffectVar("sUnits", { sDBType = "string", sDBField = "unit", bSkipAdd = true });
	EffectManager.registerEffectVar("sApply", { sDBType = "string", sDBField = "apply", sDisplay = "[%s]" });
	EffectManager.registerEffectVar("sTargeting", { sDBType = "string", bClearOnUntargetedDrop = true });

	EffectManager.setCustomOnEffectAddStart(onEffectAddStart);
	
	EffectManager.setCustomOnEffectRollEncode(onEffectRollEncode);
	EffectManager.setCustomOnEffectTextEncode(onEffectTextEncode);
	EffectManager.setCustomOnEffectTextDecode(onEffectTextDecode);

	EffectManager.setCustomOnEffectActorStartTurn(onEffectActorStartTurn);
end

---------------------------------
-- EFFECT MANAGER OVERRIDES
---------------------------------
function onEffectAddStart(rEffect)
	rEffect.nDuration = rEffect.nDuration or 1;
	if rEffect.sUnits == "minute" then
		rEffect.nDuration = rEffect.nDuration * 10;
	elseif rEffect.sUnits == "hour" or rEffect.sUnits == "day" then
		rEffect.nDuration = 0;
	end
	rEffect.sUnits = "";
end

function onEffectRollEncode(rRoll, rEffect)
	if rEffect.sTargeting and rEffect.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end
end

function onEffectTextEncode(rEffect)
	local aMessage = {};
	
	if rEffect.sUnits and rEffect.sUnits ~= "" then
		local sOutputUnits = nil;
		if rEffect.sUnits == "minute" then
			sOutputUnits = "MIN";
		elseif rEffect.sUnits == "hour" then
			sOutputUnits = "HR";
		elseif rEffect.sUnits == "day" then
			sOutputUnits = "DAY";
		end

		if sOutputUnits then
			table.insert(aMessage, "[UNITS " .. sOutputUnits .. "]");
		end
	end
	if rEffect.sTargeting and rEffect.sTargeting ~= "" then
		table.insert(aMessage, string.format("[%s]", rEffect.sTargeting:upper()));
	end
	if rEffect.sApply and rEffect.sApply ~= "" then
		table.insert(aMessage, string.format("[%s]", rEffect.sApply:upper()));
	end
	
	return table.concat(aMessage, " ");
end

function onEffectTextDecode(sEffect, rEffect)
	local s = sEffect;
	
	local sUnits = s:match("%[UNITS ([^]]+)]");
	if sUnits then
		s = s:gsub("%[UNITS ([^]]+)]", "");
		if sUnits == "MIN" then
			rEffect.sUnits = "minute";
		elseif sUnits == "HR" then
			rEffect.sUnits = "hour";
		elseif sUnits == "DAY" then
			rEffect.sUnits = "day";
		end
	end
	if s:match("%[SELF%]") then
		s = s:gsub("%[SELF%]", "");
		rEffect.sTargeting = "self";
	end
	if s:match("%[ACTION%]") then
		s = s:gsub("%[ACTION%]", "");
		rEffect.sApply = "action";
	elseif s:match("%[ROLL%]") then
		s = s:gsub("%[ROLL%]", "");
		rEffect.sApply = "roll";
	elseif s:match("%[SINGLE%]") then
		s = s:gsub("%[SINGLE%]", "");
		rEffect.sApply = "single";
	end
	
	return s;
end

function onEffectActorStartTurn(nodeActor, nodeEffect)
	local sEffName = DB.getValue(nodeEffect, "label", "");
	local aEffectComps = EffectManager.parseEffect(sEffName);

	for _,sEffectComp in ipairs(aEffectComps) do
		local rEffectComp = EffectManagerCypher.parseEffectComp(sEffectComp);
		-- Conditionals
		if rEffectComp.type == "ift" then
			break;
		elseif rEffectComp.type == "if" then
			local rActor = ActorManager.resolveActor(nodeActor);
			if not checkConditional(rActor, nodeEffect, rEffectComp) then
				break;
			end
		
		-- Ongoing damage and regeneration
		elseif rEffectComp.type == "dmgo" or rEffectComp.type == "regen" then
			local nActive = DB.getValue(nodeEffect, "isactive", 0);
			-- If the effect is skipped, then we un-skip it. 
			-- If it's skipped
			if nActive == 2 then
				EffectManagerCypher.activateSkippedEffect(nodeEffect);
			else
				EffectManagerCypher.applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp);
			end
		end
	end
end

function applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp)
	if #(rEffectComp.dice) == 0 and rEffectComp.mod == 0 then
		return;
	end
	
	local rTarget = ActorManager.resolveActor(nodeActor);
	local rActor = ActorManager.resolveActor(nodeActor);
	if rEffectComp.type == "regen" then
		local nPercentWounded = ActorHealthManager.getWoundPercent(rActor);
		
		-- If not wounded, then return
		if nPercentWounded <= 0 then
			return;
		end
		-- Regeneration does not work once creature falls below 1 hit point
		if nPercentWounded >= 1 then
			return;
		end
		
		local rAction = {};
		rAction.label = "Regeneration";
		rAction.aDice = rEffectComp.dice;
		rAction.nHeal = rEffectComp.mod;
		rAction.bSecret = EffectManager.isGMEffect(nodeActor, nodeEffect);

		if #(rEffectComp.filters) == 0 then
			rAction.sHealStat = "might" -- Default to healing might
		elseif #(rEffectComp.filters) == 1 then
			rAction.sHealStat = rEffectComp.filters[1]
		else
			return; -- Multiple regen stats are illegal. Bail
		end

		local rRoll = ActionHeal.getRoll(nil, rAction);
		if EffectManager.isGMEffect(nodeActor, nodeEffect) then
			rRoll.bSecret = true;
		end

		ActionsManager.actionDirect(nil, "heal", { rRoll }, { { rTarget } });

	elseif rEffectComp.type == "dmgo" then
		local rAction = {};
		rAction.label = "Ongoing damage";
		rAction.aDice = rEffectComp.dice;
		rAction.nDamage = rEffectComp.mod;
		rAction.bOngoing = true;

		for _, sFilter in ipairs(rEffectComp.filters) do
			if sFilter == "might" or sFilter == "speed" or sFilter == "might" then
				if rAction.sDamageStat ~= nil then
					return; -- Multiple damage stats are illegal. Bail
				end
				rAction.sDamageStat = sFilter;
			else
				if rAction.sDamageType ~= nil then
					return; -- Multiple damage types are illegal. Bail
				end
				rAction.sDamageType = sFilter;
			end
		end

		if not rAction.sDamageStat then
			rAction.sDamageStat = "might";
		end
		
		local rRoll = ActionDamage.getRoll(nil, rAction);
		if EffectManager.isGMEffect(nodeActor, nodeEffect) then
			rRoll.bSecret = true;
		end
		ActionsManager.actionDirect(nil, "damage", { rRoll }, { { rTarget } });
	end
end

-------------------------------------------------------------------------------
-- EFFECT ACCESSORS
-------------------------------------------------------------------------------
function getPiercingEffectBonus(rActor, sDamageType, sStat, rTarget)
	return EffectManagerCypher.getEffectsBonusForDamageType(rActor, { "PIERCE", "PIERCING" }, sStat, sDamageType, rTarget);
end

function getLevelEffectBonus(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsBonusByType(rActor, "LEVEL", aFilter, true, nil, true, rTarget);
end

function getEdgeEffectBonus(rActor, aFilter)
	return EffectManagerCypher.getEffectsBonusByType(rActor, "EDGE", aFilter, true);
end

function getEffortEffectBonus(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsBonusByType(rActor, "EFFORT", aFilter, true, nil, true, rTarget)
end

function getMaxEffortEffectBonus(rActor, aFilter)
	return EffectManagerCypher.getEffectsBonusByType(rActor, { "MAXEFF", "MAXEFFORT" }, aFilter, true);
end

function getAssetEffectBonus(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsBonusByType(rActor, "ASSET", aFilter, true, nil, true, rTarget)
end

function getMaxAssetsEffectBonus(rActor, aFilter)
	return EffectManagerCypher.getEffectsBonusByType(rActor, "MAXASSETS", aFilter, true);
end

function getRecoveryEffectBonus(rActor, aFilter)
	return EffectManagerCypher.getEffectsBonusByType(rActor, { "RECOVERY", "REC" }, aFilter, true);
end

function getHealEffectBonus(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsBonusByType(rActor, "HEAL", aFilter, true, nil, true, rTarget)
end

function getDamageEffectBonus(rActor, sDamageType, sStat, rTarget)
	return EffectManagerCypher.getEffectsBonusForDamageType(rActor, { "DAMAGE", "DMG" }, sStat, sDamageType, rTarget);
end

function getCostEffectBonus(rActor, rFilter)
	return EffectManagerCypher.getEffectsBonusByType(rActor, "COST", rFilter, true);
end

function getEaseEffectBonus(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsBonusByType(rActor, "EASE", aFilter, true, nil, true, rTarget);
end

function getHinderEffectBonus(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsBonusByType(rActor, "HINDER", aFilter, true, nil, true, rTarget);
end

function getArmorEffectBonus(rActor, sStat, sDamageType, rTarget)
	return EffectManagerCypher.getEffectsBonusForDamageType(rActor, "ARMOR", sStat, sDamageType, rTarget);
end

function getSuperArmorEffectBonus(rActor, sStat, sDamageType, rTarget)
	return EffectManagerCypher.getEffectsBonusForDamageType(rActor, "SUPERARMOR", sStat, sDamageType, rTarget);
end

function getVulnerabilityEffectBonus(rActor, sDamageType, sStat, rTarget)
	return EffectManagerCypher.getEffectsBonusForDamageType(rActor, "VULN", sStat, sDamageType, rTarget);
end

function getAdvantageEffects(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsByType(rActor, "ADV", aFilter, true, nil, false, rTarget)
end

function getDisadvantageEffects(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsByType(rActor, "DISADV", aFilter, true, nil, false, rTarget)
end

function getGrantAdvantageEffects(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsByType(rActor, "GRANTADV", aFilter, true, nil, false, rTarget)
end

function getGrantDisadvantageEffects(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsByType(rActor, "GRANTDISADV", aFilter, true, nil, false, rTarget)
end

function getTrainedEffects(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsByType(rActor, "TRAIN", aFilter, true, nil, true, rTarget);
end

function getSpecializedEffects(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsByType(rActor, "SPEC", aFilter, true, nil, true, rTarget);
end

function getInabilityEffects(rActor, aFilter, rTarget)
	return EffectManagerCypher.getEffectsByType(rActor, "INABILITY", aFilter, true, nil, true, rTarget);
end

function getConversionEffect(rActor, aFilter, aContent)
	if not rActor or not aContent then
		return {};
	end

	local aEffects = EffectManagerCypher.getEffectsByType(rActor, "CONVERT", aFilter, true, aContent, false);
	local aConversion = {};

	for _, rEffect in ipairs(aEffects) do
		for _, sContent in ipairs(rEffect.content) do
			-- Only add to the final conversion table if the bit of content is not originally
			-- in the matched list. This ensure that any content that's not filtered against
			-- is added here.
			if not StringManager.contains(aContent, sContent) then
				table.insert(aConversion, sContent);
			end
		end
	end

	return aConversion;
end

function getImmunityEffects(rActor, rTarget)
	return EffectManagerCypher.getEffectsByType(rActor, "IMMUNE", {}, false, nil, false, rTarget, false);
end

function getShieldEffects(rActor, aFilter)
	return EffectManagerCypher.getEffectsByType(rActor, "SHIELD", aFilter, false, nil, false, rTarget, false);
end

-------------------------------------------------------------------------------
-- EFFECT PROCESSORS
-------------------------------------------------------------------------------
function getEffectsBonusForDamageType(rActor, sEffectType, sStat, sDamageType, rFilterActor)
	if not rActor then
		return 0, 0;
	end

	local aFilter = {};
	if sStat then
		table.insert(aFilter, sStat);
	end
	if sDamageType then
		table.insert(aFilter, sDamageType);
	end

	return EffectManagerCypher.getEffectsBonusByType(rActor, sEffectType, aFilter, false, nil, false, rFilterActor, false);
end

function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bCheckEffectTargets)
	if not rActor or ((sEffect or "") == "") then
		return false;
	end
	local sLowerEffect = sEffect:lower();
	
	local aMatch = {};
	for _,v in pairs(ActorManager.getEffects(rActor)) do
		local nActive = DB.getValue(v, "isactive", 0);

		if nActive ~= 0 then
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = false;
			if bCheckEffectTargets then
				bTargeted = EffectManager.isTargetedEffect(v);
			end
			local tEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, sEffectComp in ipairs(tEffectComps) do
				local rEffectComp = EffectManagerCypher.parseEffectComp(sEffectComp);

				if rEffectComp.type == "if" then
					if not EffectManagerCypher.checkConditional(rActor, v, rEffectComp) then
						break;
					end

				elseif rEffectComp.type == "ift" then
					if not rTarget then
						break;
					end
					if not EffectManagerCypher.checkConditional(rTarget, v, rEffectComp, rActor) then
						break;
					end
			
				elseif rEffectComp.original:lower() == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif not bTargetedOnly then
						nMatch = kEffectComp;
					end
				end
			end

			-- If matched, then remove one-off effects
			if nMatch > 0 then
				EffectManagerCypher.addMatchedEffect(v, aMatch);
				EffectManagerCypher.clearTemporaryEffect(v, nMatch);
				EffectManagerCypher.activateSkippedEffect(v);
			end
		end
	end
	
	return #aMatch > 0;
end

function getEffectsBonusByType(rActor, aEffectType, aFilter, bExclusiveFilters, aContent, bExclusiveContent, rFilterActor, bTargetedOnly)
	if not rActor or not aEffectType then
		return 0, 0;
	end
	
	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aEffectType) ~= "table" then
		aEffectType = { aEffectType };
	end
	if type(aContent) ~= "table" and type(aFilter) == "string" then
		aFilter = { aFilter:lower() };
	end
	if type(aContent) ~= "table" and type(aContent) == "string" then
		aContent = { aContent:lower() };
	end
	
	-- PER EFFECT TYPE VARIABLES
	local results = {};
	local nEffectCount = 0;

	for k, v in pairs(aEffectType) do
		-- LOOK FOR EFFECTS THAT MATCH BONUSTYPE
		local aEffectsByType = EffectManagerCypher.getEffectsByType(rActor, v, aFilter, bExclusiveFilters, aContent, bExclusiveContent, rFilterActor, bTargetedOnly);

		-- ITERATE THROUGH EFFECTS THAT MATCHED
		for k2,v2 in pairs(aEffectsByType) do
			-- {type = STAT, remainder = {}, original = STATS: +1, dice = {}, mod = 1}

			-- Add matched effect to results table
			table.insert(results, v2)

			-- ADD TO EFFECT COUNT
			nEffectCount = nEffectCount + 1;
		end
	end

	local nBonus = 0;
	for k,v in pairs(results) do
		nBonus = nBonus + v.mod;
	end

	return nBonus, nEffectCount;
end

function getEffectsByType(rActor, sEffectType, aFilter, bExclusiveFilters, aContent, bExclusiveContent, rFilterActor, bTargetedOnly)
	if not rActor or not sEffectType then
		return {};
	end

	sEffectType = sEffectType:lower();

	if not aFilter then
		aFilter = {}
	end
	if type(aFilter) ~= "table" and type(aFilter) == "string" then
		aFilter = { aFilter:lower() };
	end

	if not aContent then
		aContent = {};
	end
	if type(aContent) ~= "table" and type(aContent) == "string" then
		aContent = { aContent:lower() };
	end

	local results = {};
	local resultdata = {}; -- Keeps track of the effect node and component index of entries in the results table
	aFilter = toLower(aFilter);
	aContent = toLower(aContent);
	
	-- Iterate through effects
	for _,v in pairs(DB.getChildList(ActorManager.getCTNode(rActor), "effects")) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 and EffectManagerCypher.checkTargeting(v, rFilterActor) then
			local sLabel = DB.getValue(v, "label", "");
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Look for type/subtype match
			local nMatch = 0;
			for kEffectComp, sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManagerCypher.parseEffectComp(sEffectComp); 

				if rEffectComp.type == "if" then
					if not EffectManagerCypher.checkConditional(rActor, v, rEffectComp) then
						break;
					end

				elseif rEffectComp.type == "ift" then
					if not rFilterActor then
						break;
					end
					if not EffectManagerCypher.checkConditional(rFilterActor, v, rEffectComp, rActor) then
						break;
					end
			
				elseif EffectManagerCypher.checkEffectCompType(rEffectComp, sEffectType) and
					EffectManagerCypher.checkFilters(rEffectComp, aFilter, bExclusiveFilters) and 
					EffectManagerCypher.checkContent(rEffectComp, aContent, bExclusiveContent) and 
					EffectManagerCypher.checkDamageType(rEffectComp, sEffectType, aFilter) then

						-- At this point we're guaranteed to have an active effect that matches targeting, type, and filters/content
						nMatch = kEffectComp;

						-- If this effect isn't active, then break.
						-- This moves it directly to the function to activate
						-- skipped effects
						if EffectManagerCypher.checkActive(v) then
							table.insert(results, rEffectComp);
							table.insert(resultdata, { node = v, index = kEffectComp });
						end
				end
			end -- END EFFECT COMPONENT LOOP

			-- Remove one shot effects
			if nMatch > 0 then
				EffectManagerCypher.clearTemporaryEffect(v, nMatch);
				EffectManagerCypher.activateSkippedEffect(v);
			end
		end -- END ACTIVE AND TARGETING CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results, resultdata;
end

-------------------------------------------------------------------------------
-- INTERNAL EFFECT PROCESSING HELPERS
-------------------------------------------------------------------------------

function checkConditional(rActor, nodeEffect, rEffectComp, rTarget, aIgnore)
	local bReturn = true;
	
	if not aIgnore then
		aIgnore = {};
	end
	table.insert(aIgnore, DB.getPath(nodeEffect));
	
	for _,v in ipairs(rEffectComp.conditionals) do
		if v.sConditional == "hale" then
			if  (v.bInvert and ActorManagerCypher.isHale(rActor)) or 
				(not v.bInvert and not ActorManagerCypher.isHale(rActor)) then
				bReturn = false;
				break;
			end
		elseif v.sConditional == "impaired" then
			if  (v.bInvert and ActorManagerCypher.isImpaired(rActor)) or 
				(not v.bInvert and not ActorManagerCypher.isImpaired(rActor)) then
				bReturn = false;
				break;
			end
		elseif v.sConditional == "debilitated" then
			if  (v.bInvert and ActorManagerCypher.isDebilitated(rActor)) or 
				(not v.bInvert and not ActorManagerCypher.isDebilitated(rActor)) then
				bReturn = false;
				break;
			end
		elseif v.sConditional == "wounded" then
			if  (v.bInvert and ActorManagerCypher.isWounded(rActor)) or 
				(not v.bInvert and not ActorManagerCypher.isWounded(rActor)) then
				bReturn = false;
				break;
			end
		elseif v.sConditional == "level" then
			-- LEVEL condition cannot be on PCs, so always fail
			if ActorManager.isPC(rActor) then
				bReturn = false;
				break;
			end

			local nLevel = ActorManagerCypher.getCreatureLevel(rActor);
			if  (v.bInvert and EffectManagerCypher.checkConditionValues(v, nLevel)) or 
				(not v.bInvert and not EffectManagerCypher.checkConditionValues(v, nLevel)) then
				bReturn = false;
				break;
			end
		elseif v.sConditional == "might" or v.sConditional == "speed" or v.sConditional == "intellect" then
			-- MIGHT condition cannot be on NPCs, so always fail
			if not ActorManager.isPC(rActor) then
				bReturn = false;
				break;
			end

			local nCur, nMax = ActorManagerCypher.getStatPool(rActor, v.sConditional);
			if v.bMax then
				v.nOperand = nMax
			end
			if  (v.bInvert and EffectManagerCypher.checkConditionValues(v, nCur)) or 
				(not v.bInvert and not EffectManagerCypher.checkConditionValues(v, nCur)) then
				bReturn = false;
				break;
			end
		end
	end
	
	table.remove(aIgnore);
	
	return bReturn;
end

function checkConditionValues(rConditional, nComparison)
	-- If there's no operation specified (i.e. SPEED(5)) then
	-- we treat it as an equals operation
	if (rConditional.sOperation or "") == "" then
		return nComparison == rConditional.nOperand;
	end

	if rConditional.sOperation == "<" then
		return nComparison < rConditional.nOperand;
	elseif rConditional.sOperation == ">" then
		return nComparison > rConditional.nOperand;
	elseif rConditional.sOperation == "<=" then
		return nComparison <= rConditional.nOperand;
	elseif rConditional.sOperation == ">=" then
		return nComparison >= rConditional.nOperand;
	elseif rConditional.sOperation == "=" then
		return nComparison == rConditional.nOperand;
	end

	return false;
end

function checkDamageType(rEffectComp, sEffectType, aFilter)
	if not (sEffectType == "armor" or sEffectType == "immune" or sEffectType == "vuln" or sEffectType == "shield") then
		return true;
	end

	-- if we matched "any" or "all" filters, return match
	if 	StringManager.contains(rEffectComp.filters, "all") or
		StringManager.contains(rEffectComp.filters, "any") then 
		return true;
	end

	local bUntyped = StringManager.contains(aFilter, "untyped");
	local aStatFilters = {};
	local aDmgTypeFilters = {};
	for _,tag in pairs(rEffectComp.filters) do
		if tag == "might" or tag == "speed" or tag == "intellect" then
			table.insert(aStatFilters, tag);
		else
			table.insert(aDmgTypeFilters, tag);
		end
	end
	if #aDmgTypeFilters == 0 then
		table.insert(aDmgTypeFilters, "untyped");
	end

	local bContainsStat = false;
	local bContainsDmgType = false;
	for _, sFilter in ipairs(aFilter) do
		if StringManager.contains(aStatFilters, sFilter) then
			bContainsStat = true;
		end
		if StringManager.contains(aDmgTypeFilters, sFilter) then
			bContainsDmgType = true;
		end
	end

	-- If stats are present in the effect filter, then we need to match at least one of those
	-- if dmg types are present in the effect filter, then we need to match at least one of those
	-- If there are 0 of either, then we ignore that requirement
	-- This way we can have stat filters and dmg type filters act as an AND filter when mixed together
	-- but treated as an OR filter when looked at separately
	return 	(#aStatFilters == 0 or (#aStatFilters > 0 and bContainsStat)) and
			(#aDmgTypeFilters > 0 and bContainsDmgType)
end

function checkEffectCompType(rEffectComp, sEffectType)
	return rEffectComp.type == sEffectType:lower() or rEffectComp.original == sEffectType:lower();
end

function checkTargeting(effectNode, rFilterActor)
	-- If the effect doesn't target, then we're good to go
	if not EffectManager.isTargetedEffect(effectNode) then
		return true;
	end

	return EffectManager.isEffectTarget(effectNode, rFilterActor);
end

function checkActive(effectNode)
	return DB.getValue(effectNode, "isactive", 0) == 1;
end

-- rEffectCompList can be either effectComp.filters or effectComp.content
-- bExclusive: if true, all filters much match to pass this check. if false, at least one of the filters must match.
-- Effectively bExclusive controls whether the filters are checked using AND (if true) or OR (if false)
function checkEffectFilterOrContent(rEffectCompList, aFilters, bExclusive)
	-- No remainder matches with anything
	if #(rEffectCompList) == 0 then
		return true;
	end

	-- if there are no filters to check against, any filter will match, so return true
	if #(aFilters) == 0 then
		return true;
	end
	
	local bMatchedAny = false;
	local bMatchedAll = true;
	-- Match against all effect tags, or don't match at all
	for _,tag in pairs(rEffectCompList) do
		if tag == "all" or tag == "any" then
			return true;
		end
		
		local bContains = StringManager.contains(aFilters, tag)
		if bContains then
			bMatchedAny = true;
		else
			bMatchedAll = false;
		end
	end

	if bExclusive then
		return bMatchedAll;
	end
	return bMatchedAny;
end

function checkFilters(rEffectComp, aFilters, bExclusive)
	return EffectManagerCypher.checkEffectFilterOrContent(rEffectComp.filters, aFilters, bExclusive);
end

function checkContent(rEffectComp, aFilters, bExclusive)
	return EffectManagerCypher.checkEffectFilterOrContent(rEffectComp.content, aFilters, bExclusive);
end

function clearTemporaryEffect(effectNode, nEffectComp)
	--  Effect component is 0 if there's no effect found matching criteria, so we don't do anything
	if nEffectComp == 0 then
		return;
	end

	-- 0 = inactive
	-- 1 = active
	-- 2 = skip once
	-- We only want to process active effects, so we bail if its anything else
	local nActive = DB.getValue(effectNode, "isactive", 0);
	if nActive ~= 1 then
		return;
	end

	local sApply = DB.getValue(effectNode, "apply", "");
	if sApply == "action" then
		EffectManager.notifyExpire(effectNode, 0);
	elseif sApply == "roll" then
		EffectManager.notifyExpire(effectNode, 0, true);
	elseif sApply == "single" then
		EffectManager.notifyExpire(effectNode, nEffectComp, true);
	end
end

function activateSkippedEffect(effectNode)
	local nActive = DB.getValue(effectNode, "isactive", 0);
	if nActive == 2 then
		DB.setValue(effectNode, "isactive", "number", 1);
	end
end

function addMatchedEffect(effectNode, aEffects)
	local nActive = DB.getValue(v, "isactive", 0);
	if nActive == 1 then
		table.insert(aEffects, effectNode);
	end
end

function parseEffectComp(s)
	local sType = s:match("([^:]+)[:?]?"); -- This will match everything before either a colon or the end of the string
	local aDice = {};
	local nMod = 0;
	local aContent = {}; -- Data in parenthesis before the colon, separated by a comma. i.e. IF (CONTENT): ...
	local aFilters = {}; -- Data after the colon separated by a comma that contains no parenthesis. i.e. ASSET: might, speed
	local aConditionals = {}; -- Condition data for IF and IFT

	if sType then
		local sContent = sType:match("%(([^%)]+)%)");
		sType = sType:match("([^%(%)%s:]+)")
		sType = StringManager.trim(sType:lower());

		-- Check for content (data in parenthesis)
		if sContent then
			aContent = StringManager.split(sContent, ",", true);
		end
	end

	local sData = s:match(":(.-)$"); -- Matches to everything to the right of the colon
	if sData then
		if sType == "if" or sType == "ift" then
			aConditionals = EffectManagerCypher.parseEffectConditional(sData)
		else
			local nFilterIndex = 1;
			local aWords = StringManager.parseWords(sData, "/\\%.%[%]%(%):{}");

			if #aWords > 0 then
				-- Check the very first bit of text to see if it's a text string
				if StringManager.isDiceString(aWords[1]) then
					aDice, nMod = StringManager.convertStringToDice(aWords[1]);
					nFilterIndex = 2;
				end
			end
	
			while nFilterIndex <= #aWords do
				local sWord = aWords[nFilterIndex]
				if sWord then
					sWord = StringManager.trim(sWord:lower());
					table.insert(aFilters, sWord);
				end
				nFilterIndex = nFilterIndex + 1;
			end
		end
	end

	return {
		type = sType,
		mod = nMod,
		dice = aDice,
		content = toLower(aContent),
		filters = toLower(aFilters),
		conditionals = aConditionals,
		original = StringManager.trim(s):lower();
	}
end

function parseEffectConditional(sData)
	local aConditionals = {};
	local aConditions = StringManager.split(sData, ',');

	for _, sCondition in ipairs(aConditions) do
		sCondition = sCondition:lower();
		local bInvert = sCondition:match("not%s") ~= nil;
		if bInvert then
			sCondition = string.gsub(sCondition, "not%s", "");
		end
		local sConditional = sCondition:match("n?o?t?%s?([^%s(]+)")
		local rCondition = {
			sConditional = sConditional:lower();
			bInvert = bInvert
		}

		local sOpData = sCondition:match("%(([^%)]+)%)")
		if sOpData then
			local sOperation = sOpData:match("[><=]+");
			local sValue = sOpData:match("%d+")
			local bMax = sOpData:match("max") ~= nil

			rCondition.sOperation = (sOperation or ""):lower();
			rCondition.nOperand = tonumber(sValue or "0");
			rCondition.bMax = bMax;
		end

		table.insert(aConditionals, rCondition);
	end

	return aConditionals;
end

function toLower(aList)
	local temp = {};
	for k,v in ipairs(aList or {}) do
		if type(v) == "string" then
			v = v:lower();
		end
		temp[k] = v;
	end
	return temp;
end