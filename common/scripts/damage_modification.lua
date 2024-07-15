function onInit()
    migrate();
end

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

function update(bReadOnly)
    damagetype.setReadOnly(bReadOnly);
    armor.setReadOnly(bReadOnly);
end