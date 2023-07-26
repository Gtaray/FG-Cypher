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
	elseif nClickedStage > nCur then
		self.nextStage();
	elseif nClickedStage < nCur then
		self.previousStage();
	end
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