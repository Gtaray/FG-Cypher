-- These rolls are used by NPCs to force PCs to make defense rolls without applying damage.
function onInit()
    ActionsManager.registerModHandler("defensevs", modRoll);
	ActionsManager.registerResultHandler("defensevs", onRoll);
end

--  NPCs should be the only ones making these rolls
function performRoll(draginfo, rActor, rAction)
	if ActorManager.isPC(rActor) then
		return;
	end

	rAction.sDefenseStat = RollManager.resolveStat(rAction.sDefenseStat, "speed");
	
    local rRoll = getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "defensevs";
	rRoll.aDice = {};
	rRoll.nMod = 0;

	-- This is the base difficulty of the defense task
	-- This is here for display purposes. The difficulty will be re-calced
	-- when the player makes a defense roll
	rRoll.nDifficulty = rAction.nLevel or 0;
	
	local sDescription = StringManager.capitalize(rAction.sDefenseStat);
	if (rAction.sAttackRange or "") ~= "" then
		sDescription = string.format("%s, %s", rAction.sAttackRange, sDescription);
	end
	rRoll.sDesc = string.format(
		"[ATTACK (%s)] %s", 
		sDescription,
		rAction.label);

	rRoll.sDefenseStat = rAction.sDefenseStat;

	RollManager.encodeStat(rAction.DefenseStat, rRoll);
	RollManager.encodeLevel(rAction, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	-- Get difficulty
	rRoll.nDifficulty = ActorManagerCypher.getCreatureLevel(rSource, rTarget, { "attack", "atk" });
	rRoll.sDesc = string.format("%s (Lvl %s)", rRoll.sDesc, rRoll.nDifficulty);
end

function onRoll(rSource, rTarget, rRoll)
	local sStat = rRoll.sDefenseStat;

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "roll_attack";
	if rTarget then
		rMessage.text = rMessage.text .. " -> " .. ActorManager.getDisplayName(rTarget)
	end
	Comm.deliverChatMessage(rMessage);

	if ActorManager.isPC(rTarget) then
		local rAction = {};
		rAction.nDifficulty = rRoll.nDifficulty;
		rAction.sStat = sStat;
		rAction.rTarget = rSource;
		rAction.sTraining, rAction.nAssets, rAction.nModifier = ActorManagerCypher.getDefense(rTarget, sStat);

		-- Attempt to prompt the target to defend
		-- if there's no one controlling the defending PC, then automatically roll defense
		if Session.IsHost then
			local bPrompt = PromptManager.promptDefenseRoll(rSource, rTarget, rAction);

			if not bPrompt then
				ActionDefense.performRoll(nil, rTarget, rAction);
			end
		else
			PromptManager.initiateDefensePrompt(rSource, rTarget, rAction);
		end
	end
end