-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local sStat = window.getStat()
	if (sStat or "") == "" then
		return;
	end

	local rActor = ActorManager.resolveActor(window.getActorNode());
	local rAction = {};
	rAction.label = StringManager.capitalize(sStat);
	rAction.sStat = sStat;
	rAction.nTraining, rAction.nAssets, rAction.nModifier = CharStatManager.getDefense(rActor, sStat);
	ActionDefense.payCostAndRoll(draginfo, rActor, rAction);
end

function onButtonPress()
	action();
	return true;
end
function onDragStart(button, x, y, draginfo)
	action(draginfo);
	return true;
end
