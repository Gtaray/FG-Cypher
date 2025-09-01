local _actorNode;
local _fGetOptionItems;

function onInit()
	_actorNode = getActorNode();
	_fGetOptionItems = super.getOptionItems;
	super.getOptionItems = getOptionItems;

	if _actorNode then
		DB.addHandler(DB.getPath(_actorNode, "custom_pools"), "onChildAdded", updateCustomPools)
		DB.addHandler(DB.getPath(_actorNode, "custom_pools"), "onChildDeleted", updateCustomPools)
		DB.addHandler(DB.getPath(_actorNode, "custom_pools.*.name"), "onUpdate", updateCustomPools)
	end

	-- Do onInit so that everything gets set up correctly
	if super and super.onInit then
		super.onInit()
	end
end

function onClose()
	if _actorNode then
		DB.removeHandler(DB.getPath(_actorNode, "custom_pools"), "onChildAdded", updateCustomPools)
		DB.removeHandler(DB.getPath(_actorNode, "custom_pools"), "onChildDeleted", updateCustomPools)
		DB.removeHandler(DB.getPath(_actorNode, "custom_pools.*.name"), "onUpdate", updateCustomPools)
	end
end

function getActorNode()
	local currentNode = window.getDatabaseNode();
	local parentNode = DB.getParent(currentNode)
	
	while DB.getName(parentNode) ~= "charsheet" do
		currentNode = parentNode;
		parentNode = DB.getParent(currentNode)

		if parentNode == nil then
			-- Couldn't find the actor node
			return;
		end
	end

	return currentNode;
end

function onValueChanged()
	if super and super.onValueChanged then
		super.onValueChanged()
	end

	if window and window.update then
		window.refreshDisplay();
	end
end

--
--	DATA OPTIONS
--

function refreshData()
	local tData = self.getOptionData();
	local tItems = getOptionItems(tData);
	self.setItems(tItems);
end

function getOptionItems(tData)
	local tItems = _fGetOptionItems(tData)

	if _actorNode then
		for _, pool in ipairs(CharStatManager.getCustomStatPools(_actorNode)) do
			local pool = { sValue = pool.sName:lower(), sText = pool.sName }
			table.insert(tItems, pool);
		end
	else
		-- For any other non-PC object that has a stat cycler on it.
		local sCustom = Interface.getString("char_label_custom");
		table.insert(tItems, { sValue = sCustom:lower(), sText = sCustom });
	end

	return tItems;
end

--
-- CUSTOM POOLS
-- 
function updateCustomPools()
	-- Store the existing string value
	local sInitialValue = self.getValue();
	local nInitialIndex = self.getIndex();

	-- Clear and refresh data with updated custom pools
	refreshData();

	-- If the value exists then we don't have to do anything other than
	-- sync the data so the control displays the right index.
	if self.doesCustomValueExist(sInitialValue) then
		self.refreshDisplay();
		return;
	end

	-- The value that the cycler was set to no longer exists
	-- so first we try setting the value to match the index
	-- (in case the custom pool was renamed, but otherwise keeps the same index)
	local sNewValue = getValueAtIndex(nInitialIndex);
	if sNewValue then
		self.setValue(sNewValue);
		self.refreshDisplay();
		return;
	end

	-- At this point the custom pool was removed, and the index is now out of range of the array
	-- so all we can do is reset to an empty value
	self.setValue("");
	self.refreshDisplay();
end

function doesCustomValueExist(sValue)
	return self.hasValue(sValue);
end

function getValueAtIndex(nIndex)
	if (nIndex or 0) > self.getValueCount() then
		return;
	end

	return self.getValuesData()[nIndex]
end