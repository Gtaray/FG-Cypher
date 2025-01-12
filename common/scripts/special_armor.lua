function onInit()
    migrate();

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node), "onChildUpdate", onDataChanged);

	self.onDataChanged();
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node), "onChildUpdate", onDataChanged);
end

function onDataChanged(nodeParent, bListChanged)
	self.generateDescription();
end

function toggleDetail()
	Interface.openWindow("special_armor_editor", getDatabaseNode());
end

-------------------------------------------------------------------------------
-- DESCRIPTOR BUILDING
-------------------------------------------------------------------------------
function generateDescription()
	local sDesc = "";
	local sDamageType = self.getDamageType();
	local nArmor = self.getArmor();
	local sBehavior = self.getBehavior();

	-- TODO: Maybe this changes
	if (sDamageType or "") == "" then
		sDamageType = "mundane"
	end

	local sRes = "";
	if sBehavior == "threshold" then
		sRes = "special_armor_summary_threshold";
	elseif sBehavior == "limit" then
		sRes = "special_armor_summary_limit";
	elseif nArmor == 0 then
		sRes = "special_armor_summary_immune";
	elseif nArmor > 0 then
		sRes = "special_armor_summary_resist";
	elseif nArmor < 0 then
		sRes = "special_armor_summary_vuln";
		-- invert negative armor to positive value
		nArmor = nArmor * -1;
	end

	if self.isInverted() then
		sRes = string.format("%s_inverted", sRes);
	end

	-- Only for damage reduction with an amror value of 0 do we not display a number
	if nArmor == 0 and sBehavior == "" then
		sDesc = string.format(Interface.getString(sRes), sDamageType);
	else
		sDesc = string.format(Interface.getString(sRes), sDamageType, nArmor);
	end
	desc.setValue(sDesc);
end

-------------------------------------------------------------------------------
-- ACCESSORS
-------------------------------------------------------------------------------
function getDamageType()
	return DB.getValue(getDatabaseNode(), "damagetype", ""):lower();
end

function getArmor()
	return DB.getValue(getDatabaseNode(), "armor");
end

function getBehavior()
	return DB.getValue(getDatabaseNode(), "behavior", ""):lower();
end

function isInverted()
	return DB.getValue(getDatabaseNode(), "invert", "") == "yes";
end

-------------------------------------------------------------------------------
-- MIGRATION
-------------------------------------------------------------------------------
function migrate()
    -- migrate from old resist/vuln/immune format to Armor format
    local node = getDatabaseNode();
    local amountNode = DB.getChild(node, "amount");
    local typeNode = DB.getChild(node, "type");

    -- Migrate the armor from "amount" node to "armor" node
    if amountNode then
        local nAmount = DB.getValue(amountNode);
        DB.setValue(node, "armor", "number", nAmount);
        DB.deleteNode(amountNode);
    end

    -- Adjust the 'armor' amount based on whether the old format
    -- was set to resist, vuln, or immune
    if typeNode then
        -- At this point we should guarantee an armor node
        local nArmor = DB.getValue(node, "armor", 0);
        local sType = DB.getValue(typeNode);

        if sType == "resist" then
            -- Do nothing, armor stays the same
        elseif sType == "vuln" then
            -- Flip armor to negative
            DB.setValue(node, "armor", "number", nArmor * -1);
        elseif sType == "immune" then
            DB.setValue(node, "armor", "number", 0);
        end

        DB.deleteNode(typeNode);
    end
end