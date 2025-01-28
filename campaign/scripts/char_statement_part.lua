local _sPath;
local _sOption;
local _nThreshold;


function onInit()
	if path and path[1] then
		_sPath = path[1]
	end

	local nodeActor = window.getDatabaseNode();
	if _sPath and nodeActor then
		local sNodePath = DB.getPath(nodeActor, "class", _sPath)
		DB.createNode(sNodePath)
		setValue("charsheet_statement_part", sNodePath)
	end

	DB.addHandler(DB.getPath(nodeActor, "class", _sPath, "link"), "onUpdate", onLinkUpdated)
	self.onLinkUpdated()

	self.initOption()
end

function onClose()
	local nodeActor = window.getDatabaseNode();
	if _sPath and nodeActor then
		DB.removeHandler(DB.getPath(nodeActor, "class", _sPath, "link"), "onUpdate", onLinkUpdated)
	end
	if _sOption and _nThreshold then
		OptionsManager.unregisterCallback(_sOption, onOptionChanged);
	end
end

function initOption()
	if option and option[1] then
		_sOption = option[1]
	end
	if valuethreshold and valuethreshold[1] then
		_nThreshold = tonumber(valuethreshold[1])
	end

	if _sOption and _nThreshold then
		OptionsManager.registerCallback(_sOption, onOptionChanged);
		self.onOptionChanged()
	end
end

function onLinkUpdated()
	subwindow.onLinkUpdated()
end

function onOptionChanged()
	if _sOption and _nThreshold then
		local nValue = tonumber(OptionsManager.getOption(_sOption))

		if nValue then
			setVisible(nValue >= _nThreshold);
		end
	end
end