--[[
This file is part of Courseplay (https://github.com/Courseplay/courseplay)
Copyright (C) 2022 Peter Vaiko

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

--- Drive strategy to find bales on a field and collect or wrap them
--- TODO: Separate bale wrapper and bale loaders.
---       Might be a good idea to have the bale loader strategy derive from the find bales(only wrapper) strategy.

---@class AIDriveStrategyFindBales : AIDriveStrategyCourse
AIDriveStrategyFindBales = CpObject(AIDriveStrategyCourse)

AIDriveStrategyFindBales.myStates = {
    SEARCHING_FOR_NEXT_BALE = {},
    WAITING_FOR_PATHFINDER = {},
    DRIVING_TO_NEXT_BALE = {},
    APPROACHING_BALE = {},
    WORKING_ON_BALE = {},
    REVERSING_AFTER_PATHFINDER_FAILURE = {},
    REVERSING_DUE_TO_OBSTACLE_AHEAD = {},
    DRIVING_TO_START_MARKER = {},
    WAITING_FOR_IMPLEMENTS_TO_FOLD = {}
}
--- Offset to apply at the goal marker, so we don't crash with an empty unloader waiting there with the same position.
AIDriveStrategyFindBales.invertedGoalPositionOffset = -4.5
AIDriveStrategyFindBales.minStartDistanceToField = 20
--- Off-field penalty for routes to bales (default PathfinderContext.defaultOffFieldPenalty is 7.5)
AIDriveStrategyFindBales.offFieldPenalty = 100

function AIDriveStrategyFindBales:init(task, job)
    AIDriveStrategyCourse.init(self, task, job)
    AIDriveStrategyCourse.initStates(self, AIDriveStrategyFindBales.myStates)
    -- we always need a field boundary to work
    self.state = self.states.WAITING_FOR_FIELD_BOUNDARY_DETECTION
    self.debugChannel = CpDebug.DBG_FIND_BALES
    self.bales = {}
end

function AIDriveStrategyFindBales:delete()
    AIDriveStrategyCourse.delete(self)
    g_baleToCollectManager:unlockBalesByDriver(self)
    if self.invertedStartPositionMarkerNode then
        CpUtil.destroyNode(self.invertedStartPositionMarkerNode)
    end
    for _, stuck in pairs(self.stuckAtBale or {}) do
        CpUtil.destroyNode(stuck.node)
    end
end

function AIDriveStrategyFindBales:getGeneratedCourse(jobParameters)
    return nil
end

function AIDriveStrategyFindBales:startWithoutCourse()
    -- to always have a valid course (for the traffic conflict detector mainly)
    self.course = Course.createStraightForwardCourse(self.vehicle, 25)
    self:startCourse(self.course, 1)

    self:info('Starting bale collect/wrap')

    for _, implement in pairs(self.vehicle:getAttachedImplements()) do
        self:info(' - %s', CpUtil.getName(implement.object))
    end
    self.vehicle:raiseAIEvent("onAIFieldWorkerStart", "onAIImplementStart")
    self:lowerImplements()
end

function AIDriveStrategyFindBales:collectNextBale()
    self.state = self.states.SEARCHING_FOR_NEXT_BALE
    if #self.bales > 0 then
        self:findPathToNextBale()
    else
        self:debug('No bales found, scan the field once more before leaving for the unload course.')
        self.bales, self.wrongWrapTypeFound = self:findBales()
        if #self.bales > 0 then
            self:debug('Found more bales, collecting them')
            self:findPathToNextBale()
            return
        end
        self.state = self.states.WAITING_FOR_IMPLEMENTS_TO_FOLD
    end
end

-----------------------------------------------------------------------------------------------------------------------
--- Implement handling
-----------------------------------------------------------------------------------------------------------------------
function AIDriveStrategyFindBales:initializeImplementControllers(vehicle)
    --- The bale loader/wrapper variable is used to check if a bale loader or wrapper was found.
    self.baleWrapper, self.baleWrapperController = self:addImplementController(vehicle, BaleWrapperController, BaleWrapper, {}, nil)
    if self.baleWrapperController then
        self.baleWrapperController:setKeepDrivingWhileWrapping(true)
    end
    self.baleLoader, self.baleLoaderController = self:addImplementController(vehicle, BaleLoaderController, BaleLoader, {}, nil)
    self.baleLoader = self.baleLoader or self:addImplementController(vehicle, APalletAutoLoaderController, nil, {}, "spec_aPalletAutoLoader")
    self.baleLoader = self.baleLoader or self:addImplementController(vehicle, UniversalAutoloadController, nil, {}, "spec_universalAutoload")
    self:addImplementController(vehicle, MotorController, Motorized, {}, nil)
    self:addImplementController(vehicle, WearableController, Wearable, {}, nil)
    self:addImplementController(vehicle, FoldableController, Foldable, {})
end

--- Checks if at least one baleloader is ready to load the next bale.
function AIDriveStrategyFindBales:isReadyToLoadNextBale()
    local isReadyToLoadNextBale = false
    for i, controller in pairs(self.controllers) do
        if controller.isReadyToLoadNextBale then
            isReadyToLoadNextBale = isReadyToLoadNextBale or controller:isReadyToLoadNextBale()
        end
    end
    return isReadyToLoadNextBale
end

--- Have any bales been loaded?
function AIDriveStrategyFindBales:hasBalesLoaded()
    local hasBales = false
    for i, controller in pairs(self.controllers) do
        if controller.hasBales then
            hasBales = hasBales or controller:hasBales()
        end
    end
    return hasBales
end

--- Can all bale loaders be folded?
function AIDriveStrategyFindBales:isReadyToFoldImplements()
    local canBeFolded = true
    for i, controller in pairs(self.controllers) do
        if controller.canBeFolded then
            canBeFolded = canBeFolded and controller:canBeFolded()
        end
    end
    return canBeFolded
end

function AIDriveStrategyFindBales:areBaleLoadersFull()
    local allBaleLoadersFilled = self.baleLoader ~= nil
    for i, controller in pairs(self.controllers) do
        if controller.isFull then
            allBaleLoadersFilled = allBaleLoadersFilled and controller:isFull()
        end
    end
    return allBaleLoadersFilled
end

function AIDriveStrategyFindBales:getBalesToIgnore()
    local objectsToIgnore = {}
    if self.lastBale then
        return { self.lastBale }
    elseif self.baleLoaderController then
        return self.baleLoaderController:getBalesToIgnore()
    else
        for i, controller in pairs(self.controllers) do
            if controller.getBalesToIgnore then
                for i, bale in pairs(controller:getBalesToIgnore()) do
                    table.insert(objectsToIgnore, bale)
                end

            end
        end
    end
    return objectsToIgnore
end

--- Gets called when we start driving to a bale.
function AIDriveStrategyFindBales:onStartDrivingToBale()
    for i, controller in pairs(self.controllers) do
        if controller.onStartDrivingToBale then
            controller:onStartDrivingToBale()
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------
--- Static parameters (won't change while driving)
-----------------------------------------------------------------------------------------------------------------------
function AIDriveStrategyFindBales:setAllStaticParameters()
    -- make sure we have a good turning radius set
    self.turningRadius = AIUtil.getTurningRadius(self.vehicle, true)
    -- Set the offset to 0, we'll take care of getting the grabber to the right place
    self.settings.toolOffsetX:setFloatValue(0)
    self.reverser = AIReverseDriver(self.vehicle, self.ppc)
    -- list of bales we tried (or in the process of trying) to find path for
    self.balesTried = {}
    -- when everything fails, reverse and try again. This is reset only when a pathfinding succeeds to avoid
    -- backing up forever
    self.numBalesLeftOver = 0
end

--- Bale wrap type for the bale loader.
function AIDriveStrategyFindBales:setAIVehicle(vehicle, jobParameters)
    AIDriveStrategyCourse.setAIVehicle(self, vehicle, jobParameters)
    self.baleWrapType = jobParameters.baleWrapType:getValue()
    self:debug("Bale type selected: %s", tostring(self.baleWrapType))
end
-----------------------------------------------------------------------------------------------------------------------
--- Bale finding
-----------------------------------------------------------------------------------------------------------------------
---@param bale BaleToCollect
function AIDriveStrategyFindBales:isBaleOnField(bale)
    local x, _, z = bale:getPosition()
    return CpMathUtil.isPointInPolygon(self.vehicle:cpGetFieldPolygon(), x, z)
end

--- Find bales on field
---@return BaleToCollect[] list of bales found
function AIDriveStrategyFindBales:findBales()
    local balesFound, baleWithWrongWrapType = {}, false
    for _, object in pairs(g_baleToCollectManager:getBales()) do
        local isValid, wrongWrapType = BaleToCollect.isValidBale(object,
                self.baleWrapper, self.baleLoader, self.baleWrapType)
        if isValid and g_baleToCollectManager:isValidBale(object) then
            local bale = BaleToCollect(object)
            -- if the bale has a mountObject it is already on the loader so ignore it
            if not object.mountObject and not self:isBaleGivenUp(object) and
                    g_currentMission.accessHandler:canFarmAccess(self.vehicle:getOwnerFarmId(), object) and
                    self:isBaleOnField(bale) then
                -- bales may .have multiple nodes, using the object.id deduplicates the list
                balesFound[object.id] = bale
            end
        end
        baleWithWrongWrapType = baleWithWrongWrapType or wrongWrapType
    end
    local bales = {}
    for _, bale in pairs(balesFound) do
        table.insert(bales, bale)
    end
    self:debug('Found %d bales.', #bales)
    --- Saves the number of bales found for the cp status.
    self.numBalesLeftOver = #bales
    return bales, baleWithWrongWrapType
end

---@param bales table[]
---@param balesToIgnore BaleToCollect[]|nil exclude bales on this list from the results
---@return BaleToCollect|nil closest bale
---@return number|nil distance to the closest bale
---@return number|nil index of the bale
function AIDriveStrategyFindBales:findClosestBale(bales, balesToIgnore)
    if not bales then
        return
    end
    local closestBale, minDistance, ix = nil, math.huge, 1
    local invalidBales = 0
    for i, bale in ipairs(bales) do
        if bale:isStillValid() then
            local _, _, _, d = bale:getPositionInfoFromNode(self.vehicle:getAIDirectionNode())
            self:debug('%d. bale (%d, %s) in %.1f m', i, bale:getId(), bale:getBaleObject(), d)
            if d < self.turningRadius * 4 then
                -- if it is really close, check the length of the Dubins path
                -- as we may need to drive a loop first to get to it
                d = self:getDubinsPathLengthToBale(bale)
                self:debug('    Dubins length is %.1f m', d)
            end
            if d < minDistance then
                if not table.hasElement(balesToIgnore or {}, bale) then
                    -- bale is not on the list of bales to ignore
                    closestBale = bale
                    minDistance = d
                    ix = i
                else
                    self:debug('    IGNORED')
                end
            end
        else
            --- When a bale gets wrapped it changes its identity and the node becomes invalid. This can happen
            --- when we pick up (and wrap) a bale other than the target bale, for example because there's another bale
            --- in the grabber's way. That is now wrapped but our bale list does not know about it so let's rescan the field
            self:debug('%d. bale (%d, %s) INVALID', i, bale:getId(), bale:getBaleObject())
            invalidBales = invalidBales + 1
            self:debug('Found invalid bale(s), rescanning field', invalidBales)
            self.bales = self:findBales()
            -- return empty, next time this is called everything should be ok
            return
        end
    end
    return closestBale, minDistance, ix
end

function AIDriveStrategyFindBales:getDubinsPathLengthToBale(bale)
    local start = PathfinderUtil.getVehiclePositionAsState3D(self.vehicle)
    local goal = self:getBaleTarget(bale)
    local solution = PathfinderUtil.dubinsSolver:solve(start, goal, self.turningRadius)
    return solution:getLength(self.turningRadius)
end

function AIDriveStrategyFindBales:findPathToNextBale()
    if self.bumpedIntoAnotherBale then
        self.bumpedIntoAnotherBale = false
        self:debug("Bumped into a bale other than the target on the way, rescanning.")
        self:findBales()
    end
    local bale, d, ix = self:findClosestBale(self.bales)
    if bale then
        if bale:isLoaded() then
            self:debug('Bale %d is already loaded, skipping', bale:getId())
            table.remove(self.bales, ix)
        else
            self:startPathfindingToBale(bale)
            -- remove bale from list
            table.remove(self.bales, ix)
        end
    end
end

--- The trick here is to get a target direction at the bale
function AIDriveStrategyFindBales:getBaleTarget(bale)
    -- first figure out the direction at the goal, as the pathfinder needs that.
    -- for now, just use the direction from our location towards the bale
    local xb, zb, yRot, d = bale:getPositionInfoFromNode(self.vehicle:getAIDirectionNode())
    return State3D(xb, -zb, CpMathUtil.angleFromGame(yRot))
end

--- Sets the driver as finished, so either a path
--- to the start marker as a park position can be used
--- or the driver stops directly.
function AIDriveStrategyFindBales:setFinished()
    if not self:isReadyToFoldImplements() then
        -- Waiting until the folding has finished..
        self:debugSparse("Waiting until an animation has finish, so the driver can be released ..")
        return
    end
    self.vehicle:prepareForAIDriving()
    if not self.vehicle:getIsAIReadyToDrive() then
        -- Waiting until the folding has finished..
        self:debugSparse("Waiting until an animation has finish, so the driver can be released ..")
        return
    end
    if self.invertedStartPositionMarkerNode then
        self:debug("A valid start position is found, so the driver tries to finish at the inverted goal node")
        self:startPathfindingToStartMarker()
    else
        self:finishJob()
    end
end

--- Finishes the job with the correct stop reason, as
--- the correct reason is needed for a possible AD takeover.
function AIDriveStrategyFindBales:finishJob()
    if self:areBaleLoadersFull() then
        self:debug('All the bale loaders are full, so stopping the job.')
        self.vehicle:stopCurrentAIJob(AIMessageErrorIsFull.new())
    elseif self:hasBalesLoaded() then
        if self.baleLoaderController and self.baleLoaderController:isChangingBaleSize() then
            self:debug('There really are no more bales on the field, so stopping the job')
            self.vehicle:stopCurrentAIJob(AIMessageSuccessFinishedJob.new())
        else
            self:debug('No more bales found on the field, so stopping the job and sending the loader to unload the bales.')
            self.vehicle:stopCurrentAIJob(AIMessageErrorIsFull.new())
        end
    elseif self.baleLoader and self.wrongWrapTypeFound then
        self:debug('Only bales with a wrong wrap type are left on the field.')
        self.vehicle:stopCurrentAIJob(AIMessageErrorWrongBaleWrapType.new())
    else
        self:debug('No more bales left on the field and no bales are loader and so on ..')
        self.vehicle:stopCurrentAIJob(AIMessageSuccessFinishedJob.new())
    end
end

-----------------------------------------------------------------------------------------------------------------------
--- Pathfinding
-----------------------------------------------------------------------------------------------------------------------

--- Pathfinding has finished
---@param controller PathfinderController
---@param success boolean
---@param course Course|nil
---@param goalNodeInvalid boolean|nil
function AIDriveStrategyFindBales:onPathfindingFinished(controller,
                                                        success, course, goalNodeInvalid)
    if self.state == self.states.DRIVING_TO_NEXT_BALE then
        if success then
            self.balesTried = {}
            self.reverseBlockedAtFieldEdge = false
            self:startCourse(course, 1)
            self:onStartDrivingToBale()
        else
            g_baleToCollectManager:unlockBalesByDriver(self)
            if #self.balesTried < 5 and #self.bales > #self.balesTried then
                if goalNodeInvalid then
                    -- there may be another bale too close to the previous one
                    self:debug('Finding path to next bale failed, goal node invalid.')
                    self:retryPathfindingWithAnotherBale()
                elseif self.reverseBlockedAtFieldEdge then
                    self:tryAnotherBaleInsteadOfReversing()
                elseif self:isNearFieldEdge() then
                    self.balesTried = {}
                    self:debug('Finding path to next bale failed, we are close to the field edge, back up a bit and then try again')
                    self:startReversing(self.states.REVERSING_AFTER_PATHFINDER_FAILURE)
                else
                    self:debug('Finding path to next bale failed, but we are not too close to the field edge')
                    self:retryPathfindingWithAnotherBale()
                end
            else
                self.balesTried = {}
                self:info('Pathfinding failed five times, giving up')
                self.vehicle:stopCurrentAIJob(AIMessageCpErrorNoPathFound.new())
            end
        end
    elseif self.state == self.states.DRIVING_TO_START_MARKER then
        if success then
            --- Append a straight alignment segment
            local x, _, z = course:getWaypointPosition(course:getNumberOfWaypoints())
            local dx, _, dz = localToWorld(self.invertedStartPositionMarkerNode, self.invertedGoalPositionOffset, 0, 0)

            course:append(Course.createFromTwoWorldPositions(self.vehicle, x, z, dx, dz,
                    0, 0, 0, 3, false))
            self:startCourse(course, 1)
        else
            self:finishJob()
        end
    end
end

--- After pathfinding failed, retry with another bale
function AIDriveStrategyFindBales:retryPathfindingWithAnotherBale()
    self:debug("Retrying with another bale.")
    local bale, d, ix = self:findClosestBale(self.bales, self.balesTried)
    if bale then
        self:startPathfindingToBale(bale)
    else
        self.balesTried = {}
        self:debug("No valid bale found on retry!")
        self.vehicle:stopCurrentAIJob(AIMessageCpErrorNoPathFound.new())
    end
end

function AIDriveStrategyFindBales:getPathfinderBaleTargetAsGoalNode(bale)
    local safeDistanceFromBale = bale:getSafeDistance()
    local halfVehicleWidth = AIUtil.getWidth(self.vehicle) / 2
    local goal = self:getBaleTarget(bale)
    local stuck = self.stuckAtBale and self.stuckAtBale[bale:getBaleObject()]
    if stuck then
        -- we got stuck the last time, come at the bale from a different direction
        goal.t = stuck.heading + self.retryHeadingOffsets[math.min(stuck.count, #self.retryHeadingOffsets)]
        self:debug('Got stuck %d time(s) at bale %d, approaching it %.0f degrees from the first direction',
                stuck.count, bale:getId(), math.deg(goal.t - stuck.heading))
    end
    self.lastGoalHeading = goal.t
    local configuredOffset = self:getConfiguredOffset()
    local offset = Vector(0, safeDistanceFromBale + configuredOffset)
    goal:add(offset:rotate(goal.t))
    self:debug('Start pathfinding to next bale (%d), safe distance from bale %.1f, half vehicle width %.1f, configured offset %s',
            bale:getId(), safeDistanceFromBale, halfVehicleWidth,
            configuredOffset and string.format('%.1f', configuredOffset) or 'n/a')
    return goal
end

---@param bale BaleToCollect
function AIDriveStrategyFindBales:startPathfindingToBale(bale)
    self.state = self.states.DRIVING_TO_NEXT_BALE
    self.targetBale = bale
    g_baleToCollectManager:lockBale(bale:getBaleObject(), self)
    local objectsToIgnore = self:getBalesToIgnore()
    -- ignore the target bale, we actually want to hit it, there really is no reason to trigger collisions with it
    table.insert(objectsToIgnore, bale:getBaleObject())
    local context = PathfinderContext(self.vehicle):objectsToIgnore(objectsToIgnore)
    context:allowReverse(false):maxFruitPercent(self.settings.avoidFruit:getValue() and 10 or math.huge)
    -- the bales are on the field, so stay on the field: leaving it costs so much it's practically never chosen
    context:offFieldPenalty(self.offFieldPenalty)
    local stuck = self.stuckAtBale and self.stuckAtBale[bale:getBaleObject()]
    if stuck then
        -- and keep away from the spot where we got stuck
        context:areaToAvoid(stuck.area)
    end
    table.insert(self.balesTried, bale)
    self.pathfinderController:registerListeners(self, self.onPathfindingFinished, nil,
            self.onPathfindingObstacleAtStart)
    self.pathfinderController:findPathToGoal(context, self:getPathfinderBaleTargetAsGoalNode(bale))
end

--- Searches for a path to the start marker in the inverted direction.
function AIDriveStrategyFindBales:startPathfindingToStartMarker()
    self.state = self.states.DRIVING_TO_START_MARKER
    local context = PathfinderContext(self.vehicle):objectsToIgnore(self:getBalesToIgnore())
    context:allowReverse(false):maxFruitPercent(self.settings.avoidFruit:getValue() and 10 or math.huge)
    self.pathfinderController:findPathToNode(context, self.invertedStartPositionMarkerNode,
            self.invertedGoalPositionOffset, -1.5 * AIUtil.getLength(self.vehicle), 2)
end

function AIDriveStrategyFindBales:onPathfindingObstacleAtStart(controller, lastContext, maxDistance, trailerCollisionsOnly)
    g_baleToCollectManager:unlockBalesByDriver(self)
    if self.reverseBlockedAtFieldEdge then
        -- balesTried is kept, so every bale is tried once and then we give up instead of looping
        self:tryAnotherBaleInsteadOfReversing()
        return
    end
    self.balesTried = {}
    self:debug('Pathfinding detected obstacle at start, back up and retry')
    self:startReversing(self.states.REVERSING_DUE_TO_OBSTACLE_AHEAD)
end

--- The reverse after a failed pathfinding is a blind straight line, so stop it before the back of the
--- last implement leaves the field.
function AIDriveStrategyFindBales:stopReversingAtFieldEdge()
    local implement = AIUtil.getLastAttachedImplement(self.vehicle, true)
    local x, _, z = localToWorld(implement.rootNode, 0, 0, -implement.size.length / 2 + implement.size.lengthOffset)
    if not CpMathUtil.isPointInPolygon(self.vehicle:cpGetFieldPolygon(), x, z) then
        self:debug('Reversing would take us off the field, stopping at the edge')
        self.reverseBlockedAtFieldEdge = true
        self.state = self.states.SEARCHING_FOR_NEXT_BALE
    end
end

--- Can't back up any further without leaving the field: try another bale instead of reversing again.
function AIDriveStrategyFindBales:tryAnotherBaleInsteadOfReversing()
    self:debug('At the field edge, not reversing again, trying another bale')
    self:retryPathfindingWithAnotherBale()
end

function AIDriveStrategyFindBales:startReversing(state)
    self.state = state
    self:startCourse(Course.createStraightReverseCourse(self.vehicle, 10), 1)
end

function AIDriveStrategyFindBales:isNearFieldEdge()
    local x, _, z = localToWorld(self.vehicle:getAIDirectionNode(), 0, 0, 0)
    local vehicleIsOnField = CpFieldUtil.isOnField(x, z)
    x, _, z = localToWorld(self.vehicle:getAIDirectionNode(), 0, 0, 1.2 * self.turningRadius)
    local isFieldInFrontOfVehicle = CpFieldUtil.isOnFieldArea(x, z)
    self:debug('vehicle is on field: %s, field in front of vehicle: %s',
            tostring(vehicleIsOnField), tostring(isFieldInFrontOfVehicle))
    return vehicleIsOnField and not isFieldInFrontOfVehicle
end

-----------------------------------------------------------------------------------------------------------------------
--- Event listeners
-----------------------------------------------------------------------------------------------------------------------
function AIDriveStrategyFindBales:onWaypointPassed(ix, course)
    if course:isLastWaypointIx(ix) then
        if self.state == self.states.DRIVING_TO_NEXT_BALE then
            self:debug('last waypoint while driving to next bale reached')
            self:startApproachingBale()
        elseif self.state == self.states.WORKING_ON_BALE then
            self:debug('last waypoint on bale pickup reached, start collecting bales again')
            self:collectNextBale()
        elseif self.state == self.states.APPROACHING_BALE then
            self:debug('looks like somehow we missed a bale, rescanning field')
            self.bales = self:findBales()
            self:collectNextBale()
        elseif self.state == self.states.REVERSING_AFTER_PATHFINDER_FAILURE then
            self:debug('backed up after pathfinder failed, trying again')
            self.state = self.states.SEARCHING_FOR_NEXT_BALE
        elseif self.state == self.states.REVERSING_DUE_TO_OBSTACLE_AHEAD then
            self:debug('backed due to obstacle, trying again')
            self.state = self.states.SEARCHING_FOR_NEXT_BALE
        elseif self.state == self.states.DRIVING_TO_START_MARKER then
            self:debug("Inverted start marker position is reached.")
            self:finishJob()
        end
    end
end

function AIDriveStrategyFindBales:startApproachingBale()
    self:debug('Approaching bale...')
    self:startCourse(Course.createStraightForwardCourse(self.vehicle, 20), 1)
    self.state = self.states.APPROACHING_BALE
end

--- this the part doing the actual work on the field after/before all
--- implements are started/lowered etc.
function AIDriveStrategyFindBales:getDriveData(dt, vX, vY, vZ)
    self:updateLowFrequencyImplementControllers()
    self:updateLowFrequencyPathfinder()
    if self.state == self.states.WAITING_FOR_FIELD_BOUNDARY_DETECTION then
        self:setMaxSpeed(0)
        if self:waitForFieldBoundary() then
            self:debug('Have field boundary now, checking positions.')
            if self:isPositionOk() then
                self.state = self.states.INITIAL
            end
        end
    elseif self.state == self.states.INITIAL then
        if self:getCanContinueWork() then
            self.state = self.states.SEARCHING_FOR_NEXT_BALE
        else
            --- Waiting until the unfolding has finished.
            if self.bales == nil then
                --- Makes sure the hud bale counter already gets updated
                self.bales = self:findBales()
            end
            self:setMaxSpeed(0)
        end
    elseif self.state == self.states.SEARCHING_FOR_NEXT_BALE then
        self:setMaxSpeed(0)
        self:debug('work: searching for next bale')
        self:collectNextBale()
    elseif self.state == self.states.WAITING_FOR_PATHFINDER then
        self:setMaxSpeed(0)
    elseif self.state == self.states.DRIVING_TO_NEXT_BALE then
        self:setMaxSpeed(self.settings.fieldSpeed:getValue())
        if not self.bumpedIntoAnotherBale and self.baleLoaderController and self.baleLoaderController:isGrabbingBale() then
            -- we are not at the bale yet but grabbing something, likely bumped into another bale
            self.bumpedIntoAnotherBale = true
        end
    elseif self.state == self.states.APPROACHING_BALE then
        self:setMaxSpeed(self.settings.fieldWorkSpeed:getValue() / 2)
        self:approachBale()
    elseif self.state == self.states.WORKING_ON_BALE then
        self:workOnBale()
        self:setMaxSpeed(0)
    elseif self.state == self.states.REVERSING_AFTER_PATHFINDER_FAILURE then
        self:setMaxSpeed(self.settings.reverseSpeed:getValue())
        self:stopReversingAtFieldEdge()
    elseif self.state == self.states.REVERSING_DUE_TO_OBSTACLE_AHEAD then
        self:setMaxSpeed(self.settings.reverseSpeed:getValue())
        self:stopReversingAtFieldEdge()
    elseif self.state == self.states.DRIVING_TO_START_MARKER then
        self:setMaxSpeed(self.settings.fieldSpeed:getValue())
    elseif self.state == self.states.WAITING_FOR_IMPLEMENTS_TO_FOLD then
        if self.baleWrapperController and self.baleWrapperController:isWorking() then
            self:debugSparse('Waiting for the wrapper to finish the last bale ..')
        else
            self:setFinished()
        end
        self:setMaxSpeed(0) --- folding
    end

    if self.baleWrapperController then
        if self.baleWrapperController:isWorking() then
            if self.state == self.states.APPROACHING_BALE then
                -- the wrapper can't grab the next bale until the previous one is dropped
                self:setMaxSpeed(0)
            else
                -- drive slowly on to the next bale while wrapping
                self:setMaxSpeed(self.settings.fieldWorkSpeed:getValue() / 2)
            end
        elseif self.wrappingPreviousBale then
            self.wrappingPreviousBale = false
            self.lastBale = self.baleWrapperController:getLastDroppedBale() or self.lastBale
            self:debug('Bale wrapped and dropped, last dropped bale %s', tostring(self.lastBale))
        end
    end

    self:checkIfStuck()

    local moveForwards = not self.ppc:isReversing()
    local gx, gz
    if not moveForwards then
        local maxSpeed
        gx, gz, maxSpeed = self:getReverseDriveData()
        self:setMaxSpeed(maxSpeed)
    else
        gx, _, gz = self.ppc:getGoalPointPosition()
    end

    return gx, gz, moveForwards, self.maxSpeed, 100
end

--- Stuck on the way to a bale (tree, fence, curb): we want to move, but haven't for isStuckMs.
--- Leave that bale for later and go for the next closest one. Next time, come at it from a different
--- direction (these offsets from the direction we first got stuck in, in turn) and keep away from the
--- spot we got stuck at. Stuck from every direction: the bale is left on the field for good.
AIDriveStrategyFindBales.isStuckMs = 1000 * 15
AIDriveStrategyFindBales.retryHeadingOffsets = { math.pi, math.pi / 2, -math.pi / 2 }
AIDriveStrategyFindBales.maxStuckPerBale = #AIDriveStrategyFindBales.retryHeadingOffsets + 1

function AIDriveStrategyFindBales:checkIfStuck()
    local tryingToMove = (self.state == self.states.DRIVING_TO_NEXT_BALE or
            self.state == self.states.APPROACHING_BALE) and
            not self.pathfinderController:isActive() and (self.maxSpeed or 0) > 0
    if not tryingToMove or not AIUtil.isStopped(self.vehicle) then
        self.stuckSince = nil
        return
    end
    self.stuckSince = self.stuckSince or g_time
    if g_time - self.stuckSince < self.isStuckMs then
        return
    end
    self.stuckSince = nil
    self.stuckAtBale = self.stuckAtBale or {}
    local baleObject = self.targetBale and self.targetBale:getBaleObject()
    if baleObject then
        local stuck = self.stuckAtBale[baleObject] or { count = 0, heading = self.lastGoalHeading or 0 }
        stuck.count = stuck.count + 1
        -- remember the spot: the area in front of where we are now
        CpUtil.destroyNode(stuck.node)
        local directionNode = self.vehicle:getAIDirectionNode()
        local x, _, z = getWorldTranslation(directionNode)
        local _, yRot, _ = getWorldRotation(directionNode)
        stuck.node = CpUtil.createNode('Bale finder stuck spot', x, z, yRot)
        stuck.area = PathfinderUtil.NodeArea(stuck.node, -4, -2, 8, 10)
        self.stuckAtBale[baleObject] = stuck
        self:info('Stuck for %d s on the way to bale %d (%d. time), trying the next bale',
                self.isStuckMs / 1000, self.targetBale:getId(), stuck.count)
    else
        self:info('Stuck for %d s, trying the next bale', self.isStuckMs / 1000)
    end
    g_baleToCollectManager:unlockBalesByDriver(self)
    self.balesTried = {}
    self:collectNextBale()
end

--- Did we get stuck at this bale too often to try it again?
function AIDriveStrategyFindBales:isBaleGivenUp(baleObject)
    local stuck = self.stuckAtBale and self.stuckAtBale[baleObject]
    return stuck ~= nil and stuck.count >= self.maxStuckPerBale
end

function AIDriveStrategyFindBales:approachBale()
    if self.baleLoaderController then
        if self.baleLoaderController:isGrabbingBale() then
            self:debug('Start picking up bale')
            self.state = self.states.WORKING_ON_BALE
            self.numBalesLeftOver = math.max(self.numBalesLeftOver - 1, 0)
        end
    elseif self.baleWrapper then
        self.baleWrapperController:handleBaleWrapper()
        -- while the previous bale is still being wrapped, the wrapper is busy with that one, not this one
        if self.baleWrapperController:isWorking() and not self.wrappingPreviousBale then
            -- ignore the bale on the wrapper (and later dropped), so the pathfinder doesn't think it is blocked
            self.lastBale = self.baleWrapperController:getBaleOnWrapper()
            self.wrappingPreviousBale = true
            self:debug('Start wrapping bale %s, driving on to the next one', tostring(self.lastBale))
            self.numBalesLeftOver = math.max(self.numBalesLeftOver - 1, 0)
            self:collectNextBale()
        end
    else
        if self:isReadyToLoadNextBale() then 
            self:debug('Successfully loaded a baled')
            self:collectNextBale()
            self.numBalesLeftOver = math.max(self.numBalesLeftOver - 1, 0)
        end
    end
end

--- Check if we have the field polygon (as we need it to find the bales) and if we are on or close to the field.
--- The field polygon generation is started by the job and if we direct start, may not have finished yet.
--- Once we have it, check the vehicle and start positions.
function AIDriveStrategyFindBales:isPositionOk()
    --- check, if the vehicle is near the field.
    local x, _, z = getWorldTranslation(self.vehicle.rootNode)
    if CpMathUtil.isPointInPolygon(self.vehicle:cpGetFieldPolygon(), x, z) or
            CpMathUtil.isWithinDistanceToPolygon(self.vehicle:cpGetFieldPolygon(), x, z, AIDriveStrategyFindBales.minStartDistanceToField) then
        -- now check the start position
        x, z = self.jobParameters.startPosition:getPosition()
        local angle = self.jobParameters.startPosition:getAngle()
        if x ~= nil and z ~= nil and angle ~= nil then
            --- Additional safety check, if the position is on the field or near it.
            if CpMathUtil.isPointInPolygon(self.vehicle:cpGetFieldPolygon(), x, z)
                    or CpMathUtil.isWithinDistanceToPolygon(self.vehicle:cpGetFieldPolygon(), x, z,
                    2 * AIDriveStrategyFindBales.minStartDistanceToField) then
                --- Goal position marker set in the ai menu rotated by 180 degree.
                self.invertedStartPositionMarkerNode = CpUtil.createNode("Inverted Start position marker",
                        x, z, angle + math.pi)
                self:debug("Valid goal position marker was set.")
            else
                self:debug("Start position is too far away from the field for a valid goal position!")
            end
        else
            self:debug("Invalid start position found!")
        end
    else
        self:debug('Vehicle not on field or too far away from field')
        self.vehicle:stopCurrentAIJob(AIMessageErrorTooFarFromField.new())
        return false
    end
    return true
end

function AIDriveStrategyFindBales:workOnBale()
    if self.baleLoaderController then
        if not self.baleLoaderController:isGrabbingBale() then
            self:debug('Bale picked up, moving on to the next')
            self:collectNextBale()
        end
    end
    if self.baleWrapper then
        self.baleWrapperController:handleBaleWrapper()
        if not self.baleWrapperController:isWorking() then
            self.lastBale = self.baleWrapperController:getLastDroppedBale()
            self:debug('Bale wrapped, moving on to the next, last dropped bale %s', self.lastBale)
            self:collectNextBale()
        end
    end
end

function AIDriveStrategyFindBales:calculateTightTurnOffset()
    self.tightTurnOffset = 0
end

function AIDriveStrategyFindBales:getConfiguredOffset()
    return self.settings.baleCollectorOffset:getValue()
end

function AIDriveStrategyFindBales:isAutoContinueAtWaitPointEnabled()
    return true
end

function AIDriveStrategyFindBales:isStoppingAtWaitPointAllowed()
    return true
end

function AIDriveStrategyFindBales:update(dt)
    AIDriveStrategyCourse.update(self, dt)
    self:updateImplementControllers(dt)

    if CpDebug:isChannelActive(self.debugChannel, self.vehicle) then
        if self.course then
            self.course:draw()
        elseif self.ppc:getCourse() then
            self.ppc:getCourse():draw()
        end
    end
    if self.state ~= self.states.DRIVING_TO_START_MARKER and
            self.state ~= self.states.WAITING_FOR_IMPLEMENTS_TO_FOLD then
        if self:areBaleLoadersFull() then
            self.state = self.states.WAITING_FOR_IMPLEMENTS_TO_FOLD
        end
    end
    --- Ignores the loaded auto loader bales.
    --- TODO: Maybe add a delay here?
    local loadedBales = self:getBalesToIgnore()
    for _, bale in pairs(loadedBales) do
        --- Makes sure these loaded bales from an autoload trailer,
        --- can't be selected as a target by another bale loader.
        g_baleToCollectManager:temporarilyLeaseBale(bale)
    end
end

---@param status CpStatus
function AIDriveStrategyFindBales:updateCpStatus(status)
    status:setBaleData(self.numBalesLeftOver)
end