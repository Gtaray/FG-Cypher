---@diagnostic disable: undefined-global
-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	self.onHealthChanged();
end

function onLinkChanged()
	super.onLinkChanged();
	
	-- Show the correct fields depending on if this is a PC or NPC
	local bPC = self.isPC();
	name.setLine(not bPC);
	level.setVisible(not bPC);
	hp.setVisible(not bPC);
	wounds.setVisible(not bPC);
	intellectpool.setVisible(bPC);
	speedpool.setVisible(bPC);
	mightpool.setVisible(bPC);
	damagetrack.setVisible(bPC);
end

function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local _,sStatus,sColor = ActorHealthManager.getHealthInfo(rActor);
	
	wounds.setColor(sColor);
	damagetrack.setColor(sColor);
	status.setValue(sStatus);
	
	if not self.isPC() then
		idelete.setVisibility(ActorHealthManager.isDyingOrDeadStatus(sStatus));
	end
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(DB.createChild(nodeChar, "name", "string"), true);

		damagetrack.setLink(DB.createChild(nodeChar, "wounds", "number"));
		mightpool.setLink(DB.createChild(nodeChar, "abilities.might.current", "number"));
		speedpool.setLink(DB.createChild(nodeChar, "abilities.speed.current", "number"));
		intellectpool.setLink(DB.createChild(nodeChar, "abilities.intellect.current", "number"));

		armor.setLink(DB.createChild(nodeChar, "armor", "number"));
	end
end
