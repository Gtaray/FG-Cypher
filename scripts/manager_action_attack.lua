-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerResultHandler("attack", onAttack);
end

function onAttack(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
	end
	
	local aAddIcons = {};
	
	local nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		nFirstDie = rRoll.aDice[1].result or 0;
	end
	if nFirstDie >= 20 then
		rMessage.text = rMessage.text .. " [DAMAGE +4 OR MAJOR EFFECT]";
		table.insert(aAddIcons, "roll20");
	elseif nFirstDie == 19 then
		rMessage.text = rMessage.text .. " [DAMAGE +3 OR MINOR EFFECT]";
		table.insert(aAddIcons, "roll19");
	elseif nFirstDie == 18 then
		rMessage.text = rMessage.text .. " [DAMAGE +2]";
		table.insert(aAddIcons, "roll18");
	elseif nFirstDie == 17 then
		rMessage.text = rMessage.text .. " [DAMAGE +1]";
		table.insert(aAddIcons, "roll17");
	elseif nFirstDie == 1 then
		rMessage.text = rMessage.text .. " [GM INTRUSION]";
		table.insert(aAddIcons, "roll1");
	end
	
	-- If the target is currently dazed, that reduces the difficulty by one.
	local nDazed = 0;
	if EffectManager.hasCondition(rTarget, "Dazed") then
		nDazed = nDazed + 1;
		rMessage.text = rMessage.text .. " [TARGET DAZED]";
	end

	-- We now have all the modifiers, figure out the difficulty level we succeeded at.
	local nTotal = ActionsManager.total(rRoll);
	local nSuccess = math.floor(nTotal / 3) + rRoll.nShift + nDazed;
	nSuccess = math.max(0, math.min(10, nSuccess));
	
	table.insert(aAddIcons, "task" .. nSuccess);
		
	if #aAddIcons > 0 then
		rMessage.icon = { rMessage.icon };
		for _,v in ipairs(aAddIcons) do
			table.insert(rMessage.icon, v);
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end
