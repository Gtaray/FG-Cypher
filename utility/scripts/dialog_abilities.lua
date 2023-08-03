local nMax = 0;
local nMinTier = 6;
local nMaxTier = 1;

function setData(aAbilities, aFlavorAbilities, nCount)
	nMax = nCount;

	if not nMax then
		label_abilities_remaining.setVisible(false);
		abilities_remaining.setVisible(false);
	else
		abilities_remaining.setValue(nCount);
	end

	lists.clear();

	-- This is here to keep track of what abilities are added so that
	-- the same ability isn't added in both the Type and Flavor sections
	local aAbilityTracker = {};
	for _, rAbility in ipairs(aAbilities) do
		local node = DB.findNode(rAbility.sRecord)
		if node then
			if rAbility.nTier < nMinTier then
				nMinTier = rAbility.nTier;
			end
			if rAbility.nTier > nMaxTier then
				nMaxTier = rAbility.nTier;
			end

			lists.addTypeAbility(node, rAbility.nTier);
			aAbilityTracker[rAbility.sRecord] = true;
		end
	end

	for _, rAbility in ipairs(aFlavorAbilities) do
		local node = DB.findNode(rAbility.sRecord)
		if not aAbilityTracker[rAbility.sRecord] and node then
			lists.addFlavorAbility(node, rAbility.nTier);
		end
	end

	label_tier.setVisible(nMinTier ~= nMaxTier);
	increase_tier.setVisible(nMinTier ~= nMaxTier);
	decrease_tier.setVisible(nMinTier ~= nMaxTier);
	tier.setValue(nMaxTier);
end

function getData()
	return lists.getData();
end

function isValid()
	return not nMax or getRemaining() == 0;
end

function getNumberSelected()
	return lists.getNumberSelected();
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