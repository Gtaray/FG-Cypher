local _sPrev = "previous";
local _sNext = "next";
local _sHighlight = "highlight"
local _tStages = {
	["opening"] = 1,
	["inprogress"] = 2,
	["climax"] = 3,
	["resolution"] = 4
}
local _aStages = {
	[1] = "opening",
	[2] = "inprogress",
	[3] = "climax",
	[4] = "resolution"
}
local _aDisplay = {
	[1] = "Opening",
	[2] = "In Progress",
	[3] = "Climax",
	[4] = "Resolution"
}

function onInit()
	self.updateTitle();
	self.updateStageTooltips();
	self.resetIcon();
end

function updateTitle()
	local sText = name.getValue()
	if (sText or "") == "" then
		sText = name.getEmptyText();
	end

	title.setValue(
		string.format("%s - %s", 
			sText, 
			_aDisplay[self.getCurrentStage()]
		)
	);
end

function onStageClicked(sControlName)
	local nClickedStage = _tStages[sControlName];
	local nCur = self.getCurrentStage();

	if nClickedStage == nCur then
		local w = self.openRecordWindow();

	elseif nClickedStage > nCur then
		self.nextStage();
		local w = self.openRecordWindow();

		-- If we clicked on the in progress stage, then we want to add a new 
		-- step after opening
		if nClickedStage == 2 then
			w.addStep();
		end

	elseif nClickedStage < nCur then
		self.previousStage();

	end
	self.onStageHover(sControlName, true); -- Update the icon
end

function openRecordWindow()
	-- Open the editor and set the tab to the current stage
	local w = Interface.openWindow("record_arc", getDatabaseNode());
	w.setTab(self.getCurrentStage());
	return w;
end

function onStageHover(sControlName, bHover)
	if not bHover then
		self.resetIcon()
		return;
	end

	local nHover = _tStages[sControlName];
	local nCur = self.getCurrentStage();

	local sIcon = nil;
	if nHover == nCur then
		sIcon = string.format("arc_%s_%s", _aStages[nCur], _sHighlight);
	elseif nHover > nCur then
		sIcon = string.format("arc_%s_%s", _aStages[nCur], _sNext);
	elseif nHover < nCur then
		sIcon = string.format("arc_%s_%s", _aStages[nCur], _sPrev);
	end

	if not sIcon then
		return;
	end

	icon.setIcon(sIcon);
end

function resetIcon()
	local sIcon = string.format("arc_%s", _aStages[self.getCurrentStage()]);
	icon.setIcon(sIcon);
end

function updateStageTooltips()
	self.updateStageTooltip("opening");
	self.updateStageTooltip("inprogress");
	self.updateStageTooltip("climax");
	self.updateStageTooltip("resolution");
end

function updateStageTooltip(sControl)
	local nCur = self.getCurrentStage();
	local sStage = _aStages[nCur];
	local sMode;

	if nCur == _tStages[sControl] then
		sMode = _sHighlight;
	elseif nCur > _tStages[sControl] then
		sMode = _sPrev;
	elseif nCur < _tStages[sControl] then
		sMode = _sNext;
	end

	-- This shouldn't happen, but just in case
	if not sMode and not sStage then
		return;
	end

	local sRes = string.format("char_tooltip_arc_%s_%s", sStage, sMode)
	self[sControl].setTooltipText(Interface.getString(sRes));
end

function getCurrentStage()
	return currentStage.getValue();
end

function nextStage()
	local nCur = self.getCurrentStage();
	if nCur == 4 then
		return;
	end

	nCur = nCur + 1;
	currentStage.setValue(nCur);
	self.onStageHover(_aStages[nCur], true);
end

function previousStage()
	local nCur = self.getCurrentStage();
	if nCur == 1 then
		return;
	end

	nCur = nCur - 1;
	currentStage.setValue(nCur);
	self.onStageHover(_aStages[nCur], true);
end