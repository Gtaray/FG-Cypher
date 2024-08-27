-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("MAXTARGET", onMaxDifficultyChanged);
	onMaxDifficultyChanged();

	DifficultyManager.addDifficultyUpdateHandler(onDifficultyChanged);
	onDifficultyChanged();
end

function onMaxDifficultyChanged()
	local nMax = OptionsManagerCypher.getMaxTarget();
	setMaxValue(nMax);
end

function onWheel(notches)
	if not Session.IsHost then
        return;
	end

	if not OptionsManagerCypher.isGlobalDifficultyEnabled() then
		return;
	end

	DifficultyManager.adjustGlobalDifficulty(notches)
end

function onDifficultyChanged()
	setValue(DifficultyManager.getGlobalDifficulty())
end