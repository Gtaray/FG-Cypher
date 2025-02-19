-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
function onInit()
	self.onEditModeChanged();
end

function onEditModeChanged()
	local bEditMode = WindowManager.getEditMode(windowlist, "sheet_iedit");
	idelete.setVisible(bEditMode);
end

-- Check constraints and set up for an ability roll.
function action(draginfo)
	local nodeSkill = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);

	local rAction = {};
	rAction.label = DB.getValue(nodeSkill, "name", "");
	rAction.sSkill = DB.getValue(nodeSkill, "name", "");
	rAction.sStat = RollManager.resolveStat(DB.getValue(nodeSkill, "stat", "")); -- Resolves a blank stat to "Might"
	rAction.nTraining = DB.getValue(nodeSkill, "training", 1);
	rAction.nAssets = DB.getValue(nodeSkill, "asset", 0);
	rAction.nModifier = DB.getValue(nodeSkill, "misc", 0);

	ActionSkill.payCostAndRoll(draginfo, rActor, rAction);
end
