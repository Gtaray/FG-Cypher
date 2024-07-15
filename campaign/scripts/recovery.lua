-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	might_new.setValue(might_current.getValue());
	speed_new.setValue(speed_current.getValue());
	intellect_new.setValue(intellect_current.getValue());

	self.update();
end

function setRecoveryAmount(n)
	recovery_remaining.setValue(n);
end
function apply()
	ActionRecovery.applyRecovery(getDatabaseNode(), might_new.getValue(), speed_new.getValue(), intellect_new.getValue(), recovery_remaining.getValue());
end
function update()
	local bCanIncrease = (recovery_remaining.getValue() > 0);

	button_might_decrease.setVisible(might_current.getValue() < might_new.getValue());
	button_might_increase.setVisible(bCanIncrease and (might_new.getValue() < might_max.getValue()));

	button_speed_decrease.setVisible(speed_current.getValue() < speed_new.getValue());
	button_speed_increase.setVisible(bCanIncrease and (speed_new.getValue() < speed_max.getValue()));

	button_intellect_decrease.setVisible(intellect_current.getValue() < intellect_new.getValue());
	button_intellect_increase.setVisible(bCanIncrease and (intellect_new.getValue() < intellect_max.getValue()));
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
		recovery_remaining.setValue(recovery_remaining.getValue() - 1);
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
		recovery_remaining.setValue(recovery_remaining.getValue() + 1);
	end

	update();
end
