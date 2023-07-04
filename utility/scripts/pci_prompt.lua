local nodeChar;
local sSelectedType = nil;
local nSelectedCost = 0;

function setData(node)
	if not node then
		return;
	end

	nodeChar = node;
end

function onOptionSelected(sType, nCost, bSelected)
	sSelectedType = sType;
	nSelectedCost = nCost;

	-- Clear out all of the other
	if sType ~= "reroll" then
		uncheckCheckbox("reroll")
	end
	if sType ~= "shortterm" then
		uncheckCheckbox("shortterm")
	end
	if sType ~= "mediumterm" then
		uncheckCheckbox("mediumterm")
	end
	if sType ~= "longterm" then
		uncheckCheckbox("longterm")
	end

	reroll_summary.setVisible(sType == "reroll" and bSelected);
	shortterm_summary.setVisible(sType == "shortterm" and bSelected);
	mediumterm_summary.setVisible(sType == "mediumterm" and bSelected);
	longterm_summary.setVisible(sType == "longterm" and bSelected);

	local nXp = DB.getValue(nodeChar, "xp", 0);

	accept.setVisible(bSelected and nXp >= nSelectedCost);
end

function uncheckCheckbox(sType)
	self[sType .. "_checkbox"].setValue(0);
end

function invokeIntrusion()
	IntrusionManager.handlePlayerIntrusionRespnose(nodeChar, sSelectedType, nSelectedCost);
	close();
end

function cancelIntrusion()
	close();
end