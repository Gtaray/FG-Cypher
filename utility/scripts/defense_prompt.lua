local rPc = nil;
local rAction = nil;
local aStats = nil;
local sCustomStat = nil;


function onInit()
	User.ringBell();
end

function closeWindow()
	close();
end

function setData(pc, action, stats)
	if type(aStats) == "string" then
		aStats = { aStats }
	end

	rPc = pc;
	rAction = action;
	aStats = stats;

	if #(aStats) > 1 then
		for _, sStat in ipairs(aStats) do
			-- For custom stats, we manually adjust the label text
			if not StringManager.contains({ "might", "speed", "intellect" }, sStat) then
				sStat = setCustomStat(sStat);
			end

			self[sStat .. "_label"].setVisible(true);
			self[sStat .. "_checkbox"].setVisible(true);
		end
	end

	if (rAction.sStat or "") ~= "" then
		local sStat = rAction.sStat;
		if not StringManager.contains({ "might", "speed", "intellect" }, sStat) then
			sStat = setCustomStat(sStat);
		end

		self[sStat .. "_checkbox"].setValue(1);
	end

	updateDifficulty();
end

function setCustomStat(sStat)
	self["custom_label"].setValue(StringManager.capitalize(sStat))
	sCustomStat = sStat;
	return "custom"
end

function getStatText()
	s = ""
	for i, sStat in ipairs(aStats or {}) do
		if sStat == "custom" then
			sStat = sCustomStat;
		end
		if #aStats > 2 and i > 1 then
			s = s .. ", ";
		end
		if #aStats > 1 and i == #aStats then
			s = s .. "or ";
		end
		s  = s .. sStat
	end

	return s;
end

function updateDifficulty()
	local nDiffMod = rAction.nDifficulty - effort.getValue() - assets.getValue();
	
	if ease.getValue() == 1 then
		nDiffMod = nDiffMod - 1;
	end
	if hinder.getValue() == 1 then
		nDiffMod = nDiffMod + 1;
	end

	nDiffMod = math.min(math.max(nDiffMod, 0), 6);

	local sDisplayName = ActorManager.getDisplayName(rAction.rTarget);
	if (sDisplayName or "") == "" then
		sDisplayName = "A creature"
	end

	local sDesc = string.format(
		Interface.getString("defense_prompt_description"), 
		sDisplayName,
		getStatText(),
		nDiffMod);

	description.setValue(sDesc);
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
	if sType ~= "custom" then
		uncheckCheckbox("custom");
	end

	self["button_roll"].setVisible(bSelected);
end

function uncheckCheckbox(sType)
	self[sType .. "_checkbox"].setValue(0);
end

function getStat()
	if #(aStats) == 1 then
		return aStats[1]
	end

	local sStat = "";
	if self["might_checkbox"].getValue() == 1 then
		sStat = "might";
	elseif self["speed_checkbox"].getValue() == 1 then
		sStat = "speed";
	elseif self["intellect_checkbox"].getValue() == 1 then
		sStat = "intellect";
	elseif self["custom_checkbox"].getValue() == 1 then
		sStat = sCustomStat;
	end

	return sStat
end

function updateAction()
	local sStat = getStat();

	rAction.bConverted = sStat ~= rAction.sStat;
	rAction.sStat = getStat()
	rAction.label = StringManager.capitalize(rAction.sStat)
	rAction.sTraining, rAction.nAssets, rAction.nModifier = CharStatManager.getDefense(rPc, rAction.sStat)
	rAction.nEffort = effort.getValue();
	rAction.nAssets = (rAction.nAssets or 0) + assets.getValue();

	if ease.getValue() == 1 then
		rAction.bEase = true;
	end
	if hinder.getValue() == 1 then
		rAction.bHinder = true;
	end
end


function roll()
	updateAction()

	ActionDefense.payCostAndRoll(nil, rPc, rAction);
end