function promptStepForCompletion()
	local nodeStep = getDatabaseNode()
	if PromptManager.promptCharacterArcStep(nodeStep) then
		local nodeArc = DB.getChild(nodeStep, "...");
		local nodeChar = DB.getChild(nodeArc, "...");
		CharArcManager.completeCharacterArcStep(nodeChar, nodeStep);
	end

	return true;
end