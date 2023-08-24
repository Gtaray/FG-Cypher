-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("GDIFF", onEnabledChanged)
	onEnabledChanged();

	DifficultyManager.addDifficultyUpdateHandler(onDifficultyChanged)
	onDifficultyChanged()
end

function onEnabledChanged()
	local bEnabled = OptionsManagerCypher.isGlobalDifficultyEnabled();
	setVisible(bEnabled);

	if bEnabled then
		onDifficultyChanged();
	end
end

function onWheel(notches)
	if not Session.IsHost then
        return;
	end

	DifficultyManager.adjustGlobalDifficulty(notches);
end

function onDifficultyChanged()
	if not OptionsManagerCypher.isGlobalDifficultyEnabled() then
		return;
	end

	local nDiff = DifficultyManager.getGlobalDifficulty();
	local iconName = string.format("task%s", nDiff);
	setIcon(iconName)
end