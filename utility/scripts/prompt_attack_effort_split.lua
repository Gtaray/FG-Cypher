local rRoll
local rSource
local rTarget

function setRoll(source, target, roll)
	rSource = source
	rTarget = target
	rRoll = roll
end

function setEffort(nEffort)
	attack_effort.setValue(nEffort)
end

function increment_attack()
	attack_effort.setValue(attack_effort.getValue() + 1)
	damage_effort.setValue(damage_effort.getValue() - 1)
end

function increment_damage()
	attack_effort.setValue(attack_effort.getValue() - 1)
	damage_effort.setValue(damage_effort.getValue() + 1)
end

function roll()
	local rAction = ActionCost.getLastAction()

	if rAction then
		rRoll.nEffort = attack_effort.getValue()
		rRoll.nDamageEffort = damage_effort.getValue()
		ActionCost.performLastAction(rSource, rTarget, rRoll)
	end

	close()
end