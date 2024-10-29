-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	self.onHealthChanged();
end

function onFirstLayout()
	if self.isPC() then
		IntrusionManager.registerIntrusionMenu(self);
	end
end

function onMenuSelection(selection, subselection)
	local bHandled = false;
	if self.isPC() then
		local rActor = ActorManager.resolveActor(getDatabaseNode());
		bHandled = IntrusionManager.handleMenuSelection(selection, rActor);
	end

	if not bHandled then
		super.onMenuSelection(selection, subselection);
	end
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
		idelete.setVisible(ActorHealthManager.isDyingOrDeadStatus(sStatus));
	end
end

function linkPCFields()
	super.linkPCFields();

	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		damagetrack.setLink(DB.createChild(nodeChar, "wounds", "number"));

		mightmax.setLink(DB.createChild(nodeChar, "abilities.might.max", "number"));
		mightpool.setLink(DB.createChild(nodeChar, "abilities.might.current", "number"));

		speedmax.setLink(DB.createChild(nodeChar, "abilities.speed.max", "number"));
		speedpool.setLink(DB.createChild(nodeChar, "abilities.speed.current", "number"));

		intellectmax.setLink(DB.createChild(nodeChar, "abilities.intellect.max", "number"));
		intellectpool.setLink(DB.createChild(nodeChar, "abilities.intellect.current", "number"));

		armor.setLink(DB.createChild(nodeChar, "armor", "number"));
	end
end
