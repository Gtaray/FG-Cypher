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

	rRoll.sLabel = rAction.label;
	rRoll.nLevel = rAction.nLevel or 0;
	rRoll.sStat = rAction.sStat;
	rRoll.sDefenseStat = rAction.sDefenseStat;
	rRoll.sAttackRange = rAction.sAttackRange;

	rRoll.sDesc = ActionDefenseVs.getRollLabel(rActor, rAction, rRoll)

	return rRoll;
end

function getRollLabel(rActor, rAction, rRoll)
	local sLabel = string.format("[ATTACK (%s", StringManager.capitalize(rRoll.sStat));

	if (rRoll.sAttackRange or "") ~= "" then
		sLabel = string.format("%s, %s", sLabel, rAction.sAttackRange)
	end
	sLabel = string.format(
		"%s)] %s vs %s", 
		sLabel, 
		rRoll.sLabel,
		StringManager.capitalize(rRoll.sDefenseStat));

	return sLabel
end

function modRoll(rSource, rTarget, rRoll)
	if ActionDefenseVs.rebuildRoll(rSource, rTarget, rRoll) then
		return;
	end

	-- This has to go here because it requires a source and target
	rRoll.nDifficulty = rRoll.nLevel + RollManager.getBaseRollDifficulty(rTarget, rSource, { "attack", "atk", rRoll.sStat });
	RollManager.convertBooleansToNumbers(rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	RollManager.convertNumbersToBooleans(rRoll);
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if not rRoll.bRebuilt then
		rMessage.text = string.format("%s (Lvl %s)", rMessage.text, rRoll.nDifficulty);
	end
	rMessage.icon = "action_attack";

	if rTarget then
		rMessage.text = string.format(
			"%s -> %s", 
			rMessage.text, 
			ActorManager.getDisplayName(rTarget));
	end
	Comm.deliverChatMessage(rMessage);

	ActionDefenseVs.applyRoll(rSource, rTarget, rRoll);
end

function applyRoll(rSource, rTarget, rRoll)
	if not ActorManager.isPC(rTarget) then
		return;
	end

	local rAction = {};
	rAction.nDifficulty = rRoll.nDifficulty;
	rAction.sStat = rRoll.sDefenseStat;
	rAction.rTarget = rSource;
	rAction.sTraining, rAction.nAssets, rAction.nModifier = ActorManagerCypher.getDefense(rTarget, rRoll.sDefenseStat);
	rAction.sAttackRange = rRoll.sAttackRange;
	rAction.sAttackStat = rRoll.sStat

	-- Attempt to prompt the target to defend
	-- if there's no one controlling the defending PC, then automatically roll defense
	if Session.IsHost then
		local bPrompt = PromptManager.promptDefenseRoll(rSource, rTarget, rAction);

		if not bPrompt then
			ActionDefense.payCostAndRoll(nil, rTarget, rAction);
		end
	else
		PromptManager.initiateDefensePrompt(rSource, rTarget, rAction);
	end
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
-- Returns boolean determining whether the roll was rebuilt from a chat message
function rebuildRoll(rSource, rTarget, rRoll)
	local bRebuilt = false;

	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[ATTACK.*%]([^%[]+)"));
		bRebuilt = true;
	end
	if not rRoll.sStat then
		rRoll.sStat = RollManager.decodeStat(rRoll, true);
	end
	if not rRoll.sDefenseStat then
		rRoll.sDefenseStat = StringManager.trim(rRoll.sDesc:match("%[ATTACK.-%][^%[]+ vs ([^]%s]*)") or "");
	end
	if not rRoll.sAttackRange then
		rRoll.sAttackRange = StringManager.trim(rRoll.sDesc:match("^%[.-%s%(%w+,?%s?(%w+)%)%]") or "");
	end
	if not rRoll.nDifficulty then
		rRoll.nDifficulty = tonumber(rRoll.sDesc:match("%(Lvl (%d+)%)") or "0");
	end

	rRoll.bRebuilt = bRebuilt;
	return bRebuilt;
end