function onInit()
	EffectManager.registerEffectVar("sUnits", { sDBType = "string", sDBField = "unit", bSkipAdd = true });
	EffectManager.registerEffectVar("sApply", { sDBType = "string", sDBField = "apply", sDisplay = "[%s]" });
	EffectManager.registerEffectVar("sTargeting", { sDBType = "string", bClearOnUntargetedDrop = true });

	EffectManager.setCustomOnEffectAddStart(onEffectAddStart);
	
	EffectManager.setCustomOnEffectRollEncode(onEffectRollEncode);
	EffectManager.setCustomOnEffectTextEncode(onEffectTextEncode);
	EffectManager.setCustomOnEffectTextDecode(onEffectTextDecode);
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

---------------------------------
-- EFFECT GETTERS
---------------------------------
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
				local rEffectComp = EffectManager.parseEffectCompSimple(sEffectComp);

				if rEffectComp.original:lower() == sLowerEffect then
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
				-- Switch "Skip" effect to active
				if nActive == 2 then
					DB.setValue(v, "isactive", "number", 1);

				else
					-- Remove one-off effects
					table.insert(aMatch, v);
					local sApply = DB.getValue(v, "apply", "");
					if sApply == "action" then
						EffectManager.notifyExpire(v, 0);
					elseif sApply == "roll" then
						EffectManager.notifyExpire(v, 0, true);
					elseif sApply == "single" then
						EffectManager.notifyExpire(v, nMatch, true);
					end
				end
			end
		end
	end
	
	if #aMatch > 0 then
		return true;
	end
	return false;
end

function getEffectsBonusByType(rActor, aEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor or not aEffectType then
		return 0, 0;
	end
	
	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aEffectType) ~= "table" then
		aEffectType = { aEffectType };
	end
	if type(aFilter) ~= "table" and type(aFilter) == "string" then
		aFilter = { aFilter:lower() };
	end
	
	-- PER EFFECT TYPE VARIABLES
	local results = {};
	local bonuses = {};
	local penalties = {};
	local nEffectCount = 0;

	for k, v in pairs(aEffectType) do
		-- LOOK FOR EFFECTS THAT MATCH BONUSTYPE
		local aEffectsByType = getEffectsByType(rActor, v, aFilter, rFilterActor, bTargetedOnly);

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

function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	local results = {};
	aFilter = toLower(aFilter);
	
	-- Iterate through effects
	for _,v in pairs(DB.getChildList(ActorManager.getCTNode(rActor), "effects")) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);
		if (nActive ~= 0) then
			local sLabel = DB.getValue(v, "label", "");
			local sApply = DB.getValue(v, "apply", "");

			-- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
			local bTargeted = EffectManager.isTargetedEffect(v);
			if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
				local aEffectComps = EffectManager.parseEffect(sLabel);

				-- Look for type/subtype match
				local nMatch = 0;
				for kEffectComp,sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = EffectManager.parseEffectCompSimple(sEffectComp);
										
					-- Check for match
					local comp_match = false;
					if rEffectComp.type:lower() == sEffectType:lower() or 
					   rEffectComp.original:lower() == sEffectType:lower() then

						-- Check effect targeting
						if bTargetedOnly and not bTargeted then
							comp_match = false;
						else
							comp_match = true;
						end

						-- Check filters
						if #aFilter > 0 then
							local bMatch = true;
							-- No remainder matches with anything
							-- So we skip this check
							if #(rEffectComp.remainder) > 0 then
								-- Match against all effect tags, or don't match at all
								for _,tag in pairs(rEffectComp.remainder) do
									if tag:lower() == "all" then
										bMatch = true;
										break;
									end
									
									if not StringManager.contains(aFilter, tag:lower()) then
										bMatch = false;
										break;
									end
								end
							else
								-- No remainders found in the effect, which means
								-- we should match against anything
								bMatch = true;
							end
							if not bMatch then
								comp_match = false;
							end
						end
					end

					-- Match!
					if comp_match then
						nMatch = kEffectComp;
						if nActive == 1 then
							table.insert(results, rEffectComp);
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- Remove one shot effects
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						if sApply == "action" then
							EffectManager.notifyExpire(v, 0);
						elseif sApply == "roll" then
							EffectManager.notifyExpire(v, 0, true);
						elseif sApply == "single" then
							EffectManager.notifyExpire(v, nMatch, true);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results;
end

function getArmorEffectBonusForDamageType(rActor, sEffectType, sStat, sDamageType, rFilterActor, bTargetedOnly)
	if not rActor then
		return 0, 0;
	end
	
	-- PER EFFECT TYPE VARIABLES
	local results = {};
	local nEffectCount = 0;

	local aArmorEffects = getArmorEffectsForDamageType(rActor, sEffectType, sStat, sDamageType, rFilterActor, bTargetedOnly);

	-- ITERATE THROUGH EFFECTS THAT MATCHED
	for k,v in pairs(aArmorEffects) do
		-- {type = STAT, remainder = {}, original = STATS: +1, dice = {}, mod = 1}

		-- Add matched effect to results table
		table.insert(results, v)

		-- ADD TO EFFECT COUNT
		nEffectCount = nEffectCount + 1;
	end

	local nBonus = 0;
	for k,v in pairs(results) do
		nBonus = nBonus + v.mod;
	end

	return nBonus, nEffectCount;
end

function getArmorEffectsForDamageType(rActor, sEffectType, sStat, sDamageType, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	local results = {};
	sEffectType = sEffectType:lower();
	sStat = sStat:lower();
	sDamageType = sDamageType:lower();
	
	-- Iterate through effects
	for _,v in pairs(DB.getChildList(ActorManager.getCTNode(rActor), "effects")) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);

		if (nActive ~= 0) then
			local sLabel = DB.getValue(v, "label", "");
			local sApply = DB.getValue(v, "apply", "");

			-- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
			local bTargeted = EffectManager.isTargetedEffect(v);
			if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
				local aEffectComps = EffectManager.parseEffect(sLabel);

				-- Look for type/subtype match
				local nMatch = 0;
				for kEffectComp,sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = EffectManager.parseEffectCompSimple(sEffectComp);
										
					-- Check for match
					local comp_match = false;
					if rEffectComp.type:lower() == sEffectType then

						-- Check effect targeting
						if bTargetedOnly and not bTargeted then
							comp_match = false;
						else
							comp_match = true;
						end

						-- Match against all effect tags, or don't match at all
						local bMatch = true;

						-- If there's no remainders, but the damage type is set to some type
						-- then we do not match.
						if #(rEffectComp.remainder) == 0 and sDamageType ~= "untyped" then
							bMatch = false;
						end

						for _,tag in pairs(rEffectComp.remainder) do
							tag = tag:lower();

							if tag == "all" then
								bMatch = true;
								break;
							end

							--
							if DamageTypeManager.isDamageType(tag) then	
								-- If the effect has a damage type tag, but the damage being dealt is untyped
								-- then there isn't a match.
								if sDamageType == "untyped" then
									bMatch = false;

								-- Otherwise if the tag doesn't match the given damage type, then this effect doesn't match.
								elseif tag ~= sDamageType then
									bMatch = false;
								end
							else
								-- tag isn't a damage type, so it must be a stat
								if tag ~= sStat then
									bMatch = false;
								end
							end
						end

						if not bMatch then
							comp_match = false;
						end
					end

					-- Match!
					if comp_match then
						nMatch = kEffectComp;
						if nActive == 1 then
							table.insert(results, rEffectComp);
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- Remove one shot effects
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						if sApply == "action" then
							EffectManager.notifyExpire(v, 0);
						elseif sApply == "roll" then
							EffectManager.notifyExpire(v, 0, true);
						elseif sApply == "single" then
							EffectManager.notifyExpire(v, nMatch, true);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results;
end

function getConversionEffect(rActor, aTypes, aFilter)
	if not rActor or not aTypes then
		return false;
	end

	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aTypes) ~= "table" then
		aTypes = { aTypes };
	end
	if type(aFilter) ~= "table" and type(aFilter) == "string" then
		aFilter = { aFilter:lower() };
	end

	local rMatchedComp;
	for _,v in pairs(ActorManager.getEffects(rActor)) do
		local nActive = DB.getValue(v, "isactive", 0);
		local sApply = DB.getValue(v, "apply", "");

		if nActive ~= 0 then
			local sLabel = DB.getValue(v, "label", "");
			local tEffectComps = EffectManager.parseEffect(sLabel);

			local nMatch = 0;
			-- Iterate through each effect component looking for a type match
			for kEffectComp, sEffectComp in ipairs(tEffectComps) do
				local rEffectComp = EffectManagerCypher.parseConversionEffectComp(sEffectComp);
				local comp_match = true;

				-- Check to see that the conversion effect has a type that we care about
				if StringManager.contains(aTypes, rEffectComp.type) then

					-- Check filters
					if #aFilter > 0 then
						local bFilterMatch = true;
						-- No remainder matches with anything
						-- So we skip this check
						if #(rEffectComp.remainder) > 0 then
							-- Match against all effect tags, or don't match at all
							for _,tag in pairs(rEffectComp.remainder) do
								if tag:lower() == "all" or tag:lower() == "any" then
									bFilterMatch = true;
									break;
								end
								
								if not StringManager.contains(aFilter, tag:lower()) then
									bFilterMatch = false;
									break;
								end
							end
						else
							-- No remainders found in the effect, which means
							-- we should match against anything
							bFilterMatch = true;
						end

						if not bFilterMatch then
							comp_match = false;
						end
					end
				end

				-- Match!
				if comp_match then
					nMatch = kEffectComp;
					if nActive == 1 then
						rMatchedComp = rEffectComp;

						-- Break out of the loop the first time we find a match
						break;
					end
				end
			end -- END EFFECT COMPONENT LOOP

			-- Remove one shot effects
			if nMatch > 0 then
				if nActive == 2 then
					DB.setValue(v, "isactive", "number", 1);
				else
					if sApply == "action" then
						EffectManager.notifyExpire(v, 0);
					elseif sApply == "roll" then
						EffectManager.notifyExpire(v, 0, true);
					elseif sApply == "single" then
						EffectManager.notifyExpire(v, nMatch, true);
					end
				end
			end
		end
	end

	return rMatchedComp.result;
end

function parseConversionEffectComp(s)
	local aStrings = StringManager.split(s, ":", true);
	local sType, sResult = aStrings[1]:match("CONVERT%s*%(([^,]+),%s*([^)]+)%)");
	local aFilters = {};
	if aStrings[2] then
		aFilters = StringManager.split(aStrings[2], ",", true)
	end

	return  {
		type = sType or "", 
		result = sResult, 
		remainder = aFilters, 
		original = StringManager.trim(s)
	};
end

function toLower(aList)
	local temp = {};
	for k,v in ipairs(aList or {}) do
		temp[k] = v:lower();
	end
	return temp;
end