function onInit()
	local node = getDatabaseNode()
	DB.addHandler(DB.getPath(node, "*"), "onUpdate", onDataChanged);

	updateSummary();
end

function onClose()
	local node = getDatabaseNode()
	DB.removeHandler(DB.getPath(node, "*"), "onUpdate", onDataChanged);
end

function setLink(sClass, sRecord)
	if (sClass or "") == "" or (sRecord or "") == "" then
		return;
	end
	if not (sClass == "item" or sClass == "ability") then
		return
	end

	local node = getDatabaseNode();

	DB.setValue(node, "link", "windowreference", sClass, sRecord);

	if sClass == "item" then
		DB.setValue(node, "property", "string", "Item")
	elseif sClass == "ability" then
		DB.setValue(node, "property", "string", "Ability")
	end
end

function onDataChanged()
	updateSummary();
end

function getSummaryText()
	local sText = CharModManager.getCharacterModificationSummary(getDatabaseNode());
	return sText;
end

function updateSummary()
	local sText = getSummaryText();
	summary.setValue(StringManager.capitalize(sText))
end

function update(bReadOnly)
end