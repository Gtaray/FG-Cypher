local nMax = 0;
local nMinTier = 6;
local nMaxTier = 1;

function setData(aAbilities, nCount)
	nMax = nCount;

	if not nMax then
		label_abilities_remaining.setVisible(false);
		abilities_remaining.setVisible(false);
	else
		abilities_remaining.setValue(nCount);
	end

	abilities.closeAll();
	for _, rAbility in ipairs(aAbilities) do
		local node = DB.findNode(rAbility.sRecord)
		if node then
			if rAbility.nTier < nMinTier then
				nMinTier = rAbility.nTier;
			end
			if rAbility.nTier > nMaxTier then
				nMaxTier = rAbility.nTier;
			end

			abilities.addEntry(node, rAbility.nTier);
		end
	end

	label_tier.setVisible(nMinTier ~= nMaxTier);
	increase_tier.setVisible(nMinTier ~= nMaxTier);
	decrease_tier.setVisible(nMinTier ~= nMaxTier);
	tier.setValue(nMaxTier);
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
		if parentcontrol.window.updateAbilities then
			parentcontrol.window.updateAbilities();
		end
	end
end

function onIncrease()
	local nCurrentTier = tier.getValue();
	if nCurrentTier == nMaxTier then
		return;
	end

	tier.setValue(math.min(nCurrentTier + 1, nMaxTier));
end

function onDecrease()
	local nCurrentTier = tier.getValue();
	if nCurrentTier == nMinTier then
		return;
	end

	tier.setValue(math.max(nCurrentTier - 1, nMinTier));
end