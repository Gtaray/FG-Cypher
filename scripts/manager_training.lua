local _tStringToNumber = {
	["inability"] = 0,
	["practiced"] = 1,
	["trained"] = 2,
	["specialized"] = 3
}

local _tNumberToDifficulty = {
	[0] = 1,
	[1] = 0,
	[2] = -1,
	[3] = -2
}

-- Converts a string of "inability", "practiced", "trained", "specialized" to a number
-- that's used by the training icon, so 0, 1, 2, and 3
function convertTrainingStringToNumber(sTraining)
	return _tStringToNumber[sTraining:lower()];
end

function convertTrainingStringToDifficultyModifier(sTraining)
	return getDifficultyModifier(convertTrainingStringToNumber(sTraining))
end

-- Simple method that converts training value (0-3) to a difficulty modifier
function getDifficultyModifier(nTraining)
	return _tNumberToDifficulty[nTraining];
end

function getTrainingModifier(vTraining)
	if type(vTraining) == "string" then
		vTraining = convertTrainingStringToNumber(vTraining)
	end

	-- multiply by -3 to invert the negative difficulty mod to a positive flat mod (or visa versa)
	return getDifficultyModifier(vTraining) * -3;
end

function modifyTraining(nTraining, vDelta)
	if type(vDelta) == "string" then
		vDelta = convertTrainingStringToDifficultyModifier(vDelta);
	end

	return math.max(math.min(nTraining + vDelta, 3), 0);
end