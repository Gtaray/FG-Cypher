-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DifficultyManager.addGmiThresholdUpdateHandler(onGmiThresholdChanged)
	onGmiThresholdChanged()
end

function onWheel(notches)
	if not Session.IsHost then
        return;
	end

	DifficultyManager.adjustGmiThreshold(notches);
end

function onGmiThresholdChanged()
	setValue(DifficultyManager.getGmiThreshold())
end