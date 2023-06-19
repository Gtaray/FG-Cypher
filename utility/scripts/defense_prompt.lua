rAttacker = nil;
rTarget = nil;
sStat = nil;
nDifficulty = 0;

function onInit()
	User.ringBell();
end

function closeWindow()
	close();
end

function setData(rSource, rPC, sStat, nDifficulty)
	rAttacker = rSource;
	rTarget = rPC;
	self.nDifficulty = nDifficulty;
	self.sStat = sStat;

	updateDifficulty();
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
		self.sStat,
		nDiffMod);

	description.setValue(sDesc);
end

function roll()
	local rAction = {};
	rAction.label = StringManager.capitalize(self.sStat)
	rAction.sStat = self.sStat;
	rAction.rTarget = rAttacker;
	rAction.sTraining, rAction.nAssets, rAction.nModifier = ActorManagerCypher.getDefense(rTarget, rAction.sStat)
	rAction.label = StringManager.capitalize(rAction.sStat);
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