local nMax = 0;
function setData(aRecords, nCount)
	nMax = nCount;

	if not nMax then
		label_abilities_remaining.setVisible(false);
		abilities_remaining.setVisible(false);
	else
		abilities_remaining.setValue(nCount);
	end

	for _, sRecord in ipairs(aRecords) do
		local node = DB.findNode(sRecord)
		if node then
			abilities.addEntry(node);
		end
	end
end

function getData()
	local aAbilities = {};
	for _,w in pairs(abilities.getWindows()) do
		if w.selected.getValue() == 1 then
			local _, sRecord = w.shortcut.getValue();
			local nMultiselect = w.multiselect.getValue() or 1;
			local node = DB.findNode(sRecord);
			if node then
				table.insert(aAbilities, {
					node = node,
					multiselect = nMultiselect,
				});
			end
		end
	end
	return aAbilities;
end

function isValid()
	return not nMax or getRemaining() == 0;
end

function getNumberSelected()
	local nSelections = 0;
	for _,w in pairs(abilities.getWindows()) do
		if w.selected.getValue() == 1 then
			nSelections = nSelections + (w.multiselect.getValue() or 1);
		end
	end
	return nSelections;
end

function hasRemaining()
	-- if no max is set, always return true
	if not nMax then
		return true;
	end
	return getRemaining() > 0;
end

function getRemaining()
	return abilities_remaining.getValue();
end

function onSelectionChanged()
	if nMax then
		local nRemaining = nMax - self.getNumberSelected();
		abilities_remaining.setValue(nRemaining);
		parentcontrol.window.updateAbilities();
	end
end