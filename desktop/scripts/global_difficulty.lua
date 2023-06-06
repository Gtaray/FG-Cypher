-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DifficultyManager.addUpdateHandler(onDifficultyChanged)
	onDifficultyChanged()
end

function onWheel(notches)
	if not Session.IsHost then
        return;
	end

	DifficultyManager.adjustGlobalDifficulty(notches);
end

function onDifficultyChanged()
	local nDiff = DifficultyManager.getGlobalDifficulty();
	local iconName = string.format("task%d", nDiff);
	setIcon(iconName)
end