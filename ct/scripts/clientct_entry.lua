---@diagnostic disable: undefined-global
-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	onHealthChanged();
end

function onFactionChanged()
	super.onFactionChanged();
	updateHealthDisplay();
end

function onLinkChanged()
	updateHealthDisplay();
end

function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local sColor = ActorHealthManager.getHealthColor(rActor);
	
	wounds.setColor(sColor);
	damagetrack.setColor(sColor);
	status.setColor(sColor);
end

function updateHealthDisplay()
	local sOption;
	if friendfoe.getValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end
	
	if sOption == "detailed" then
		local sClass,_ = link.getValue();
		local bPC = (sClass == "charsheet");
		
		hp.setVisible(not bPC);
		wounds.setVisible(not bPC);
		intellectpool.setVisible(bPC);
		speedpool.setVisible(bPC);
		mightpool.setVisible(bPC);
		damagetrack.setVisible(bPC);

		status.setVisible(false);
	elseif sOption == "status" then
		hp.setVisible(false);
		wounds.setVisible(false);
		intellectpool.setVisible(false);
		speedpool.setVisible(false);
		mightpool.setVisible(false);
		damagetrack.setVisible(false);

		status.setVisible(true);
	else
		hp.setVisible(false);
		wounds.setVisible(false);
		intellectpool.setVisible(false);
		speedpool.setVisible(false);
		mightpool.setVisible(false);
		damagetrack.setVisible(false);

		status.setVisible(false);
	end
end
