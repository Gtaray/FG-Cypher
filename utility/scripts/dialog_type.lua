-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local fCallback;
local rData;

function setData(data, callback)
	rData = data;
	fCallback = callback;

	local bShowStats = rData.nFloatingStats > 0;
	stats.subwindow.setData(rData.nMight, rData.nSpeed, rData.nIntellect, rData.nFloatingStats);
	stats.setVisible(bShowStats);
end

function processOK()
	if fCallback then
		fCallback(rData);
	end
	close();
end

function processCancel()
	close();
end
