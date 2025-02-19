local _fGetTargeting
function onInit()
	_fGetTargeting = ActionsManager.getTargeting
	ActionsManager.getTargeting = ActionsManagerCypher.getTargeting;
end

function getTargeting(rSource, rTarget, sDragType, rRolls)
	local tTargetGroups = _fGetTargeting(rSource, rTarget, sDragType, rRolls);

	for nIndex, rRoll in ipairs(rRolls) do
		local bMulti = false;
		if tTargetGroups[nIndex] then
			bMulti = #(tTargetGroups[nIndex]) > 1
		end
		if bMulti then
			RollManager.encodeMultiTarget(rRoll);
		end
	end
	return tTargetGroups;
end