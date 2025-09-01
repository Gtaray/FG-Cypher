function setOptions(aOptions)
	local tItems = { sValue = "", sText = Interface.getString() };
	for _, sOption in ipairs(aOptions) do
		table.insert(tItems, Interface.getString(sOption));
	end

	edge.setItems(tItems);
	edge.setValue("");
end

function getData()
	return (edge.getValue() or ""):lower();
end

function update()
	windowlist.window.update();
end