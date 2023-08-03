rAttacker = nil;
rTarget = nil;
sStat = nil;
sDefault = nil;
nDifficulty = 0;

function onInit()
	User.ringBell();
end

function closeWindow()
	close();
end

function setData(rSource, rPC, aStats, sDefault, nDifficulty)
	if type(aStats) == "string" then
		aStats = { aStats }
	end

	rAttacker = rSource;
	rTarget = rPC;
	self.nDifficulty = nDifficulty;
	self.aStats = aStats;

	if #(self.aStats) > 1 then
		for _, sStat in ipairs(aStats) do
			self[sStat .. "_label"].setVisible(true);
			self[sStat .. "_checkbox"].setVisible(true);
		end

		if (sDefault or "") ~= "" then
			self.sDefault = sDefault;
			self[sDefault .. "_checkbox"].setValue(1);
		end
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
	local nDiffMod = nDifficulty - effort.getValue() - assets.getValue();
	
	if ease.getValue() == 1 then
		nDiffMod = nDiffMod - 1;
	end
	if hinder.getValue() == 1 then
		nDiffMod = nDiffMod + 1;
	end

	nDiffMod = math.min(math.max(nDiffMod, 0), 6);

	local sDisplayName = ActorManager.getDisplayName(rAttacker);
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
	local rAction = {};

	rAction.label = StringManager.capitalize(sStat)
	rAction.bConverted = sStat ~= self.sDefault;
	rAction.sStat = sStat;
	rAction.rTarget = rAttacker;
	rAction.sTraining, rAction.nAssets, rAction.nModifier = ActorManagerCypher.getDefense(rTarget, rAction.sStat)
	rAction.nEffort = effort.getValue();
	rAction.nAssets = rAction.nAssets + assets.getValue();

	if ease.getValue() == 1 then
		rAction.bEase = true;
	end
	if hinder.getValue() == 1 then
		rAction.bHinder = true;
	end

	-- Only add in difficulty if the attacker is an NPC
	-- This will change when I come up with a better answer for PvP rolls
	if not ActorManager.isPC(rAttacker) then
		rAction.nDifficulty = self.nDifficulty
	end

	ActionDefense.payCostAndRoll(nil, rTarget, rAction);
end