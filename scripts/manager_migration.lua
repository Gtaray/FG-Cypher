function onInit()
	if not Session.IsHost then
		return;
	end

	DB.addHandler("charsheet", "onChildAdded", onCharsheetAdded);
	self.migrateV2_to_V3();
end

function onClose()
	DB.removeHandler("charsheet", "onChildAdded", onCharsheetAdded);
end

function onCharsheetAdded(nodeParent, charNode)
	DB.setValue(charNode, "version", "number", 3);
end

-- V2 is not an official designation, as V3 is the first version that's 'officially' tracked
-- Most things older than V2 were migrated ad-hoc in the controls themselves. However the transition from
-- V2 to V3 is quite extensive.
function migrateV2_to_V3()
	-- Migrate all of the characters to the new format
	for _, charnode in ipairs(DB.getChildList("charsheet")) do
		local nVersion = DB.getValue(charnode, "version", 0)
		if nVersion < 3 then
			self.migrateCharacterToV3(charnode)
		end
	end

	-- Migrate training data on all items, abilities, and NPCs
	for _, itemnode in ipairs(DB.getChildList("item")) do
		local nVersion = DB.getValue(itemnode, "version", 0)
		if nVersion < 3 then
			self.migrateItemToV3(itemnode)
		end
	end
	for _, abilitynode in ipairs(DB.getChildList("ability")) do
		local nVersion = DB.getValue(abilitynode, "version", 0)
		if nVersion < 3 then
			self.migrateAbilityToV3(abilitynode)
		end
	end
	for _, npcnode in ipairs(DB.getChildList("npc")) do
		local nVersion = DB.getValue(npcnode, "version", 0)
		if nVersion < 3 then
			self.migrateAbilityToV3(npcnode)
		end
	end
end

function migrateCharacterToV3(charnode)
	if DB.getChild(charnode, "abilities") then
		local statnode = DB.createChild(charnode, "stats");
		self.migrateStatToV3(charnode, "might");
		self.migrateStatToV3(charnode, "speed");
		self.migrateStatToV3(charnode, "intellect");
		DB.deleteChild(charnode, "abilities");
	end

	MigrationManager.moveValue(charnode, "tier", "advancement.tier", "number", 1);
	MigrationManager.moveValue(charnode, "xp", "advancement.xp", "number", 0);
	MigrationManager.moveValue(charnode, "advancement.abilities", "advancement.stats", "number", 0);

	local defnode = DB.createChild(charnode, "defenses")
	local armornode = DB.createChild(defnode, "armor");

	if DB.getChild(charnode, "Armor") then
		DB.setValue(armornode, "base", "number", DB.getValue(charnode, "Armor.base", 0));
		MigrationManager.moveValue(charnode, "Armor.base", "defenses.armor.base", "number", 0);
		MigrationManager.moveValue(charnode, "Armor.mod", "defenses.armor.mod", "number", 0);
		MigrationManager.moveValue(charnode, "Armor.superarmor", "defenses.armor.superarmor", "number", 0);
		DB.deleteChild(charnode, "Armor");
	end

	if DB.getChild(charnode, "resistances") then
		DB.copyNode(DB.getChild(charnode, "resistances"), DB.createChild(defnode, "resistances"));
		DB.deleteChild(charnode, "resistances");
	end

	MigrationManager.moveValue(charnode, "effort", "effort.base", "number", 1);

	if DB.getChild(charnode, "ArmorSpeedPenalty") then
		MigrationManager.moveValue(charnode, "ArmorSpeedPenalty.base", "effort.armorpenalty.base", "number", 0);
		MigrationManager.moveValue(charnode, "ArmorSpeedPenalty.mod", "effort.armorpenalty.mod", "number", 0);
		DB.deleteChild(charnode, "ArmorSpeedPenalty");
	end

	MigrationManager.moveValue(charnode, "recoveryrollmod", "health.recovery.mod", "number", 0);
	MigrationManager.moveValue(charnode, "recoveryused", "health.recovery.used", "number", 0);
	MigrationManager.moveValue(charnode, "wounds", "health.damagetrack", "number", 0);

	MigrationManager.moveValue(charnode, "inittraining", "initiative.training", "number", 1);
	MigrationManager.moveValue(charnode, "initasset", "initiative.assets", "number", 0);
	MigrationManager.moveValue(charnode, "initmod", "initiative.mod", "number", 0);

	MigrationManager.moveValue(charnode, "class.type", "class.type_temp.name", "string", "");
	MigrationManager.moveValue(charnode, "class.typelink", "class.type_temp.link", "windowreference", "");
	MigrationManager.copyAndDeleteSource(charnode, "class.type_temp", "class.type");

	MigrationManager.moveValue(charnode, "class.descriptor", "class.descriptor_temp.name", "string", "");
	MigrationManager.moveValue(charnode, "class.descriptorlink", "class.descriptor_temp.link", "windowreference", "");
	MigrationManager.copyAndDeleteSource(charnode, "class.descriptor_temp", "class.descriptor");

	MigrationManager.moveValue(charnode, "class.focus", "class.focus_temp.name", "string", "");
	MigrationManager.moveValue(charnode, "class.focuslink", "class.focus_temp.link", "windowreference", "");
	MigrationManager.copyAndDeleteSource(charnode, "class.focus_temp", "class.focus");

	MigrationManager.moveValue(charnode, "class.ancestry", "class.ancestry_temp.name", "string", "");
	MigrationManager.moveValue(charnode, "class.ancestrylink", "class.ancestry_temp.link", "windowreference", "");
	MigrationManager.copyAndDeleteSource(charnode, "class.ancestry_temp", "class.ancestry");

	MigrationManager.moveValue(charnode, "class.flavor", "class.flavor_temp.name", "string", "");
	MigrationManager.moveValue(charnode, "class.flavorlink", "class.flavor_temp.link", "windowreference", "");
	MigrationManager.copyAndDeleteSource(charnode, "class.flavor_temp", "class.flavor");
	
	for _, arcnode in ipairs(DB.getChildList(charnode, "characterarcs")) do
		self.migrateCharacterArcToV3(arcnode)
	end

	-- Migrate all places where "Training" is saved as a string to a number
	for _, attacknode in ipairs(DB.getChildList(charnode, "attacklist")) do
		MigrationManager.migrateTrainingStringToNumber(attacknode)
	end

	for _, abilitynode in ipairs(DB.getChildList(charnode, "abilitylist")) do
		for _, actionnode in ipairs(DB.getChildList(abilitynode, "actions")) do
			MigrationManager.migrateTrainingStringToNumber(actionnode)
		end
	end

	for _, itemnode in ipairs(DB.getChildList(charnode, "inventorylist")) do
		for _, actionnode in ipairs(DB.getChildList(itemnode, "actions")) do
			MigrationManager.migrateTrainingStringToNumber(actionnode)
		end
	end

	for _, custompool in ipairs(DB.getChildList(charnode, "custom_pools")) do
		MigrationManager.migrateTrainingStringToNumber(custompool)
	end

	DB.setValue(charnode, "version", "number", 3);
end

function migrateStatToV3(charnode, sStat)
	local sOldPath = "abilities." .. sStat;
	local sNewPath = "stats." .. sStat;

	-- If the old node is already not here, then we can return.
	if not DB.getChild(charnode, sOldPath) then
		return;
	end
	MigrationManager.moveValue(charnode, sOldPath .. ".current", sNewPath .. ".current", "number", 0);
	MigrationManager.moveValue(charnode, sOldPath .. ".max", sNewPath .. ".maxbase", "number", 0);
	MigrationManager.moveValue(charnode, sOldPath .. ".edge", sNewPath .. ".edge", "number", 0);
	DB.copyNode(DB.getPath(charnode, sOldPath, "def"), DB.getPath(charnode, sNewPath, "def"))
end

function migrateCharacterArcToV3(arcnode)
	-- If the arc exists in the old version, then it is implicitly already paid for.
	DB.setValue(arcnode, "paid", "number", 1);

	DB.setValue(arcnode, "description", "string", DB.getText(arcnode, "opening", ""));
	DB.deleteChild(arcnode, "opening");

	local nCurrentStage = DB.getValue(arcnode, "currentStage", 1);
	-- The old "stage 1" was already paid for and should be in progress, which is 
	-- "stage 2" in the new setup.
	if nCurrentStage == 1 then
		nCurrentStage = 2;
	end
	DB.setValue(arcnode, "stage", "number", nCurrentStage);
	DB.deleteChild(arcnode, "currentStage");

	local progressnode = DB.createChild(arcnode, "progress");
	for _, stepnode in ipairs(DB.getChildList(arcnode, "steps")) do
		local newstep = DB.createChild(progressnode);

		DB.setValue(newstep, "description", "string", DB.getText(stepnode, "step", ""));
		local bComplete = DB.getValue(stepnode, "complete", "") == "yes"
		if bComplete then
			DB.setValue(newstep, "done", "number", 1);
			DB.setValue(newstep, "rewardGained", "number", 1);
		else
			DB.setValue(newstep, "done", "number", 0);
		end
	end
	DB.deleteChild(arcnode, "steps");

	local climaxnode = DB.createChild(arcnode, "climax_temp");
	DB.setValue(climaxnode, "description", "string", DB.getText(arcnode, "climax", ""));
	if nCurrentStage >= 4 then
		DB.setValue(climaxnode, "done", "number", 1);
		DB.setValue(climaxnode, "rewardGained", "number", 1);
	end
	DB.deleteChild(arcnode, "climax");
	DB.copyNode(climaxnode, DB.createChild(arcnode, "climax"));
	DB.deleteChild(arcnode, "climax_temp");

	local resolutionnode = DB.createChild(arcnode, "resolution_temp");
	DB.setValue(resolutionnode, "description", "string", DB.getText(arcnode, "resolution", ""));
	if nCurrentStage >= 5 then
		DB.setValue(resolutionnode, "done", "number", 1);
		DB.setValue(resolutionnode, "rewardGained", "number", 1);
	end
	DB.deleteChild(arcnode, "resolution");
	DB.copyNode(resolutionnode, DB.createChild(arcnode, "resolution"))
	DB.deleteChild(arcnode, "resolution_temp");
end

function migrateItemToV3(item)
	for _, actionnode in ipairs(DB.getChildList(item, "actions")) do
		MigrationManager.migrateTrainingStringToNumber(actionnode)
	end

	DB.setValue(item, "version", "number", 3);
end

function migrateAbilityToV3(ability)
	for _, actionnode in ipairs(DB.getChildList(item, "actions")) do
		MigrationManager.migrateTrainingStringToNumber(actionnode)
	end

	DB.setValue(ability, "version", "number", 3);
end

function migrateNpcToV3(npc)
	-- NPCs have an <actions> node that holds all of their powers
	-- And each of those actions nodes has another list of <actions> for the invidual rolls
	for _, powernode in ipairs(DB.getChildList(npc, "actions")) do
		for _, actionnode in ipairs(DB.getChildList(powernode, "actions")) do
			MigrationManager.migrateTrainingStringToNumber(actionnode)
		end
	end
	DB.setValue(npc, "version", "number", 3);
end

function migrateTrainingStringToNumber(node)
	local vValue = DB.getValue(node, "training");
	if vValue ~= nil and type(vValue) == "string" then
		DB.deleteChild(node, "training")
		DB.setValue(node, "training", "number", TrainingManager.convertTrainingStringToNumber(vValue))
	end
end

function moveValue(node, sOriginPath, sDesinationPath, sType, vDefault, bPersistOrigin)
	DB.setValue(node, sDesinationPath, sType, DB.getValue(node, sOriginPath, vDefault));
	if not bPersistOrigin then
		DB.deleteChild(node, sOriginPath);
	end
end

function copyAndDeleteSource(node, sSourcePath, sDestPath)
	DB.copyNode(DB.getPath(node, sSourcePath), DB.createChild(node, sDestPath));
	DB.deleteChild(node, sSourcePath)
end