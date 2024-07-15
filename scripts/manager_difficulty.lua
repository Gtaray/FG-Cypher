-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if not Session.IsHost then
		return
	end

	DifficultyManager.initializeGlobalDifficulty()
	DifficultyManager.initializeGmiThreshold()
end

-------------------------------------------------------------------------------
-- DIFFICULTY
-------------------------------------------------------------------------------
DIFFICULTY_DEFAULT = 3
DIFFICULTY_MINIMUM = 1
DIFFICULTY_PATH = "global.difficulty";

function initializeGlobalDifficulty()
	local node = DB.findNode(DifficultyManager.DIFFICULTY_PATH);

	if not node then
		node = DB.createNode(DifficultyManager.DIFFICULTY_PATH, "number");
		DB.setValue(node, "", "number", DifficultyManager.DIFFICULTY_DEFAULT)
	end

	if node then
		local globalnode = DB.getParent(node);
		DB.setPublic(node, true);
		DB.setPublic(globalnode, true);
	end
end

function addDifficultyUpdateHandler(fHandler)
	DB.addHandler(DifficultyManager.DIFFICULTY_PATH, "onUpdate", fHandler);
end

function getGlobalDifficulty()
	if not OptionsManagerCypher.isGlobalDifficultyEnabled() then
		return nil;
	end
	return DB.getValue(DifficultyManager.DIFFICULTY_PATH, DifficultyManager.DIFFICULTY_DEFAULT);
end

function setGlobalDifficulty(nDifficulty)
	-- Clamp difficulty between min and max
	nDifficulty = math.min(
		math.max(
			DifficultyManager.DIFFICULTY_MINIMUM, 
			nDifficulty), 
		OptionsManagerCypher.getMaxTarget()
	)
	DB.setValue(DifficultyManager.DIFFICULTY_PATH, "number", nDifficulty);
end

function adjustGlobalDifficulty(nIncrement)
	if not OptionsManagerCypher.isGlobalDifficultyEnabled() then
		return nil;
	end
	
	local nDiff = DifficultyManager.getGlobalDifficulty();
	DifficultyManager.setGlobalDifficulty(nDiff + nIncrement);
end

-------------------------------------------------------------------------------
-- GMI THRESHOLD
-------------------------------------------------------------------------------
GMI_DEFAULT = 1
GMI_MINIMUM = 1
GMI_MAXIMUM = 20
GMI_PATH = "global.gmi_threshold";

function initializeGmiThreshold()
	local node = DB.findNode(DifficultyManager.GMI_PATH);

	if not node then
		node = DB.createNode(DifficultyManager.GMI_PATH, "number");
		DB.setValue(node, "", "number", DifficultyManager.GMI_DEFAULT)
	end

	if node then
		local globalnode = DB.getParent(node);
		DB.setPublic(node, true);
		DB.setPublic(globalnode, true);
	end
end

function addGmiThresholdUpdateHandler(fHandler)
	DB.addHandler(DifficultyManager.GMI_PATH, "onUpdate", fHandler);
end

function getGmiThreshold()
	return DB.getValue(DifficultyManager.GMI_PATH, DifficultyManager.GMI_DEFAULT);
end

function setGmiThreshold(nDifficulty)
	-- Clamp difficulty between min and max
	nDifficulty = math.min(
		math.max(
			DifficultyManager.GMI_MINIMUM, 
			nDifficulty), 
		DifficultyManager.GMI_MAXIMUM
	)
	DB.setValue(DifficultyManager.GMI_PATH, "number", nDifficulty);
end

function adjustGmiThreshold(nIncrement)
	local nDiff = DifficultyManager.getGmiThreshold();
	DifficultyManager.setGmiThreshold(nDiff + nIncrement);
end