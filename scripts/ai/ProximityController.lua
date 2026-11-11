ProximityController = CpObject()

ProximityController.states = {
    NO_OBSTACLE = {},
    SLOW_DOWN = {},
    STOP = {}
}

-- Proximity sensor
-- how far the sensor can see
ProximityController.sensorRange = 10
-- the sensor will proportionally reduce speed when objects are in range down to this limit (won't set a speed lower than this)
ProximityController.minLimitedSpeed = 2
-- will stop under this threshold
ProximityController.stopThresholdNormal = 1.5
ProximityController.messageThreshold = 3 * 1000 -- 3sec
-- an obstacle that has held us up this long and is not moving itself is driven through (ghosting)
ProximityController.ghostAfterMs = 10 * 1000
-- keep ghosting at least this long
ProximityController.ghostMinMs = 8 * 1000
-- give up waiting to get clear of an obstacle that is not a vehicle after this long
ProximityController.ghostMaxMs = 90 * 1000
-- m of air between us and the obstacle before we become solid again
ProximityController.ghostClearance = 3
-- collision groups a ghost may drive through, never the terrain
ProximityController.ghostableFlagNames = { 'VEHICLE', 'DYNAMIC_OBJECT', 'TREE', 'STATIC_OBJECT', 'BUILDING', 'PLAYER' }
function ProximityController:init(vehicle, width)
    self.vehicle = vehicle
    -- if anything closer than this, we stop
    self.stopThreshold = CpTemporaryObject(self.stopThresholdNormal)
    self.blockingVehicle = CpTemporaryObject(nil)
    self.blockingObject = CpTemporaryObject(nil)
    self.ignoreObjectCallbackRegistrations = {}
    -- when did an obstacle start holding us up while we wanted to move
    self.blockedSince = nil
    -- the obstacle we are driving through, see startGhost()
    self.ghost = nil
    local frontMarker, backMarker = Markers.getMarkerNodes(self.vehicle)
    self.forwardLookingProximitySensorPack = WideForwardLookingProximitySensorPack(
            self.vehicle, frontMarker, self.sensorRange, 1, width)
    self.backwardLookingProximitySensorPack = WideBackwardLookingProximitySensorPack(
            self.vehicle, backMarker, self.sensorRange, 1, self.vehicle.size.width)

    self.showBlockedByObjectMessageTimer = CpTemporaryObject(false)
    self:setState(self.states.NO_OBSTACLE, 'proximity controller initialized')
end

function ProximityController:setState(state, debugString)
    if self.state ~= state then
        CpUtil.debugVehicle(CpDebug.DBG_TRAFFIC, self.vehicle, debugString)
        self.state = state
    end
end

function ProximityController:setTemporaryStopThreshold(value, ttlMs)
    self.stopThreshold:set(value, ttlMs)
end

function ProximityController:registerIsSlowdownEnabledCallback(object, callback)
    self.isSlowdownEnabledCallback = callback
    self.isSlowdownEnabledCallbackObject = object
end

function ProximityController:isSlowdownEnabled(vehicle)
    if self.isSlowdownEnabledCallbackObject then
        return self.isSlowdownEnabledCallback(self.isSlowdownEnabledCallbackObject, vehicle)
    else
        return true
    end
end

--- Register a function the controller calls when a vehicle has been blocking us for some time.
function ProximityController:registerBlockingVehicleListener(object, callback)
    self.onBlockingVehicleCallback = callback
    self.onBlockingVehicleObject = object
end

---@param vehicle table the vehicle blocking us
---@param isBack boolean true if it was detected behind us
function ProximityController:onBlockingVehicle(vehicle, isBack)
    if self.onBlockingVehicleObject then
        -- notify our listeners
        self.onBlockingVehicleCallback(self.onBlockingVehicleObject, vehicle, isBack)
    end
end

--- Register a function the controller calls when any object which isn't a vehicle has been blocking us for some time.
function ProximityController:registerBlockingObjectListener(object, callback)
    self.onBlockingObjectCallback = callback
    self.onBlockingObjectObject = object
end

function ProximityController:unregisterBlockingObjectListener()
    self.onBlockingObjectCallback = nil
    self.onBlockingObjectObject = nil
end

---@param isBack boolean true if it was detected behind us
function ProximityController:onBlockingObject(isBack)
    if self.onBlockingObjectObject then
        -- notify our listeners
        self.onBlockingObjectCallback(self.onBlockingObjectObject, isBack)
    end
end

--- Registers a function to ignore a object or vehicle.
--- Multiple objects can register multiple callbacks.
--- An object/vehicle is ignored when any of the callbacks ignores it (OR)
--- TODO: Consider consolidating this with the other ignore logic for vehicles.
function ProximityController:registerIgnoreObjectCallback(object, callback)
    if not self.ignoreObjectCallbackRegistrations[object] then
        self.ignoreObjectCallbackRegistrations[object] = {}
    end
    self.ignoreObjectCallbackRegistrations[object][callback] = true
end

---@param object table
---@param vehicle table
---@param moveForwards boolean
---@param hitTerrain boolean
---@return boolean ignore object
function ProximityController:ignoreObject(object, vehicle, moveForwards, hitTerrain)
    for callbackObject, registeredCallbacks in pairs(self.ignoreObjectCallbackRegistrations) do
        for callbackFunction, _ in pairs(registeredCallbacks) do
            if callbackFunction(callbackObject, object, vehicle, moveForwards, hitTerrain) then
                -- one of the registered callback wants to ignore, then ignore
                return true
            end
        end
    end
    return false
end

---@return number, table distance of vehicle and vehicle if there is one in range
function ProximityController:checkBlockingVehicleFront()
    return self.forwardLookingProximitySensorPack:getClosestObjectDistanceAndRootVehicle()
end

---@return number, table distance of vehicle and vehicle if there is one in range
function ProximityController:checkBlockingVehicleBack()
    return self.backwardLookingProximitySensorPack:getClosestObjectDistanceAndRootVehicle()
end

--- Is vehicle in range of the front or rear sensors?
---@param vehicle table
---@return boolean, number true if vehicle is in range, distance of vehicle
function ProximityController:isVehicleInRange(vehicle)
    for _, sensorPack in ipairs({self.forwardLookingProximitySensorPack, self.backwardLookingProximitySensorPack}) do
        local d, otherVehicle = sensorPack:getClosestObjectDistanceAndRootVehicle()
        if otherVehicle == vehicle then
            return true, d
        end
    end
end

function ProximityController:disableLeftSide()
    self.forwardLookingProximitySensorPack:disableLeftSide()
    self.backwardLookingProximitySensorPack:disableRightSide()
end

function ProximityController:disableRightSide()
    self.forwardLookingProximitySensorPack:disableRightSide()
    self.backwardLookingProximitySensorPack:disableLeftSide()
end

function ProximityController:enableBothSides()
    self.forwardLookingProximitySensorPack:enable()
    self.backwardLookingProximitySensorPack:enable()
end

---@param maxSpeed number current maximum allowed speed for vehicle
---@param moveForwards boolean are we moving forwards?
---@return number|nil gx world x coordinate to drive to or nil
---@return number|nil gz world z coordinate to drive to or nil
---@return boolean|nil direction is forwards if true or nil
---@return number maximum speed adjusted to slow down (or 0 to stop) when obstacles are ahead, otherwise maxSpeed
function ProximityController:getDriveData(maxSpeed, moveForwards)
    local gx, gz, direction, speed, blocker = self:getDriveDataFromSensors(maxSpeed, moveForwards)
    self:updateGhost(maxSpeed, speed, blocker)
    return gx, gz, direction, speed
end

---@return number|nil, number|nil, boolean|nil, number as getDriveData()
---@return table|nil the obstacle we stopped for: { vehicle, object, objectId, hitTerrain, d }
function ProximityController:getDriveDataFromSensors(maxSpeed, moveForwards)
    local d, vehicle, object, range, deg, dAvg, hitTerrain, objectId = math.huge, nil, nil, 10, 0, 0, false, nil
    local pack = moveForwards and self.forwardLookingProximitySensorPack or self.backwardLookingProximitySensorPack
    if pack then
        d, vehicle, object, hitTerrain, deg, dAvg, objectId = pack:getClosestObjectDistanceAndRootVehicle()
        range = pack:getRange()
    end
    if self:ignoreObject(object, vehicle, moveForwards, hitTerrain) then
        self:setState(self.states.NO_OBSTACLE, 'No obstacle')
        self.vehicle:resetCpActiveInfoText(InfoTextManager.BLOCKED_BY_OBJECT)
        return nil, nil, nil, maxSpeed
    end
    if self:isGhosted(vehicle, object, objectId) then
        self:setState(self.states.NO_OBSTACLE, 'Driving through the obstacle')
        self.vehicle:resetCpActiveInfoText(InfoTextManager.BLOCKED_BY_OBJECT)
        return nil, nil, nil, maxSpeed
    end
    if object then
        --- Makes sure the detected object is not an implement or the root vehicle.
        for _, childVehicle in pairs(self.vehicle:getChildVehicles()) do
            if object == childVehicle then
                self.vehicle:resetCpActiveInfoText(InfoTextManager.BLOCKED_BY_OBJECT)
                return nil, nil, nil, maxSpeed
            end
        end
    end

    local blocker
    local normalizedD = d / (range - self.stopThreshold:get())
    if d < self.stopThreshold:get() then
        -- too close, stop
        self:setState(self.states.STOP,
                string.format('Obstacle ahead, d = %.1f, deg = %.1f, too close, stop.', d, deg))
        maxSpeed = 0
        blocker = { vehicle = vehicle, object = object, objectId = objectId, hitTerrain = hitTerrain, d = d }
        self.showBlockedByObjectMessageTimer:setAndProlong(true, self.messageThreshold, self.messageThreshold)
        if vehicle ~= nil then
            if vehicle == self.blockingVehicle:get() then
                -- have been blocked by this guy long enough, try to recover
                CpUtil.debugVehicle(CpDebug.DBG_TRAFFIC, self.vehicle,
                        '%s has been blocking us for a while at %.1f m', CpUtil.getName(vehicle), d)
                self:onBlockingVehicle(vehicle, not moveForwards)
            end
            if not self.blockingVehicle:isPending() then
                -- first time we are being blocked by a vehicle, remember the time
                CpUtil.debugVehicle(CpDebug.DBG_TRAFFIC, self.vehicle, '%s is blocking us (%.1fm)', CpUtil.getName(vehicle), d)
                self.blockingVehicle:set(vehicle, nil, 7000)
            end
        else
            -- whatever is blocking us, it is not a vehicle
            if self.blockingObject:get() then
                -- have been blocked by an object long enough
                CpUtil.debugVehicle(CpDebug.DBG_TRAFFIC, self.vehicle, 'An object has been blocking us for a while at %.1f m', d)
                self:onBlockingObject(not moveForwards)
                self.blockingObject:set(false, nil, nil)
            elseif not self.blockingObject:isPending() then
                -- first time we are being blocked
                CpUtil.debugVehicle(CpDebug.DBG_TRAFFIC, self.vehicle, 'An object blocking us at %.1f m', d)
                self.blockingObject:set(true, nil, 5000)
            end
        end

    elseif normalizedD < 1 and self:isSlowdownEnabled(vehicle) then
        -- something in range, reduce speed proportionally when enabled
        local deltaV = maxSpeed - self.minLimitedSpeed
        maxSpeed = self.minLimitedSpeed + normalizedD * deltaV
        self:setState(self.states.SLOW_DOWN,
                string.format('Obstacle ahead, d = %.1f, deg = %.1f, slowing down to %.1f', d, deg, maxSpeed))
    else
        self:setState(self.states.NO_OBSTACLE, string.format('No obstacle, d = %.1f, deg = %.1f.', d, deg))
        self.blockingVehicle:reset()
    end
    if self.showBlockedByObjectMessageTimer:get() then
        self.vehicle:setCpInfoTextActive(InfoTextManager.BLOCKED_BY_OBJECT)
    else
        self.vehicle:resetCpActiveInfoText(InfoTextManager.BLOCKED_BY_OBJECT)
    end
    return nil, nil, nil, maxSpeed, blocker
end

function ProximityController:isStopped()
    return self.state == self.states.STOP   
end

-----------------------------------------------------------------------------------------------------------------------
--- Ghosting: drive through an obstacle that has held us up for a long time
---
--- Two Courseplay harvesters stopping for each other, a parked vehicle on the headland, a bale, a tree: when
--- the proximity sensor has stopped us for ghostAfterMs although we wanted to move, and the obstacle itself is
--- not moving, we stop colliding with that kind of obstacle (see CpCollisionGhost) and ignore it in the sensor
--- until we are clear of it. Only on the server, where the physics run.
-----------------------------------------------------------------------------------------------------------------------

function ProximityController:delete()
    self:endGhost('driver stopped')
end

function ProximityController:isGhostEnabled()
    if self.vehicle.isServer == false then
        return false
    end
    local settings = g_Courseplay and g_Courseplay.globalSettings
    local setting = settings and settings.driveThroughWhenBlocked
    return setting == nil or setting:getValue()
end

---@return boolean true if the obstacle the sensor sees is the one we are driving through
function ProximityController:isGhosted(vehicle, object, objectId)
    local ghost = self.ghost
    if ghost == nil then
        return false
    end
    return (vehicle ~= nil and vehicle == ghost.vehicle) or
            (objectId ~= nil and objectId == ghost.objectId) or
            (object ~= nil and object == ghost.object)
end

--- The collision flags a ghost may remove from our masks to pass this obstacle: the obstacle's groups,
--- never the terrain.
---@return table list of flags, empty when the obstacle can't be ghosted
function ProximityController:getGhostableFlags(blocker)
    local flags = {}
    for _, name in ipairs(self.ghostableFlagNames) do
        if CollisionFlag[name] then
            table.insert(flags, CollisionFlag[name])
        end
    end
    local result = {}
    if blocker.objectId and blocker.objectId ~= 0 and getCollisionFilterGroup and entityExists(blocker.objectId) then
        result = CpCollisionGhost.getFlagsInGroup(getCollisionFilterGroup(blocker.objectId), flags)
    end
    if blocker.vehicle and CollisionFlag.VEHICLE then
        local hasVehicleFlag = false
        for _, flag in ipairs(result) do
            hasVehicleFlag = hasVehicleFlag or flag == CollisionFlag.VEHICLE
        end
        if not hasVehicleFlag then
            table.insert(result, CollisionFlag.VEHICLE)
        end
    end
    return result
end

---@param vehicle table
---@return boolean true if the vehicle moves slower than 1 km/h
function ProximityController.isStandingStill(vehicle)
    return math.abs(vehicle.lastSpeedReal or 0) * 3600 < 1
end

local function getRadius(vehicle)
    local size = vehicle.size
    if size and size.length and size.width then
        return math.max(size.length, size.width) / 2
    end
    return 5
end

local function getTotalLength(vehicle)
    local length = 0
    for _, v in ipairs(vehicle.getChildVehicles and vehicle:getChildVehicles() or { vehicle }) do
        length = length + ((v.size and v.size.length) or 10)
    end
    return length
end

--- Is any part of a within clearance meters of any part of b (conservative, by bounding circles)?
function ProximityController.areVehiclesClose(a, b, clearance)
    local partsA = a.getChildVehicles and a:getChildVehicles() or { a }
    local partsB = b.getChildVehicles and b:getChildVehicles() or { b }
    for _, va in ipairs(partsA) do
        for _, vb in ipairs(partsB) do
            if va.rootNode and vb.rootNode and entityExists(va.rootNode) and entityExists(vb.rootNode) then
                local ax, _, az = getWorldTranslation(va.rootNode)
                local bx, _, bz = getWorldTranslation(vb.rootNode)
                if MathUtil.vector2Length(ax - bx, az - bz) < getRadius(va) + getRadius(vb) + clearance then
                    return true
                end
            end
        end
    end
    return false
end

---@param blocker table the obstacle we stopped for
function ProximityController:startGhost(blocker)
    local flags = self:getGhostableFlags(blocker)
    if #flags == 0 then
        CpUtil.debugVehicle(CpDebug.DBG_TRAFFIC, self.vehicle, 'Blocked for a while, but the obstacle can not be driven through')
        -- try again in a while
        self.blockedSince = g_time
        return
    end
    local ghost = { vehicle = blocker.vehicle, object = blocker.object, objectId = blocker.objectId,
                    since = g_time, flags = flags }
    ghost.x, _, ghost.z = getWorldTranslation(self.vehicle.rootNode)
    for _, node in ipairs(CpCollisionGhost.getComponentNodes(self.vehicle)) do
        CpCollisionGhost.hold(ghost, node, flags)
    end
    if ghost.vehicle and CollisionFlag.VEHICLE then
        for _, node in ipairs(CpCollisionGhost.getComponentNodes(ghost.vehicle)) do
            CpCollisionGhost.hold(ghost, node, { CollisionFlag.VEHICLE })
        end
    end
    self.ghost = ghost
    self.blockedSince = nil
    CpUtil.debugVehicle(CpDebug.DBG_TRAFFIC, self.vehicle, 'Blocked by %s for %.0f seconds, driving through it',
            ghost.vehicle and CpUtil.getName(ghost.vehicle) or 'an object', self.ghostAfterMs / 1000)
end

function ProximityController:endGhost(reason)
    if self.ghost == nil then
        return
    end
    CpCollisionGhost.release(self.ghost)
    CpUtil.debugVehicle(CpDebug.DBG_TRAFFIC, self.vehicle, 'Solid again (%s)', reason)
    self.ghost = nil
end

---@return boolean true when the ghost can end: minimum time over and no overlap with the obstacle possible
function ProximityController:isClearOfGhostedObstacle()
    local ghost = self.ghost
    local elapsed = g_time - ghost.since
    if elapsed < self.ghostMinMs then
        return false
    end
    if self.vehicle.isDeleted or not entityExists(self.vehicle.rootNode) then
        return true
    end
    if ghost.vehicle then
        if ghost.vehicle.isDeleted then
            return true
        end
        return not ProximityController.areVehiclesClose(self.vehicle, ghost.vehicle, self.ghostClearance)
    end
    local x, _, z = getWorldTranslation(self.vehicle.rootNode)
    local moved = MathUtil.vector2Length(x - ghost.x, z - ghost.z)
    return moved > getTotalLength(self.vehicle) + self.ghostClearance or elapsed > self.ghostMaxMs
end

--- Called once per getDriveData(): keeps the blocked timer, starts a ghost when we have been held up long
--- enough and ends it once we are clear of the obstacle.
---@param requestedMaxSpeed number the speed the strategy asked for
---@param speed number the speed we returned
---@param blocker table|nil the obstacle we stopped for
function ProximityController:updateGhost(requestedMaxSpeed, speed, blocker)
    if self.ghost then
        if self:isClearOfGhostedObstacle() then
            self:endGhost('clear of the obstacle')
        end
        return
    end
    -- blocked only counts when the strategy wanted to move and the sensor, not the terrain, held us
    local blocked = blocker ~= nil and (requestedMaxSpeed or 0) > 0 and (speed or 0) <= 0 and not blocker.hitTerrain
    if not blocked then
        self.blockedSince = nil
        return
    end
    if self.blockedSince == nil then
        self.blockedSince = g_time
        return
    end
    if g_time - self.blockedSince < self.ghostAfterMs or not self:isGhostEnabled() then
        return
    end
    if blocker.vehicle and not ProximityController.isStandingStill(blocker.vehicle) then
        -- it is moving, it may get out of our way, give it another chance
        self.blockedSince = g_time
        return
    end
    self:startGhost(blocker)
end
