-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

DIFFICULTY_DEFAULT = 3
DIFFICULTY_MINIMUM = 1
DIFFICULTY_MAXIMUM = 10
DIFFICULTY_PATH = "global.difficulty";

function onInit()
	initializeGlobalDifficulty()
end

function initializeGlobalDifficulty()
	local target = DB.getValue(DifficultyManager.DIFFICULTY_PATH)
	if Session.IsHost and target == nil then
		DB.setValue(DifficultyManager.DIFFICULTY_PATH, "number", DifficultyManager.DIFFICULTY_DEFAULT)
		DB.setPublic(DifficultyManager.DIFFICULTY_PATH, true)
	end
end

function addUpdateHandler(fHandler)
	DB.addHandler(DifficultyManager.DIFFICULTY_PATH, "onUpdate", fHandler);
end

function getGlobalDifficulty()
	return DB.getValue(DifficultyManager.DIFFICULTY_PATH, "", DifficultyManager.DIFFICULTY_DEFAULT);
end

function setGlobalDifficulty(nDifficulty)
	-- Clamp difficulty between min and max
	nDifficulty = math.min(
		math.max(
			DifficultyManager.DIFFICULTY_MINIMUM, 
			nDifficulty), 
		DifficultyManager.DIFFICULTY_MAXIMUM
	)
	DB.setValue(DifficultyManager.DIFFICULTY_PATH, "number", nDifficulty);
end

function adjustGlobalDifficulty(nIncrement)
	local nDiff = DifficultyManager.getGlobalDifficulty();
	DifficultyManager.setGlobalDifficulty(nDiff + nIncrement);
end