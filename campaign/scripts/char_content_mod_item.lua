function onInit()
	local node = getDatabaseNode()
	DB.addHandler(DB.getPath(node, "*"), "onUpdate", onDataChanged);

	updateSummary();
end

function onClose()
	local node = getDatabaseNode()
	DB.removeHandler(DB.getPath(node, "*"), "onUpdate", onDataChanged);
end

function onDataChanged()
	updateSummary();
end

function getSummaryText()
	return CharModificationManager.getCharacterModificationSummary(getDatabaseNode());
end

function updateSummary()
	local sText = getSummaryText();
	summary.setValue(StringManager.capitalize(sText))
end

function update(bReadOnly)
end