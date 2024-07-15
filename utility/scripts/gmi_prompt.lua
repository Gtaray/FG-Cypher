local rActor;

function getSourceNode()
	return ActorManager.getCreatureNode(rActor);
end

function getSourceName()
	return ActorManager.getDisplayName(rActor)
end

function setActor(actor)
	if not actor then
		return;
	end

	rActor = actor

	local sResource = IntrusionManager.getIntrusionResourceText(false)
	description.setValue(string.format(
		Interface.getString("gmi_prompt_description"), 
		getSourceName(),
		sResource
	));

	-- Now that we have set the actor, we can update the refuse button's tooltip
	-- since it needs to check the xp value of the actor
	refuse.update();
end

function setOptions(rCharacters)
	for i, rChar in ipairs(rCharacters) do
		characters.addEntry(rChar.sNode, rChar.sToken, rChar.sName, rChar.nXpOrHeroPoints);		
	end
end

function onSelect(sNode, sName)
	selectedname.setValue(sName);
	selected.setValue(sNode);
end

function acceptIntrusion()
	IntrusionManager.sendGmIntrusionResponse(rActor, selected.getValue())
	close();
end

function refuseIntrusion()
	if OptionsManagerCypher.areHeroPointsEnabled() then
		IntrusionManager.subtractOneHeroPoint(rActor);
	else
		IntrusionManager.subtractOneXp(rActor);
	end
	IntrusionManager.sendGmIntrusionRefusedResponse(rActor);
	close();
end