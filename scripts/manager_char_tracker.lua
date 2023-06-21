-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

TRACKER_PATH = "tracker"

function getTrackerNode(rActor)
    local charnode = ActorManager.getCreatureNode(rActor);
    if not charnode then
        return;
    end

    return DB.createChild(charnode, CharTrackerManager.TRACKER_PATH); 
end

-- TODO: Pull getModificationSummary outof this functino
-- it won't work for types/foci/descriptors
function addToTracker(rActor, rMod)
    if not rActor or not rMod then
        return;
    end

    local trackernode = CharTrackerManager.getTrackerNode(rActor);
    if not trackernode then
        return;
    end

    local nOrder = (CharTrackerManager.getMaxOrder(rActor) or 0) + 1;

    local modnode = DB.createChild(trackernode);
    if not modnode then
        return;
    end
    DB.setValue(modnode, "order", "number", nOrder);

    local sSummary = CharModManager.getModificationSummary(rMod);
    DB.setValue(modnode, "summary", "string", sSummary);

    local sSourceText = "";
    if (rMod.sSourceClass or "") ~= "" then
        sSourceText = string.format("%s: ", StringManager.capitalize(rMod.sSourceClass))
    end
    sSourceText = sSourceText .. StringManager.capitalize(rMod.sSourceName)

    DB.setValue(modnode, "source", "string", DB.getPath(rMod.nodeSource))
    DB.setValue(modnode, "sourcetext", "string", sSourceText)
end

function getMaxOrder(rActor)
    local trackernode = CharTrackerManager.getTrackerNode(rActor);

    local nMax = 0;
    for _, node in ipairs(DB.getChildList(trackernode)) do
        local nOrder = DB.getValue(node, "order", 0);
        if nOrder > nMax then
            nMax = nOrder;
        end
    end

    return nMax;
end