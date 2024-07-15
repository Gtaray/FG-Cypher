function onInit()
	self.updateStat(0, 0, 0, "might");
	self.updateStat(0, 0, 0, "speed");
	self.updateStat(0, 0, 0, "intellect");
	self.updateAbilities({});
end

function updateMight(nOrig, nNew, nEdge)
	self.updateStat(nOrig, nNew, nEdge, "might");
end

function updateSpeed(nOrig, nNew, nEdge)
	self.updateStat(nOrig, nNew, nEdge, "speed");
end

function updateIntellect(nOrig, nNew, nEdge)
	self.updateStat(nOrig, nNew, nEdge, "intellect");
end

function updateStat(nOrig, nNew, nEdge, sStat)
	local bShow = false;
	local sText = ""
	if nOrig ~= nNew then
		bShow = true;
		sText = string.format(
			Interface.getString("label_dialog_summary_stat_update"), 
			nOrig, 
			nNew);
	end

	if nEdge > 0 then
		bShow = true;
		if sText ~= "" then
			sText = string.format("%s      ", sText)
		end

		sText = string.format("%s%s %s edge",
			sText,
			DiceManager.convertDiceToString({}, nEdge, true),
			Interface.getString(sStat));
	end

	self["label_" .. sStat].setVisible(bShow)
	self[sStat].setVisible(bShow)
	self[sStat].setValue(sText);
end

function updateAbilities(aAbilities)
	local bShow = #aAbilities > 0;
	self["label_abilities"].setVisible(bShow);
	self["abilities"].setVisible(bShow);
	
	abilities.closeAll();
	for _, rData in ipairs(aAbilities) do
		abilities.addEntry(rData.node, rData.multiselect);
	end
end