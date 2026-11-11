--[[
Collision ghosting: lets a Courseplay vehicle drive through whatever has been blocking it.

Two shapes collide only when each one's collision group is in the other one's mask. Removing the
obstacle's group flags from the masks of a vehicle's components makes the vehicle pass through that
kind of obstacle, and removing the VEHICLE flag from the obstacle's components (when the obstacle is a
vehicle) makes sure the obstacle's wheels and shapes do not catch on the ghosted vehicle either.

Masks are shared engine state: two ghosts may change the same node (both harvesters in a deadlock ghost
each other), so the original mask of a node is kept here together with every holder's flags, and the
original is written back only when the last holder has released the node.

Physics runs on the server, where the Courseplay strategies run, so no network event is needed.
]]

---@class CpCollisionGhost
CpCollisionGhost = {
    -- node -> { original = mask, holders = { [holder] = { flag, ... } } }
    held = {},
    -- holder -> { node, ... }
    nodesByHolder = {}
}

local function hasFlag(value, flag)
    return math.floor(value / flag) % 2 == 1
end

--- The flags of the group (only the ones listed in flags) that a ghost may remove from a mask.
---@param group number collision group of the obstacle's shape
---@param flags table list of single bit flags that may be ghosted
---@return table list of flags, empty if none of the flags is set in the group
function CpCollisionGhost.getFlagsInGroup(group, flags)
    local result = {}
    if group then
        for _, flag in ipairs(flags) do
            if hasFlag(group, flag) then
                table.insert(result, flag)
            end
        end
    end
    return result
end

local function maskWithoutHolders(entry)
    local mask = entry.original
    local removed = {}
    for _, flags in pairs(entry.holders) do
        for _, flag in ipairs(flags) do
            if not removed[flag] and hasFlag(mask, flag) then
                mask = mask - flag
                removed[flag] = true
            end
        end
    end
    return mask
end

--- Remove flags from the collision mask of a node on behalf of holder.
---@param holder table anything that identifies the ghost, release(holder) restores everything it holds
---@param node number
---@param flags table list of single bit flags to remove from the node's mask
function CpCollisionGhost.hold(holder, node, flags)
    if node == nil or node == 0 or not entityExists(node) or #flags == 0 then
        return
    end
    local entry = CpCollisionGhost.held[node]
    if entry == nil then
        local mask = getCollisionFilterMask(node)
        if mask == nil then
            return
        end
        entry = { original = mask, holders = {} }
        CpCollisionGhost.held[node] = entry
    end
    entry.holders[holder] = flags
    setCollisionFilterMask(node, maskWithoutHolders(entry))
    local nodes = CpCollisionGhost.nodesByHolder[holder]
    if nodes == nil then
        nodes = {}
        CpCollisionGhost.nodesByHolder[holder] = nodes
    end
    nodes[node] = true
end

--- Restore every node this holder changed (unless another holder still holds it).
---@param holder table
function CpCollisionGhost.release(holder)
    local nodes = CpCollisionGhost.nodesByHolder[holder]
    if nodes == nil then
        return
    end
    CpCollisionGhost.nodesByHolder[holder] = nil
    for node, _ in pairs(nodes) do
        local entry = CpCollisionGhost.held[node]
        if entry then
            entry.holders[holder] = nil
            if entityExists(node) then
                setCollisionFilterMask(node, maskWithoutHolders(entry))
            end
            if next(entry.holders) == nil then
                CpCollisionGhost.held[node] = nil
            end
        end
    end
end

---@param holder table
---@return boolean true if the holder changed at least one node
function CpCollisionGhost.isHolding(holder)
    return CpCollisionGhost.nodesByHolder[holder] ~= nil
end

--- The component nodes of a vehicle and everything attached to it.
---@param vehicle table root vehicle
---@return table list of nodes
function CpCollisionGhost.getComponentNodes(vehicle)
    local nodes = {}
    if vehicle == nil or vehicle.isDeleted then
        return nodes
    end
    local vehicles = vehicle.getChildVehicles and vehicle:getChildVehicles() or { vehicle }
    for _, v in ipairs(vehicles) do
        for _, component in ipairs(v.components or {}) do
            if component.node and component.node ~= 0 and entityExists(component.node) then
                table.insert(nodes, component.node)
            end
        end
    end
    return nodes
end
