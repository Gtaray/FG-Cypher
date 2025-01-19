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
	
	updateStageVisibility();
end

function onEditModeChanged()
	updateStageVisibility();
end

function updateStageVisibility()
	local node = getDatabaseNode();
	local nStage = DB.getValue(node, "stage", 1)
	local bEditMode = WindowManager.getEditMode(self, "sheet_iedit");

	notstarted.subwindow.complete.setVisible(nStage == 1);

	if (nStage == 2 or bEditMode) and header_progress.isCollapsed() then
		header_progress.toggle(true)
	end
	header_progress.setVisible(bEditMode or nStage == 2 or nStage == 5);
	progress_iadd.setVisible(bEditMode or nStage == 2);
	progress.setVisible(bEditMode or nStage == 2 or nStage == 5);
	progress.subwindow.complete.setVisible(nStage == 2);

	if (nStage == 3 or bEditMode) and header_climax.isCollapsed() then
		header_climax.toggle(true)
	end
	header_climax.setVisible(bEditMode or nStage == 3 or nStage == 5);
	climax.setVisible(bEditMode or nStage == 3 or nStage == 5);
	climax.subwindow.complete.setVisible(nStage == 3);

	if (nStage == 4 or bEditMode) and header_resolution.isCollapsed() then
		header_resolution.toggle(true)
	end
	header_resolution.setVisible(bEditMode or nStage == 4 or nStage == 5)
	resolution.setVisible(bEditMode or nStage == 4 or nStage == 5);
	resolution.subwindow.complete.setVisible(nStage == 4);

	if nStage == 5 and not bEditMode then
		header_progress.toggle(false);
		header_climax.toggle(false);
		header_resolution.toggle(false);
	end
end

function nextPhase()
	local node = getDatabaseNode();
	local nStage = DB.getValue(node, "stage", 1);

	if nStage == 1 then
		self.startArc()
	elseif nStage == 2 then
		self.completeProgress();
	elseif nStage == 3 then
		self.completeClimax();
	elseif nStage == 4 then
		self.completeResolution();
	end
end

function startArc()
	local nodeArc = getDatabaseNode();
	local nodeChar = DB.getChild(nodeArc, "...");

	-- If the prompt returns true, it means we the prompt wasn't shown and we can just add the arc
	if PromptManager.promptCharacterArcStart(nodeArc) then
		CharManager.buyNewCharacterArc(nodeChar, nodeArc);
	end
end

function completeStep()
end

function completeProgress()
	local nodeArc = getDatabaseNode();
	local nodeChar = DB.getChild(nodeArc, "...");

	-- If the prompt returns true, it means we the prompt wasn't shown and we can just add the arc
	if PromptManager.promptCharacterArcProgress(nodeArc) then
		CharManager.completeCharacterArcProgress(nodeChar, nodeArc);
	end
end

function completeClimax()
	local nodeArc = getDatabaseNode();
	local nodeChar = DB.getChild(nodeArc, "...");

	-- If the prompt returns true, it means we the prompt wasn't shown and we can just add the arc
	if PromptManager.promptCharacterArcClimax(nodeArc) then
		CharManager.completeCharacterArcClimax(nodeChar, nodeArc);
	end
end

function completeResolution()
	local nodeArc = getDatabaseNode();
	local nodeChar = DB.getChild(nodeArc, "...");

	-- If the prompt returns true, it means we the prompt wasn't shown and we can just add the arc
	if PromptManager.promptCharacterArcResolution(nodeArc) then
		CharManager.completeCharacterArcResolution(nodeChar, nodeArc);
	end
end