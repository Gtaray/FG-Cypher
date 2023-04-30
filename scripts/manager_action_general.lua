-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerResultHandler("dice", onRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local aAddIcons = {};
	local nFirstDie = rRoll.aDice[1].result or 0;
	if nFirstDie >= 20 then
		rMessage.text = rMessage.text .. " [MAJOR EFFECT]";
		table.insert(aAddIcons, "roll20");
	elseif nFirstDie == 19 then
		rMessage.text = rMessage.text .. " [MINOR EFFECT]";
		table.insert(aAddIcons, "roll19");
	elseif nFirstDie == 1 then
		rMessage.text = rMessage.text .. " [GM INTRUSION]";
		table.insert(aAddIcons, "roll1");
	end

	RollManager.processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons);
	
	Comm.deliverChatMessage(rMessage);
end
