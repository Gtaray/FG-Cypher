-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--	POWER GROUP UPDATING
--

local _tPowerGroupUpdatePause = {};
function arePowerGroupUpdatesPaused(nodeChar)
	return _tPowerGroupUpdatePause[nodeChar] or false;
end
function pausePowerGroupUpdates(nodeChar)
	_tPowerGroupUpdatePause[nodeChar] = true;
end
function resumePowerGroupUpdates(nodeChar)
	_tPowerGroupUpdatePause[nodeChar] = nil;
end

--
--	POWER USAGE UPDATING
--

local _tPowerUsageUpdatePause = {};
function arePowerUsageUpdatesPaused(nodeChar)
	return _tPowerUsageUpdatePause[nodeChar] or false;
end
function pausePowerUsageUpdates(nodeChar)
	_tPowerUsageUpdatePause[nodeChar] = true;
end
function resumePowerUsageUpdates(nodeChar)
	_tPowerUsageUpdatePause[nodeChar] = nil;
end

--
-- POWER DISPLAY UPDATING
--
function updatePowerDisplay(w)
	if not w.header or not w.header.subwindow then
		return;
	end
	if not w.header.subwindow.group or not w.header.subwindow.actionsmini then
		return;
	end

	local bEditMode = WindowManager.getEditMode(w, "actions_iedit");
	w.header.subwindow.group.setVisible(bEditMode);
	w.header.subwindow.actionsmini.setVisible(not bEditMode);
end