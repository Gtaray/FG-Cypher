function addEntry(sClass, sRecord)
	local w = createWindow();
	if w then
		w.link.setValue(sClass, sRecord);
	end
	return w;
end

-- We never need to worry about w1 and w2 having different visibility
-- states for tier and given controls, because the visibility for those
-- controls are defined at the list level.
-- When these controls aren't visible, they will always be the same,
-- and thus sorting will only apply to names.
function onSortCompare(w1, w2)
	if w1.tier.getValue() ~= w2.tier.getValue() then
		return w1.tier.getValue() > w2.tier.getValue()
	end

	if w1.given.getValue() ~= w2.given.getValue() then
		return w1.given.getValue() < w2.given.getValue()
	end

	return w1.name.getValue() > w2.name.getValue()
end

function update(bReadOnly)
	for _,w in ipairs(getWindows()) do
		w.update(bReadOnly);
	end
end