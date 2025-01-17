-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.addHandlers();
	self.onTypeUpdated();
end
function onClose()
	self.removeHandlers();
end

function addHandlers()
	local node = getDatabaseNode();
	DB.addHandler(node, "onDelete", self.onDelete);
	DB.addHandler(DB.getPath(node, "type"), "onUpdate", self.onTypeUpdated);
end
function removeHandlers()
	local node = getDatabaseNode();
	DB.removeHandler(node, "onDelete", self.onDelete);
	DB.removeHandler(DB.getPath(node, "type"), "onUpdate", self.onTypeUpdated);
end

function onDelete(node)
	ItemManager.onCharRemoveEvent(node);
	self.removeHandlers();
end
function onTypeUpdated()
	local sType = DB.getValue(getDatabaseNode(), "type", "")
	local bHasType = sType ~= "";
	type.setVisible(bHasType);
	type_na.setVisible(not bHasType);
end
