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

function addToTracker(rActor, sSummary, sSource)
	rActor = ActorManager.resolveActor(rActor);

    if not rActor or (sSummary or "") == "" then
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
    DB.setValue(modnode, "summary", "string", sSummary);

    local sSourceText = "";
    if (sSource or "") ~= "" then
        sSourceText = StringManager.capitalize(sSource);
    end

    DB.setValue(modnode, "source", "string", sSourceText)
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