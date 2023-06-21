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