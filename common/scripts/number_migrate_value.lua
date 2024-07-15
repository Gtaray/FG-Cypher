function onInit()
	if super and super.onInit then
		super.onInit()
	end

	local node = window.getDatabaseNode();
	local targetnode = nil;
	if migrate and migrate[1] then
		targetnode = DB.getChild(node, migrate[1])
	end

	-- Confirm that the old node actually exists
	if not targetnode then
		return
	end

	local nVal = DB.getValue(node, migrate[1], 0)
	setValue(nVal);
	DB.deleteNode(targetnode)
end