function onInit()
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "stage"), "onUpdate", onStageUpdated)
	onStageUpdated();
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "stage"), "onUpdate", onStageUpdated)
end

function onStageUpdated()
	updateVisibility();
end

function onEditModeChanged()
	updateVisibility();
end

function updateVisibility()
	local node = getDatabaseNode();
	local nStage = DB.getValue(node, "stage", 0)
	local bEditMode = WindowManager.getEditMode(self, "sheet_iedit");

	-- If the arc is done, we default to collapsing all headers
	if nStage == 5 and not bEditMode then
		header.toggle(false);
	end
end