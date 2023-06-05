-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();

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

-- TODO: Update this to roll a generic roll with cost
function onCostDoubleClicked()
	local rActor = ActorManager.resolveActor(DB.getChild(getDatabaseNode(), "..."));
	local sStat = coststat.getValue() or "";
	local rAction = {
		sDesc = string.format("[COST (%s)] %s", StringManager.capitalize(sStat), name.getValue()),
		nCost = cost.getValue(),
		sStat = sStat;
		sCostStat = sStat,
		nEffort = 0,
		nAssets = 0,
		bDisableEdge = false
	};

	local aFilter = { rAction.sCostStat};
	RollManager.addEdgeToAction(rActor, rAction, aFilter);
	RollManager.addWoundedToAction(rActor, rAction);
	RollManager.addArmorCostToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rActor, rAction);
	RollManager.resolveMaximumEffort(rActor, rAction, aFilter);
	RollManager.resolveMaximumAssets(rActor, rAction, aFilter);
	RollManager.calculateBaseEffortCost(rActor, rAction);
	RollManager.adjustEffortCostWithEffects(rActor, rAction, aFilter);

	-- Jank. We encode to sDesc, then set label to match the encoded result
	-- because encodeEdge requires rRoll.sDesc, and spendPointsForRoll requires label
	rAction.label = rAction.sDesc;

	if RollManager.spendPointsForRoll(rActor, rAction) then
		local rMessage = ChatManager.createBaseMessage(rActor);
		rMessage.text = rAction.label;
		rMessage.icon = "action_damage";

		rMessage.text = RollManager.encodeEdge(rAction, rMessage.text);
		rMessage.text = RollManager.encodeEffort(rAction, rMessage.text);
		rMessage.dice = {};
		rMessage.diemodifier = rAction.nCost;
 
		Comm.deliverChatMessage(rMessage);
	end
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
