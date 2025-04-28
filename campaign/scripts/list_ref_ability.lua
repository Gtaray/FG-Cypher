--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function addEntry(sClass, sRecord)
	local w = createWindow();
	if w then
		w.link.setValue(sClass, sRecord);
	end
	return w;
end

function update(bReadOnly)
	for _,w in ipairs(getWindows()) do
		w.update(bReadOnly);
	end
end