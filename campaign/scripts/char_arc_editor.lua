local _aStages = {
	"Not Started",
	"In Progress",
	"Climax",
	"Resolution",
	"Complete"
}
local _aStageIndexes = {}
local _bUpdating = false;

function onInit()
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "stage"), "onUpdate", onStageUpdated)

	for i, s in ipairs(_aStages) do
		_aStageIndexes[s] = i
	end

	stage.addItems(getStages());

	onStageUpdated();
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "stage"), "onUpdate", onStageUpdated)
end

function onStageUpdated()
	_bUpdating = true;
	local node = getDatabaseNode();
	local nStage = DB.getValue(node, "stage", 0);
	local sStage = getStage(nStage);
	stage.setListValue(sStage);
	_bUpdating = false;
end

function onStageSelected()
	if _bUpdating then
		return;
	end

	local sStage = stage.getSelectedValue();
	local nStage = getStageIndex(sStage);
	DB.setValue(getDatabaseNode(), "stage", "number", nStage)
end

function getStages()
	return _aStages
end

function getStage(nIndex)
	return _aStages[nIndex]
end

function getStageIndex(sStage)
	return _aStageIndexes[sStage];
end