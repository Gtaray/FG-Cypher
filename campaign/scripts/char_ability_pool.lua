-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local _sStat;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	
	_sStat = self.getStat();

	self.initWidgets();
	self.updateWidgetDisplay();

	local node = window.getDatabaseNode();
	DB.addHandler(DB.getPath(node, "max"), "onUpdate", onMaxUpdated);
	self.onMaxUpdated();
	self.onValueChanged();
end

function onClose()
	local node = window.getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "max"), "onUpdate", onMaxUpdated);
end

function onValueChanged()
	-- Update the text color based on value
	local nodeActor = self.getActorNode()
	local nCur, nMax = CharStatManager.getStatPool(nodeActor, _sStat)
	setColor(ColorManager.getTokenHealthColor(1 - (nCur / nMax), false));
end

function onMaxUpdated()
	local nodeActor = self.getActorNode()
	local nCur, nMax = CharStatManager.getStatPool(nodeActor, _sStat)

	-- If the pool is at max, then have the pool increase with the max
	local bUpdateCurrent = false;
	if nCur == getMaxValue() then
		bUpdateCurrent = true;
	end

	setMaxValue(nMax);
	if bUpdateCurrent then
		setValue(nMax);
	end

	self.updateWidgetDisplay();
	self.onValueChanged();
end

function getActorNode()
	return window.getActorNode();
end

function getStat()
	return DB.getName(window.getDatabaseNode());
end

---------------------------------------------
-- MAX STAT DISPLAY
---------------------------------------------
local maxWidget = nil;
function initWidgets()
	maxWidget = addTextWidget({ 
		font = "sheetlabelmini", text = "0", 
		position = "topright", x = 5, y = 0,
		frame = "tempmodsmall", frameoffset = "4,2,4,2",
	});
	maxWidget.setVisible(true);
end

function updateWidgetDisplay()
	local nodeActor = self.getActorNode()
	local _, nMax = CharStatManager.getStatPool(nodeActor, _sStat)

	maxWidget.setText(string.format("%d", nMax));
end

---------------------------------------------
-- ROLLING
---------------------------------------------
function action(draginfo)
	local rAction = {
		label = StringManager.capitalize(_sStat),
		sStat = _sStat
	}
	
	local rActor = ActorManager.resolveActor(self.getActorNode())
	ActionStat.payCostAndRoll(draginfo, rActor, rAction);
end

function onDoubleClick(x, y)
	action();
	return true;
end
function onDragStart(button, x, y, draginfo)
	action(draginfo);
	return true;
end

---------------------------------------------
-- HANDLE HEALING ON DROP
---------------------------------------------
function onDrop(x, y, draginfo)
	if draginfo.isType("recovery") then
		self.handleRecoveryDrop(draginfo);
		return true;
	elseif draginfo.isType("number") then
		setValue(getValue() + draginfo.getNumberData());
		return true;
	end
end

function handleRecoveryDrop(draginfo)
	local aDice = draginfo.getDiceData();
	if aDice then
		return;
	end
	local nApplied = draginfo.getNumberData();
	local nRemainder = 0;
    local bRemoveWound = false;

    if getValue() == 0 and nApplied > 0 then
        bRemoveWound = true;
    end

	local nodeActor = self.getActorNode();
	local nCur, nMax = CharStatManager.getStatPool(nodeActor, _sStat)
	local nPool = nCur + nApplied;
	
	if nPool > nMax then
		nRemainder = nPool - nMax;
		nApplied = nApplied - nRemainder;
		nPool = nMax;
	end
	
	if nApplied > 0 then
		setValue(nPool);
	
		local sName = StringManager.capitalize(DB.getName(DB.getParent(getDatabaseNode())));
		
		if nRemainder > 0 then
			local rRoll = { sType = "recovery", aDice = {}, nMod = nRemainder };
			rRoll.sDesc = string.format("[RECOVERY] [APPLIED %d TO %s] Remainder", nApplied, sName);
			local rMessage = ActionsManager.createActionMessage(rActor, rRoll);
			Comm.deliverChatMessage(rMessage);
		else
			local rRoll = {};
			rRoll.sDesc = string.format("[RECOVERY] [APPLIED %d TO %s]", nApplied, sName);
			local rMessage = ActionsManager.createActionMessage(rActor, rRoll);
			Comm.deliverChatMessage(rMessage);
		end
	end

    if bRemoveWound then
        local nCurrentWound = DB.getValue(nodeActor, "wounds", 0);
        DB.setValue(nodeActor, "wounds", "number", math.max(0, nCurrentWound - 1));
    end
end
