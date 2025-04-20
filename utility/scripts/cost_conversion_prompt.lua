local rActor;
local rRoll;

function setData(aStats, sDefault)
	for _, sStat in ipairs(aStats) do
		self[sStat .. "_label"].setVisible(true);
		self[sStat .. "_checkbox"].setVisible(true);
	end

	if (sDefault or "") ~= "" then
		self[sDefault .. "_checkbox"].setValue(1);
	end
end

function setRoll(actor, roll)
	rActor = actor;
	rRoll = roll;
end

function onOptionSelected(sType, bSelected)
	sSelectedType = sType;

	-- Clear out all of the other
	if sType ~= "might" then
		uncheckCheckbox("might")
	end
	if sType ~= "speed" then
		uncheckCheckbox("speed")
	end
	if sType ~= "intellect" then
		uncheckCheckbox("intellect")
	end

	self["accept"].setVisible(bSelected);
end

function uncheckCheckbox(sType)
	self[sType .. "_checkbox"].setValue(0);
end

function roll()
	local sNewStat = "";
	if self["might_checkbox"].getValue() == 1 then
		sNewStat = "might";
	elseif self["speed_checkbox"].getValue() == 1 then
		sNewStat = "speed";
	elseif self["intellect_checkbox"].getValue() == 1 then
		sNewStat = "intellect";
	end	

	if sNewStat ~= rRoll.sCostStat then
		rRoll.sDesc = string.format("%s [CONVERTED]", rRoll.sDesc);
		rRoll.sDesc = rRoll.sDesc:gsub(
			StringManager.capitalize(rRoll.sCostStat), 
			StringManager.capitalize(sNewStat));
			rRoll.sCostStat = sNewStat;
	end

	ActionsManager.performAction(nil, rActor, rRoll);
	close();
end