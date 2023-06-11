-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler(DB.getPath(getDatabaseNode(), "adjustments"), "onChildAdded", onAdjustmentAdded);
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "adjustments"), "onChildAdded", onAdjustmentAdded);
end

function onAdjustmentAdded(nodeList, nodeAdjustment)
	local nMaxOrder = 0;
	for _, node in ipairs(DB.getChildList(nodeList)) do
		local nOrder = DB.getValue(node, "order", 0);
		if nOrder > nMaxOrder then
			nMaxOrder = nOrder;
		end
	end

	nMaxOrder = nMaxOrder + 1;
	DB.setValue(nodeAdjustment, "order", "number", nMaxOrder);
end

function getType()
	local actionnode = parentcontrol.window.getDatabaseNode();
	return DB.getValue(actionnode, "type", "");
end