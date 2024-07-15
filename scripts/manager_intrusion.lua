OOB_MSG_TYPE_GMI_PROMPT = "gmiprompt";
OOB_MSG_TYPE_GMI_RESPONSE = "gmiresponse";

hero_point_intrusions = {
	"reroll",
	"shortterm"
}

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSG_TYPE_GMI_PROMPT, handleGmIntrusionPrompt);
	OOBManager.registerOOBMsgHandler(OOB_MSG_TYPE_GMI_RESPONSE, handleGmIntrusionResponse);
end

function registerIntrusionMenu(window)
	if not Session.IsHost then
		return;
	end

	if not window then
		return;
	end
	
	window.registerMenuItem(Interface.getString("menu_gm_intrusion"), "italics", 7);
end

function handleMenuSelection(selection, rActor)
	if not rActor then
		return false;
	end

	if selection == 7 then
		IntrusionManager.invokeGmIntrusion(rActor);
		return true;
	end

	return false;
end

function invokeGmIntrusion(rActor)
	IntrusionManager.sendGmIntrusionNotification(rActor);
	IntrusionManager.sendGmIntrusionPrompt(rActor);
end

function canHeroPointsBeSpentOnPcIntrusion(sIntrusionType)
	return StringManager.contains(hero_point_intrusions, sIntrusionType)
end

-------------------------------------------------------------------------------
-- GM INTRUSION PROMPT & RESPONSE
-------------------------------------------------------------------------------

function sendGmIntrusionPrompt(rActor)
	if not Session.IsHost then
		return;
	end

	-- Gets the username of the player who owns rActor
	local sUser = PromptManager.getUser(rActor);

	if sUser == nil then
		ChatManager.SystemMessage(Interface.getString("gmi_message_user_not_found"));
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSG_TYPE_GMI_PROMPT;
	msgOOB.sActorNode = ActorManager.getCreatureNodeName(rActor);

	local i = 1;
	-- Get all of the other PCs
	for _, charnode in ipairs(DB.getChildList("charsheet")) do
		local sNode = DB.getPath(charnode);

		if msgOOB.sActorNode ~= sNode then
			local sKey = string.format("char_%s", i);
			msgOOB[sKey .. "_node"] = sNode;
			msgOOB[sKey .. "_name"] = DB.getValue(charnode, "name", "");
			msgOOB[sKey .. "_token"] = DB.getValue(charnode, "token", "");

			if OptionsManagerCypher.areHeroPointsEnabled() then
				msgOOB[sKey .. "_xp"] = CharManager.getHeroPoints(charnode)
			else
				msgOOB[sKey .. "_xp"] = CharManager.getExperience(charnode);
			end

			i = i + 1;
		end
	end

	Comm.deliverOOBMessage(msgOOB, sUser)
end

function handleGmIntrusionPrompt(msgOOB)
	local rActor = ActorManager.resolveActor(msgOOB.sActorNode)
	local window = Interface.openWindow("prompt_gm_intrusion", "")

	if not window then
		return;
	end

	local i = 1;
	local sKey = string.format("char_%s", i);
	local rCharacters = {};
	while msgOOB[sKey .. "_node"] do
		table.insert(rCharacters, {
			sNode = msgOOB[sKey .. "_node"],
			sName = msgOOB[sKey .. "_name"],
			sToken = msgOOB[sKey .. "_token"],
			nXpOrHeroPoints = msgOOB[sKey .. "_xp"]
		});

		i = i + 1;
		sKey = string.format("char_%s", i);
	end

	window.setActor(rActor);
	window.setOptions(rCharacters);
end

function sendGmIntrusionResponse(rActor, sSelectedCharacterNode)
	local msgOOB = {};
	msgOOB.type = OOB_MSG_TYPE_GMI_RESPONSE;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rActor);
	msgOOB.sTargetNode = sSelectedCharacterNode;

	Comm.deliverOOBMessage(msgOOB)
end

function handleGmIntrusionResponse(msgOOB)
	if not Session.IsHost then
		return;
	end
	
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode)
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode)

	if OptionsManagerCypher.areHeroPointsEnabled() then
		IntrusionManager.addOneHeroPoint(rSource);
		IntrusionManager.addOneHeroPoint(rTarget);	
	else
		IntrusionManager.addOneXp(rSource);
		IntrusionManager.addOneXp(rTarget);	
	end

	IntrusionManager.sendGmIntrusionAcceptedResponse(rSource, rTarget);
end

-------------------------------------------------------------------------------
-- PC INTRUSION
-------------------------------------------------------------------------------
function handlePlayerIntrusionResponse(nodeChar, sType, nCost)
	local rActor = ActorManager.resolveActor(nodeChar);

	-- Only deduct hero points if that option is enabled, and if the intrusion
	-- costs a single point
	if OptionsManagerCypher.areHeroPointsEnabled() and (IntrusionManager.canHeroPointsBeSpentOnPcIntrusion(sType)) then
		IntrusionManager.modifyHeroPoints(rActor, -nCost);
	else
		IntrusionManager.modifyXp(rActor, -nCost);
	end

	local sMessage = Interface.getString(string.format("pci_message_%s", sType));
	sMessage = string.format(sMessage, ActorManager.getDisplayName(rActor));

	IntrusionManager.sendPcIntrusionNotification(sMessage);
end

-------------------------------------------------------------------------------
-- XP MODIFICATION
-------------------------------------------------------------------------------
function addOneXp(rActor)
	return IntrusionManager.modifyXp(rActor, 1);
end

function subtractOneXp(rActor)
	return IntrusionManager.modifyXp(rActor, -1);
end

function modifyXp(rActor, nXp)
	local node = ActorManager.getCreatureNode(rActor)
	if not node then
		return 0;
	end

	local nCur = DB.getValue(node, "xp", 0);
	DB.setValue(node, "xp", "number", nCur + nXp);
	return nCur + nXp;
end

-------------------------------------------------------------------------------
-- HERO POINT MODIFICATION
-------------------------------------------------------------------------------
function addOneHeroPoint(rActor)
	if not OptionsManagerCypher.areHeroPointsEnabled() then
		return
	end
	return IntrusionManager.modifyHeroPoints(rActor, 1);
end

function subtractOneHeroPoint(rActor)
	if not OptionsManagerCypher.areHeroPointsEnabled() then
		return
	end
	return IntrusionManager.modifyHeroPoints(rActor, -1);
end

function modifyHeroPoints(rActor, nPoints)
	if not OptionsManagerCypher.areHeroPointsEnabled() then
		return
	end

	local node = ActorManager.getCreatureNode(rActor)
	if not node then
		return 0;
	end

	local nCur = CharManager.getHeroPoints(node)
	local nNew = nCur + nPoints
	CharManager.setHeroPoints(node, nNew)

	return nNew;
end

-------------------------------------------------------------------------------
-- MESSAGING
-------------------------------------------------------------------------------
function getIntrusionResourceText(bPlural)
	local sText = "XP"
	if OptionsManagerCypher.areHeroPointsEnabled() then
		sText = "Hero Point"
		if bPlural then
			sText = sText .. "s"
		end
	end

	return sText
end

function sendGmIntrusionNotification(rActor)
	if not rActor then
		return;
	end

	local rMessage = {
		text = string.format(
			Interface.getString("gmi_message_gm_intrusion"), 
			ActorManager.getDisplayName(rActor)),
		icon = "roll1",
		font = "msgfont"
	}
	Comm.deliverChatMessage(rMessage);
end

function sendGmIntrusionAcceptedResponse(rActor, rTarget)
	if not rActor or not rTarget then
		return;
	end

	local sResource = IntrusionManager.getIntrusionResourceText(false)
	local rMessage = {
		text = string.format(
			Interface.getString("gmi_message_gm_intrusion_accept"), 
			ActorManager.getDisplayName(rActor),
			sResource,
			sResource,
			ActorManager.getDisplayName(rTarget)),
		font = "msgfont"
	}
	Comm.deliverChatMessage(rMessage);
end

function sendGmIntrusionRefusedResponse(rActor)
	if not rActor then
		return;
	end
	
	local rMessage = {
		text = string.format(
			Interface.getString("gmi_message_gm_intrusion_refuse"), 
			ActorManager.getDisplayName(rActor),
			IntrusionManager.getIntrusionResourceText(false)),
		font = "msgfont"
	}
	Comm.deliverChatMessage(rMessage);
end

function sendPcIntrusionNotification(sMessage)	
	local rMessage = {
		text = sMessage,
		font = "msgfont",
		icon = "playerintrusion"
	}
	Comm.deliverChatMessage(rMessage);
end