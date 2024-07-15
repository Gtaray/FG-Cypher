local nodeChar;
local sSelectedType = nil;
local nSelectedCost = 0;

function getNode()
	return nodeChar
end

function setData(node)
	if not node then
		return;
	end

	nodeChar = node;

	description.setValue(string.format(
		Interface.getString("pci_prompt_description"), 
		ActorManagerCypher.getXP(nodeChar)
	))
end

function setSelection(sSelected, nCost)
	sSelectedType = sSelected
	nSelectedCost = nCost
end

function onOptionSelected(sType, nCost, bSelected)
	setSelection(sType, nCost)

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

	local nResource = 0;
	if (sType == "reroll" or sType == "shortterm") and OptionsManagerCypher.areHeroPointsEnabled() then
		nResource = CharManager.getHeroPoints(nodeChar)
	else
		nResource = DB.getValue(nodeChar, "xp", 0);
	end

	accept.setVisible(bSelected and nResource >= nSelectedCost);
end

function uncheckCheckbox(sType)
	self[sType .. "_checkbox"].setValue(0);
end

function invokeIntrusion()
	IntrusionManager.handlePlayerIntrusionResponse(nodeChar, sSelectedType, nSelectedCost);
	close();
end

function cancelIntrusion()
	close();
end