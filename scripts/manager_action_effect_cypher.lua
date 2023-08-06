-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function payCostAndRoll(draginfo, rActor, rAction)
	rAction.sSourceRollType = "effect";

	if not ActionCost.performRoll(draginfo, rActor, rAction) then
		ActionEffect.performRoll(draginfo, rActor, rAction);
	end
end

-- We have to wrap the performRoll function here so that we can handle
-- adjusting the duration or contents of an effect based on effort spent
function performRoll(draginfo, rActor, rAction)
	-- Check to see if we need to modify the duration of the effect
	-- based on effort spent
	if rAction.nEffort > 0 then
		--ActionEffectCypher.replaceTokens(rActor, rAction)
		if rAction.rDurationScaling.sDiceMult == "effort" then
			for _, dice in ipairs(rAction.rDurationScaling.aDice or {}) do
				for i=1, rAction.nEffort do
					table.insert(rAction.aDice, dice)
				end
			end
		end

		if rAction.rDurationScaling.sModMult == "effort" then
			rAction.nDuration = rAction.nDuration + ((rAction.rDurationScaling.nMod or 0) * rAction.nEffort);
		end
	end

	-- We want to replace tokens even if we don't spend effort
	-- since effects can be used without effort. Though the onus is on the
	-- effect creator to make sure their effect scales with 0 effort
	ActionEffectCypher.replaceTokens(rActor, rAction);

	ActionEffect.performRoll(draginfo, rActor, rAction);
end

-----------------------------
-- TOKEN REPLACEMENT FOR EFFORT
-----------------------------

function replaceTokens(rActor, rAction)
	local sNewText = rAction.sName;
	for temp in string.gmatch(rAction.sName, "({{.-}})") do
		local token = (temp:match("{{(.-)}}") or ""):lower();
		local value = "EMPTY";

		if token == "effort" then
			local nBase = rAction.rEffectScaling.nBase or 0;
			local nMod = rAction.rEffectScaling.nMod or 0;
			local nEffort = rAction.nEffort or 0;
			value = tostring(nBase + (nMod * nEffort))
		elseif token == "cost" then
			-- NOT YET IMPLEMENTED
			-- local cost = ActionCost.getCostState(rActor, bRetainState);
			-- if cost then
			-- 	value = cost.nCost;
			-- end
		elseif token == "costscale" then
			-- NOT YET IMPLEMENTED
			-- local cost = ActionCost.getCostState(rActor, bRetainState);
			-- if cost then
			-- 	value = cost.nCostScaling;
			-- end
		end
		if (value or "") == "" then
			value = "EMPTY"
		end

		sNewText = sNewText:gsub(temp, value)
	end
	rAction.sName = sNewText;
end