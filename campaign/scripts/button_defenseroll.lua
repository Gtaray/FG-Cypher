-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local sStat = stat[1];
	if (sStat or "") == "" then
		return;
	end

	local rActor = ActorManager.resolveActor(window.getDatabaseNode());
	local rAction = {};
	rAction.label = StringManager.capitalize(sStat);
	rAction.sStat = sStat;
	rAction.sTraining, rAction.nAssets, rAction.nModifier = ActorManagerCypher.getDefense(rActor, sStat);
	ActionDefense.performRoll(draginfo, rActor, rAction);
end

function onButtonPress()
	action();
	return true;
end
function onDragStart(button, x, y, draginfo)
	action(draginfo);
	return true;
end
