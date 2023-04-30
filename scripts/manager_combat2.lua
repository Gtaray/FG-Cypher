-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncStandard);

	CombatManager.setCustomCombatReset(resetInit);

	CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd);
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
