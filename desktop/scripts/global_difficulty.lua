-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DifficultyManager.addDifficultyUpdateHandler(onGmiThresholdChanged)
	onGmiThresholdChanged()
end

function onWheel(notches)
	if not Session.IsHost then
        return;
	end

	DifficultyManager.adjustGlobalDifficulty(notches);
end

function onGmiThresholdChanged()
	local nDiff = DifficultyManager.getGlobalDifficulty();
	local iconName = string.format("task%s", nDiff);
	setIcon(iconName)
end