-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
OOB_MSGTYPE_RESETEDGE = "resetedge";

function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncStandard);

	CombatManager.setCustomCombatReset(resetInit);
	CombatManager.setCustomTurnEnd(sendTurnEndMessage)
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RESETEDGE, handleTurnEndMessage);

	CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd);
end

-- Because we want EVERYONE to reset their edge when a turn changes, we have to use
-- an OOB, since the normal turn end event is host-only
function sendTurnEndMessage()
	if not Session.IsHost then
		return;
	end

	local msgOOB = {
		type = OOB_MSGTYPE_RESETEDGE
	};

	Comm.deliverOOBMessage(msgOOB);
end

function handleTurnEndMessage()
	RollManager.enableEdge();
end

--
-- ADD FUNCTIONS
--

function onNPCPostAdd(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	-- Setup
	local nLevel = DB.getValue(tCustom.nodeCT, "level", 0);

	-- Health
	local nHP = DB.getValue(tCustom.nodeRecord, "hp", 0);
	if nHP == 0 then
		nHP = nLevel * 3;
	end
	DB.setValue(tCustom.nodeCT, "hp", "number", nHP);
	
	-- Combat properties
	local sDamage = DB.getValue(tCustom.nodeRecord, "damagestr", "");
	local nDamage = tonumber(string.match(sDamage, "(%d+)")) or 0;
	if nDamage == 0 then
		nDamage = nLevel;
	end
	DB.setValue(tCustom.nodeCT, "damage", "number", nDamage);
	
	-- Roll initiative and sort
	local nBaseInit = nLevel * 3;
	local sOptINITNPC = OptionsManager.getOption("INITNPC");
	if sOptINITNPC == "group" then
		local nMaxInit = nBaseInit;
		for _,v in pairs(CombatManager.getCombatantNodes()) do
			local sClass, _ = DB.getValue(v, "link", "", "");
			if sClass ~= "charsheet" then
				nMaxInit = math.max(nMaxInit, DB.getValue(v, "initresult", 0));
			end
		end
		for _,v in pairs(CombatManager.getCombatantNodes()) do
			local sClass, _ = DB.getValue(v, "link", "", "");
			if sClass ~= "charsheet" then
				DB.setValue(v, "initresult", "number", nMaxInit);
			end
		end
	else
		DB.setValue(tCustom.nodeCT, "initresult", "number", nBaseInit);
	end

	local sModifications = DB.getValue(tCustom.nodeCT, "modifications", "");
	local aEffects = CombatManagerCypher.parseNpcModifications(sModifications, tCustom.nodeCT);
	for _, effect in ipairs(aEffects) do
		EffectManager.addEffect(nil, nil, tCustom.nodeCT, effect, false);
	end
end

--
-- RESET FUNCTIONS
--

function rest(bShort)
	CombatManager.resetInit();
	
	if not bShort then
		for _,v in pairs(CombatManager.getCombatantNodes()) do
			local sClass, sRecord = DB.getValue(v, "link", "", "");
			if sClass == "charsheet" and sRecord ~= "" then
				local nodePC = DB.findNode(sRecord);
				if nodePC then
					CharManager.rest(nodePC);
				end
			end
		end
	end
end

function rollInit()
	local nMaxInit = 0;
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local sClass, _ = DB.getValue(v, "link", "", "");
		if sClass == "charsheet" then
			local nInit = math.random(20);
			DB.setValue(v, "initresult", "number", nInit);
			nMaxInit = math.max(nMaxInit, nInit);
		end
	end
	
	if OptionsManager.getOption("INITPC") == "group" then
		for _,v in pairs(CombatManager.getCombatantNodes()) do
			local sClass, _ = DB.getValue(v, "link", "", "");
			if sClass == "charsheet" then
				DB.setValue(v, "initresult", "number", nMaxInit);
			end
		end
	end
end

function resetInit()
	local nMaxInit = 0;
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local sClass, _ = DB.getValue(v, "link", "", "");
		if sClass == "charsheet" then
			DB.setValue(v, "initresult", "number", 0);
		else
			local nBaseInit = DB.getValue(v, "level", 0) * 3;
			DB.setValue(v, "initresult", "number", nBaseInit);
			nMaxInit = math.max(nMaxInit, nBaseInit);
		end
	end

	if OptionsManager.getOption("INITNPC") == "group" then
		for _,v in pairs(CombatManager.getCombatantNodes()) do
			local sClass, _ = DB.getValue(v, "link", "", "");
			if sClass ~= "charsheet" then
				DB.setValue(v, "initresult", "number", nMaxInit);
			end
		end
	end
end

function parseNpcModifications(sText, nodeCreature)
	-- Get rid of some problem characters, and make lowercase
	local sLocal = sText:gsub("’", "'");
	sLocal = sLocal:gsub("–", "-");
	sLocal = sLocal:lower();

	-- Parse the words
	local aWords, aWordStats = StringManager.parseWords(sLocal, ".:;\n");

	-- Build Effects
	return CombatManagerCypher.parseModification(aWords, nodeCreature)
end

-- Adds markers for end of sentence, end of clause, and clause label separators
function parseHelper(s, words, words_stats)
	local final_words = {};
	local final_words_stats = {};
	
	-- Separate words ending in periods, colons and semicolons
	for i = 1, #words do
	  local nSpecialChar = string.find(words[i], "[%.:;\n]");
	  if nSpecialChar then
		  local sWord = words[i];
		  local nStartPos = words_stats[i].startpos;
		  while nSpecialChar do
			  if nSpecialChar > 1 then
				  table.insert(final_words, string.sub(sWord, 1, nSpecialChar - 1));
				  table.insert(final_words_stats, {startpos = nStartPos, endpos = nStartPos + nSpecialChar - 1});
			  end
			  
			  table.insert(final_words, string.sub(sWord, nSpecialChar, nSpecialChar));
			  table.insert(final_words_stats, {startpos = nStartPos + nSpecialChar - 1, endpos = nStartPos + nSpecialChar});
			  
			  nStartPos = nStartPos + nSpecialChar;
			  sWord = string.sub(sWord, nSpecialChar + 1);
			  
			  nSpecialChar = string.find(sWord, "[%.:;\n]");
		  end
		  if string.len(sWord) > 0 then
			  table.insert(final_words, sWord);
			  table.insert(final_words_stats, {startpos = nStartPos, endpos = words_stats[i].endpos});
		  end
	  else
		  table.insert(final_words, words[i]);
		  table.insert(final_words_stats, words_stats[i]);
	  end
	end
	
  return final_words, final_words_stats;
end

function parseModification(aWords, nodeCreature)
	local effects = {};
	local i = 1;
	while aWords[i] do
		local effect = nil;

		-- Look for defense modification
		if StringManager.isWord(aWords[i], {"defense", "defends" }) then
			i, effect = parseDefenseModification(aWords, i, nodeCreature);
		-- Look for attack modification
		elseif StringManager.isWord(aWords[i], "attacks") then
			i, effect = parseAttackModification(aWords, i, nodeCreature);
		end

		if effect then
			table.insert(effects, effect);
		end

		i = i + 1;
	end

	return effects
end

function parseDefenseModification(aWords, i, nodeCreature)
	local sStat = nil;
	local nLevel = nil;
	if aWords[i - 1] and StringManager.isWord(aWords[i - 1], { "might", "speed", "intellect"}) then
		sStat = aWords[i - 1];
	end
	if aWords[i + 1] and StringManager.isWord(aWords[i + 1], "as")
		and aWords[i + 2] and StringManager.isWord(aWords[i + 2], "level")
		and aWords[i + 3] and tonumber(aWords[i + 3]) then
		nLevel = tonumber(aWords[i + 3]);
		i = i + 3
	end

	local effect = nil;

	-- stat is optional, level is not.
	if nLevel ~= nil then
		local nCreatureLevel = ActorManagerCypher.getCreatureLevel(nodeCreature);

		-- We want the difference between the state level and creature level
		-- so we know what mod the effect should have
		nLevel = nLevel - nCreatureLevel
		local sName = string.format("LEVEL: %s defense", nLevel);
		if sStat then
			sName = string.format("%s, %s", sName, sStat);
		end
		effect = {
			nGMOnly = 1,
			sName = sName,
			nDuration = 0
		}
	end
	return i, effect
end

function parseAttackModification(aWords, i, nodeCreature)
	local sStat = nil;
	local nLevel = nil;
	if aWords[i - 1] and StringManager.isWord(aWords[i - 1], { "might", "speed", "intellect"}) then
		sStat = aWords[i - 1];
	end
	if aWords[i + 1] and StringManager.isWord(aWords[i + 1], "as")
		and aWords[i + 2] and StringManager.isWord(aWords[i + 2], "level")
		and aWords[i + 3] and tonumber(aWords[i + 3]) then
		nLevel = tonumber(aWords[i + 3]);
		i = i + 3
	end

	local effect = nil;

	-- stat is optional, level is not.
	if nLevel ~= nil then
		local nCreatureLevel = ActorManagerCypher.getCreatureLevel(nodeCreature);

		-- We want the difference between the state level and creature level
		-- so we know what mod the effect should have
		nLevel = nLevel - nCreatureLevel
		local sName = string.format("LEVEL: %s attack", nLevel);
		if sStat then
			sName = string.format("%s, %s", sName, sStat);
		end
		effect = {
			nGMOnly = 1,
			sName = sName,
			nDuration = 0
		}
	end
	return i, effect
end
