local _fInitialize;
local _sPath; -- Relative path to the actor node from the window's DB node
local _actorNode;
local _sLabels;
local _sValues;

local _tLabels = {};
local _tValues = {};

function onInit()
	_fInitialize = super.initialize;
	super.initialize = initialize;

	_actorNode = getActorNode();

	if _actorNode then
		DB.addHandler(DB.getPath(_actorNode, "custom_pools"), "onChildAdded", updateCustomPools)
		DB.addHandler(DB.getPath(_actorNode, "custom_pools"), "onChildDeleted", updateCustomPools)
		DB.addHandler(DB.getPath(_actorNode, "custom_pools.*.name"), "onUpdate", updateCustomPools)
	end

	-- Do onInit so that everything gets set up correctly
	super.onInit()
end

function onClose()
	if _actorNode then
		DB.removeHandler(DB.getPath(_actorNode, "custom_pools"), "onChildAdded", updateCustomPools)
		DB.removeHandler(DB.getPath(_actorNode, "custom_pools"), "onChildDeleted", updateCustomPools)
		DB.removeHandler(DB.getPath(_actorNode, "custom_pools.*.name"), "onUpdate", updateCustomPools)
	end
end

function onValueChanged()
	if super and super.onValueChanged then
		super.onValueChanged()
	end
	if window and window.update then
		window.update();
	end
end

function initialize(sLabels, sValues, sEmptyLabel, sInitialValue)
	-- We only ever want to set these once, when the control is first initialized
	if not _sLabels then
		_sLabels = sLabels
	end
	if not _sValues then
		_sValues = sValues
	end

	if _actorNode then
		for _, pool in ipairs(ActorManagerCypher.getCustomStatPools(_actorNode)) do
			sLabels = string.format("%s|%s", sLabels, pool.sName);
			sValues = string.format("%s|%s", sValues, pool.sName:lower());
		end
	else
		local sCustom = Interface.getString("char_label_custom");
		sLabels = string.format("%s|%s", sLabels, sCustom);
		sValues = string.format("%s|%s", sValues, sCustom:lower());
	end

	-- Since we can't get these tables from the base object, we have to save it here
	if sLabels then
		_tLabels = StringManager.split(sLabels, "|", true);
	end
	if sValues then
		_tValues = StringManager.split(sValues, "|", true);
	end

	if _fInitialize then
		_fInitialize(sLabels, sValues, sEmptyLabel, sInitialValue);
	end
end

function updateCustomPools()
	-- Store the existing string value
	local sInitialValue = super.getStringValue();
	local nInitialIndex = getIndexForValue(sInitialValue);

	-- Re-initialize to update with new custom pools
	super.initialize(_sLabels, _sValues);

	-- If the value exists then we don't have to do anything other than
	-- sync the data so the control displays the right index.
	if doesCustomValueExist(sInitialValue) then
		super.update();
		return;
	end

	-- The value that the cycler was set to no longer exists
	-- so first we try setting the value to match the index
	-- (in case the custom pool was renamed, but otherwise keeps the same index)
	local sNewValue = getValueAtIndex(nInitialIndex);
	if sNewValue then
		super.setStringValue(sNewValue)
		super.update();
		return;
	end

	-- At this point the custom pool was removed, and the index is now out of range of the array
	-- so all we can do is reset to an empty value
	super.setStringValue("");
	super.update();
end

-- Returns the index of the value in _tValues if it exists
-- Or nil if not.
function doesCustomValueExist(sValue)
	return getIndexForValue(sValue) ~= nil
end

function getIndexForValue(sValue)
	for index, value in ipairs(_tValues) do
		if sValue == value then
			return index;
		end
	end
end

function getValueAtIndex(nIndex)
	if (nIndex or 0) > #_tValues then
		return;
	end

	return _tValues[nIndex]
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