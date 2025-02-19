local _sStat;

function onInit()
	if parentcontrol.stat and parentcontrol.stat[1] then
		_sStat = parentcontrol.stat[1]
	end

	title.setValue(Interface.getString("char_title_" .. _sStat))
end

function getActorNode()
	return DB.getChild(getDatabaseNode(), "...");
end

function getStat()
	return _sStat
end