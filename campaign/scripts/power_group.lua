-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onToggle()
	windowlist.onHeaderToggle(self);
end

local bFilter = true;
function setFilter(bNewFilter)
	bFilter = bNewFilter;
end
function getFilter()
	return bFilter;
end

local nodeGroup = nil;
function setNode(node)
	nodeGroup = node;
	if nodeGroup then
		link.setVisible(true);
	else
		link.setVisible(false);
	end
end
function getNode()
	return nodeGroup;
end

function deleteGroup()
	if nodeGroup then
		DB.deleteNode(nodeGroup);
	end
end

function setHeaderGroup(rGroup, sGroup, bAllowDelete)
	if sGroup == "" then
		name.setValue(Interface.getString("char_label_abilities"));
		name.setIcon("char_abilities");
	else
		name.setValue(sGroup);
		name.setIcon("char_abilities_orange");
		group.setValue(sGroup);

		setNode(rGroup.node);
		if bAllowDelete then
			idelete.setVisible(true);
		end
	end
end

