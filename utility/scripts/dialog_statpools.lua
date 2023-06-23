-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
end

function setData(nMight, nSpeed, nIntellect, nFlex)
	might_current.setValue(nMight);
	speed_current.setValue(nSpeed);
	intellect_current.setValue(nIntellect);

	might_new.setValue(might_current.getValue());
	speed_new.setValue(speed_current.getValue());
	intellect_new.setValue(intellect_current.getValue());

	setFloatingStatAmount(nFlex);

	self.update();
end

function getData()
	return might_new.getValue(), speed_new.getValue(), intellect_new.getValue();
end

function setFloatingStatAmount(n)
	stats_remaining.setValue(n);
end

function update()
	local bCanIncrease = (stats_remaining.getValue() > 0);

	button_might_decrease.setVisible(might_current.getValue() < might_new.getValue());
	button_might_increase.setVisible(bCanIncrease);

	button_speed_decrease.setVisible(speed_current.getValue() < speed_new.getValue());
	button_speed_increase.setVisible(bCanIncrease);

	button_intellect_decrease.setVisible(intellect_current.getValue() < intellect_new.getValue());
	button_intellect_increase.setVisible(bCanIncrease);
end

function onIncrease(sStat)
	local bIncreased = true;

	if sStat == "might" then
		might_new.setValue(might_new.getValue() + 1);
	elseif sStat == "speed" then
		speed_new.setValue(speed_new.getValue() + 1);
	elseif sStat == "intellect" then
		intellect_new.setValue(intellect_new.getValue() + 1);
	else
		bIncreased = false;
	end

	if bIncreased then
		stats_remaining.setValue(stats_remaining.getValue() - 1);
	end

	self.update();
end
function onDecrease(sStat)
	local bDecreased = true;

	if sStat == "might" then
		might_new.setValue(might_new.getValue() - 1);
	elseif sStat == "speed" then
		speed_new.setValue(speed_new.getValue() - 1);
	elseif sStat == "intellect" then
		intellect_new.setValue(intellect_new.getValue() - 1);
	else
		bDecreased = false;
	end

	if bDecreased then
		stats_remaining.setValue(stats_remaining.getValue() + 1);
	end

	self.update();
end
