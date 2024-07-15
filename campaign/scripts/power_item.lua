-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	local charnode = DB.getChild(node, "...");

	-- Migrate "statcost" to "cost"
	local sStat = DB.getValue(node, "stat", "");
	if sStat ~= "" then
		DB.setValue(node, "coststat", "string", sStat);
		DB.deleteNode(DB.getChild(node, "stat"));
	end
	local nCost = DB.getValue(node, "statcost", 0);
	if nCost ~= 0 then
		DB.setValue(node, "cost", "number", nCost);
		DB.deleteNode(DB.getChild(node, "statcost"));
	end

	PowerManagerCore.registerDefaultPowerMenu(self);
	PowerManagerCore.handleDefaultPowerInitParse(node);

	if ActorManager.isPC(charnode) then
		registerMenuItem(Interface.getString("char_menu_hideability"), "tokenvisibility", 7);
		registerMenuItem(Interface.getString("char_menu_confirm"), "tokenvisibility", 7, 7);
	end

	self.updateDetailButton();
	self.toggleDetail();
	self.onDisplayChanged();

	local sActionsPath = PowerManagerCore.getPowerActionsPath();
	DB.addHandler(DB.getPath(node, sActionsPath), "onChildAdded", self.onActionListChanged);
	DB.addHandler(DB.getPath(node, sActionsPath), "onChildDeleted", self.onActionListChanged);
	DB.addHandler(DB.getPath(node, "period"), "onUpdate", self.onUsePeriodChanged);

	if ActorManager.isPC(self.getCharNode()) then
		onCostChanged();
		onUsePeriodChanged();
	end
end

function onClose()
	if super and super.onClose then
		super.onClose();
	end
	local node = getDatabaseNode();
	local sActionsPath = PowerManagerCore.getPowerActionsPath();
	DB.removeHandler(DB.getPath(node, sActionsPath), "onChildAdded", self.onActionListChanged);
	DB.removeHandler(DB.getPath(node, sActionsPath), "onChildDeleted", self.onActionListChanged);
end

function getCharNode()
	return DB.getChild(getDatabaseNode(), "...");
end

function onMenuSelection(...)
	local args = { ... }
	if args[1] == 7 and args[2] == 7 then
		DB.setValue(getDatabaseNode(), "actionTabVisibility", "string", "hide")
	end
	PowerManagerCore.onDefaultPowerMenuSelection(self, ...)
end

function onCostChanged()
	local bShow = (cost.getValue() ~= 0);
	statcostview.setVisible(bShow);
				
	local sStatView = "" .. cost.getValue();
	local sStat = coststat.getValue();
	if sStat ~= "" then
		sStatView = sStatView .. " " .. StringManager.capitalize(sStat:sub(1,2));
	end
	statcostview.setValue(sStatView);
end

function initiateCostRoll(draginfo)
	local rActor = ActorManager.resolveActor(DB.getChild(getDatabaseNode(), "..."));
	local sStat = coststat.getValue() or "";
	local rAction = {
		label = name.getValue(),
		nCost = cost.getValue(),
		sCostStat = RollManager.resolveStat(sStat, "might")
	};

	ActionCost.performRoll(draginfo, rActor, rAction);
end

function onUsePeriodChanged()
	local bShowUseCheckbox = DB.getValue(getDatabaseNode(), "period", "") ~= "";
	used.setVisible(bShowUseCheckbox);
end

function onActionListChanged()
	if not activatedetail then
		return;
	end

	self.updateDetailButton();
	if DB.getChildCount(getDatabaseNode(), PowerManagerCore.getPowerActionsPath()) > 0 then
		activatedetail.setValue(1);
	else
		activatedetail.setValue(0);
	end
end
function updateDetailButton()
	if not activatedetail then
		return;
	end

	local bShow = (DB.getChildCount(getDatabaseNode(), PowerManagerCore.getPowerActionsPath()) > 0);
	activatedetail.setVisible(bShow);
end
function toggleDetail()
	if not activatedetail then
		return;
	end

	local bShow = (activatedetail.getValue() == 1);
	if bShow then
		actions.setDatabaseNode(DB.createChild(getDatabaseNode(), PowerManagerCore.getPowerActionsPath()));
	else
		actions.setDatabaseNode(nil);
	end
	actions.setVisible(bShow);
end

function onDisplayChanged()
	PowerManagerCore.updatePowerDisplay(self);
end
