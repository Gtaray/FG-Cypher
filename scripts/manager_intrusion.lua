OOB_MSG_TYPE_GMI_PROMPT = "gmiprompt";
OOB_MSG_TYPE_GMI_RESPONSE = "gmiresponse";

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
		return;
	end

	if selection == 7 then
		IntrusionManager.invokeGmIntrusion(rActor);
	end
end

function invokeGmIntrusion(rActor)
	IntrusionManager.sendGmIntrusionNotification(rActor);
	IntrusionManager.sendGmIntrusionPrompt(rActor);
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
			sToken = msgOOB[sKey .. "_token"]
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

	IntrusionManager.addOneXp(rSource);
	IntrusionManager.addOneXp(rTarget);	
	IntrusionManager.sendGmIntrusionAcceptedResponse(rSource, rTarget);
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
-- MESSAGING
-------------------------------------------------------------------------------
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

	local rMessage = {
		text = string.format(
			Interface.getString("gmi_message_gm_intrusion_accept"), 
			ActorManager.getDisplayName(rActor),
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
			ActorManager.getDisplayName(rActor)),
		font = "msgfont"
	}
	Comm.deliverChatMessage(rMessage);
end