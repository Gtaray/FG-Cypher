-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

DIFFICULTY_DEFAULT = 3
DIFFICULTY_MINIMUM = 1
DIFFICULTY_MAXIMUM = 10
DIFFICULTY_PATH = "global.difficulty";
local node = nil;

function onInit()
	initializeGlobalDifficulty()
end

function initializeGlobalDifficulty()
	node = DB.findNode(DifficultyManager.DIFFICULTY_PATH);

	if Session.IsHost and not node then
		node = DB.createNode(DifficultyManager.DIFFICULTY_PATH, "number");
		DB.setValue(node, "", "number", DifficultyManager.DIFFICULTY_DEFAULT)
	end

	if node then
		local globalnode = DB.getParent(node);
		DB.setPublic(globalnode, true);
	end
end

function addUpdateHandler(fHandler)
	DB.addHandler(DifficultyManager.DIFFICULTY_PATH, "onUpdate", fHandler);
end

function getGlobalDifficulty()
	return DB.getValue(node, "", DifficultyManager.DIFFICULTY_DEFAULT);
end

function setGlobalDifficulty(nDifficulty)
	-- Clamp difficulty between min and max
	nDifficulty = math.min(
		math.max(
			DifficultyManager.DIFFICULTY_MINIMUM, 
			nDifficulty), 
		DifficultyManager.DIFFICULTY_MAXIMUM
	)
	DB.setValue(node, "", "number", nDifficulty);
end

function adjustGlobalDifficulty(nIncrement)
	local nDiff = DifficultyManager.getGlobalDifficulty();
	DifficultyManager.setGlobalDifficulty(nDiff + nIncrement);
end