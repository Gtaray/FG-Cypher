rAttacker = nil;
rTarget = nil;
sStat = nil;
nDifficulty = 0;
local bAccepted = false;

function onInit()
	User.ringBell();
end

-- When closing the window, if we haven't clicked the roll button then automatically
-- roll the defense
function onClose()
	if not bAccepted then
		roll();
	end
end

function closeWindow()
	close();
end

function setData(rSource, rPC, sStat, nDifficulty)
	rAttacker = rSource;
	rTarget = rPC;
	self.nDifficulty = nDifficulty;
	self.sStat = sStat;

	local sDesc = string.format(
		Interface.getString("defense_prompt_description"), 
		ActorManager.getDisplayName(rAttacker),
		self.sStat,
		self.nDifficulty);
	description.setValue(sDesc);
end

function roll()
	local rAction = {};
	rAction.label = StringManager.capitalize(self.sStat)
	rAction.sStat = self.sStat;
	rAction.nDifficulty = self.nDifficulty
	rAction.rTarget = rAttacker;
	rAction.sTraining, rAction.nAssets, rAction.nModifier = ActorManagerCypher.getDefense(rTarget, rAction.sStat)
	rAction.label = StringManager.capitalize(rAction.sStat);

	ActionDefense.performRoll(nil, rTarget, rAction);

	bAccepted = true;
	return true;
end