rPc = nil;
rAction = nil;
aStats = nil;


function onInit()
	User.ringBell();
end

function closeWindow()
	close();
end

function setData(rPC, rAction, aStats)
	if type(aStats) == "string" then
		aStats = { aStats }
	end

	self.rPc = rPC;
	self.rAction = rAction;
	self.aStats = aStats;

	if #(self.aStats) > 1 then
		for _, sStat in ipairs(aStats) do
			self[sStat .. "_label"].setVisible(true);
			self[sStat .. "_checkbox"].setVisible(true);
		end
	end

	if (self.rAction.sStat or "") ~= "" then
		self[self.rAction.sStat .. "_checkbox"].setValue(1);
	end

	updateDifficulty();
end

function getStatText()
	local s = "";
	if #(self.aStats) == 1 then
		return self.aStats[1];
	end
	if #(self.aStats) == 3 then
		return "any stat";
	end

	return string.format("%s or %s", self.aStats[1], self.aStats[2]);
end

function updateDifficulty()
	local nDiffMod = self.rAction.nDifficulty - effort.getValue() - assets.getValue();
	
	if ease.getValue() == 1 then
		nDiffMod = nDiffMod - 1;
	end
	if hinder.getValue() == 1 then
		nDiffMod = nDiffMod + 1;
	end

	nDiffMod = math.min(math.max(nDiffMod, 0), 6);

	local sDisplayName = ActorManager.getDisplayName(self.rAction.rTarget);
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

	self["button_roll"].setVisible(bSelected);
end

function uncheckCheckbox(sType)
	self[sType .. "_checkbox"].setValue(0);
end

function getStat()
	if #(self.aStats) == 1 then
		return self.aStats[1]
	end

	local sStat = "";
	if self["might_checkbox"].getValue() == 1 then
		sStat = "might";
	elseif self["speed_checkbox"].getValue() == 1 then
		sStat = "speed";
	elseif self["intellect_checkbox"].getValue() == 1 then
		sStat = "intellect";
	end

	return sStat
end


function roll()
	local sStat = getStat();

	self.rAction.bConverted = sStat ~= self.rAction.sStat;
	self.rAction.sStat = getStat()
	self.rAction.label = StringManager.capitalize(self.rAction.sStat)
	self.rAction.sTraining, self.rAction.nAssets, self.rAction.nModifier = ActorManagerCypher.getDefense(rPc, self.rAction.sStat)
	self.rAction.nEffort = effort.getValue();
	self.rAction.nAssets = rAction.nAssets + assets.getValue();

	if ease.getValue() == 1 then
		rAction.bEase = true;
	end
	if hinder.getValue() == 1 then
		rAction.bHinder = true;
	end

	ActionDefense.payCostAndRoll(nil, rPc, rAction);
end