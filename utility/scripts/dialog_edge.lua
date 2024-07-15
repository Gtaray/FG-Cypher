function clear()
	edge.closeAll();
end

function setData(rEdgeOptions)
	local nTotal = 0;
	for i, aOptions in ipairs(rEdgeOptions) do
		edge.addEntry(aOptions)
		nTotal = nTotal + #aOptions;
	end
	return nTotal;
end

function getData()
	local rEdge = {
		["might"] = 0,
		["speed"] = 0,
		["intellect"] = 0,
	}
	for _, w in pairs(edge.getWindows()) do
		local sStat = w.getData();
		if (sStat or "-") ~= "-" then
			rEdge[sStat] = rEdge[sStat] + 1;
		end
	end

	return rEdge;
end

function isValid()
	for _, w in pairs(edge.getWindows()) do
		local sStat = w.getData();
		if (sStat or "-") == "-" then
			return false;
		end
	end

	return true;
end

function update()
	if parentcontrol and parentcontrol.window and parentcontrol.window.updateStats then
		parentcontrol.window.updateStats();
	end
end