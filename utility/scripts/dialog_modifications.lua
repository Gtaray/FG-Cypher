function addModification(rData)
	-- If the modification isn't in the list of accepted ones, then bail
	local sWinClass = aWindows[rData.sType or ""];
	if not sWinClass then
		return;
	end

	if rData.sType == "stats" then
		local w = self.createWindow("dialog_statpools")

	elseif rData.sType == "edge" then
		local w = self.createWindow("dialog_edge")

	end
	stats.subwindow.setData(rData.nMight, rData.nSpeed, rData.nIntellect, rData.nFloatingStats);
end

function createWindow(sClass)
	return modifications.subwindow.modifications.createWindowWithClass(sClass)
end

function processOK()
	if fCallback then
		rData.nMight, rData.nSpeed, rData.nIntellect = stats.subwindow.getData();
		fCallback(rData);
	end
	close()
end

function processCancel()
	close();
end