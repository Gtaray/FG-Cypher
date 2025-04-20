-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	windowlist.onChildWindowAdded(self);

	local node = getDatabaseNode();

	-- Migrate "statcost" to "cost"
	local sStat = DB.getValue(node, "stat", "");
	if sStat ~= "" then
		DB.setValue(node, "coststat", "string", sStat);
		DB.deleteChild(node, "stat");
	end
	local nCost = DB.getValue(node, "statcost", 0);
	if nCost ~= 0 then
		DB.setValue(node, "cost", "number", nCost);
		DB.deleteChild(node, "statcost");
	end

	DB.addHandler(DB.getPath(node, "period"), "onUpdate", self.onUsePeriodChanged);
	DB.addHandler(DB.getPath(node, "cost"), "onUpdate", self.onCostChanged);
	DB.addHandler(DB.getPath(node, "coststat"), "onUpdate", self.onCostChanged);

	if ActorManager.isPC(self.getCharNode()) then
		onCostChanged();
		onUsePeriodChanged();
	end
end

function onClose()
	super.onClose();
	DB.removeHandler(DB.getPath(node, "period"), "onUpdate", self.onUsePeriodChanged);
	DB.removeHandler(DB.getPath(node, "cost"), "onUpdate", self.onCostChanged);
	DB.removeHandler(DB.getPath(node, "coststat"), "onUpdate", self.onCostChanged);
end

function getCharNode()
	return DB.getChild(getDatabaseNode(), "...");
end

function onCostChanged()
	local bShow = (header.subwindow.cost.getValue() ~= 0);
	header.subwindow.statcostview.setVisible(bShow);
				
	local sStatView = "" .. header.subwindow.cost.getValue();
	local sStat = header.subwindow.coststat.getValue();
	if sStat ~= "" then
		sStatView = sStatView .. " " .. StringManager.capitalize(sStat:sub(1,2));
	end
	header.subwindow.statcostview.setValue(sStatView);
end

function initiateCostRoll(draginfo)
	local rActor = ActorManager.resolveActor(DB.getChild(getDatabaseNode(), "..."));
	local sStat = header.subwindow.coststat.getValue() or "";
	local rAction = {
		label = header.subwindow.name.getValue(),
		nCost = header.subwindow.cost.getValue(),
		sCostStat = RollManager.resolveStat(sStat, "might")
	};

	ActionCost.performRoll(draginfo, rActor, rAction);
end

function onUsePeriodChanged()
	local bShowUseCheckbox = DB.getValue(getDatabaseNode(), "period", "") ~= "";
	header.subwindow.used.setVisible(bShowUseCheckbox);
end