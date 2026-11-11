--- The CourseCorrect panel: the Courseplay hud as one compact panel, in the look of the CourseCorrect (FS25_Guidance)
--- panel. The course of the vehicle on a small map with the field's outline, what it will do, the settings that
--- matter (more behind "More settings") and big Start / Stop buttons. Everything it does goes through Courseplay's own
--- functions and settings, nothing of Courseplay's driving changes.
--- Drawn new every frame from the vehicle's state, with the same functions as the classic hud (CpBaseHud), which
--- stays selectable in the global settings.
---@class CpModernHud
CpModernHud = CpObject()

local Draw = CpHudDraw

CpModernHud.TITLE = "CourseCorrect"
CpModernHud.WIDTH = 360 -- reference pixels (1920x1080), scaled with the ui scale
CpModernHud.PAD = 14
CpModernHud.ROW = 30
CpModernHud.PLOT = 230

--- Colors as they look on the screen (sRGB), see CpHudDraw.linear
CpModernHud.C = {
    bg = {0.06, 0.07, 0.085, 0.94},
    shadow = {0, 0, 0, 0.35},
    surface = {0.11, 0.125, 0.145, 1},
    chip = {0.15, 0.165, 0.19, 1},
    track = {1, 1, 1, 0.10},
    hover = {0.20, 0.22, 0.26, 1},
    line = {1, 1, 1, 0.06},
    text = {0.93, 0.94, 0.95, 1},
    muted = {0.60, 0.64, 0.69, 1},
    accent = {0.20, 0.72, 0.45, 1},
    accentHover = {0.25, 0.80, 0.51, 1},
    danger = {0.86, 0.30, 0.30, 1},
    dangerHover = {0.93, 0.38, 0.38, 1},
    warn = {0.98, 0.75, 0.25, 1},
    pill = {0.18, 0.20, 0.23, 1},
    white = {1, 1, 1, 1},
}

--- What the panel shows: the course or the saved courses
CpModernHud.VIEW_COURSE = "course"
CpModernHud.VIEW_SAVED = "saved"
CpModernHud.VIEW_FLEET = "fleet"
CpModernHud.VIEW_SETTINGS = "settings"
CpModernHud.VIEWS = {CpModernHud.VIEW_COURSE, CpModernHud.VIEW_SAVED, CpModernHud.VIEW_FLEET, CpModernHud.VIEW_SETTINGS}
--- The settings shown: vehicle, generator or global, and which group of the page (as the menus' sub tabs)
CpModernHud.settingsPage = "vehicle"
CpModernHud.settingsGroup = 1
CpModernHud.view = CpModernHud.VIEW_COURSE
--- The folder open in the saved courses (its name, nil: all folders)
CpModernHud.savedFolder = nil

--- The same for all vehicles: where the panel is (left edge, top edge; screen 0..1, nil: the default place),
--- minimized, the map zoom and what is unfolded. The position and minimized are saved with the user settings.
CpModernHud.posX = nil
CpModernHud.posTop = nil
CpModernHud.minimized = false
CpModernHud.mapZoomIx = 1
CpModernHud.showMore = false
CpModernHud.showDetails = false
--- The course map shown (off: the course's information in its place); saved with the user settings
CpModernHud.showMap = true
CpModernHud.xmlKey = "ModernHud"

CpModernHud.MAP_ZOOMS = {1, 2, 4, 8}
CpModernHud.WHEEL_DELAY = 120 -- ms between two zoom steps of the mouse wheel
CpModernHud.MAP_RECENTER = 0.2 -- zoomed in, the map centers on the vehicle again once it is this part of the view away
CpModernHud.DROPDOWN_ROWS = 9 -- options shown at once in an open list (more: the mouse wheel scrolls)
CpModernHud.DROPDOWN_MAX_OPTIONS = 60 -- settings with more values have no list, only - and +
CpModernHud.MESSAGE_MS = 6000
CpModernHud.MESSAGE_LINES = 4
CpModernHud.GENERATE_TIMEOUT_MS = 20000

--- The job switch: the values of the hud's selected job setting, with short names
CpModernHud.JOB_TEXTS = {
    [1] = "CP_cc_job_fieldWork",
    [2] = "CP_cc_job_bales",
    [3] = "CP_cc_job_bunkerSilo",
    [4] = "CP_cc_job_siloLoader",
    [5] = "CP_cc_job_unloader",
}

--- The course generator settings shown always, the others are behind "More settings"
CpModernHud.MAIN_GENERATOR_SETTINGS = {"workWidth", "numberOfHeadlands", "centerMode", "autoRowAngle",
                                       "manualRowAngleDeg"}

function CpModernHud.registerXmlSchema(xmlSchema, baseKey)
    xmlSchema:register(XMLValueType.FLOAT, baseKey .. CpModernHud.xmlKey .. "#posX", "CourseCorrect panel left edge.")
    xmlSchema:register(XMLValueType.FLOAT, baseKey .. CpModernHud.xmlKey .. "#posTop", "CourseCorrect panel top edge.")
    xmlSchema:register(XMLValueType.BOOL, baseKey .. CpModernHud.xmlKey .. "#minimized", "CourseCorrect panel minimized.")
    xmlSchema:register(XMLValueType.BOOL, baseKey .. CpModernHud.xmlKey .. "#startOnArrival",
            "Start the course when AutoDrive has brought the vehicle to its field.")
    xmlSchema:register(XMLValueType.BOOL, baseKey .. CpModernHud.xmlKey .. "#showMap", "CourseCorrect panel shows the map.")
end

function CpModernHud.saveToXmlFile(xmlFile, baseKey)
    if CpModernHud.posX ~= nil and CpModernHud.posTop ~= nil then
        xmlFile:setValue(baseKey .. CpModernHud.xmlKey .. "#posX", CpModernHud.posX)
        xmlFile:setValue(baseKey .. CpModernHud.xmlKey .. "#posTop", CpModernHud.posTop)
    end
    xmlFile:setValue(baseKey .. CpModernHud.xmlKey .. "#minimized", CpModernHud.minimized)
    xmlFile:setValue(baseKey .. CpModernHud.xmlKey .. "#startOnArrival", CpModernHud.startOnArrival)
    xmlFile:setValue(baseKey .. CpModernHud.xmlKey .. "#showMap", CpModernHud.showMap)
end

function CpModernHud.loadFromXmlFile(xmlFile, baseKey)
    CpModernHud.posX = xmlFile:getValue(baseKey .. CpModernHud.xmlKey .. "#posX")
    CpModernHud.posTop = xmlFile:getValue(baseKey .. CpModernHud.xmlKey .. "#posTop")
    CpModernHud.minimized = xmlFile:getValue(baseKey .. CpModernHud.xmlKey .. "#minimized", false)
    CpModernHud.startOnArrival = xmlFile:getValue(baseKey .. CpModernHud.xmlKey .. "#startOnArrival", true)
    CpModernHud.showMap = xmlFile:getValue(baseKey .. CpModernHud.xmlKey .. "#showMap", true)
end

local function t(key, ...)
    local text = g_i18n:getText(key)
    if select("#", ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

--- Is AutoDrive driving the vehicle?
local function isAutoDriveActive(vehicle)
    local stateModule = vehicle.ad and vehicle.ad.stateModule
    return stateModule ~= nil and stateModule.isActive ~= nil and stateModule:isActive()
end

function CpModernHud:init(vehicle)
    self.vehicle = vehicle
    self.isOpen = false
    self.elements = {}
    self.wheelElements = {}
    self.popupElements = {}
    self.mouseX, self.mouseY = nil, nil
end

function CpModernHud:delete()
    self.isOpen = false
    self:releaseKeys()
end

------------------------------------------------------------------------------------------------------------------------
--- Same functions as the classic hud
------------------------------------------------------------------------------------------------------------------------

function CpModernHud:openClose(open)
    self.isOpen = open
    self.dragging, self.dropdown, self.mapPan, self.confirmClear = nil, nil, nil, nil
    if not open then
        self:releaseKeys()
    end
end

function CpModernHud:getIsOpen()
    return self.isOpen
end

function CpModernHud:isMouseOverArea(posX, posY)
    local box = self.box
    return self.isOpen and box ~= nil and posX >= box.x and posX <= box.x + box.w
            and posY >= box.y and posY <= box.y + box.h
end

function CpModernHud:getIsHovered()
    return self.mouseX ~= nil and g_inputBinding:getShowMouseCursor() and self:isMouseOverArea(self.mouseX, self.mouseY)
end

function CpModernHud:moveToPosition(x, y)
    CpModernHud.posX, CpModernHud.posTop = x, y
end

function CpModernHud:isBunkerSiloLayoutActive()
    return self.vehicle:cpIsHudBunkerSiloJobSelected()
end

function CpModernHud:isSiloLoaderLayoutActive()
    return self.vehicle:cpIsHudSiloLoaderJobSelected()
end

function CpModernHud:isCombineUnloaderLayoutActive()
    return self.vehicle:cpIsHudUnloaderJobSelected()
end

------------------------------------------------------------------------------------------------------------------------
--- Sizes and input
------------------------------------------------------------------------------------------------------------------------

function CpModernHud:w(px)
    local x = getNormalizedScreenValues(px * g_gameSettings:getValue("uiScale"), 0)
    return x
end

function CpModernHud:h(px)
    local _, y = getNormalizedScreenValues(0, px * g_gameSettings:getValue("uiScale"))
    return y
end

--- Common sizes, in screen units
function CpModernHud:metrics()
    return {
        pad = self:w(CpModernHud.PAD), padY = self:h(CpModernHud.PAD), rowH = self:h(CpModernHud.ROW),
        width = self:w(CpModernHud.WIDTH), textSize = self:h(13), smallSize = self:h(11.5), titleSize = self:h(17),
        radius = self:h(12), smallRadius = self:h(7), headerH = self:h(54), tabsH = self:h(36),
    }
end

function CpModernHud:isHover(x, y, w, h)
    if self.mouseX == nil or not g_inputBinding:getShowMouseCursor() then
        return false
    end
    return self.mouseX >= x and self.mouseX <= x + w and self.mouseY >= y and self.mouseY <= y + h
end

--- A click target for this frame
function CpModernHud:addElement(x, y, w, h, onClick)
    table.insert(self.elements, {x = x, y = y, w = w, h = h, onClick = onClick})
end

--- A mouse wheel target for this frame, onWheel(1 up / -1 down)
function CpModernHud:addWheelElement(x, y, w, h, onWheel)
    table.insert(self.wheelElements, {x = x, y = y, w = w, h = h, onWheel = onWheel})
end

local function isWheel(button)
    return button == Input.MOUSE_BUTTON_WHEEL_UP or button == Input.MOUSE_BUTTON_WHEEL_DOWN
end

function CpModernHud:mouseEvent(posX, posY, isDown, isUp, button)
    if not self.isOpen then
        return
    end
    self.mouseX, self.mouseY = posX, posY
    if self.dragging then
        local d = self.dragging
        CpModernHud.posX, CpModernHud.posTop = d.x + posX - d.mouseX, d.top + posY - d.mouseY
        if isUp and button == Input.MOUSE_BUTTON_LEFT then
            self.dragging = nil
        end
        return
    end
    -- the zoomed map being moved
    if self.mapPan then
        local p = self.mapPan
        -- (meters per screen unit: the map's width in meters over its width on the screen)
        local perX = p.span / p.w
        local perY = perX * g_screenHeight / g_screenWidth
        self.mapCenter = {x = p.x - (posX - p.mouseX) * perX, z = p.z + (posY - p.mouseY) * perY, zoom = p.zoom,
                          pinned = true}
        if isUp and button == Input.MOUSE_BUTTON_LEFT then
            self.mapPan = nil
        end
        return
    end
    if not isDown or not g_inputBinding:getShowMouseCursor() then
        return
    end
    -- an open list: the wheel scrolls it, a click picks an option or (anywhere else) closes it
    local d = self.dropdown
    if d and d.box then
        if isWheel(button) and self:isHover(d.box.x, d.box.y, d.box.w, d.box.h) then
            d.scroll = (d.scroll or 0) + (button == Input.MOUSE_BUTTON_WHEEL_UP and -1 or 1)
            return
        end
        if button == Input.MOUSE_BUTTON_LEFT then
            for _, e in ipairs(self.popupElements) do
                if self:isHover(e.x, e.y, e.w, e.h) then
                    e.onClick()
                    return
                end
            end
            -- (its own value again: the row's click closes it)
            if not self:isHover(d.x, d.y, d.w, d.rowH) then
                self.dropdown = nil
                return
            end
        end
    end
    if isWheel(button) then
        local dir = button == Input.MOUSE_BUTTON_WHEEL_UP and 1 or -1
        -- over the course map: zoom
        local box = self.plotShown and self.plot and self.plot.box
        if box and self:isHover(box.x, box.y, box.w, box.h) then
            if (g_time or 0) >= (self.wheelTime or 0) + CpModernHud.WHEEL_DELAY then
                self.wheelTime = g_time or 0
                self:zoomMap(dir)
            end
            return
        end
        for _, e in ipairs(self.wheelElements) do
            if self:isHover(e.x, e.y, e.w, e.h) then
                e.onWheel(dir)
                return
            end
        end
    elseif button == Input.MOUSE_BUTTON_LEFT then
        for _, e in ipairs(self.elements) do
            if self:isHover(e.x, e.y, e.w, e.h) then
                e.onClick()
                return
            end
        end
        -- on the zoomed map: move the map (it stops following the vehicle till zoomed again)
        local plot = self.plot
        local box = self.plotShown and plot and plot.box
        if box and (plot.zoom or 1) > 1 and self.mapCenter and self:isHover(box.x, box.y, box.w, box.h) then
            self.mapPan = {mouseX = posX, mouseY = posY, x = self.mapCenter.x, z = self.mapCenter.z,
                           zoom = self.mapCenter.zoom, span = plot.span, w = box.w}
            return
        end
        -- anywhere else on the panel: pick it up
        box = self.box
        if box and self:isHover(box.x, box.y, box.w, box.h) and g_Courseplay.globalSettings.isHudMoveable:getValue() then
            self.dragging = {mouseX = posX, mouseY = posY, x = box.x, top = box.y + box.h}
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Small parts
------------------------------------------------------------------------------------------------------------------------

--- Text vertically centered in a box of height h at y
function CpModernHud:textIn(x, y, h, size, text, color, align, bold)
    -- under an open list: not drawn (the game draws all text after all boxes, it would show through the list)
    local box = not self.drawingDropdown and self.dropdown and self.dropdown.box
    if box then
        local w = Draw.textWidth(size, text, bold)
        local left = x
        if align == RenderText.ALIGN_CENTER then
            left = x - w / 2
        elseif align == RenderText.ALIGN_RIGHT then
            left = x - w
        end
        if left < box.x + box.w and left + w > box.x and y < box.y + box.h and y + h > box.y then
            return
        end
    end
    Draw.text(x, y + h / 2 - size * 0.36, size, text, color, align, bold)
end

--- A rounded button; onClick nil draws it disabled
function CpModernHud:button(x, y, w, h, label, color, hoverColor, textColor, onClick, size)
    local hover = onClick ~= nil and self:isHover(x, y, w, h)
    size = size or self:h(13)
    Draw.roundRect(x, y, w, h, math.min(self:h(7), h / 2), hover and hoverColor or color)
    self:textIn(x + w / 2, y, h, size, Draw.fit(label, size, w - self:w(8), true), textColor,
            RenderText.ALIGN_CENTER, true)
    if onClick then
        self:addElement(x, y, w, h, onClick)
    end
end

--- A small button on the map (and other surfaces), as wide as its label
function CpModernHud:chip(x, y, label, onClick, highlighted)
    local C = CpModernHud.C
    local m = self:metrics()
    local w, h = Draw.textWidth(m.smallSize, label, true) + self:w(18), self:h(22)
    self:button(x, y, w, h, label, highlighted and C.accent or C.chip, highlighted and C.accentHover or C.hover,
            highlighted and C.white or C.text, onClick, m.smallSize)
    return w, h
end

local function splitLong(word, size, width)
    local parts = {}
    while Draw.textWidth(size, word) > width and #word > 1 do
        local n = #word
        while n > 1 and Draw.textWidth(size, word:sub(1, n)) > width do
            n = n - 1
        end
        table.insert(parts, word:sub(1, n))
        word = word:sub(n + 1)
    end
    table.insert(parts, word)
    return parts
end

--- The text in lines of at most 'width', and at most maxLines (the last one cut short)
local function wrapLines(text, size, width, maxLines)
    local lines, line = {}, nil
    for word in text:gmatch("%S+") do
        for _, part in ipairs(splitLong(word, size, width)) do
            local candidate = line and (line .. " " .. part) or part
            if line and Draw.textWidth(size, candidate) > width then
                table.insert(lines, line)
                line = part
            else
                line = candidate
            end
        end
    end
    if line then
        table.insert(lines, line)
    end
    if maxLines and #lines > maxLines then
        local last = table.concat(lines, " ", maxLines)
        for i = #lines, maxLines, -1 do
            lines[i] = nil
        end
        lines[maxLines] = Draw.fit(last, size, width)
    end
    return lines
end

function CpModernHud:countLines(text, size, width)
    return #wrapLines(text, size, width)
end

--- Text in lines from the top of the box (x, y, h), each line 'size' * 1.4 high; centered: x is the middle
function CpModernHud:textLines(x, y, h, size, text, width, color, maxLines, centered)
    local lineH = size * 1.4
    local lines = wrapLines(text, size, width, maxLines)
    for i, line in ipairs(lines) do
        self:textIn(x, y + h - i * lineH, lineH, size, line, color, centered and RenderText.ALIGN_CENTER or nil)
    end
    return #lines * lineH
end

function CpModernHud:showMessage(text, isError)
    self.message = text
    self.messageIsError = isError
    self.messageUntil = (g_time or 0) + CpModernHud.MESSAGE_MS
end

--- The message under the content: its height (0 without one)
function CpModernHud:messageHeight()
    if self.message and (g_time or 0) > (self.messageUntil or 0) then
        self.message = nil
    end
    if not self.message then
        return 0
    end
    local m = self:metrics()
    local n = math.max(1, math.min(CpModernHud.MESSAGE_LINES,
            self:countLines(self.message, m.smallSize, m.width - 2 * m.pad)))
    return n * m.smallSize * 1.4 + self:h(8)
end

function CpModernHud:drawMessage(x, cy, messageH)
    if not self.message or messageH <= 0 then
        return cy
    end
    local m = self:metrics()
    cy = cy - messageH
    self:textLines(x + m.pad, cy + self:h(4), messageH - self:h(8), m.smallSize, self.message, m.width - 2 * m.pad,
            self.messageIsError and CpModernHud.C.danger or CpModernHud.C.muted, CpModernHud.MESSAGE_LINES)
    return cy
end

------------------------------------------------------------------------------------------------------------------------
--- What the vehicle is doing
------------------------------------------------------------------------------------------------------------------------

--- Done part of the course, nil when not driving one
function CpModernHud:getProgress(status)
    if status and status:getIsActive() and status.currentWaypointIx and status.numberOfWaypoints
            and status.numberOfWaypoints > 0 then
        return math.max(0, math.min(1, status.currentWaypointIx / status.numberOfWaypoints))
    end
end

--- Courseplay's remaining time text ("1h:23m", "12m:5s", "45s", see CpGuiUtil.getFormatTimeText) back to seconds,
--- nil for anything else (the text is all the clients get)
local function parseRemainingTime(text)
    if text == nil or text == "" then
        return nil
    end
    local total, found = 0, false
    for n, unit in tostring(text):gmatch("(%d+)([hms])") do
        total = total + tonumber(n) * (unit == "h" and 3600 or unit == "m" and 60 or 1)
        found = true
    end
    return found and total or nil
end

--- The game's clock when the work is done ("14:32") from Courseplay's remaining time: the remaining time is real
--- seconds (distance over speed), the clock runs timeScale times as fast. nil without a usable time.
function CpModernHud.finishTimeText(remainingText)
    local seconds = parseRemainingTime(remainingText)
    local environment = g_currentMission and g_currentMission.environment
    if seconds == nil or environment == nil or environment.dayTime == nil then
        return nil
    end
    local missionInfo = g_currentMission.missionInfo
    local timeScale = missionInfo and missionInfo.timeScale or 1
    local dayMs = 24 * 60 * 60 * 1000
    local ms = (environment.dayTime + seconds * 1000 * timeScale) % dayMs
    local minutes = math.floor(ms / 60000)
    return string.format("%02d:%02d", math.floor(minutes / 60), minutes % 60)
end

--- The first Courseplay info text of the vehicle (waiting for an unloader, finished...), or nil
function CpModernHud:getInfoText(vehicle)
    if g_infoTextManager == nil then
        return nil
    end
    for _, info in ipairs(g_infoTextManager:getActiveInfoTexts()) do
        if info.vehicle == vehicle then
            return info.text
        end
    end
end

---@return string, table the status and its color
function CpModernHud:getStatus(vehicle, status)
    local C = CpModernHud.C
    if vehicle:getIsCpCourseRecorderActive() then
        if vehicle:getIsCpCourseRecorderPaused() then
            return t("CP_cc_status_recordingPaused"), C.warn
        end
        return t("CP_cc_status_recording"), C.danger
    end
    local info = self:getInfoText(vehicle)
    if vehicle:getIsCpActive() then
        if info then
            return info, C.warn
        end
        local fraction = self:getProgress(status)
        if fraction and vehicle:cpIsHudFieldWorkJobSelected() then
            return t("CP_cc_status_working", math.floor(fraction * 100 + 0.5)), C.accent
        end
        return t("CP_cc_status_active"), C.accent
    end
    if isAutoDriveActive(vehicle) then
        local stateModule = vehicle.ad.stateModule
        local name = stateModule.getFirstMarkerName and stateModule:getFirstMarkerName()
        return name and t("CP_cc_status_autoDriveTo", name) or t("CP_cc_status_autoDrive"), C.accent
    end
    if vehicle:getIsAIActive() then
        return t("CP_cc_status_otherHelper"), C.muted
    end
    if info then
        return info, C.warn
    end
    if vehicle:getCanStartCp() then
        return t("CP_cc_status_ready"), C.text
    end
    if vehicle:cpIsHudFieldWorkJobSelected() and not vehicle:hasCpCourse() then
        return t("CP_cc_status_noCourse"), C.muted
    end
    return t("CP_cc_status_notReady"), C.muted
end

------------------------------------------------------------------------------------------------------------------------
--- The course on the map: Courseplay's course as the parts the map draws, and what is in it
------------------------------------------------------------------------------------------------------------------------

local function isInPolygon(polygon, x, z)
    local inside = false
    local j = #polygon
    for i = 1, #polygon do
        local a, b = polygon[i], polygon[j]
        if (a.z > z) ~= (b.z > z) and x < (b.x - a.x) * (z - a.z) / (b.z - a.z) + a.x then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function getDistanceToOutline(outline, x, z)
    local best = math.huge
    local j = #outline
    for i = 1, #outline do
        local a, b = outline[j], outline[i]
        local dx, dz = b.x - a.x, b.z - a.z
        local length2 = dx * dx + dz * dz
        local f = length2 > 0 and math.max(0, math.min(1, ((x - a.x) * dx + (z - a.z) * dz) / length2)) or 0
        best = math.min(best, math.sqrt((x - a.x - dx * f) ^ 2 + (z - a.z - dz * f) ^ 2))
        j = i
    end
    return best
end

--- Inside the polygon or at most 'margin' meters away from its edge
local function isNearPolygon(polygon, x, z, margin)
    return isInPolygon(polygon, x, z) or (margin > 0 and getDistanceToOutline(polygon, x, z) <= margin)
end

local function getArea(polygon)
    local area = 0
    local j = #polygon
    for i = 1, #polygon do
        area = area + (polygon[j].x + polygon[i].x) * (polygon[j].z - polygon[i].z)
        j = i
    end
    return math.abs(area / 2)
end

--- The field outline Courseplay found last for the vehicle, if the course is on it (a course loaded from the saved
--- courses may be on another field).
local function getOutlineFor(vehicle, waypoints)
    local polygon = vehicle.cpGetFieldPolygon and vehicle:cpGetFieldPolygon()
    if polygon == nil or #polygon < 3 or #waypoints == 0 then
        return nil
    end
    local inside, samples = 0, 0
    local step = math.max(1, math.floor(#waypoints / 20))
    for i = 1, #waypoints, step do
        samples = samples + 1
        if isInPolygon(polygon, waypoints[i].x, waypoints[i].z) then
            inside = inside + 1
        end
    end
    if inside < samples * 0.7 then
        return nil
    end
    return polygon
end

--- Without Courseplay's field outline (it has it only where the field was detected, not a client the course came
--- to from the server or a save): the course's outermost headland around the field, the longest unbroken run of
--- headland 1 (an island's headland is a shorter one). Its line is half a work width inside the field's edge.
local function getHeadlandOutline(course, waypoints)
    local best, run = {}, {}
    for i, wp in ipairs(waypoints) do
        if course:isOnHeadland(i, 1) then
            table.insert(run, {x = wp.x, z = wp.z})
        else
            if #run > #best then
                best = run
            end
            run = {}
        end
    end
    if #run > #best then
        best = run
    end
    return #best >= 3 and best or nil
end

--- The course for the map (waypoints with the part each one ends: headland, row, turn or connecting path), the
--- field outline (the given one or the vehicle's) and what is in it. Made again only when the course changes.
---@param cacheName string|nil where it is kept, for another course than the vehicle's own
function CpModernHud:getCourseInfo(vehicle, course, cacheName, outline)
    cacheName = cacheName or "courseInfo"
    local info = self[cacheName]
    if info and info.course == course and info.numWaypoints == course:getNumberOfWaypoints() then
        return info
    end
    local waypoints = course:getAllWaypoints()
    local plotWaypoints = {}
    local rows, turns, workLength = 0, 0, 0
    for i, wp in ipairs(waypoints) do
        local prev = waypoints[i - 1]
        local part
        if course:isOnConnectingPath(i) then
            part = "C"
        elseif prev and wp:isRowStart() then
            -- from the end of a row (a turn) or from the headland to the first row
            part = prev:isRowEnd() and "T" or "C"
        elseif course:isOnHeadland(i) then
            part = "H"
        else
            part = "R"
        end
        if wp:isRowStart() and not course:isOnHeadland(i) then
            rows = rows + 1
        end
        if part == "T" then
            turns = turns + 1
        end
        if prev and (part == "H" or part == "R") then
            workLength = workLength + math.sqrt((wp.x - prev.x) ^ 2 + (wp.z - prev.z) ^ 2)
        end
        plotWaypoints[i] = {x = wp.x, z = wp.z, t = part}
    end
    outline = outline or getOutlineFor(vehicle, waypoints)
    -- where the other helpers count as on the field
    local othersOutline, othersMargin = outline, 0
    if othersOutline == nil then
        othersOutline = getHeadlandOutline(course, waypoints)
        othersMargin = (course:getWorkWidth() or 0) / 2
    end
    info = {
        course = course,
        othersOutline = othersOutline,
        othersMargin = othersMargin,
        numWaypoints = course:getNumberOfWaypoints(),
        plotCourse = {waypoints = plotWaypoints, outline = outline},
        area = outline and getArea(outline),
        headlands = course:getNumberOfHeadlands() or 0,
        rows = rows,
        turns = turns,
        length = course:getLength() or 0,
        workLength = workLength,
        workWidth = course:getWorkWidth(),
        multiTools = course:getMultiTools(),
    }
    self[cacheName] = info
    return info
end

------------------------------------------------------------------------------------------------------------------------
--- The other helpers working the field: Courseplay unloaders set to it (also while away unloading), Courseplay's
--- field workers and other helpers (AutoDrive...) on it. Found from what every player has (the running jobs, where
--- the vehicles are), not from the drivers, which only run on the server.
------------------------------------------------------------------------------------------------------------------------

CpModernHud.OTHERS_INTERVAL_MS = 1000
CpModernHud.OTHERS_LISTED = 4
--- How far off the field's edge a vehicle still counts as on it (an unloader beside a combine on the outer headland)
CpModernHud.OTHERS_MARGIN = 25
--- A truck without a field set: a Courseplay combine this close (m) is the one it is for
CpModernHud.NEAR_COMBINE = 300
CpModernHud.ROLES = {
    unloader = {color = {1.0, 0.72, 0.22, 1}, awayColor = {1.0, 0.72, 0.22, 0.7}, key = "CP_cc_role_unloader"},
    autoDrive = {color = {1.0, 0.72, 0.22, 1}, awayColor = {1.0, 0.72, 0.22, 0.7}, key = "CP_cc_role_autoDrive"},
    worker = {color = {0.45, 0.70, 1.0, 1}, awayColor = {0.45, 0.70, 1.0, 0.7}, key = "CP_cc_role_worker"},
    helper = {color = {0.62, 0.72, 0.86, 1}, awayColor = {0.62, 0.72, 0.86, 0.7}, key = "CP_cc_role_helper"},
}

--- What a helper is doing, and where its work is (an unloader: the field its job is set to), nil if it isn't working
local function getRole(v)
    if v.getIsCpCombineUnloaderActive and v:getIsCpCombineUnloaderActive() then
        local job = v:getJob()
        local parameters = job and job.getCpJobParameters and job:getCpJobParameters()
        local position = parameters and parameters.fieldPosition
        if position then
            local x, z = position:getPosition()
            if x and z then
                return "unloader", x, z
            end
        end
        return "unloader"
    end
    if v.getIsCpFieldWorkActive and v:getIsCpFieldWorkActive() then
        return "worker"
    end
    local ad = v.ad and v.ad.stateModule
    if ad and ad.isActive and ad:isActive() then
        return "autoDrive"
    end
    if v.getIsAIActive and v:getIsAIActive() then
        return "helper"
    end
end

--- The other helpers of the farm working the field with this outline: list of {vehicle, role, color, awayColor}
--- (looked for once a second)
---@param extraMargin number|nil m the outline is inside the field's edge (a headland line instead of the outline)
function CpModernHud:getOthers(vehicle, outline, extraMargin)
    if outline == nil then
        return {}
    end
    local now = g_time or 0
    local c = self.othersCache
    if c and c.outline == outline and c.vehicle == vehicle and now - c.time < CpModernHud.OTHERS_INTERVAL_MS then
        return c.list
    end
    local list = {}
    local farmId = vehicle:getOwnerFarmId()
    for _, v in ipairs(g_currentMission.vehicleSystem.vehicles) do
        if v ~= vehicle and v.rootNode and not v.isDeleted and (v.getRootVehicle == nil or v:getRootVehicle() == v)
                and v.getOwnerFarmId and v:getOwnerFarmId() == farmId then
            local role, x, z = getRole(v)
            if role then
                local margin = extraMargin or 0
                if x == nil then
                    -- where it is now (not where its job is): it may run along the field's edge
                    x, _, z = getWorldTranslation(v.rootNode)
                    margin = CpModernHud.OTHERS_MARGIN + (extraMargin or 0)
                end
                if isNearPolygon(outline, x, z, margin) then
                    local r = CpModernHud.ROLES[role]
                    table.insert(list, {vehicle = v, role = role, color = r.color, awayColor = r.awayColor})
                end
            end
        end
    end
    -- the field workers (combines) first, then the unloaders
    table.sort(list, function(a, b)
        if (a.role == "worker") ~= (b.role == "worker") then
            return a.role == "worker"
        end
        return a.vehicle:getName() < b.vehicle:getName()
    end)
    self.othersCache = {outline = outline, vehicle = vehicle, time = now, list = list}
    return list
end

--- Height of the list of the others under the map (0 without any)
function CpModernHud:othersHeight(others)
    local n = math.min(#others, CpModernHud.OTHERS_LISTED)
    return n > 0 and (n * self:h(19) + self:h(4)) or 0
end

--- The others in a list: their color, name and what they do; a click enters the vehicle
function CpModernHud:drawOthers(x, cy, others)
    local C = CpModernHud.C
    local m = self:metrics()
    local rowH = self:h(19)
    local n = math.min(#others, CpModernHud.OTHERS_LISTED)
    cy = cy - self:h(4)
    for k = 1, n do
        local o = others[k]
        cy = cy - rowH
        local rowX, rowW = x + m.pad, m.width - 2 * m.pad
        local hover = self:isHover(rowX, cy, rowW, rowH)
        Draw.disc(rowX + self:w(6), cy + rowH / 2, self:h(4), o.color)
        local doing = self:getInfoText(o.vehicle) or t(CpModernHud.ROLES[o.role].key)
        if k == n and #others > n then
            doing = t("CP_cc_others_more", #others - n + 1)
        end
        local doingW = math.min(Draw.textWidth(m.smallSize, doing), rowW * 0.5)
        self:textIn(rowX + rowW, cy, rowH, m.smallSize, Draw.fit(doing, m.smallSize, doingW), C.muted,
                RenderText.ALIGN_RIGHT)
        self:textIn(rowX + self:w(16), cy, rowH, m.smallSize,
                Draw.fit(o.vehicle:getName(), m.smallSize, rowW - doingW - self:w(26)), hover and C.accentHover or C.text)
        self:addElement(rowX, cy, rowW, rowH, function()
            if g_localPlayer then
                g_localPlayer:requestToEnterVehicle(o.vehicle)
            end
        end)
    end
    return cy
end

function CpModernHud:getSummary(info)
    if info.area then
        return t("CP_cc_summary", info.area / 10000, info.headlands, info.rows, info.length / 1000)
    end
    return t("CP_cc_summaryNoField", info.headlands, info.rows, info.length / 1000)
end

--- The details of the course: {label, value} pairs
---@param vehicle table|nil whose course (another vehicle's on the Fleet tab), the panel's vehicle without
function CpModernHud:getDetails(info, status, vehicle)
    vehicle = vehicle or self.vehicle
    local list = {}
    -- (as Courseplay's own hud: the course's name and the waypoint it is at)
    local name = vehicle.getCurrentCpCourseName and vehicle:getCurrentCpCourseName()
    if name and name ~= "" then
        table.insert(list, {t("CP_cc_detail_course"), name})
    end
    table.insert(list, {t("CP_cc_detail_waypoint"), self:getWaypointText(status, info)})
    local timeLeft = status and status:getIsActive() and status:getTimeRemainingText()
    if timeLeft and timeLeft ~= "" then
        table.insert(list, {t("CP_cc_detail_timeLeft"), timeLeft})
        local done = CpModernHud.finishTimeText(timeLeft)
        if done then
            table.insert(list, {t("CP_cc_detail_doneAt"), done})
        end
    end
    if info.area then
        table.insert(list, {t("CP_cc_detail_area"), string.format("%.2f ha", info.area / 10000)})
    end
    table.insert(list, {t("CP_cc_detail_length"), string.format("%.1f km", info.length / 1000)})
    table.insert(list, {t("CP_cc_detail_working"), string.format("%.1f km", info.workLength / 1000)})
    table.insert(list, {t("CP_cc_detail_headlands"), tostring(info.headlands)})
    table.insert(list, {t("CP_cc_detail_rows"), tostring(info.rows)})
    table.insert(list, {t("CP_cc_detail_turns"), tostring(info.turns)})
    table.insert(list, {t("CP_cc_detail_workWidth"), string.format("%.1f m", info.workWidth or 0)})
    if (info.multiTools or 1) > 1 then
        table.insert(list, {t("CP_cc_detail_multiTools"), tostring(info.multiTools)})
    end
    return list
end

--- The waypoint the driver is at of all of them ("820/1834", as Courseplay's own hud), "--/1834" when not driving
function CpModernHud:getWaypointText(status, info)
    local total = status and status.numberOfWaypoints or (info and info.numWaypoints)
    if status and status:getIsActive() and status.currentWaypointIx and total then
        return string.format("%d/%d", status.currentWaypointIx, total)
    end
    return total and string.format("--/%d", total) or "--/--"
end

--- The values of the course generator settings, to see whether they changed since the course was made
local function getGeneratorValues(vehicle)
    local values = {}
    for _, setting in ipairs(vehicle:getCourseGeneratorSettingsTable()) do
        values[setting:getName()] = setting:getValue()
    end
    return values
end

--- Have the course generator settings changed since the panel first saw this course?
function CpModernHud:haveSettingsChanged(vehicle, course)
    local snapshot = self.generatorSnapshot
    if snapshot == nil or snapshot.course ~= course then
        self.generatorSnapshot = {course = course, values = getGeneratorValues(vehicle)}
        return false
    end
    for name, value in pairs(getGeneratorValues(vehicle)) do
        if snapshot.values[name] ~= value then
            return true
        end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------------
--- What the buttons do (all through Courseplay's own functions)
------------------------------------------------------------------------------------------------------------------------

--- A new course for the field the vehicle is on, as Courseplay's "generate course" key makes it
function CpModernHud:generateCourse(vehicle)
    if self.generating and (g_time or 0) < self.generating then
        return
    end
    if vehicle:cpIsFieldBoundaryDetectionRunning() then
        self:showMessage(t("CP_error_field_detection_still_running"), true)
        return
    end
    self.generating = (g_time or 0) + CpModernHud.GENERATE_TIMEOUT_MS
    local x, _, z = getWorldTranslation(vehicle.rootNode)
    CourseGeneratorInterface():startGenerationWithDetection({x = x, z = z}, vehicle,
            vehicle:getCourseGeneratorSettings(), self, function(self, course)
                self.generating = nil
                self.generatorSnapshot = nil
                if course == nil then
                    self:showMessage(t("CP_error_could_not_generate_course"), true)
                end
            end)
end

function CpModernHud:isGenerating(vehicle)
    return (self.generating and (g_time or 0) < self.generating) or vehicle:cpIsFieldBoundaryDetectionRunning()
end

------------------------------------------------------------------------------------------------------------------------
--- Start away from the field: AutoDrive takes the vehicle to a marker of the field (one named after the field first,
--- then one at its edge, then the nearest). On arrival (the player's choice, "On arrival") the panel starts the course
--- as Start does, at the start chosen; AutoDrive's own settings stay as they are.
------------------------------------------------------------------------------------------------------------------------

CpModernHud.FIELD_NEAR = 40 -- m off its field a vehicle is still at it (the field edge, a gateway)
CpModernHud.MARKER_RANGE = 400 -- m from the course's start an AutoDrive marker may be
CpModernHud.MARKER_AT_FIELD = 15 -- m from the field's edge a marker is the field's own
CpModernHud.AUTODRIVE_TIMEOUT_MS = 15000 -- AutoDrive didn't set off: nothing to start
CpModernHud.ARRIVED_DISTANCE = 50 -- m from the marker AutoDrive stopped: arrived (else it was stopped on the way)
CpModernHud.ARRIVAL_SETTLE_MS = 1500 -- after AutoDrive has stopped, before the course is started
CpModernHud.BLOCKED_MS = 10000 -- AutoDrive standing this long at the field (blocked, e.g. by trucks): stopped there
CpModernHud.BLOCKED_SPEED = 1 -- km/h, slower is standing
--- Start the course when AutoDrive has brought the vehicle there (saved with the user settings)
CpModernHud.startOnArrival = true
--- Vehicles AutoDrive is taking to their field to start them there:
--- {marker, outline, waypoints, since, seenActive, stoppedAt, blockedSince, stopSent}
CpModernHud.pendingAutoDrive = {}

--- AutoDrive's mod and the vehicle's AutoDrive state, nil without AutoDrive or without its send-to event
local function getAutoDrive(vehicle)
    local ad = FS25_AutoDrive
    local stateModule = vehicle.ad and vehicle.ad.stateModule
    if ad == nil or stateModule == nil or ad.ADInputManager == nil or ad.AutoDriveSendToEvent == nil
            or ad.ADStateModule == nil then
        return nil
    end
    return ad, stateModule
end

--- Is the vehicle at the field of the course (on it or near its edge, without the outline: near the course)?
function CpModernHud:isAtField(vehicle, info)
    return CpModernHud.isAtFieldOf(vehicle, info.plotCourse.outline, info.plotCourse.waypoints)
end

function CpModernHud.isAtFieldOf(vehicle, outline, waypoints)
    local x, _, z = getWorldTranslation(vehicle.rootNode)
    if outline then
        return isInPolygon(outline, x, z) or getDistanceToOutline(outline, x, z) <= CpModernHud.FIELD_NEAR
    end
    for _, wp in ipairs(waypoints or {}) do
        if (wp.x - x) ^ 2 + (wp.z - z) ^ 2 <= CpModernHud.FIELD_NEAR ^ 2 then
            return true
        end
    end
    return false
end

--- The AutoDrive marker for the course's field: within MARKER_RANGE of its start, one named after the field's
--- number, else one at the field's edge, else any; the nearest of the first kind there is. {id, name} or nil
function CpModernHud:findMarker(info)
    local ad = g_Courseplay.autoDrive
    local start = info.plotCourse.waypoints[1]
    if ad == nil or ad.GetAvailableDestinations == nil or start == nil then
        return nil
    end
    local ok, destinations = pcall(ad.GetAvailableDestinations, ad)
    if not ok or destinations == nil then
        return nil
    end
    local outline = info.plotCourse.outline
    -- the field's number on the map (its id, or its farmland's)
    local patterns = {}
    local farmland = g_farmlandManager and g_farmlandManager:getFarmlandAtWorldPosition(start.x, start.z)
    for _, number in ipairs({CpFieldUtil.getFieldIdAtWorldPosition(start.x, start.z), farmland and farmland.id}) do
        if number and number > 0 then
            table.insert(patterns, "%f[%d]" .. number .. "%f[%D]")
        end
    end
    local function isNamedAfterField(name)
        for _, pattern in ipairs(patterns) do
            if tostring(name):find(pattern) then
                return true
            end
        end
        return false
    end
    local best, bestCost
    for id, m in pairs(destinations) do
        if m.x and m.z then
            local d = math.sqrt((m.x - start.x) ^ 2 + (m.z - start.z) ^ 2)
            if d <= CpModernHud.MARKER_RANGE then
                local cost = d + 2000
                if isNamedAfterField(m.name) then
                    cost = d
                elseif outline and (isInPolygon(outline, m.x, m.z)
                        or getDistanceToOutline(outline, m.x, m.z) <= CpModernHud.MARKER_AT_FIELD) then
                    cost = d + 1000
                end
                if bestCost == nil or cost < bestCost then
                    best, bestCost = {id = m.id or id, name = m.name or tostring(id), x = m.x, z = m.z}, cost
                end
            end
        end
    end
    return best
end

--- AutoDrive drives the vehicle to the marker (its own event). With startThere the panel starts the course on arrival,
--- unless AutoDrive does it itself (its start helper set to Courseplay by the player): never both.
---@param unloader table|nil {x, z} the field position of an unloader: on arrival its combine unloader job is started
--- there (not a course), also when AutoDrive's own start helper is Courseplay (it would start field work)
---@return boolean sent
function CpModernHud.sendWithAutoDrive(vehicle, marker, startThere, info, unloader)
    local ad, stateModule = getAutoDrive(vehicle)
    if ad == nil then
        return false
    end
    local autoDriveStartsIt = stateModule:getStartHelper() and stateModule:getUsedHelper() == ad.ADStateModule.HELPER_CP
    ad.AutoDriveSendToEvent.sendEvent(vehicle, marker.id)
    if startThere and (unloader or not autoDriveStartsIt) then
        CpModernHud.pendingAutoDrive[vehicle] = {marker = marker, since = g_time or 0, seenActive = false,
                                                 outline = info and info.plotCourse.outline,
                                                 waypoints = info and info.plotCourse.waypoints,
                                                 unloader = unloader}
    else
        CpModernHud.pendingAutoDrive[vehicle] = nil
    end
    return true
end

--- Starts the vehicle's Courseplay combine unloader job (as Courseplay's hud does), at the field at (fieldX, fieldZ)
--- when given. The server starts the driver; this client finds the field (Courseplay's own check, which also wants
--- the vehicle at the field).
---@return boolean started (sent to the server)
---@return string|nil why not
function CpModernHud.startUnloaderJob(vehicle, fieldX, fieldZ)
    if vehicle.isDeleted or vehicle:getIsAIActive() then
        return false
    end
    local job = vehicle.getCpCombineUnloaderJob and vehicle:getCpCombineUnloaderJob()
    if job == nil or not (vehicle.getCanStartCpCombineUnloader and vehicle:getCanStartCpCombineUnloader()) then
        return false
    end
    local parameters = job:getCpJobParameters()
    if fieldX and fieldZ and parameters and parameters.fieldPosition then
        parameters.fieldPosition:setPosition(fieldX, fieldZ)
    end
    local player = g_currentMission.playerSystem and g_currentMission.playerSystem:getLocalPlayer()
    job:applyCurrentState(vehicle, g_currentMission, player and player.farmId or vehicle:getOwnerFarmId(), true)
    job:setValues()
    local success, message = job:validate(false)
    if not success then
        return false, message
    end
    g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(job, vehicle:getOwnerFarmId()))
    return true
end

--- Is the vehicle there: near the marker, or at the course's field?
local function isThere(vehicle, pending)
    local x, _, z = getWorldTranslation(vehicle.rootNode)
    local m = pending.marker
    if m.x ~= nil and (x - m.x) ^ 2 + (z - m.z) ^ 2 <= CpModernHud.ARRIVED_DISTANCE ^ 2 then
        return true
    end
    return (pending.outline ~= nil or pending.waypoints ~= nil)
            and CpModernHud.isAtFieldOf(vehicle, pending.outline, pending.waypoints)
end

--- Every frame: AutoDrive has brought a vehicle to its marker or field and stopped there: the course started (as
--- Start does, at the start chosen). AutoDrive standing at the field for BLOCKED_MS (blocked by trucks at the
--- gateway, say) is stopped there and the course started the same way. Stopped on the way, or something else drives
--- it now: nothing.
function CpModernHud.updatePendingAutoDrive()
    local now = g_time or 0
    for vehicle, pending in pairs(CpModernHud.pendingAutoDrive) do
        local ad, stateModule = getAutoDrive(vehicle)
        if ad == nil or vehicle.isDeleted then
            CpModernHud.pendingAutoDrive[vehicle] = nil
        elseif stateModule:isActive() then
            pending.seenActive, pending.stoppedAt = true, nil
            local speed = vehicle.getLastSpeed and vehicle:getLastSpeed() or 0
            if speed < CpModernHud.BLOCKED_SPEED and isThere(vehicle, pending) then
                pending.blockedSince = pending.blockedSince or now
                if not pending.stopSent and now - pending.blockedSince >= CpModernHud.BLOCKED_MS
                        and ad.ADInputManager.onInputCall then
                    -- (a toggle: sent once, only while AutoDrive is active)
                    pending.stopSent = true
                    ad.ADInputManager:onInputCall(vehicle, "input_start_stop")
                end
            else
                pending.blockedSince = nil
            end
        elseif not pending.seenActive then
            if now - pending.since > CpModernHud.AUTODRIVE_TIMEOUT_MS then
                CpModernHud.pendingAutoDrive[vehicle] = nil
            end
        else
            pending.stoppedAt = pending.stoppedAt or now
            if now - pending.stoppedAt >= CpModernHud.ARRIVAL_SETTLE_MS then
                CpModernHud.pendingAutoDrive[vehicle] = nil
                if pending.unloader then
                    if isThere(vehicle, pending) and not vehicle:getIsAIActive() then
                        local started, message = CpModernHud.startUnloaderJob(vehicle, pending.unloader.x, pending.unloader.z)
                        if not started and message and g_currentMission.showBlinkingWarning then
                            g_currentMission:showBlinkingWarning("CP: " .. message, 5000)
                        end
                    end
                elseif isThere(vehicle, pending) and not vehicle:getIsAIActive() and vehicle:hasCpCourse() and vehicle:getCanStartCp() then
                    vehicle:cpStartStopDriver(true)
                end
            end
        end
    end
end

--- Start: at the field the course starts, away from it AutoDrive takes it there first (when there is a marker) and
--- the course starts there (On arrival: Start)
function CpModernHud:startFieldwork(vehicle, info)
    if info == nil or getAutoDrive(vehicle) == nil or self:isAtField(vehicle, info) then
        vehicle:cpStartStopDriver(true)
        return
    end
    local marker = self:findMarker(info)
    if marker == nil then
        self:showMessage(t("CP_cc_go_noMarker"), false)
        vehicle:cpStartStopDriver(true)
    elseif CpModernHud.sendWithAutoDrive(vehicle, marker, CpModernHud.startOnArrival, info) then
        self:showMessage(t(CpModernHud.startOnArrival and "CP_cc_go_sent" or "CP_cc_go_sentStay", marker.name), false)
    else
        vehicle:cpStartStopDriver(true)
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Unloaders and their combine: a truck goes to the combine's field with AutoDrive and unloads it there, a combine
--- calls a free truck of the farm the same way
------------------------------------------------------------------------------------------------------------------------

--- A point on the field of the course for an unloader's field position: a row or headland waypoint in the middle
--- of the course. nil without a course.
local function fieldPointOf(info)
    local waypoints = info and info.plotCourse.waypoints or {}
    local n = #waypoints
    if n == 0 then
        return nil
    end
    local mid = math.max(1, math.floor(n / 2))
    for d = 0, n do
        for _, i in ipairs({mid + d, mid - d}) do
            local wp = waypoints[i]
            if wp and (wp.t == "R" or wp.t == "H") then
                return wp.x, wp.z
            end
        end
    end
    return waypoints[mid].x, waypoints[mid].z
end

--- Would Start take the unloader to its combine's field with AutoDrive first (away from the field, AutoDrive there,
--- a course of the combine to find a marker by)?
function CpModernHud:unloaderGoes(vehicle, map)
    local info = map and map.info
    return info ~= nil and #info.plotCourse.waypoints > 0 and getAutoDrive(vehicle) ~= nil
            and not self:isAtField(vehicle, info)
end

--- Start of an unloader: at the field Courseplay starts it, away from it AutoDrive takes it to the field's marker
--- first and the unloader job starts on arrival (Courseplay itself only starts an unloader at the field).
function CpModernHud:startUnloader(vehicle, map)
    if not self:unloaderGoes(vehicle, map) then
        vehicle:cpStartStopDriver(true)
        return
    end
    local info = map.info
    local marker = self:findMarker(info)
    if marker == nil then
        self:showMessage(t("CP_cc_go_noMarker"), false)
        vehicle:cpStartStopDriver(true)
        return
    end
    local parameters = vehicle.getCpCombineUnloaderJobParameters and vehicle:getCpCombineUnloaderJobParameters()
    local x, z
    if parameters and parameters.fieldPosition then
        x, z = parameters.fieldPosition:getPosition()
    end
    if x == nil then
        x, z = fieldPointOf(info)
    end
    if CpModernHud.sendWithAutoDrive(vehicle, marker, true, info, {x = x, z = z}) then
        self:showMessage(t("CP_cc_go_unloaderSent", marker.name), false)
    else
        vehicle:cpStartStopDriver(true)
    end
end

--- Is the vehicle a combine (or forage harvester), one that unloaders can be called for?
local function isCombine(vehicle)
    if vehicle.spec_combine then
        return true
    end
    return AIUtil ~= nil and Combine ~= nil and AIUtil.hasChildVehicleWithSpecialization ~= nil
            and AIUtil.hasChildVehicleWithSpecialization(vehicle, Combine) or false
end

--- The farm's trucks free to unload a combine: with a trailer, nobody driving them (no helper, no AutoDrive, no
--- player). Nearest to the vehicle first.
function CpModernHud:getFreeTrucks(vehicle)
    local list = {}
    local farmId = vehicle:getOwnerFarmId()
    local vx, _, vz = getWorldTranslation(vehicle.rootNode)
    for _, v in ipairs(g_currentMission.vehicleSystem.vehicles) do
        if v ~= vehicle and v.rootNode and not v.isDeleted and (v.getRootVehicle == nil or v:getRootVehicle() == v)
                and v.getOwnerFarmId and v:getOwnerFarmId() == farmId
                and v.getCanStartCpCombineUnloader and v:getCanStartCpCombineUnloader()
                and not v:getIsAIActive() and not isAutoDriveActive(v)
                and not (v.getIsControlled and v:getIsControlled()) then
            local x, _, z = getWorldTranslation(v.rootNode)
            table.insert(list, {vehicle = v, distance = math.sqrt((x - vx) ^ 2 + (z - vz) ^ 2)})
        end
    end
    table.sort(list, function(a, b)
        return a.distance < b.distance
    end)
    return list
end

--- Call the truck to the combine's field: at the field its unloader job starts now, away from it AutoDrive brings
--- it to the field's marker and the job starts on arrival. The field is set as its job's field position.
function CpModernHud:callTruck(combine, truck, info)
    local x, z = fieldPointOf(info)
    if x == nil then
        return
    end
    local name = truck:getName()
    if CpModernHud.isAtFieldOf(truck, info.plotCourse.outline, info.plotCourse.waypoints) or getAutoDrive(truck) == nil then
        local started, message = CpModernHud.startUnloaderJob(truck, x, z)
        if started then
            self:showMessage(t("CP_cc_call_started", name), false)
        else
            self:showMessage(message and (name .. ": " .. message) or t("CP_cc_call_failed", name), true)
        end
        return
    end
    local marker = self:findMarker(info)
    if marker == nil then
        self:showMessage(t("CP_cc_call_noWay", name), true)
        return
    end
    local parameters = truck.getCpCombineUnloaderJobParameters and truck:getCpCombineUnloaderJobParameters()
    if parameters and parameters.fieldPosition then
        parameters.fieldPosition:setPosition(x, z)
    end
    if CpModernHud.sendWithAutoDrive(truck, marker, true, info, {x = x, z = z}) then
        self:showMessage(t("CP_cc_call_sent", name, marker.name), false)
    else
        self:showMessage(t("CP_cc_call_failed", name), true)
    end
end

CpModernHud.CALL_ROWS = 5 -- trucks listed at once when calling one

--- Calling a truck, in the map's place: the free trucks with how far away they are, a click calls one; Cancel.
function CpModernHud:drawCallTruck(vehicle, info, plotX, plotY, plotW, plotH)
    local C = CpModernHud.C
    local m = self:metrics()
    local trucks = self:getFreeTrucks(vehicle)
    local titleH = self:h(26)
    local rowH = self:h(26)
    local bh = self:h(26)
    local function cancel()
        self.callingTruck = nil
    end
    self:textIn(plotX + plotW / 2, plotY + plotH - self:h(8) - titleH, titleH, m.textSize,
            t(#trucks > 0 and "CP_cc_call_ask" or "CP_cc_call_none"), C.text, RenderText.ALIGN_CENTER)
    local rowX, rowW = plotX + self:w(10), plotW - self:w(20)
    local cy = plotY + plotH - self:h(8) - titleH
    local n = math.min(#trucks, CpModernHud.CALL_ROWS)
    for k = 1, n do
        local truck = trucks[k]
        cy = cy - rowH
        local hover = self:isHover(rowX, cy, rowW, rowH)
        if hover then
            Draw.roundRect(rowX, cy, rowW, rowH, m.smallRadius, C.hover)
        end
        local d = truck.distance
        local distance = d >= 1000 and string.format("%.1f km", d / 1000) or string.format("%d m", math.floor(d + 0.5))
        local distanceW = Draw.textWidth(m.smallSize, distance)
        self:textIn(rowX + rowW - self:w(8), cy, rowH, m.smallSize, distance, C.muted, RenderText.ALIGN_RIGHT)
        self:textIn(rowX + self:w(8), cy, rowH, m.smallSize,
                Draw.fit(truck.vehicle:getName(), m.smallSize, rowW - distanceW - self:w(24)), C.text)
        self:addElement(rowX, cy, rowW, rowH, function()
            self.callingTruck = nil
            self:callTruck(vehicle, truck.vehicle, info)
        end)
    end
    local bw = plotW * 0.4
    self:button(plotX + (plotW - bw) / 2, plotY + self:h(8), bw, bh, t("CP_cc_btn_cancel"), C.chip, C.hover, C.text,
            cancel, m.smallSize)
    self:setKey("cancel", t("CP_cc_btn_cancel"), cancel)
    self:setKey("back", t("CP_cc_btn_cancel"), cancel)
end

------------------------------------------------------------------------------------------------------------------------
--- Setting rows: Courseplay settings as label, - value +, a list of the values on the value
------------------------------------------------------------------------------------------------------------------------

--- A row for a Courseplay setting
---@param opts table|nil label, value, disabledText (shown when the setting is disabled), live (also while working)
function CpModernHud:settingRow(setting, opts)
    opts = opts or {}
    local disabled = setting:getIsDisabled()
    local row = {
        label = opts.label or setting:getTitle(),
        value = opts.value or (disabled and opts.disabledText) or setting:getString(),
        live = opts.live,
        disabled = disabled,
    }
    if not disabled then
        row.dec = function()
            setting:setPreviousItem()
        end
        row.inc = function()
            setting:setNextItem()
        end
        if setting.values and setting.texts and #setting.texts > 1
                and #setting.texts <= CpModernHud.DROPDOWN_MAX_OPTIONS then
            row.options = setting.texts
            row.current = setting.current
            row.select = function(ix)
                setting:setValue(setting.values[ix])
            end
        end
    end
    return row
end

--- The rows of the visible settings, in this order
function CpModernHud:addSettingRows(rows, settings, opts)
    for _, setting in ipairs(settings) do
        if setting and setting:getIsVisible() then
            table.insert(rows, self:settingRow(setting, opts))
        end
    end
end

--- The headlands as one row: automatic (- and + change the headland width, the number follows the work width) or
--- the number of them; the list switches between the two.
function CpModernHud:getHeadlandsRow(vehicle)
    local generator = vehicle:getCourseGeneratorSettings()
    local number, automatic, width = generator.numberOfHeadlands, generator.automaticHeadlands, generator.headlandWidth
    if automatic == nil or width == nil then
        return self:settingRow(number)
    end
    local row
    if automatic:getValue() then
        local n = CpCourseGeneratorSettings.getAutomaticNumberOfHeadlands(vehicle)
        row = self:settingRow(width, {value = t("CP_cc_headlands_auto", n * generator.workWidth:getValue(), n)})
        row.options = {t("CP_cc_headlands_setNumber")}
        for _, text in ipairs(width.texts) do
            table.insert(row.options, text)
        end
        row.current = width.current + 1
        row.select = function(ix)
            if ix == 1 then
                automatic:setValue(false)
            else
                width:setValue(width.values[ix - 1])
            end
        end
    else
        row = self:settingRow(number)
        row.options = {t("CP_cc_headlands_automatic")}
        for _, text in ipairs(number.texts) do
            table.insert(row.options, text)
        end
        row.current = number.current + 1
        row.select = function(ix)
            if ix == 1 then
                automatic:setValue(true)
            else
                number:setValue(number.values[ix - 1])
            end
        end
    end
    row.label = t("CP_cc_headlands")
    return row
end

--- With a plow (the tool offset setting is off then) Courseplay's plow strategy sets the side offset itself from the
--- plow's AI markers. Its value worked out the same way here (the strategy only runs on the server), so an offset
--- that leaves a strip unworked shows: "automatic · 1.4 m".
function CpModernHud:getAutomaticOffsetText(vehicle)
    local plows = Plow and AIUtil.getAllChildVehiclesWithSpecialization(vehicle, Plow) or {}
    local cache = self.plowControllers
    if cache == nil or cache.vehicle ~= vehicle then
        cache = {vehicle = vehicle, controllers = {}}
        self.plowControllers = cache
    end
    local offset = 0
    for _, implement in ipairs(plows) do
        local controller = cache.controllers[implement]
        if controller == nil then
            controller = PlowController(vehicle, implement)
            cache.controllers[implement] = controller
        end
        local ok, value = pcall(controller.getAutomaticXOffset, controller)
        if not ok or value == nil then
            -- turning plow in the middle of rotating
            return CpBaseHud.automaticText
        end
        offset = offset + value
    end
    if #plows == 0 then
        return CpBaseHud.automaticText
    end
    return string.format("%s · %.1f m", CpBaseHud.automaticText, offset)
end

--- The field work rows: the main course generator settings, the offsets and with "More settings" the others
function CpModernHud:getFieldworkRows(vehicle)
    local generator = vehicle:getCourseGeneratorSettings()
    local rows = {}
    -- (in the headlands row)
    local main = {automaticHeadlands = true, headlandWidth = true, fieldMargin = true, rowOverlapPercent = true}
    for _, name in ipairs(CpModernHud.MAIN_GENERATOR_SETTINGS) do
        main[name] = true
        if name == "numberOfHeadlands" then
            table.insert(rows, self:getHeadlandsRow(vehicle))
        elseif generator[name] then
            self:addSettingRows(rows, {generator[name]})
        end
        if name == "workWidth" and generator.fieldMargin then
            -- always here (Courseplay shows it in expert mode only): a strip left along the field edge is fixed with it
            table.insert(rows, self:settingRow(generator.fieldMargin))
        end
        if name == "workWidth" and generator.rowOverlapPercent then
            self:addSettingRows(rows, {generator.rowOverlapPercent})
        end
    end
    local settings = vehicle:getCpSettings()
    local automaticOffset = settings.toolOffsetX:getIsDisabled() and self:getAutomaticOffsetText(vehicle)
    table.insert(rows, self:settingRow(settings.toolOffsetX, {disabledText = automaticOffset, live = true}))
    self:addSettingRows(rows, {vehicle:getCpLaneOffsetSetting()}, {live = true})
    if CpModernHud.showMore then
        local more = {}
        for _, setting in ipairs(vehicle:getCourseGeneratorSettingsTable()) do
            if not main[setting:getName()] then
                table.insert(more, setting)
            end
        end
        self:addSettingRows(rows, more)
    end
    return rows
end

--- Setting rows shown at once, more scroll with the mouse wheel (the panel doesn't grow with them)
CpModernHud.MAX_ROWS = 7

function CpModernHud:shownRows(rows, maxRows)
    return math.min(#rows, maxRows or CpModernHud.MAX_ROWS)
end

--- Setting rows: label, - value +, and section headings ({header = true, label}); at most maxRows (MAX_ROWS) of
--- them, the wheel scrolls the others in. Returns the new top.
function CpModernHud:drawSettingRows(x, cy, rows, editable, maxRows)
    local C = CpModernHud.C
    local m = self:metrics()
    local pad, rowH, width, textSize = m.pad, m.rowH, m.width, m.textSize
    local chipW, chipH = self:w(24), self:h(22)
    local valueW = self:w(120)
    local shown = self:shownRows(rows, maxRows)
    local maxScroll = #rows - shown
    self.rowScroll = math.max(0, math.min(self.rowScroll or 0, maxScroll))
    self:addRowKeys(rows, shown, editable)
    local keyRow = self:hasKeys() and self.keyRow
    local top = cy
    for k = 1, shown do
        local row = rows[self.rowScroll + k]
        local previous = rows[self.rowScroll + k - 1]
        cy = cy - rowH
        if keyRow == self.rowScroll + k then
            -- the row the keys work on
            Draw.roundRect(x + pad - self:w(6), cy + self:h(1), width - 2 * pad + self:w(12), rowH - self:h(2),
                    m.smallRadius, C.surface)
            Draw.roundRect(x + pad - self:w(6), cy + self:h(5), self:w(3), rowH - self:h(10), self:h(1.5), C.accent)
        end
        if k > 1 and not row.header and not (previous and previous.header) then
            Draw.rect(x + pad, cy + rowH, width - 2 * pad, self:h(1), C.line)
        end
        if row.header then
            -- a section heading, as in Courseplay's menus
            self:textIn(x + pad, cy, rowH, m.smallSize, Draw.fit(row.label, m.smallSize, width - 2 * pad, true),
                    C.accent, nil, true)
        else
            local usableRow = (editable or row.live) and not row.disabled
            local rightX = x + width - pad
            local incX = rightX - chipW
            local valueX = incX - valueW
            local decX = valueX - chipW
            self:textIn(x + pad, cy, rowH, textSize, Draw.fit(row.label, textSize, decX - x - pad - self:w(6)), C.muted)
            local chipY = cy + (rowH - chipH) / 2
            for _, chip in ipairs({{decX, "-", row.dec}, {incX, "+", row.inc}}) do
                local cx, label, fn = chip[1], chip[2], chip[3]
                local usable = usableRow and fn ~= nil
                local hover = usable and self:isHover(cx, chipY, chipW, chipH)
                Draw.roundRect(cx, chipY, chipW, chipH, chipH / 2, hover and C.hover or C.chip)
                self:textIn(cx + chipW / 2, chipY, chipH, textSize, label, usable and C.text or C.muted,
                        RenderText.ALIGN_CENTER, true)
                if usable then
                    self:addElement(cx, chipY, chipW, chipH, fn)
                end
            end
            -- a row with options: its value opens a list of them to pick from
            if usableRow and row.options then
                local id = row.label
                local d = self.dropdown
                if d and d.id == id then
                    self.dropdownSeen = true
                    d.x, d.y, d.w, d.rowH, d.options, d.current, d.select = valueX, cy, valueW, rowH, row.options,
                            row.current, row.select
                end
                row.click = function()
                    if self.dropdown and self.dropdown.id == id then
                        self.dropdown = nil
                        return
                    end
                    local scroll = math.max(0, math.min((row.current or 1) - 3, #row.options - CpModernHud.DROPDOWN_ROWS))
                    self.dropdown = {id = id, x = valueX, y = cy, w = valueW, rowH = rowH, options = row.options,
                                     current = row.current, select = row.select, scroll = scroll}
                    self.dropdownSeen = true
                end
            end
            local valueHover = usableRow and row.click and self:isHover(valueX, cy, valueW, rowH)
            -- a value too long for the space between the chips gets a little smaller (not below three quarters)
            local valueSize = textSize
            local room = valueW - self:w(8)
            local tw = Draw.textWidth(textSize, row.value, true)
            if tw > room then
                valueSize = textSize * math.max(0.75, room / tw)
            end
            self:textIn(valueX + valueW / 2, cy, rowH, valueSize, Draw.fit(row.value, valueSize, room, true),
                    (valueHover and C.accentHover) or (usableRow and C.text) or C.muted, RenderText.ALIGN_CENTER, true)
            if usableRow and row.click then
                self:addElement(valueX, cy, valueW, rowH, row.click)
            end
        end
    end
    if maxScroll > 0 then
        local areaH = top - cy
        self:addWheelElement(x, cy, width, areaH, function(dir)
            self.rowScroll = math.max(0, math.min(maxScroll, self.rowScroll - dir))
            self.dropdown = nil
        end)
        -- a thin bar where the shown rows are
        local barH = areaH * shown / #rows
        local barY = top - barH - (areaH - barH) * self.rowScroll / maxScroll
        Draw.roundRect(x + width - self:w(7), barY, self:w(3), barH, self:h(1.5), C.muted)
    end
    return cy
end

--- The open list of a row's options, under its value (above it near the bottom of the screen)
function CpModernHud:drawDropdown()
    local d = self.dropdown
    local C = CpModernHud.C
    local m = self:metrics()
    self.drawingDropdown = true
    local itemH = d.rowH * 0.85
    local shown = math.min(#d.options, CpModernHud.DROPDOWN_ROWS)
    d.scroll = math.max(0, math.min(d.scroll or 0, #d.options - shown))
    local widest = d.w
    for _, label in ipairs(d.options) do
        widest = math.max(widest, Draw.textWidth(m.smallSize, label) + self:w(28))
    end
    local w = math.min(widest, m.width - 2 * m.pad)
    local x = math.max(0, d.x + d.w - w)
    local h = shown * itemH + self:h(8)
    local y = d.y - h
    if y < 0.01 then
        y = d.y + d.rowH
    end
    d.box = {x = x, y = y, w = w, h = h}
    Draw.roundRect(x - self:w(2), y - self:h(3), w + self:w(4), h + self:h(4), m.smallRadius, C.shadow)
    Draw.roundRect(x, y, w, h, m.smallRadius, C.surface)
    for k = 1, shown do
        local ix = d.scroll + k
        local iy = y + h - self:h(4) - k * itemH
        local current = ix == d.current
        local hover = self:isHover(x, iy, w, itemH) or (d.keyIx == ix and self:hasKeys())
        if current or hover then
            Draw.roundRect(x + self:w(4), iy + self:h(1), w - self:w(8), itemH - self:h(2), self:h(5),
                    current and C.accent or C.hover)
        end
        self:textIn(x + self:w(12), iy, itemH, m.smallSize, Draw.fit(d.options[ix], m.smallSize, w - self:w(24)),
                current and C.white or C.text, nil, current)
        table.insert(self.popupElements, {x = x, y = iy, w = w, h = itemH, onClick = function()
            self.dropdown = nil
            if d.select then
                d.select(ix)
            end
        end})
    end
    -- more than shown: a thin bar where the shown ones are
    if #d.options > shown then
        local barH = h * shown / #d.options
        local barY = y + h - barH - (h - barH) * d.scroll / (#d.options - shown)
        Draw.roundRect(x + w - self:w(4), barY, self:w(2), barH, self:h(1), C.muted)
    end
    self.drawingDropdown = false
end

--- A switch of options ({value, label}), 'segTotal' wide at the right edge (the whole width without a label).
--- Returns the new top.
function CpModernHud:drawSwitch(x, cy, h, label, options, selectedValue, onSelect, enabled, segTotal)
    local C = CpModernHud.C
    local m = self:metrics()
    cy = cy - h
    if label then
        self:textIn(x + m.pad, cy, h, m.textSize, label, C.muted)
    end
    local segH = self:h(26)
    local segY = cy + (h - segH) / 2
    segTotal = segTotal or (m.width - 2 * m.pad)
    local segX0 = x + m.width - m.pad - segTotal
    local segW = segTotal / #options
    Draw.roundRect(segX0, segY, segTotal, segH, segH / 2, C.chip)
    for k, option in ipairs(options) do
        local sx = segX0 + (k - 1) * segW
        local selected = selectedValue == option[1]
        local hover = enabled and not selected and self:isHover(sx, segY, segW, segH)
        if selected or hover then
            Draw.roundRect(sx + self:w(2), segY + self:h(2), segW - self:w(4), segH - self:h(4),
                    (segH - self:h(4)) / 2, selected and C.accent or C.hover)
        end
        self:textIn(sx + segW / 2, segY, segH, m.smallSize, Draw.fit(option[2], m.smallSize, segW - self:w(6), selected),
                (selected and C.white) or (enabled and C.text) or C.muted, RenderText.ALIGN_CENTER, selected)
        if enabled and not selected then
            self:addElement(sx, segY, segW, segH, function()
                onSelect(option[1])
            end)
        end
    end
    return cy
end

--- A switch for a Courseplay setting with a few values (its values and texts as the options; labels: shorter
--- texts by value)
function CpModernHud:drawSettingSwitch(x, cy, h, label, setting, enabled, segTotal, labels)
    local options = {}
    for ix, value in ipairs(setting.values) do
        table.insert(options, {value, labels and labels[value] or setting.texts[ix]})
    end
    return self:drawSwitch(x, cy, h, label, options, setting:getValue(), function(value)
        setting:setValue(value)
    end, enabled and not setting:getIsDisabled(), segTotal)
end

------------------------------------------------------------------------------------------------------------------------
--- Drawing: the frame (background, header, tabs) and the views in it
------------------------------------------------------------------------------------------------------------------------

--- The tabs: the course is in the panel, saved courses and settings open Courseplay's menus.
function CpModernHud:getTabs(vehicle)
    return {
        {key = "CP_cc_tab_course", view = CpModernHud.VIEW_COURSE},
        {key = "CP_cc_tab_saved", view = CpModernHud.VIEW_SAVED},
        {key = "CP_cc_tab_fleet", view = CpModernHud.VIEW_FLEET},
        {key = "CP_cc_tab_settings", view = CpModernHud.VIEW_SETTINGS},
    }
end

--- Background, header (title, vehicle, status, minimize, help, close) and the tabs, for content 'contentH' high.
--- Returns the panel's left edge and the top of the content.
function CpModernHud:drawFrame(m, contentH, subtitle, status, statusColor)
    local C = CpModernHud.C
    local vehicle = self.vehicle
    local width = m.width
    local tabsH = CpModernHud.minimized and 0 or m.tabsH
    local height = m.headerH + tabsH + contentH + m.padY
    -- by default on the left (Courseplay's info texts are on the right)
    local x = CpModernHud.posX or self:w(24)
    local top = CpModernHud.posTop or 0.78
    x = math.max(0, math.min(1 - width, x))
    top = math.max(height, math.min(1, top))
    local y = top - height
    self.box = {x = x, y = y, w = width, h = height}

    Draw.roundRect(x - self:w(3), y - self:h(6), width + self:w(6), height + self:h(6), m.radius * 1.3, C.shadow)
    Draw.roundRect(x, y, width, height, m.radius, C.bg)
    Draw.roundRect(x + m.radius, top - self:h(3), width - 2 * m.radius, self:h(3), self:h(1.5), C.accent)

    -- header
    local cy = top - m.headerH
    local pillH = self:h(24)
    local pillY = cy + (m.headerH - pillH) / 2
    local closeW = self:w(28)
    local closeX = x + width - m.pad - closeW
    self:textIn(x + m.pad, cy + m.headerH * 0.46, m.headerH * 0.5, m.titleSize, CpModernHud.TITLE, C.text, nil, true)
    -- the build this is, e.g. 8.1.0.3-cc.1 (the Courseplay version, then the CourseCorrect build), after the title
    local titleW = Draw.textWidth(m.titleSize, CpModernHud.TITLE, true)
    local version = g_Courseplay and g_Courseplay.currentVersion
    local versionW = 0
    if version then
        versionW = self:w(8) + Draw.textWidth(m.smallSize, version)
        self:textIn(x + m.pad + titleW + self:w(8), cy + m.headerH * 0.46, m.headerH * 0.5, m.smallSize, version, C.muted)
    end
    subtitle = Draw.fit(subtitle or "", m.smallSize, closeX - 2 * closeW - self:w(12) - x - m.pad)
    self:textIn(x + m.pad, cy + m.headerH * 0.06, m.headerH * 0.45, m.smallSize, subtitle, C.muted)
    local function headerButton(bx, label, onClick, on)
        local hover = self:isHover(bx, pillY, closeW, pillH)
        if hover or on then
            Draw.roundRect(bx, pillY, closeW, pillH, pillH / 2, on and C.accent or C.hover)
        end
        self:textIn(bx + closeW / 2, pillY, pillH, m.textSize, label, (hover or on) and C.text or C.muted,
                RenderText.ALIGN_CENTER, true)
        self:addElement(bx, pillY, closeW, pillH, onClick)
    end
    headerButton(closeX, "×", function()
        vehicle:closeCpHud()
    end)
    -- minimize (only the course map and start / stop stay) / the whole panel again
    local miniX = closeX - self:w(4) - closeW
    headerButton(miniX, CpModernHud.minimized and "+" or "–", function()
        CpModernHud.minimized = not CpModernHud.minimized
        self.dropdown = nil
    end)
    if status then
        -- as wide as the status, but not over the title or the vehicle's name under it (a long status is shortened,
        -- with no room left it isn't shown)
        local leftW = math.max(titleW + versionW,
                Draw.textWidth(m.smallSize, subtitle or ""))
        local room = miniX - self:w(6) - (x + m.pad + leftW + self:w(8))
        if room < self:w(70) then
            status = nil
        else
            local pillW = math.min(Draw.textWidth(m.smallSize, status) + self:w(30), room)
            status = Draw.fit(status, m.smallSize, pillW - self:w(30))
        end
    end
    if status then
        local pillW = Draw.textWidth(m.smallSize, status) + self:w(30)
        local pillX = miniX - self:w(6) - pillW
        Draw.roundRect(pillX, pillY, pillW, pillH, pillH / 2, C.pill)
        Draw.disc(pillX + self:w(13), pillY + pillH / 2, self:h(4), statusColor)
        self:textIn(pillX + self:w(22), pillY, pillH, m.smallSize, status, C.text)
    end
    if CpModernHud.minimized then
        return x, cy
    end

    -- tabs
    cy = cy - m.tabsH
    local tabs = self:getTabs(vehicle)
    local tabH = self:h(28)
    local tabY = cy + (m.tabsH - tabH) / 2
    local tabsW = width - 2 * m.pad
    local tabW = tabsW / #tabs
    Draw.roundRect(x + m.pad, tabY, tabsW, tabH, tabH / 2, C.chip)
    for k, tab in ipairs(tabs) do
        local tx = x + m.pad + (k - 1) * tabW
        local selected = tab.view ~= nil and tab.view == CpModernHud.view
        local hover = not selected and self:isHover(tx, tabY, tabW, tabH)
        if selected or hover then
            Draw.roundRect(tx + self:w(2), tabY + self:h(2), tabW - self:w(4), tabH - self:h(4), (tabH - self:h(4)) / 2,
                    selected and C.surface or C.hover)
        end
        self:textIn(tx + tabW / 2, tabY, tabH, m.smallSize, Draw.fit(t(tab.key), m.smallSize, tabW - self:w(6), selected),
                selected and C.text or C.muted, RenderText.ALIGN_CENTER, selected)
        if not selected then
            self:addElement(tx, tabY, tabW, tabH, tab.onClick or function()
                self:showView(tab.view)
            end)
        end
    end
    return x, cy
end

---@param status CpStatus
function CpModernHud:draw(status)
    if not self.isOpen then
        return
    end
    self.status = status
    self.elements = {}
    self.wheelElements = {}
    self.plotShown = false
    self.dropdownSeen = false
    self.keyHandlers = {}
    if self:wantsKeys() and not g_gui:getIsGuiVisible() then
        self:takeKeys()
    end
    if not CpModernHud.minimized then
        -- Q / E: the tabs
        local views = CpModernHud.VIEWS
        local current = 1
        for i, view in ipairs(views) do
            if view == CpModernHud.view then
                current = i
            end
        end
        self:setKey("pagePrev", t("CP_cc_key_prevTab"), function()
            self:showView(views[(current - 2) % #views + 1])
        end)
        self:setKey("pageNext", t("CP_cc_key_nextTab"), function()
            self:showView(views[current % #views + 1])
        end)
    end
    self:setKey("back", t("CP_cc_key_back"), function()
        self.vehicle:resetCpHud()
    end)
    if CpModernHud.minimized then
        self:drawMini()
    elseif CpModernHud.view == CpModernHud.VIEW_SAVED then
        self:drawSaved()
    elseif CpModernHud.view == CpModernHud.VIEW_FLEET then
        self:drawFleet()
    elseif CpModernHud.view == CpModernHud.VIEW_SETTINGS then
        self:drawSettings()
    else
        self:drawCourse()
    end
    -- an open list on top of everything (closed when its row isn't shown any more)
    if self.dropdown and not self.dropdownSeen then
        self.dropdown = nil
    end
    self.popupElements = {}
    if self.dropdown then
        self:drawDropdown()
    end
    self:updateKeyTexts()
end

--- The progress bar through the course and how much of it is done (and how long it still takes), in a row h high.
--- With a name (another vehicle's progress, the combine's on an unloader) the name is in front of the bar.
function CpModernHud:drawProgress(m, x, y, h, doneFraction, status, name)
    local C = CpModernHud.C
    local barH = self:h(5)
    local barY = y + (h - barH) / 2
    local label = string.format("%d%%", math.floor(doneFraction * 100 + 0.5))
    if status and status:getIsActive() and status.currentWaypointIx and status.numberOfWaypoints then
        label = label .. " · " .. self:getWaypointText(status)
    end
    local timeLeft = status and status:getTimeRemainingText()
    if timeLeft and timeLeft ~= "" and doneFraction < 1 then
        label = label .. " · " .. t("CP_cc_progress_left", timeLeft)
        -- and the game's clock when it is done
        local done = CpModernHud.finishTimeText(timeLeft)
        if done then
            label = label .. " · " .. t("CP_cc_progress_doneAt", done)
        end
    end
    local barX = x + m.pad
    local barW = m.width - 2 * m.pad - Draw.textWidth(m.smallSize, label) - self:w(10)
    if name then
        local nameW = math.min(Draw.textWidth(m.smallSize, name), (m.width - 2 * m.pad) * 0.35)
        self:textIn(barX, y, h, m.smallSize, Draw.fit(name, m.smallSize, nameW), C.muted)
        barX = barX + nameW + self:w(8)
        barW = barW - nameW - self:w(8)
    end
    Draw.roundRect(barX, barY, barW, barH, barH / 2, C.track)
    if doneFraction > 0 then
        Draw.roundRect(barX, barY, math.max(barH, barW * doneFraction), barH, barH / 2, C.accent)
    end
    self:textIn(x + m.width - m.pad, y, h, m.smallSize, label, C.muted, RenderText.ALIGN_RIGHT)
end

--- The map closer (step 1) or further out (-1)
function CpModernHud:zoomMap(step)
    local ix = math.max(1, math.min(#CpModernHud.MAP_ZOOMS, CpModernHud.mapZoomIx + step))
    if ix ~= CpModernHud.mapZoomIx then
        CpModernHud.mapZoomIx = ix
        self.mapCenter = nil
    end
end

--- The course map, with what is done and where the vehicle is; - and + zoom in round the vehicle (it follows it)
--- and out to the whole course
function CpModernHud:drawCoursePlot(vehicle, info, plotX, plotY, plotW, plotH, progressIx, others)
    local C = CpModernHud.C
    local zoomIx = CpModernHud.mapZoomIx
    local zoom = CpModernHud.MAP_ZOOMS[zoomIx]
    local center
    if zoom > 1 then
        local vx, _, vz = getWorldTranslation(vehicle.rootNode)
        local c = self.mapCenter
        local span = self.plot and self.plot.span or 100
        if c == nil or c.zoom ~= zoom or (not c.pinned
                and (vx - c.x) ^ 2 + (vz - c.z) ^ 2 > (span * CpModernHud.MAP_RECENTER) ^ 2) then
            c = {x = vx, z = vz, zoom = zoom}
            self.mapCenter = c
        end
        center = c
    end
    local key = string.format("%.5f%.5f%.5f%d%.1f%.1f", plotX, plotY, plotW, zoom, center and center.x or 0,
            center and center.z or 0)
    if self.plot == nil or self.plot.course ~= info.plotCourse or self.plotKey ~= key then
        self.plot = Draw.makePlot(info.plotCourse, plotX, plotY, plotW, plotH, zoom, center)
        self.plotKey = key
    end
    Draw.drawPlot(self.plot, progressIx or 0, vehicle, self:h(1.6), others)
    self.plotShown = true
    -- the others' arrows: a click enters the vehicle, its name over the arrow under the mouse
    local m = self:metrics()
    local hovered
    for _, marker in ipairs(self.plot.markers or {}) do
        local hw, hh = self:w(12), self:h(12)
        local v = marker.vehicle
        if self:isHover(marker.x - hw, marker.y - hh, 2 * hw, 2 * hh) then
            hovered = hovered or marker
        end
        self:addElement(marker.x - hw, marker.y - hh, 2 * hw, 2 * hh, function()
            if g_localPlayer then
                g_localPlayer:requestToEnterVehicle(v)
            end
        end)
    end
    if hovered then
        local name = hovered.vehicle:getName()
        local tipH = self:h(20)
        local tipW = math.min(Draw.textWidth(m.smallSize, name) + self:w(14), plotW - self:w(8))
        local tipX = math.max(plotX + self:w(4), math.min(plotX + plotW - tipW - self:w(4), hovered.x - tipW / 2))
        local tipY = hovered.y + hovered.size * 0.6
        if tipY + tipH > plotY + plotH - self:h(4) then
            tipY = hovered.y - hovered.size * 0.6 - tipH
        end
        Draw.roundRect(tipX, tipY, tipW, tipH, tipH / 2, C.pill)
        self:textIn(tipX + tipW / 2, tipY, tipH, m.smallSize, Draw.fit(name, m.smallSize, tipW - self:w(10)), C.text,
                RenderText.ALIGN_CENTER)
    end
    -- zoom: - and + at the bottom right
    local bs = self:h(22)
    local bw = bs / g_screenAspectRatio
    local bx, by = plotX + plotW - 2 * bw - self:w(10), plotY + self:h(6)
    self:button(bx, by, bw, bs, "–", C.chip, C.hover, zoomIx > 1 and C.text or C.muted,
            zoomIx > 1 and function() self:zoomMap(-1) end or nil, self:h(14))
    self:button(bx + bw + self:w(4), by, bw, bs, "+", C.chip, C.hover,
            zoomIx < #CpModernHud.MAP_ZOOMS and C.text or C.muted,
            zoomIx < #CpModernHud.MAP_ZOOMS and function() self:zoomMap(1) end or nil, self:h(14))
end

--- The map shown or hidden (for everyone who doesn't like it: the course's information in its place), as a link
--- right aligned at 'right'. Returns its width.
function CpModernHud:drawMapSwitch(right, y, h)
    local C = CpModernHud.C
    local m = self:metrics()
    local text = t(CpModernHud.showMap and "CP_cc_map_hide" or "CP_cc_map_show")
    local w = Draw.textWidth(m.smallSize, text) + self:w(8)
    local hover = self:isHover(right - w, y, w, h)
    self:textIn(right, y, h, m.smallSize, text, hover and C.text or C.accent, RenderText.ALIGN_RIGHT)
    self:addElement(right - w, y, w, h, function()
        CpModernHud.showMap = not CpModernHud.showMap
        self.plot, self.plotKey = nil, nil
    end)
    return w
end

--- Clear the course: asked first (in the map's place)
function CpModernHud:clearChipAction(vehicle)
    local function askClear()
        self.confirmClear = vehicle
    end
    self:setKey("cancel", t("CP_cc_btn_clear"), askClear)
    return askClear
end

--- Copy the course for another vehicle, or forget the copied one: {label, onClick}, nil: nothing to do
function CpModernHud:copyChip(vehicle, course)
    if CpBaseHud.courseCache == nil then
        return {t("CP_cc_btn_copy"), function()
            CpBaseHud.courseCache = vehicle:getFieldWorkCourse()
            self:showMessage(t("CP_cc_copied", vehicle:getCurrentCpCourseName()), false)
        end}
    elseif CpBaseHud.courseCache ~= course then
        return {t("CP_cc_btn_forget"), function()
            CpBaseHud.courseCache = nil
        end}
    end
end

--- The map hidden: its buttons (clear, turn round, copy) in a row
function CpModernHud:drawCourseChips(vehicle, course, x, y, editable)
    local gap = self:w(6)
    if editable then
        x = x + self:chip(x, y, t("CP_cc_btn_clear"), self:clearChipAction(vehicle)) + gap
        x = x + self:chip(x, y, t("CP_cc_btn_reverse"), function()
            vehicle:cpReverseCurrentCourse()
        end) + gap
    end
    local copy = self:copyChip(vehicle, course)
    if copy then
        self:chip(x, y, copy[1], copy[2])
    end
end

CpModernHud.DETAIL_ROW = 19 -- px

function CpModernHud:detailsHeight(details)
    return #details > 0 and (math.ceil(#details / 2) * self:h(CpModernHud.DETAIL_ROW) + self:h(6)) or 0
end

--- The course's information, label and value in two columns. Returns the new top.
function CpModernHud:drawDetails(x, cy, details)
    local C = CpModernHud.C
    local m = self:metrics()
    local h, rowH = self:detailsHeight(details), self:h(CpModernHud.DETAIL_ROW)
    cy = cy - h
    Draw.roundRect(x + m.pad, cy, m.width - 2 * m.pad, h, m.smallRadius, C.surface)
    local colW = (m.width - 2 * m.pad) / 2
    for k, d in ipairs(details) do
        local col, line = (k - 1) % 2, math.floor((k - 1) / 2)
        local dx = x + m.pad + col * colW + self:w(10)
        local dy = cy + h - self:h(3) - (line + 1) * rowH
        local labelW = Draw.textWidth(m.smallSize, d[1])
        self:textIn(dx, dy, rowH, m.smallSize, d[1], C.muted)
        self:textIn(dx + colW - self:w(20), dy, rowH, m.smallSize,
                Draw.fit(d[2], m.smallSize, colW - labelW - self:w(30), true), C.text, RenderText.ALIGN_RIGHT, true)
    end
    return cy
end

--- The job switch (field work, bales, silo...), when the vehicle can do more than one: its height
function CpModernHud:jobSwitchHeight(vehicle)
    local setting = vehicle:cpGetHudSelectedJobSetting()
    if vehicle:getIsAIActive() or #setting.values < 2 then
        return 0
    end
    return self:h(34)
end

function CpModernHud:drawJobSwitch(x, cy, vehicle)
    local setting = vehicle:cpGetHudSelectedJobSetting()
    local options = {}
    for ix, value in ipairs(setting.values) do
        local key = CpModernHud.JOB_TEXTS[value]
        table.insert(options, {value, key and t(key) or setting.texts[ix]})
    end
    return self:drawSwitch(x, cy, self:h(34), nil, options, setting:getValue(), function(value)
        setting:setValue(value)
        self.dropdown = nil
    end, true)
end

--- The buttons at the bottom: Start / Stop and the one on the left (nil: Start / Stop over the whole width).
--- Returns the new top.
---@param startLabel string|nil another label for Start ("Go to combine")
function CpModernHud:drawButtons(m, x, cy, vehicle, left, canStart, onStart, startLabel)
    local C = CpModernHud.C
    local buttonsH = self:h(44)
    cy = cy - m.padY * 0.5 - buttonsH
    local gap = self:w(10)
    local fullW = m.width - 2 * m.pad
    local half = (fullW - gap) / 2
    local rightX, rightW = x + m.pad, fullW
    if left then
        rightX, rightW = x + m.pad + half + gap, half
        self:button(x + m.pad, cy, half, buttonsH, left.label, left.color or C.surface, left.hoverColor or C.hover,
                left.onClick and (left.textColor or C.text) or C.muted, left.onClick)
        if left.key and left.onClick then
            self:setKey(left.key, left.label, left.onClick, true)
        end
    end
    local label, onClick
    if vehicle:getIsCpActive() then
        label, onClick = t("CP_cc_btn_stop"), function()
            vehicle:cpStartStopDriver(true)
        end
        self:button(rightX, cy, rightW, buttonsH, label, C.danger, C.dangerHover, C.white, onClick)
    elseif isAutoDriveActive(vehicle) and FS25_AutoDrive and FS25_AutoDrive.ADInputManager then
        label, onClick = t("CP_cc_btn_stopAutoDrive"), function()
            CpModernHud.pendingAutoDrive[vehicle] = nil
            FS25_AutoDrive.ADInputManager:onInputCall(vehicle, "input_start_stop")
        end
        self:button(rightX, cy, rightW, buttonsH, label, C.danger, C.dangerHover, C.white, onClick)
    elseif vehicle:getIsAIActive() then
        -- another helper has the vehicle: it can be stopped here
        label, onClick = t("CP_cc_btn_stopHelper"), function()
            vehicle:cpStartStopDriver(true)
        end
        self:button(rightX, cy, rightW, buttonsH, label, C.danger, C.dangerHover, C.white, onClick)
    else
        label, onClick = startLabel or t("CP_cc_btn_start"), canStart and (onStart or function()
            vehicle:cpStartStopDriver(true)
        end) or nil
        self:button(rightX, cy, rightW, buttonsH, label, canStart and C.accent or C.pill, C.accentHover,
                canStart and C.white or C.muted, onClick)
    end
    if onClick then
        self:setKey("accept", label, onClick, true)
    end
    return cy
end

--- The Course tab: the job of the vehicle selected in Courseplay's hud
function CpModernHud:drawCourse()
    local vehicle = self.vehicle
    if vehicle:cpIsHudBaleFinderJobSelected() then
        return self:drawHelperJob("bales")
    elseif vehicle:cpIsHudBunkerSiloJobSelected() then
        return self:drawHelperJob("bunkerSilo")
    elseif vehicle:cpIsHudSiloLoaderJobSelected() then
        return self:drawHelperJob("siloLoader")
    elseif vehicle:cpIsHudUnloaderJobSelected() then
        return self:drawHelperJob("unloader")
    end
    return self:drawFieldwork()
end

--- Field work: the course on the map, its settings, start at and the buttons
function CpModernHud:drawFieldwork()
    local vehicle = self.vehicle
    local status = self.status
    local C = CpModernHud.C
    local m = self:metrics()
    local pad, padY, rowH, width = m.pad, m.padY, m.rowH, m.width
    local textSize, smallSize = m.textSize, m.smallSize
    local course = vehicle:hasCpCourse() and vehicle:getFieldWorkCourse() or nil
    local info = course and self:getCourseInfo(vehicle, course)
    local active = vehicle:getIsCpActive()
    local editable = not vehicle:getIsAIActive()
    local recording = vehicle:getIsCpCourseRecorderActive()
    local rows = self:getFieldworkRows(vehicle)
    -- the map hidden: its buttons in a row and the course's information always shown in its place
    local calling = course ~= nil and self.callingTruck == vehicle
    local mapHidden = info ~= nil and not CpModernHud.showMap and not recording and not self:isGenerating(vehicle)
            and not (self.confirmClear == vehicle and editable) and not calling
    local details = info and (CpModernHud.showDetails or mapHidden) and self:getDetails(info, status) or {}
    local doneFraction = self:getProgress(status)
    local others = info and self:getOthers(vehicle, info.othersOutline, info.othersMargin) or {}

    local switchH = self:jobSwitchHeight(vehicle)
    local othersH = self:othersHeight(others)
    local progressH = (course and doneFraction) and self:h(16) or 0
    local plotH = mapHidden and self:h(30) or self:h(CpModernHud.PLOT)
    local summaryH = self:h(26)
    local detailsH = self:detailsHeight(details)
    local changed = course and not active and self:haveSettingsChanged(vehicle, course)
    local warnH = changed and self:h(22) or 0
    local moreH = self:h(26)
    local startAtH = self:h(34)
    local onArrivalH = getAutoDrive(vehicle) and self:h(34) or 0
    local showCourse = course and vehicle:getCpSettings().showCourse
    local linesH = showCourse and self:h(34) or 0
    local buttonsH = self:h(44)
    local messageH = self:messageHeight()
    local contentH = switchH + progressH + plotH + othersH + summaryH + detailsH + warnH + padY * 0.5 + self:shownRows(rows) * rowH + moreH
            + startAtH + onArrivalH + linesH + padY * 0.5 + buttonsH + messageH

    local statusText, statusColor = self:getStatus(vehicle, status)
    local x, cy = self:drawFrame(m, contentH, vehicle:getName(), statusText, statusColor)
    if switchH > 0 then
        cy = self:drawJobSwitch(x, cy, vehicle)
    end
    if progressH > 0 then
        cy = cy - progressH
        self:drawProgress(m, x, cy, progressH, doneFraction, status)
    end

    -- the course map (or what is going on instead)
    cy = cy - plotH
    local plotX, plotW = x + pad, width - 2 * pad
    if not mapHidden then
        Draw.roundRect(plotX, cy, plotW, plotH, m.smallRadius, C.surface)
    end
    if mapHidden then
        self:drawCourseChips(vehicle, course, plotX, cy + (plotH - self:h(22)) / 2, editable)
    elseif recording then
        local paused = vehicle:getIsCpCourseRecorderPaused()
        self:textLines(plotX + plotW / 2, cy + plotH * 0.3, plotH * 0.4, textSize,
                t(paused and "CP_cc_record_paused" or "CP_cc_record_running"), plotW - 2 * pad,
                paused and C.warn or C.accent, 3, true)
    elseif self:isGenerating(vehicle) then
        self:textIn(plotX + plotW / 2, cy, plotH, textSize, t("CP_cc_generating"), C.muted, RenderText.ALIGN_CENTER)
    elseif calling then
        -- calling a truck: the free trucks, in the map's place
        self:drawCallTruck(vehicle, info, plotX, cy, plotW, plotH)
    elseif course and self.confirmClear == vehicle and editable then
        -- clearing the course: asked first, in the map's place
        self:textIn(plotX + plotW / 2, cy + plotH * 0.5, plotH * 0.3, textSize, t("CP_cc_clear_ask"), C.text,
                RenderText.ALIGN_CENTER)
        local gap, bh = self:w(8), self:h(30)
        local boxW = plotW * 0.86
        local bw = (boxW - gap) / 2
        local bx, by = plotX + (plotW - boxW) / 2, cy + plotH * 0.5 - bh - self:h(12)
        local function clear()
            self.confirmClear = nil
            vehicle:resetCpCoursesFromGui()
        end
        local function cancel()
            self.confirmClear = nil
        end
        self:button(bx, by, bw, bh, t("CP_cc_btn_clear"), C.danger, C.dangerHover, C.white, clear, smallSize)
        self:button(bx + bw + gap, by, bw, bh, t("CP_cc_btn_cancel"), C.chip, C.hover, C.text, cancel, smallSize)
        self:setKey("accept", t("CP_cc_btn_clear"), clear)
        self:setKey("cancel", t("CP_cc_btn_cancel"), cancel)
        self:setKey("back", t("CP_cc_btn_cancel"), cancel)
    elseif course then
        self:drawCoursePlot(vehicle, info, plotX, cy, plotW, plotH, active and status.currentWaypointIx or 0, others)
        local chipY = cy + plotH - self:h(22) - self:h(6)
        if editable then
            -- clear the course (asked first, see above), turn it round
            self:chip(plotX + self:w(6), chipY, t("CP_cc_btn_clear"), self:clearChipAction(vehicle))
            local reverseLabel = t("CP_cc_btn_reverse")
            local reverseW = Draw.textWidth(smallSize, reverseLabel, true) + self:w(18)
            self:chip(plotX + plotW - reverseW - self:w(6), chipY, reverseLabel, function()
                vehicle:cpReverseCurrentCourse()
            end)
        end
        -- copy the course for another vehicle (pasted where there is no course)
        local copy = self:copyChip(vehicle, course)
        if copy then
            self:chip(plotX + self:w(6), cy + self:h(6), copy[1], copy[2])
        end
        -- a combine: call a free truck of the farm to the field
        if isCombine(vehicle) then
            local callLabel = t("CP_cc_btn_callTruck")
            local callW = Draw.textWidth(smallSize, callLabel, true) + self:w(18)
            self:chip(plotX + plotW - callW - self:w(6), cy + self:h(6), callLabel, function()
                self.callingTruck = vehicle
            end)
        end
    else
        local hint = t("CP_cc_hint_noCourse", t("CP_cc_btn_newCourse"))
        local hintW = plotW - 2 * pad
        local buttonsShown = (CpBaseHud.courseCache and 1 or 0) + 1
        local hintH = self:countLines(hint, textSize, hintW) * textSize * 1.4
        self:textLines(plotX + plotW / 2, cy + plotH * 0.5 + self:h(8), hintH, textSize, hint, hintW, C.muted, 4, true)
        local bw, bh = plotW * 0.7, self:h(30)
        local by = cy + plotH * 0.5 - bh
        self:button(plotX + (plotW - bw) / 2, by, bw, bh, t("CP_cc_btn_savedCourses"), C.chip, C.hover, C.text,
                function()
                    self:showView(CpModernHud.VIEW_SAVED)
                end, smallSize)
        if buttonsShown > 1 then
            by = by - bh - self:h(8)
            local name = CpCourseManager.getCourseName(CpBaseHud.courseCache)
            self:button(plotX + (plotW - bw) / 2, by, bw, bh, t("CP_cc_btn_paste", name), C.accent, C.accentHover,
                    C.white, editable and function()
                        vehicle:cpCopyCourse(CpBaseHud.courseCache)
                    end or nil, smallSize)
        end
    end

    if othersH > 0 then
        cy = self:drawOthers(x, cy, others)
    end

    -- the summary (a click shows the details)
    cy = cy - summaryH
    if info then
        local mapW = self:drawMapSwitch(x + width - pad, cy, summaryH)
        local summary = self:getSummary(info)
        local summaryW = width - 2 * pad - mapW - self:w(8)
        if mapHidden then
            self:textIn(x + pad, cy, summaryH, smallSize, Draw.fit(summary, smallSize, summaryW), C.muted)
        else
            local hover = self:isHover(x + pad, cy, summaryW, summaryH)
            self:textIn(x + pad, cy, summaryH, smallSize, Draw.fit(summary, smallSize, summaryW - self:w(16)),
                    hover and C.text or C.muted)
            self:textIn(x + pad + summaryW, cy, summaryH, smallSize, CpModernHud.showDetails and "-" or "+", C.accent,
                    RenderText.ALIGN_RIGHT, true)
            self:addElement(x + pad, cy, summaryW, summaryH, function()
                CpModernHud.showDetails = not CpModernHud.showDetails
            end)
        end
    elseif recording then
        self:textIn(x + pad, cy, summaryH, smallSize, t("CP_cc_record_hint"), C.muted)
    end
    if detailsH > 0 then
        cy = self:drawDetails(x, cy, details)
    end
    if warnH > 0 then
        cy = cy - warnH
        self:textIn(x + pad, cy, warnH, smallSize, Draw.fit(t("CP_cc_settingsChanged"), smallSize, width - 2 * pad),
                C.warn)
    end

    -- settings: label, - value +
    cy = self:drawSettingRows(x, cy - padY * 0.5, rows, editable)

    -- more / fewer settings, record a course
    cy = cy - moreH
    local moreText = CpModernHud.showMore and t("CP_cc_lessSettings") or t("CP_cc_moreSettings")
    local moreW = Draw.textWidth(smallSize, moreText) + self:w(12)
    local moreHover = self:isHover(x + pad, cy, moreW, moreH)
    self:textIn(x + pad, cy, moreH, smallSize, moreText, moreHover and C.text or C.accent)
    local function toggleMore()
        CpModernHud.showMore = not CpModernHud.showMore
        self.dropdown = nil
        self.rowScroll, self.keyRow = 0, nil
    end
    self:addElement(x + pad, cy, moreW, moreH, toggleMore)
    self:setKey("extra1", moreText, toggleMore)
    if vehicle:getCanStartCpCourseRecorder() and not recording then
        local recText = t("CP_cc_record_start")
        local recW = Draw.textWidth(smallSize, recText) + self:w(12)
        local recX = x + width - pad - recW
        local recHover = self:isHover(recX, cy, recW, moreH)
        self:textIn(x + width - pad, cy, moreH, smallSize, recText, recHover and C.text or C.accent,
                RenderText.ALIGN_RIGHT)
        self:addElement(recX, cy, recW, moreH, function()
            vehicle:cpStartCourseRecorder()
        end)
    end

    -- start at: nearest / first / last, as one switch
    cy = self:drawSettingSwitch(x, cy, startAtH, t("CP_cc_startAt"), vehicle:getCpStartingPointSetting(), editable,
            self:w(210), {
                [CpFieldWorkJobParameters.START_AT_NEAREST_POINT] = t("CP_cc_start_nearest"),
                [CpFieldWorkJobParameters.START_AT_FIRST_POINT] = t("CP_cc_start_first"),
                [CpFieldWorkJobParameters.START_AT_LAST_POINT] = t("CP_cc_start_last"),
            })
    -- away from the field AutoDrive takes it there: then start the course, or just stay there
    if onArrivalH > 0 then
        cy = self:drawSwitch(x, cy, onArrivalH, t("CP_cc_onArrival"),
                {{true, t("CP_cc_onArrival_start")}, {false, t("CP_cc_onArrival_stay")}}, CpModernHud.startOnArrival,
                function(value)
                    CpModernHud.startOnArrival = value
                end, true, self:w(210))
    end
    -- the course's lines on the field (Courseplay's show course setting, each player's own): off, start and end of
    -- the rows, round the driver, all
    if linesH > 0 then
        cy = self:drawSettingSwitch(x, cy, linesH, t("CP_cc_lines"), showCourse, true, self:w(210), {
            [CpVehicleSettings.SHOW_COURSE_DEACTIVATED] = t("CP_cc_lines_off"),
            [CpVehicleSettings.SHOW_COURSE_START_STOP] = t("CP_cc_lines_startStop"),
            [CpVehicleSettings.SHOW_COURSE_AROUND_CURRENT_WP] = t("CP_cc_lines_near"),
            [CpVehicleSettings.SHOW_COURSE_ALL] = t("CP_cc_lines_all"),
        })
    end

    -- buttons: new course + start, stop while working, the recorder's while recording
    if recording then
        local paused = vehicle:getIsCpCourseRecorderPaused()
        cy = cy - padY * 0.5 - buttonsH
        local gap = self:w(10)
        local half = (width - 2 * pad - gap) / 2
        self:button(x + pad, cy, half, buttonsH, t(paused and "CP_cc_btn_resume" or "CP_cc_btn_pause"),
                paused and C.accent or C.surface, paused and C.accentHover or C.hover, paused and C.white or C.text,
                function()
                    vehicle:toggleCpCourseRecorderPause()
                end)
        self:button(x + pad + half + gap, cy, half, buttonsH, t("CP_cc_btn_stopRecording"), C.danger, C.dangerHover,
                C.white, function()
                    vehicle:cpStopCourseRecorder()
                end)
    else
        local canGenerate = editable and not self:isGenerating(vehicle) and vehicle:getCanStartCpFieldWork()
        cy = self:drawButtons(m, x, cy, vehicle, not active and {
            label = course and t("CP_cc_btn_newCourse") or t("CP_cc_btn_makeCourse"),
            color = changed and C.accent or nil, hoverColor = changed and C.accentHover or nil,
            textColor = changed and C.white or nil,
            onClick = canGenerate and function()
                self:generateCourse(vehicle)
            end or nil,
            key = "extra2",
        } or nil, course ~= nil and vehicle:getCanStartCp(), function()
            self:startFieldwork(vehicle, info)
        end)
    end
    self:drawMessage(x, cy, messageH)
end

--- The helpers without a field work course: what the job does, how far it is and its settings
function CpModernHud:getHelperJob(kind, vehicle, status)
    local settings = vehicle:getCpSettings()
    local job = {rows = {}}
    if kind == "bales" then
        local parameters = vehicle:getCpBaleFinderJobParameters()
        table.insert(job.rows, self:settingRow(settings.baleCollectorOffset, {disabledText = CpBaseHud.automaticText,
                                                                             live = true}))
        self:addSettingRows(job.rows, {parameters.baleWrapType})
        if status:getIsActive() then
            job.progress = {t("CP_baleFinder_balesLeftover"), status:getBalesText()}
        end
    elseif kind == "bunkerSilo" then
        local parameters = vehicle:getCpBunkerSiloWorkerJobParameters()
        self:addSettingRows(job.rows, {parameters.drivingForwardsIntoSilo, parameters.waitAtParkPosition})
        self:addSettingRows(job.rows, {settings.levelerHeightOffset, settings.bunkerSiloWorkWidth}, {live = true})
        local stop = parameters.stopWithCompactedSilo
        local row = self:settingRow(stop)
        row.value = stop:getString()
        table.insert(job.rows, row)
        if status:getIsActive() then
            job.progress = {t("CP_bunkerSilo_compactionPercentage"), stop:getValue()
                    and string.format("%s/99%%", status:getCompactionText(true)) or status:getCompactionText()}
        end
    elseif kind == "siloLoader" then
        self:addSettingRows(job.rows, {settings.bunkerSiloWorkWidth, settings.loadingShovelHeightOffset},
                {live = true})
        if status:getIsActive() then
            job.progress = {t("CP_siloLoader_fillLevelProgress"), status:getSiloFillLevelPercentageLeftOver()}
        end
        job.positions = true
    elseif kind == "unloader" then
        local parameters = vehicle:getCpCombineUnloaderJobParameters()
        self:addSettingRows(job.rows, {parameters.unloadTarget})
        self:addSettingRows(job.rows, {settings.fullThreshold, settings.combineOffsetX, settings.combineOffsetZ},
                {live = true})
        job.positions = true
    end
    return job
end

--- The map of an unloader: the field its job is set to, the course of a combine working it with how far it is, the
--- combines and the other unloaders. The field is Courseplay's outline when the vehicle has one round the job's
--- position (the detection ran here, or it came over the network), otherwise the course of a Courseplay combine
--- round that position: a client mostly has only that (a truck the combine called, a job started by another player).
--- Nil without either.
function CpModernHud:getUnloaderMap(vehicle)
    local parameters = vehicle.getCpCombineUnloaderJobParameters and vehicle:getCpCombineUnloaderJobParameters()
    local position = parameters and parameters.fieldPosition
    local x, z
    if position then
        x, z = position:getPosition()
    end
    if x == nil or z == nil then
        -- no field set on the map: where the truck is (AutoDrive or the player brought it to a Courseplay combine,
        -- the map page can't set the field while AutoDrive drives). The combine whose course it stands at, else
        -- the nearest working one close by.
        x, _, z = getWorldTranslation(vehicle.rootNode)
        local combine, info = self:findCombineAt(vehicle, x, z, CpModernHud.NEAR_COMBINE)
        if info == nil then
            return nil
        end
        local status = combine.getCpStatus and combine:getCpStatus()
        local active = status and status:getIsActive()
        return {info = info, others = self:getOthers(vehicle, info.othersOutline, info.othersMargin), combine = combine,
                combineStatus = active and status or nil, progressIx = active and status.currentWaypointIx or 0}
    end
    local outline = vehicle.cpGetFieldPolygon and vehicle:cpGetFieldPolygon()
    if outline == nil or #outline < 3 or not isInPolygon(outline, x, z) then
        outline = nil
    end
    local info, others, combine
    if outline then
        others = self:getOthers(vehicle, outline)
        for _, o in ipairs(others) do
            if o.role == "worker" and o.vehicle.hasCpCourse and o.vehicle:hasCpCourse() then
                combine = o.vehicle
                info = self:getCourseInfo(combine, combine:getFieldWorkCourse(), "otherCourseInfo", outline)
                break
            end
        end
    else
        combine, info = self:findCombineAt(vehicle, x, z)
        if info then
            others = self:getOthers(vehicle, info.othersOutline, info.othersMargin)
        end
    end
    if info then
        local status = combine.getCpStatus and combine:getCpStatus()
        local active = status and status:getIsActive()
        return {info = info, others = others, combine = combine, combineStatus = active and status or nil,
                progressIx = active and status.currentWaypointIx or 0}
    end
    if outline == nil then
        return nil
    end
    -- no combine with a course: the field alone
    if self.fieldOnlyInfo == nil or self.fieldOnlyInfo.plotCourse.outline ~= outline then
        self.fieldOnlyInfo = {plotCourse = {waypoints = {}, outline = outline}}
    end
    return {info = self.fieldOnlyInfo, others = others, progressIx = 0}
end

--- The Courseplay field worker (combine) of the farm whose course runs round the position, and its course's
--- information (cached per vehicle: a course is thousands of waypoints). One that is driving before one that stands.
---@param nearDistance number|nil m: a combine this close to the position counts too (the nearest of those), for
--- a truck standing by a combine but off its course
---@return table|nil combine
---@return table|nil info as getCourseInfo gives it
function CpModernHud:findCombineAt(vehicle, x, z, nearDistance)
    local found, foundInfo
    local near, nearInfo, nearD
    local farmId = vehicle:getOwnerFarmId()
    for _, v in ipairs(g_currentMission.vehicleSystem.vehicles) do
        if v ~= vehicle and v.rootNode and not v.isDeleted and (v.getRootVehicle == nil or v:getRootVehicle() == v)
                and v.getOwnerFarmId and v:getOwnerFarmId() == farmId
                and v.getIsCpFieldWorkActive and v:getIsCpFieldWorkActive() and v.hasCpCourse and v:hasCpCourse() then
            local info = self:getCourseInfo(v, v:getFieldWorkCourse(), "combineInfo" .. tostring(v.rootNode))
            if info.othersOutline and #info.othersOutline >= 3
                    and isNearPolygon(info.othersOutline, x, z, info.othersMargin + CpModernHud.OTHERS_MARGIN) then
                local status = v.getCpStatus and v:getCpStatus()
                if status and status:getIsActive() then
                    return v, info
                end
                if found == nil then
                    found, foundInfo = v, info
                end
            elseif nearDistance then
                local vx, _, vz = getWorldTranslation(v.rootNode)
                local d = math.sqrt((vx - x) ^ 2 + (vz - z) ^ 2)
                if d <= nearDistance and (nearD == nil or d < nearD) then
                    near, nearInfo, nearD = v, info, d
                end
            end
        end
    end
    if found then
        return found, foundInfo
    end
    return near, nearInfo
end

function CpModernHud:drawHelperJob(kind)
    local vehicle = self.vehicle
    local status = self.status
    local C = CpModernHud.C
    local m = self:metrics()
    local pad, padY, rowH, width = m.pad, m.padY, m.rowH, m.width
    local smallSize = m.smallSize
    local job = self:getHelperJob(kind, vehicle, status)
    local editable = not vehicle:getIsAIActive()
    local description = t("CP_cc_info_" .. kind)
    local textW = width - 2 * pad
    local descriptionH = self:countLines(description, smallSize, textW) * smallSize * 1.4 + self:h(10)
    local switchH = self:jobSwitchHeight(vehicle)
    local progressH = job.progress and self:h(28) or 0
    -- an unloader: its field, the combine and the others on a map
    local map = kind == "unloader" and self:getUnloaderMap(vehicle)
    local mapH = map and (CpModernHud.showMap and self:h(CpModernHud.PLOT) + self:h(26) or self:h(26)) or 0
    local othersH = map and self:othersHeight(map.others) or 0
    -- the combine's progress (its status comes to every player)
    local combineFraction = map and map.combineStatus and self:getProgress(map.combineStatus)
    local combineProgressH = combineFraction and self:h(16) or 0
    -- an unloader without a map: why (wrapped, it is a sentence)
    local noFieldText = (kind == "unloader" and not map) and t("CP_cc_unloader_noField") or nil
    local noFieldH = noFieldText and (self:countLines(noFieldText, smallSize, textW) * smallSize * 1.4 + self:h(6)) or 0
    -- no field work job (no field implement attached): why there are no courses here
    local fieldworkPossible = false
    for _, value in ipairs(vehicle:cpGetHudSelectedJobSetting().values) do
        if value == 1 then
            fieldworkPossible = true
        end
    end
    local noFieldworkText = not fieldworkPossible and t("CP_cc_hint_noFieldwork")
    local noFieldworkH = noFieldworkText and (self:countLines(noFieldworkText, smallSize, textW) * smallSize * 1.4
            + self:h(6)) or 0
    local buttonsH = self:h(44)
    local messageH = self:messageHeight()
    local contentH = switchH + descriptionH + noFieldworkH + combineProgressH + mapH + othersH + noFieldH + progressH + padY * 0.5 + self:shownRows(job.rows) * rowH + padY * 0.5 + buttonsH
            + messageH
    local statusText, statusColor = self:getStatus(vehicle, status)
    local x, cy = self:drawFrame(m, contentH, vehicle:getName(), statusText, statusColor)
    if switchH > 0 then
        cy = self:drawJobSwitch(x, cy, vehicle)
    end
    cy = cy - descriptionH
    self:textLines(x + pad, cy + self:h(5), descriptionH - self:h(5), smallSize, description, textW, C.muted)
    if noFieldworkH > 0 then
        cy = cy - noFieldworkH
        self:textLines(x + pad, cy, noFieldworkH - self:h(6), smallSize, noFieldworkText, textW, C.warn)
    end
    if combineProgressH > 0 then
        cy = cy - combineProgressH
        self:drawProgress(m, x, cy, combineProgressH, combineFraction, map.combineStatus, map.combine:getName())
    end
    if map then
        -- the map (or not: the switch alone), the switch under it
        local plotH = mapH - self:h(26)
        if plotH > 0 then
            cy = cy - plotH
            Draw.roundRect(x + pad, cy, textW, plotH, m.smallRadius, C.surface)
            self:drawCoursePlot(vehicle, map.info, x + pad, cy, textW, plotH, map.progressIx, map.others)
        end
        cy = cy - self:h(26)
        self:drawMapSwitch(x + width - pad, cy, self:h(26))
        if othersH > 0 then
            cy = self:drawOthers(x, cy, map.others)
        end
    elseif noFieldH > 0 then
        cy = cy - noFieldH
        self:textLines(x + pad, cy, noFieldH - self:h(6), smallSize, noFieldText, textW, C.muted)
    end
    if progressH > 0 then
        cy = cy - progressH
        self:textIn(x + pad, cy, progressH, m.textSize, job.progress[1], C.muted)
        self:textIn(x + width - pad, cy, progressH, m.textSize, job.progress[2], C.accent, RenderText.ALIGN_RIGHT, true)
    end
    cy = self:drawSettingRows(x, cy - padY * 0.5, job.rows, editable)
    local left
    if job.positions then
        -- where it loads and unloads is set on Courseplay's map
        left = {label = t("CP_cc_btn_positions"), onClick = editable and function()
            CpGuiUtil.openCourseGeneratorGui(vehicle)
        end or nil}
    end
    -- an unloader away from its combine's field: Start takes it there with AutoDrive first
    local onStart, startLabel
    if kind == "unloader" and map then
        onStart = function()
            self:startUnloader(vehicle, map)
        end
        startLabel = self:unloaderGoes(vehicle, map) and t("CP_cc_btn_goToCombine") or nil
    end
    cy = self:drawButtons(m, x, cy, vehicle, left, vehicle:getCanStartCp(), onStart, startLabel)
    self:drawMessage(x, cy, messageH)
end

--- Minimized: the header, the progress, the course map and start / stop
function CpModernHud:drawMini()
    local vehicle = self.vehicle
    local status = self.status
    local C = CpModernHud.C
    local m = self:metrics()
    local course = vehicle:cpIsHudFieldWorkJobSelected() and vehicle:hasCpCourse() and vehicle:getFieldWorkCourse() or nil
    -- the unloader's map; with field work selected but no course too, when the unloader job has its field (a truck
    -- the combine called)
    local unloaderMap = (vehicle:cpIsHudUnloaderJobSelected() or course == nil) and self:getUnloaderMap(vehicle)
    local doneFraction = self:getProgress(status)
    local progressH = (course and doneFraction) and self:h(16) or 0
    -- an unloader: the combine's progress instead
    local progressStatus, combineName = status, nil
    if progressH == 0 and unloaderMap and unloaderMap.combineStatus then
        doneFraction = self:getProgress(unloaderMap.combineStatus)
        if doneFraction then
            progressH, progressStatus, combineName = self:h(16), unloaderMap.combineStatus, unloaderMap.combine:getName()
        end
    end
    local info = course and self:getCourseInfo(vehicle, course)
    local miniDetails
    if not CpModernHud.showMap and (info or unloaderMap) then
        miniDetails = {}
        for _, d in ipairs(info and self:getDetails(info, status) or {}) do
            if #miniDetails < 4 then
                table.insert(miniDetails, d)
            end
        end
    end
    local plotH = miniDetails and (self:detailsHeight(miniDetails) + self:h(26)) or self:h(CpModernHud.PLOT)
    local buttonsH = self:h(44)
    local statusText, statusColor = self:getStatus(vehicle, status)
    local x, cy = self:drawFrame(m, progressH + plotH + m.padY * 0.5 + buttonsH, vehicle:getName(), statusText,
            statusColor)
    if progressH > 0 then
        cy = cy - progressH
        self:drawProgress(m, x, cy, progressH, doneFraction, progressStatus, combineName)
    end
    local plotX, plotW = x + m.pad, m.width - 2 * m.pad
    if miniDetails then
        local top = cy
        cy = cy - self:h(26)
        self:drawMapSwitch(x + m.width - m.pad, cy, self:h(26))
        if info then
            self:textIn(plotX, cy, self:h(26), m.smallSize, Draw.fit(self:getSummary(info), m.smallSize, plotW * 0.7),
                    C.muted)
        end
        if #miniDetails > 0 then
            self:drawDetails(x, cy, miniDetails)
        end
        cy = top - plotH
    else
        cy = cy - plotH
        Draw.roundRect(plotX, cy, plotW, plotH, m.smallRadius, C.surface)
    end
    if miniDetails then
        -- (drawn above)
    elseif info then
        self:drawCoursePlot(vehicle, info, plotX, cy, plotW, plotH, vehicle:getIsCpActive() and status.currentWaypointIx or 0,
                self:getOthers(vehicle, info.othersOutline, info.othersMargin))
    elseif unloaderMap then
        self:drawCoursePlot(vehicle, unloaderMap.info, plotX, cy, plotW, plotH, unloaderMap.progressIx, unloaderMap.others)
    else
        -- no course and no map: why (no field implement, the unloader's field not found)
        local hint = vehicle:cpIsHudUnloaderJobSelected() and t("CP_cc_unloader_noField")
                or (not vehicle:getCanStartCpFieldWork() and t("CP_cc_hint_noFieldwork")) or nil
        local lineH = self:h(22)
        local textY = hint and cy + plotH / 2 or cy
        self:textIn(plotX + plotW / 2, textY, hint and lineH or plotH, m.smallSize, t("CP_cc_mini_noCourse"), C.muted,
                RenderText.ALIGN_CENTER)
        if hint then
            self:textIn(plotX + plotW / 2, textY - lineH, lineH, m.smallSize,
                    Draw.fit(hint, m.smallSize, plotW - self:w(20)), C.muted, RenderText.ALIGN_CENTER)
        end
    end
    if not miniDetails and (info or unloaderMap) then
        -- hide the map: a chip on it, top right
        local label = t("CP_cc_map_hide")
        local chipW = Draw.textWidth(m.smallSize, label, true) + self:w(18)
        self:chip(plotX + plotW - chipW - self:w(6), cy + plotH - self:h(22) - self:h(6), label, function()
            CpModernHud.showMap = false
            self.plot, self.plotKey = nil, nil
        end)
    end
    -- no course: Make course on the left, as the full panel has it (greyed without a field implement); an unloader:
    -- its positions (Courseplay's map)
    local left
    if course == nil and vehicle:cpIsHudFieldWorkJobSelected() and not vehicle:getIsCpActive() then
        local canGenerate = not vehicle:getIsAIActive() and not self:isGenerating(vehicle)
                and vehicle:getCanStartCpFieldWork()
        left = {label = t("CP_cc_btn_makeCourse"), key = "extra2", onClick = canGenerate and function()
            self:generateCourse(vehicle)
        end or nil}
    elseif vehicle:cpIsHudUnloaderJobSelected() and not vehicle:getIsCpActive() then
        left = {label = t("CP_cc_btn_positions"), onClick = not vehicle:getIsAIActive() and function()
            CpGuiUtil.openCourseGeneratorGui(vehicle)
        end or nil}
    end
    local onStart, startLabel
    if info then
        onStart = function()
            self:startFieldwork(vehicle, info)
        end
    elseif unloaderMap and vehicle:cpIsHudUnloaderJobSelected() then
        onStart = function()
            self:startUnloader(vehicle, unloaderMap)
        end
        startLabel = self:unloaderGoes(vehicle, unloaderMap) and t("CP_cc_btn_goToCombine") or nil
    end
    self:drawButtons(m, x, cy, vehicle, left, vehicle:getCanStartCp(), onStart, startLabel)
end

------------------------------------------------------------------------------------------------------------------------
--- The Fleet tab: every Courseplay and AutoDrive vehicle of the farm with what it does, how far away it is and how
--- far it is with its course; a click enters it. Found from what every player has (the jobs, where the vehicles are).
------------------------------------------------------------------------------------------------------------------------

CpModernHud.FLEET_ROWS = 7 -- vehicles shown at once, more: the mouse wheel scrolls
CpModernHud.FLEET_ROW = 54 -- px, three lines: name and status, progress, distance and tanks
CpModernHud.FLEET_INTERVAL_MS = 1000
CpModernHud.FUEL_WARN = 15 -- % fuel left shown in the warning color
local FLEET_ORDER = {worker = 1, unloader = 2, autoDrive = 3, helper = 4}

--- The biggest tank of the vehicle and its implements (seeds, fertilizer, the grain tank, a trailer; not fuel, DEF or
--- air) and how full it is, and the vehicle's fuel: {tank = {title, percent} or nil, fuel = percent or nil}. The tank
--- is named after what is in it, when there is something in it.
local function getFillLevels(vehicle)
    local result = {}
    local function isConsumer(object, ix)
        local spec = object.spec_motorized
        for _, consumer in ipairs(spec and spec.consumers or {}) do
            if consumer.fillUnitIndex == ix then
                return true
            end
        end
        return false
    end
    local best
    local function scan(object, depth)
        if object.getFillUnits then
            for ix, unit in pairs(object:getFillUnits()) do
                local capacity = unit.capacity or 0
                local fillType = unit.fillType
                if capacity > 0 and fillType ~= FillType.DEF and fillType ~= FillType.AIR and not isConsumer(object, ix)
                        and (best == nil or capacity > best.capacity) then
                    best = {capacity = capacity, level = unit.fillLevel or 0, fillType = fillType}
                end
            end
        end
        if depth < 6 and object.getAttachedImplements then
            for _, implement in pairs(object:getAttachedImplements()) do
                if implement.object then
                    scan(implement.object, depth + 1)
                end
            end
        end
    end
    scan(vehicle, 0)
    if best then
        local title
        if best.level > 0.5 and best.fillType and best.fillType ~= FillType.UNKNOWN and g_fillTypeManager then
            title = g_fillTypeManager:getFillTypeTitleByIndex(best.fillType)
        end
        result.tank = {title = title, percent = math.floor(100 * best.level / best.capacity + 0.5)}
    end
    if vehicle.getConsumerFillUnitIndex and vehicle.getFillUnitFillLevelPercentage then
        for _, name in ipairs({"DIESEL", "ELECTRICCHARGE", "METHANE"}) do
            local fillType = FillType[name]
            local ix = fillType and vehicle:getConsumerFillUnitIndex(fillType)
            if ix then
                result.fuel = math.floor(100 * (vehicle:getFillUnitFillLevelPercentage(ix) or 0) + 0.5)
                break
            end
        end
    end
    return result
end

--- The farm's vehicles with Courseplay or AutoDrive: {vehicle, role (nil: idle), color, distance}, the working ones
--- first (looked for once a second)
function CpModernHud:getFleet(vehicle)
    local now = g_time or 0
    local c = self.fleetCache
    if c and now - c.time < CpModernHud.FLEET_INTERVAL_MS then
        return c.list
    end
    local C = CpModernHud.C
    local list = {}
    local farmId = vehicle:getOwnerFarmId()
    local vx, _, vz = getWorldTranslation(vehicle.rootNode)
    for _, v in ipairs(g_currentMission.vehicleSystem.vehicles) do
        if v.rootNode and not v.isDeleted and (v.getRootVehicle == nil or v:getRootVehicle() == v)
                and v.getOwnerFarmId and v:getOwnerFarmId() == farmId and (v.getCpStatus ~= nil or v.ad ~= nil) then
            local role = getRole(v)
            local x, _, z = getWorldTranslation(v.rootNode)
            table.insert(list, {vehicle = v, role = role, color = role and CpModernHud.ROLES[role].color or C.muted,
                                distance = math.sqrt((x - vx) ^ 2 + (z - vz) ^ 2), fill = getFillLevels(v)})
        end
    end
    table.sort(list, function(a, b)
        local ra, rb = FLEET_ORDER[a.role] or 5, FLEET_ORDER[b.role] or 5
        if ra ~= rb then
            return ra < rb
        end
        return a.vehicle:getName() < b.vehicle:getName()
    end)
    self.fleetCache = {time = now, list = list}
    return list
end

--- What a vehicle of the fleet does, and its color
function CpModernHud:getFleetStatus(v)
    local C = CpModernHud.C
    if v.getIsCpCourseRecorderActive and v.getIsCpActive and v.cpIsHudFieldWorkJobSelected and v.getCanStartCp
            and v.hasCpCourse then
        return self:getStatus(v, v.getCpStatus and v:getCpStatus())
    end
    if isAutoDriveActive(v) then
        local stateModule = v.ad.stateModule
        local name = stateModule.getFirstMarkerName and stateModule:getFirstMarkerName()
        return name and t("CP_cc_status_autoDriveTo", name) or t("CP_cc_status_autoDrive"), C.accent
    end
    if v.getIsAIActive and v:getIsAIActive() then
        return t("CP_cc_status_otherHelper"), C.muted
    end
    return t("CP_cc_fleet_idle"), C.muted
end

local function distanceText(d)
    if d >= 1000 then
        return string.format("%.1f km", d / 1000)
    end
    return string.format("%d m", math.floor(d + 0.5))
end

--- A vehicle of the fleet: its color, name and status, under it how far away it is and its progress
function CpModernHud:drawFleetRow(x, y, w, h, e, isOwn)
    local C = CpModernHud.C
    local m = self:metrics()
    local v = e.vehicle
    local hover = not isOwn and self:isHover(x, y, w, h)
    if isOwn or hover then
        Draw.roundRect(x, y + self:h(2), w, h - self:h(4), m.smallRadius, isOwn and C.surface or C.hover)
    end
    local line = h / 3
    local topY, midY, bottomY = y + 2 * line, y + line, y
    local left = x + self:w(22)
    Draw.disc(x + self:w(10), topY + line / 2, self:h(4), e.color)
    -- the name and what it does
    local status, color = self:getFleetStatus(v)
    local statusW = math.min(Draw.textWidth(m.smallSize, status), w * 0.5)
    self:textIn(x + w - self:w(8), topY, line, m.smallSize, Draw.fit(status, m.smallSize, statusW),
            color == C.text and C.muted or color, RenderText.ALIGN_RIGHT)
    local name = v:getName()
    if isOwn then
        name = name .. " " .. t("CP_cc_fleet_you")
    end
    self:textIn(left, topY, line, m.smallSize, Draw.fit(name, m.smallSize, w - statusW - self:w(36), true),
            hover and C.accentHover or C.text, nil, true)
    -- its progress: the bar, how far it is, how long it still takes and when it is done
    local cpStatus = v.getCpStatus and v:getCpStatus()
    local fraction = self:getProgress(cpStatus)
    if fraction then
        local barH = self:h(4)
        local label = string.format("%d%%", math.floor(fraction * 100 + 0.5))
        local timeLeft = cpStatus:getTimeRemainingText()
        if timeLeft and timeLeft ~= "" and fraction < 1 then
            label = label .. " · " .. timeLeft
            local done = CpModernHud.finishTimeText(timeLeft)
            if done then
                label = label .. " · " .. t("CP_cc_progress_doneAt", done)
            end
        end
        local labelW = Draw.textWidth(m.smallSize, label)
        local barW = w - (left - x) - labelW - self:w(16)
        local barY = midY + (line - barH) / 2
        Draw.roundRect(left, barY, barW, barH, barH / 2, C.track)
        if fraction > 0 then
            Draw.roundRect(left, barY, math.max(barH, barW * fraction), barH, barH / 2, C.accent)
        end
        self:textIn(x + w - self:w(8), midY, line, m.smallSize, label, C.muted, RenderText.ALIGN_RIGHT)
    end
    -- how far away it is, its tank and fuel; its course on this panel (the row's button, before the row's click)
    local rightEdge = x + w - self:w(8)
    if not isOwn and v.hasCpCourse and v:hasCpCourse() and v.getFieldWorkCourse and v:getFieldWorkCourse() then
        local label = t("CP_cc_fleet_course")
        local chipW, chipH = Draw.textWidth(m.smallSize, label, true) + self:w(16), line - self:h(2)
        self:button(rightEdge - chipW, bottomY + (line - chipH) / 2, chipW, chipH, label, C.chip, C.hover, C.text,
                function()
                    self.peek = v
                    self.plot, self.plotKey = nil, nil
                end, m.smallSize)
        rightEdge = rightEdge - chipW - self:w(8)
    end
    local parts = {}
    if not isOwn then
        table.insert(parts, distanceText(e.distance))
    end
    local fill = e.fill or {}
    if fill.tank then
        table.insert(parts, fill.tank.title and t("CP_cc_fleet_tank", fill.tank.title, fill.tank.percent)
                or t("CP_cc_fleet_tankEmpty"))
    end
    local text = table.concat(parts, " · ")
    local room = rightEdge - left
    local fuelText = fill.fuel and t("CP_cc_fleet_fuel", fill.fuel)
    local fuelW = fuelText and Draw.textWidth(m.smallSize, fuelText) or 0
    if fuelText then
        room = room - fuelW - (text ~= "" and Draw.textWidth(m.smallSize, " · ") or 0)
    end
    if text ~= "" then
        text = Draw.fit(text, m.smallSize, math.max(room, self:w(40)))
        self:textIn(left, bottomY, line, m.smallSize, text, C.muted)
    end
    if fuelText then
        local sep = text ~= "" and " · " or ""
        self:textIn(left + Draw.textWidth(m.smallSize, text .. sep), bottomY, line, m.smallSize, fuelText,
                fill.fuel < CpModernHud.FUEL_WARN and C.warn or C.muted)
    end
    if not isOwn then
        self:addElement(x, y, w, h, function()
            if g_localPlayer then
                g_localPlayer:requestToEnterVehicle(v)
            end
        end)
    end
end

function CpModernHud:drawFleet()
    local vehicle = self.vehicle
    -- another vehicle's course opened from its row: that instead of the list, while it has a course
    local peek = self.peek
    if peek then
        if peek == vehicle or peek.isDeleted or not (peek.hasCpCourse and peek:hasCpCourse())
                or not (peek.getFieldWorkCourse and peek:getFieldWorkCourse()) then
            self.peek = nil
        else
            return self:drawPeek(vehicle, peek)
        end
    end
    local C = CpModernHud.C
    local m = self:metrics()
    local pad, padY, width, smallSize = m.pad, m.padY, m.width, m.smallSize
    local fleet = self:getFleet(vehicle)
    local rowH = self:h(CpModernHud.FLEET_ROW)
    local shown = math.min(#fleet, CpModernHud.FLEET_ROWS)
    local listH = math.max(shown, 1) * rowH
    local footerH = self:h(28)
    local messageH = self:messageHeight()
    local contentH = listH + footerH + messageH + padY * 0.5
    local statusText, statusColor = self:getStatus(vehicle, self.status)
    local x, cy = self:drawFrame(m, contentH, vehicle:getName(), statusText, statusColor)
    local listX, listW = x + pad, width - 2 * pad
    local top = cy
    local maxScroll = math.max(0, #fleet - shown)
    self.fleetScroll = math.max(0, math.min(self.fleetScroll or 0, maxScroll))
    if #fleet == 0 then
        cy = cy - listH
        self:textIn(listX + listW / 2, cy, listH, smallSize, t("CP_cc_fleet_empty"), C.muted, RenderText.ALIGN_CENTER)
    else
        for k = 1, shown do
            local e = fleet[self.fleetScroll + k]
            cy = cy - rowH
            self:drawFleetRow(listX, cy, listW, rowH, e, e.vehicle == vehicle)
        end
        if maxScroll > 0 then
            self:addWheelElement(listX, top - listH, listW, listH, function(dir)
                self.fleetScroll = math.max(0, math.min(maxScroll, (self.fleetScroll or 0) - dir))
            end)
        end
    end
    -- how many are working; which part of the list this is
    cy = cy - footerH
    local working = 0
    for _, e in ipairs(fleet) do
        if e.role then
            working = working + 1
        end
    end
    self:textIn(listX, cy, footerH, smallSize, t("CP_cc_fleet_count", working, #fleet), C.muted)
    if maxScroll > 0 then
        self:textIn(x + width - pad, cy, footerH, smallSize,
                string.format("%d-%d / %d", self.fleetScroll + 1, self.fleetScroll + shown, #fleet), C.muted,
                RenderText.ALIGN_RIGHT)
    end
    self:drawMessage(x, cy, messageH)
end

--- Another vehicle's course on this panel (the Course button of its Fleet row): whose it is and what it does, its
--- progress, its course on the map with the others on that field, the course's details; Enter vehicle, and Stop for
--- a driving one. The row's keys: Backspace back to the list.
function CpModernHud:drawPeek(vehicle, peek)
    local C = CpModernHud.C
    local m = self:metrics()
    local pad, padY, width, smallSize = m.pad, m.padY, m.width, m.smallSize
    local textW = width - 2 * pad
    local course = peek:getFieldWorkCourse()
    local info = self:getCourseInfo(peek, course, "peekCourseInfo")
    local status = peek.getCpStatus and peek:getCpStatus()
    local active = status ~= nil and status:getIsActive()
    local fraction = self:getProgress(status)
    local others = self:getOthers(peek, info.othersOutline, info.othersMargin)
    local details = self:getDetails(info, status, peek)

    local navH = self:h(32)
    local progressH = fraction and self:h(16) or 0
    local plotH = self:h(CpModernHud.PLOT)
    local summaryH = self:h(26)
    local detailsH = self:detailsHeight(details)
    local buttonsH = self:h(44)
    local messageH = self:messageHeight()
    local contentH = navH + progressH + plotH + summaryH + detailsH + padY * 0.5 + buttonsH + messageH
    local statusText, statusColor = self:getStatus(vehicle, self.status)
    local x, cy = self:drawFrame(m, contentH, vehicle:getName(), statusText, statusColor)

    -- back to the list; whose course this is and what it does
    cy = cy - navH
    local function back()
        self.peek = nil
        self.plot, self.plotKey = nil, nil
    end
    local backW = self:chip(x + pad, cy + (navH - self:h(22)) / 2, t("CP_cc_tab_fleet"), back)
    self:setKey("back", t("CP_cc_tab_fleet"), back)
    local peekStatus, peekColor = self:getFleetStatus(peek)
    local statusW = math.min(Draw.textWidth(smallSize, peekStatus), textW * 0.4)
    self:textIn(x + width - pad, cy, navH, smallSize, Draw.fit(peekStatus, smallSize, statusW),
            peekColor == C.text and C.muted or peekColor, RenderText.ALIGN_RIGHT)
    local nameX = x + pad + backW + self:w(10)
    self:textIn(nameX, cy, navH, smallSize,
            Draw.fit(peek:getName(), smallSize, x + width - pad - statusW - self:w(10) - nameX, true), C.text, nil, true)
    if progressH > 0 then
        cy = cy - progressH
        self:drawProgress(m, x, cy, progressH, fraction, status)
    end

    -- its course, where it and the others on the field are
    cy = cy - plotH
    local plotX, plotW = x + pad, textW
    Draw.roundRect(plotX, cy, plotW, plotH, m.smallRadius, C.surface)
    self:drawCoursePlot(peek, info, plotX, cy, plotW, plotH, active and status.currentWaypointIx or 0, others)
    cy = cy - summaryH
    self:textIn(plotX, cy, summaryH, smallSize, Draw.fit(self:getSummary(info), smallSize, plotW), C.muted)
    if detailsH > 0 then
        cy = self:drawDetails(x, cy, details)
    end

    -- Enter vehicle, and Stop while something drives it (Courseplay, AutoDrive or another helper)
    cy = cy - padY * 0.5 - buttonsH
    local function enter()
        if g_localPlayer then
            g_localPlayer:requestToEnterVehicle(peek)
        end
    end
    local stopLabel, stop
    if peek.getIsCpActive and peek:getIsCpActive() then
        stopLabel, stop = t("CP_cc_btn_stop"), function()
            peek:cpStartStopDriver(true)
        end
    elseif isAutoDriveActive(peek) and FS25_AutoDrive and FS25_AutoDrive.ADInputManager then
        stopLabel, stop = t("CP_cc_btn_stopAutoDrive"), function()
            CpModernHud.pendingAutoDrive[peek] = nil
            FS25_AutoDrive.ADInputManager:onInputCall(peek, "input_start_stop")
        end
    elseif peek.getIsAIActive and peek:getIsAIActive() and peek.cpStartStopDriver then
        stopLabel, stop = t("CP_cc_btn_stopHelper"), function()
            peek:cpStartStopDriver(true)
        end
    end
    local gap = self:w(10)
    local enterW = stop and (textW - gap) / 2 or textW
    self:button(x + pad, cy, enterW, buttonsH, t("CP_cc_peek_enter"), C.accent, C.accentHover, C.white, enter)
    self:setKey("accept", t("CP_cc_peek_enter"), enter)
    if stop then
        self:button(x + pad + enterW + gap, cy, enterW, buttonsH, stopLabel, C.danger, C.dangerHover, C.white, stop)
    end
    self:drawMessage(x, cy, messageH)
end

------------------------------------------------------------------------------------------------------------------------
--- The saved courses: Courseplay's course storage (folders with courses, on this PC), with Load, Go, Rename and
--- Delete for a course; Save stores the vehicle's course. Everything through Courseplay's own course manager
--- functions, its full menu (move, copy, the editor) stays a click away.
------------------------------------------------------------------------------------------------------------------------

CpModernHud.SAVED_ROWS = 6 -- folders / courses shown at once, more: the mouse wheel scrolls
CpModernHud.SAVED_ROW = 56 -- px
CpModernHud.SAVED_REFRESH_MS = 2000

function CpModernHud:showView(view)
    CpModernHud.view = view
    self.dropdown, self.confirmDelete, self.savedScroll, self.savedCache, self.rowScroll = nil, nil, 0, nil, 0
    self.keyRow, self.savedHighlight, self.fleetScroll, self.callingTruck, self.peek = nil, nil, 0, nil, nil
    if view == CpModernHud.VIEW_SAVED and g_Courseplay.courseStorage then
        -- (what was saved or deleted meanwhile, also by Courseplay's menu)
        g_Courseplay.courseStorage:refresh()
    end
end

--- The folders and courses of the open folder: {folder (view), folders = {{view, name, count}}, files = {{view, name}}}
function CpModernHud:getSavedEntries()
    local now = g_time or 0
    local c = self.savedCache
    if c and c.folderName == CpModernHud.savedFolder and now - c.time < CpModernHud.SAVED_REFRESH_MS then
        return c
    end
    local top = g_Courseplay.courseStorage.currentDirectoryView
    local folder = top
    if CpModernHud.savedFolder then
        local entry = top:getEntryByName(CpModernHud.savedFolder)
        if entry and entry:isDirectory() then
            folder = entry
        else
            CpModernHud.savedFolder = nil
        end
    end
    c = {folderName = CpModernHud.savedFolder, folder = folder, top = top, time = now, items = {}}
    for _, entry in ipairs(folder:getEntries()) do
        if entry:isDirectory() then
            local count = 0
            for _, sub in ipairs(entry:getEntries()) do
                if not sub:isDirectory() then
                    count = count + 1
                end
            end
            table.insert(c.items, {view = entry, name = entry:getName(), isFolder = true, count = count})
        else
            table.insert(c.items, {view = entry, name = entry:getName()})
        end
    end
    self.savedCache = c
    return c
end

--- Asks for a name (the game's text dialog), then onName(name) with a name that can be a file name
function CpModernHud:askName(title, defaultText, onName)
    TextInputDialog.show(function(_, text, clickOk)
        if clickOk and text ~= nil and text ~= "" then
            onName(CpUtil.cleanFilePath(text))
            self:refreshSaved()
        end
    end, self, defaultText or "", title, title, 50, g_i18n:getText("button_ok"))
end

--- Saved, renamed or deleted: Courseplay's course storage read from disk again (it keeps its list in memory, its own
--- menu does the same after every change), the list rebuilt
function CpModernHud:refreshSaved()
    if g_Courseplay.courseStorage then
        g_Courseplay.courseStorage:refresh()
    end
    self.savedCache = nil
end

--- The saved course on the vehicle, through Courseplay's course manager
function CpModernHud:loadSavedCourse(vehicle, item)
    vehicle:appendLoadedCpCourse(item.view:getEntity())
    -- (Courseplay's load doesn't return whether it worked: the course on the vehicle tells)
    if not vehicle:hasCpCourse() then
        self:showMessage(t("CP_cc_saved_loadFailed", item.name), true)
        return false
    end
    self.generatorSnapshot = nil
    return true
end

--- Go: the course loaded, then started at the field or AutoDrive takes it there first (see startFieldwork)
function CpModernHud:goWithSavedCourse(vehicle, item)
    if not self:loadSavedCourse(vehicle, item) then
        return
    end
    self:showView(CpModernHud.VIEW_COURSE)
    local course = vehicle:hasCpCourse() and vehicle:getFieldWorkCourse()
    if course then
        self:startFieldwork(vehicle, self:getCourseInfo(vehicle, course))
    end
end

function CpModernHud:drawSaved()
    local vehicle = self.vehicle
    local C = CpModernHud.C
    local m = self:metrics()
    local pad, padY, width, smallSize = m.pad, m.padY, m.width, m.smallSize
    local textW = width - 2 * pad
    local saved = self:getSavedEntries()
    local editable = not vehicle:getIsAIActive()
    local canGo = editable and vehicle:getCanStartCpFieldWork()
    local hasCourse = vehicle:hasCpCourse()

    local saveH = hasCourse and self:h(46) or 0
    local navH = self:h(32)
    local hint = not canGo and editable and t("CP_cc_saved_goNeedsImplement")
    local hintH = hint and (self:countLines(hint, smallSize, textW) * smallSize * 1.4 + self:h(4)) or 0
    local rowH = self:h(CpModernHud.SAVED_ROW)
    local shown = math.min(#saved.items, CpModernHud.SAVED_ROWS)
    local listH = math.max(shown, 1) * rowH
    local footerH = self:h(28)
    local messageH = self:messageHeight()
    local contentH = saveH + navH + hintH + listH + footerH + messageH + padY * 0.5

    local statusText, statusColor = self:getStatus(vehicle, self.status)
    local x, cy = self:drawFrame(m, contentH, vehicle:getName(), statusText, statusColor)

    -- save the vehicle's course (in the open folder)
    if saveH > 0 then
        cy = cy - saveH
        local defaultName = vehicle:getCurrentCpCourseName()
        self:button(x + pad, cy + self:h(6), textW, saveH - self:h(6), t("CP_cc_saved_save"), C.accent, C.accentHover,
                C.white, function()
                    self:askName(t("CP_cc_saved_saveTitle"), defaultName, function(name)
                        local file, created = saved.folder:addFile(name)
                        if not created then
                            self:showMessage(t("CP_cc_saved_exists", name), true)
                        elseif not vehicle:saveCpCourses(file, name) then
                            self:showMessage(t("CP_cc_saved_saveFailed", name), true)
                        else
                            self:showMessage(t("CP_cc_saved_saved", name), false)
                        end
                    end)
                end)
    end

    -- the folders, or back to them; how many there are
    cy = cy - navH
    local chipY = cy + (navH - self:h(22)) / 2
    if CpModernHud.savedFolder then
        self:chip(x + pad, chipY, t("CP_cc_saved_allFolders"), function()
            CpModernHud.savedFolder, self.savedScroll, self.confirmDelete, self.savedCache = nil, 0, nil, nil
        end)
        self:textIn(x + width - pad, cy, navH, smallSize,
                Draw.fit(CpModernHud.savedFolder, smallSize, textW * 0.5, true), C.text, RenderText.ALIGN_RIGHT, true)
    else
        self:chip(x + pad, chipY, t("CP_cc_saved_newFolder"), function()
            self:askName(t("CP_cc_saved_newFolder"), "", function(name)
                if not saved.top:addDirectory(name) then
                    self:showMessage(t("CP_cc_saved_exists", name), true)
                end
            end)
        end)
        self:textIn(x + width - pad, cy, navH, smallSize, t("CP_cc_saved_entryCount", #saved.items), C.muted,
                RenderText.ALIGN_RIGHT)
    end
    if hintH > 0 then
        cy = cy - hintH
        self:textLines(x + pad, cy, hintH - self:h(4), smallSize, hint, textW, C.warn)
    end

    -- the list, scrolled with the mouse wheel
    local top = cy
    local maxScroll = math.max(0, #saved.items - shown)
    self.savedScroll = math.max(0, math.min(self.savedScroll or 0, maxScroll))
    self:addSavedKeys(saved, shown, vehicle, editable, canGo)
    if #saved.items == 0 then
        cy = cy - rowH
        self:textIn(x + width / 2, cy, rowH, smallSize, t("CP_cc_saved_empty"), C.muted, RenderText.ALIGN_CENTER)
    end
    for k = 1, shown do
        local item = saved.items[self.savedScroll + k]
        cy = cy - rowH
        if k > 1 then
            Draw.rect(x + pad, cy + rowH, textW, self:h(1), C.line)
        end
        if self:hasKeys() and self.savedHighlight == self.savedScroll + k then
            Draw.roundRect(x + pad - self:w(6), cy + self:h(1), textW + self:w(12), rowH - self:h(2), m.smallRadius,
                    C.surface)
            Draw.roundRect(x + pad - self:w(6), cy + self:h(6), self:w(3), rowH - self:h(12), self:h(1.5), C.accent)
        end
        self:drawSavedItem(x, cy, rowH, item, vehicle, editable, canGo)
    end
    if maxScroll > 0 then
        local areaH = top - cy
        self:addWheelElement(x, cy, width, areaH, function(dir)
            self.savedScroll = math.max(0, math.min(maxScroll, self.savedScroll - dir))
            self.confirmDelete = nil
        end)
        local barH = areaH * shown / #saved.items
        local barY = top - barH - (areaH - barH) * self.savedScroll / maxScroll
        Draw.roundRect(x + width - self:w(7), barY, self:w(3), barH, self:h(1.5), C.muted)
    end

    -- Courseplay's full course manager (move, copy, the editor)
    cy = cy - padY * 0.5 - footerH
    local linkText = t("CP_cc_saved_openManager")
    local linkW = Draw.textWidth(smallSize, linkText) + self:w(12)
    local linkHover = self:isHover(x + pad, cy, linkW, footerH)
    self:textIn(x + pad, cy, footerH, smallSize, linkText, linkHover and C.text or C.accent)
    self:addElement(x + pad, cy, linkW, footerH, function()
        CpGuiUtil.openCourseManagerGui(vehicle)
    end)
    self:drawMessage(x, cy, messageH)
end

--- One folder (open it) or course (Load, Go, Rename, Delete), or the question before deleting it
function CpModernHud:drawSavedItem(x, y, rowH, item, vehicle, editable, canGo)
    local C = CpModernHud.C
    local m = self:metrics()
    local pad, width, smallSize, textSize = m.pad, m.width, m.smallSize, m.textSize
    local textW = width - 2 * pad
    local lineH = rowH * 0.42
    local buttonH = self:h(24)
    local buttonY = y + (rowH * 0.58 - buttonH) / 2
    if self.confirmDelete == item.name then
        self:textIn(x + pad, y + rowH - lineH, lineH, textSize,
                Draw.fit(t("CP_cc_saved_deleteAsk", item.name), textSize, textW), C.text)
        local bw = (textW - self:w(8)) / 2
        local function delete()
            self.confirmDelete = nil
            g_Courseplay.courseStorage:validate(item.view)
            if item.view:delete() then
                self:showMessage(t("CP_cc_saved_deleted", item.name), false)
            else
                self:showMessage(t(item.isFolder and "CP_cc_saved_folderNotEmpty" or "CP_cc_saved_deleteFailed",
                        item.name), true)
            end
            self:refreshSaved()
        end
        self:button(x + pad, buttonY, bw, buttonH, t("CP_cc_saved_delete"), C.danger, C.dangerHover, C.white, delete,
                smallSize)
        self:setKey("accept", t("CP_cc_saved_delete"), delete)
        self:button(x + pad + bw + self:w(8), buttonY, bw, buttonH, t("CP_cc_btn_cancel"), C.chip, C.hover, C.text,
                function()
                    self.confirmDelete = nil
                end, smallSize)
        return
    end
    if item.isFolder then
        -- a folder: its name and how many courses, Open
        local openLabel = t("CP_cc_saved_open")
        local openW = Draw.textWidth(smallSize, openLabel, true) + self:w(22)
        Draw.roundRect(x + pad, y + rowH * 0.58, self:w(14), self:h(10), self:h(2), C.warn)
        self:textIn(x + pad + self:w(20), y + rowH * 0.5, rowH * 0.42, textSize,
                Draw.fit(item.name, textSize, textW - openW - self:w(28), true), C.text, nil, true)
        self:textIn(x + pad, y + rowH * 0.08, rowH * 0.4, smallSize, t("CP_cc_saved_courseCount", item.count), C.muted)
        self:button(x + width - pad - openW, y + (rowH - buttonH) / 2, openW, buttonH, openLabel, C.chip, C.hover, C.text,
                function()
                    CpModernHud.savedFolder, self.savedScroll, self.savedCache = item.name, 0, nil
                end, smallSize)
        local deleteLabel = t("CP_cc_saved_delete")
        if item.count == 0 and editable then
            local deleteW = Draw.textWidth(smallSize, deleteLabel, true) + self:w(18)
            self:button(x + width - pad - openW - self:w(6) - deleteW, y + (rowH - buttonH) / 2, deleteW, buttonH,
                    deleteLabel, C.chip, C.hover, C.text, function()
                        self.confirmDelete = item.name
                    end, smallSize)
        end
        return
    end
    -- a course: its name, then Load, Go, Rename, Delete
    self:textIn(x + pad, y + rowH - lineH, lineH, textSize, Draw.fit(item.name, textSize, textW, true), C.text, nil, true)
    local gap = self:w(6)
    local bw = (textW - 3 * gap) / 4
    local buttons = {
        {t("CP_cc_saved_load"), editable and function()
            if self:loadSavedCourse(vehicle, item) then
                self:showMessage(t("CP_cc_saved_loaded", item.name), false)
                self:showView(CpModernHud.VIEW_COURSE)
            end
        end, C.chip, C.hover, C.text},
        {t("CP_cc_saved_go"), canGo and function()
            self:goWithSavedCourse(vehicle, item)
        end, C.accent, C.accentHover, C.white},
        {t("CP_cc_saved_rename"), function()
            self:askName(t("CP_cc_saved_rename"), item.name, function(name)
                g_Courseplay.courseStorage:validate(item.view)
                if not item.view:rename(name) then
                    self:showMessage(t("CP_cc_saved_exists", name), true)
                end
            end)
        end, C.chip, C.hover, C.text},
        {t("CP_cc_saved_delete"), function()
            self.confirmDelete = item.name
        end, C.chip, C.hover, C.text},
    }
    for k, b in ipairs(buttons) do
        -- (no function: disabled)
        local onClick = b[2] or nil
        self:button(x + pad + (k - 1) * (bw + gap), buttonY, bw, buttonH, b[1], onClick and b[3] or C.pill, b[4],
                onClick and b[5] or C.muted, onClick, smallSize)
    end
end

------------------------------------------------------------------------------------------------------------------------
--- The settings: Courseplay's settings pages in the panel, sorted as in its menus. Vehicle settings in their
--- sections, the course generator's (fields and vines, the menu's two tabs) and the global ones (the menu's two tabs).
--- Each setting as a row with - value + and a list of its values; Courseplay's own menus a click away.
------------------------------------------------------------------------------------------------------------------------

CpModernHud.SETTINGS_ROWS = 12 -- rows shown at once, more: the mouse wheel scrolls

--- The pages, each with its groups: {id, label, menu (opens Courseplay's menu), groups = {{label, sections, settings,
--- vehicle}}}
function CpModernHud:getSettingsPages(vehicle)
    local vehicleSections = CpVehicleSettings.getSettingSetup()
    local generatorSections = CpCourseGeneratorSettings.getSettingSetup()
    local vineSections = CpCourseGeneratorSettings.getVineSettingSetup()
    local globalSettings = g_Courseplay.globalSettings
    local globalSections = globalSettings:getSettingSetup()
    local globalGroups = {}
    -- (Courseplay's menu shows its first two sections, as tabs)
    for i = 1, math.min(2, #globalSections) do
        table.insert(globalGroups, {label = g_i18n:getText(globalSections[i].title), sections = {globalSections[i]},
                                    settings = globalSettings:getSettings()})
    end
    local generatorGroups = {{label = t("CP_cc_settings_fields"), sections = generatorSections,
                              settings = vehicle:getCourseGeneratorSettings(), vehicle = vehicle}}
    if vehicle.getCpVineSettings then
        table.insert(generatorGroups, {label = t("CP_cc_settings_vines"), sections = vineSections,
                                       settings = vehicle:getCpVineSettings(), vehicle = vehicle})
    end
    return {
        {id = "vehicle", label = t("CP_cc_settings_vehicle"), groups = {
            {sections = vehicleSections, settings = vehicle:getCpSettings(), vehicle = vehicle}},
         menu = function()
             CpGuiUtil.openVehicleSettingsGui(vehicle)
         end},
        {id = "generator", label = t("CP_cc_settings_generator"), groups = generatorGroups,
         menu = function()
             CpGuiUtil.openCourseGeneratorGui(vehicle)
         end},
        {id = "global", label = t("CP_cc_settings_global"), groups = globalGroups,
         menu = function()
             CpGuiUtil.openGlobalSettingsGui(vehicle)
         end},
    }
end

--- Is a section shown, and can its settings be changed? As Courseplay's menus decide it.
local function getSectionState(section, vehicle)
    local class = section.class
    if section.isExpertModeOnly and not g_Courseplay.globalSettings.expertModeActive:getValue() then
        return false, false
    end
    local visible, disabled = true, false
    if class and section.isVisibleFunc and class[section.isVisibleFunc] then
        visible = class[section.isVisibleFunc](vehicle or class)
    end
    if class and section.isDisabledFunc and class[section.isDisabledFunc] then
        disabled = class[section.isDisabledFunc](vehicle or class)
    end
    return visible, disabled
end

--- The rows of a group: a heading per section (with more than one) and its visible settings
function CpModernHud:getSettingsRows(group)
    local rows = {}
    for _, section in ipairs(group.sections) do
        local visible, disabled = getSectionState(section, group.vehicle)
        if visible then
            local sectionRows = {}
            for _, template in ipairs(section.elements) do
                local setting = group.settings[template:getName()]
                if setting and setting:getIsVisible() then
                    local row = self:settingRow(setting, {live = true})
                    if disabled then
                        row.disabled, row.dec, row.inc, row.options = true, nil, nil, nil
                    end
                    table.insert(sectionRows, row)
                end
            end
            if #sectionRows > 0 then
                if #group.sections > 1 then
                    table.insert(rows, {header = true, label = g_i18n:getText(section.title)})
                end
                for _, row in ipairs(sectionRows) do
                    table.insert(rows, row)
                end
            end
        end
    end
    return rows
end

function CpModernHud:drawSettings()
    local vehicle = self.vehicle
    local C = CpModernHud.C
    local m = self:metrics()
    local pad, padY, rowH, width, smallSize = m.pad, m.padY, m.rowH, m.width, m.smallSize
    local pages = self:getSettingsPages(vehicle)
    local page = pages[1]
    for _, p in ipairs(pages) do
        if p.id == CpModernHud.settingsPage then
            page = p
        end
    end
    local groupIx = math.max(1, math.min(CpModernHud.settingsGroup, #page.groups))
    local group = page.groups[groupIx]
    local rows = group and self:getSettingsRows(group) or {}
    local switchH = self:h(34)
    local groupsH = #page.groups > 1 and self:h(32) or 0
    local listH = math.max(1, self:shownRows(rows, CpModernHud.SETTINGS_ROWS)) * rowH
    local footerH = self:h(28)
    local messageH = self:messageHeight()
    local contentH = switchH + groupsH + padY * 0.5 + listH + footerH + messageH

    local statusText, statusColor = self:getStatus(vehicle, self.status)
    local x, cy = self:drawFrame(m, contentH, vehicle:getName(), statusText, statusColor)

    -- the page, and its group (as the menus' tabs)
    local options = {}
    for _, p in ipairs(pages) do
        table.insert(options, {p.id, p.label})
    end
    local function showPage(id)
        CpModernHud.settingsPage, CpModernHud.settingsGroup = id, 1
        self.rowScroll, self.dropdown, self.keyRow = 0, nil, nil
    end
    cy = self:drawSwitch(x, cy, switchH, nil, options, page.id, showPage, true)
    for i, p in ipairs(pages) do
        if p == page then
            local nextPage = pages[i % #pages + 1]
            self:setKey("extra2", nextPage.label, function()
                showPage(nextPage.id)
            end)
        end
    end
    if groupsH > 0 then
        local groupOptions = {}
        for i, g in ipairs(page.groups) do
            table.insert(groupOptions, {i, g.label})
        end
        local function showGroup(ix)
            CpModernHud.settingsGroup = ix
            self.rowScroll, self.dropdown, self.keyRow = 0, nil, nil
        end
        cy = self:drawSwitch(x, cy, groupsH, nil, groupOptions, groupIx, showGroup, true)
        local nextGroup = groupIx % #page.groups + 1
        self:setKey("extra1", page.groups[nextGroup].label, function()
            showGroup(nextGroup)
        end)
    end

    if #rows == 0 then
        cy = cy - padY * 0.5 - listH
        self:textIn(x + width / 2, cy, listH, smallSize, t("CP_cc_settings_none"), C.muted, RenderText.ALIGN_CENTER)
    else
        cy = self:drawSettingRows(x, cy - padY * 0.5, rows, true, CpModernHud.SETTINGS_ROWS)
    end

    -- Courseplay's help and its menu of this page
    cy = cy - footerH
    local helpText = t("CP_cc_settings_help")
    local helpW = Draw.textWidth(smallSize, helpText) + self:w(12)
    local helpHover = self:isHover(x + pad, cy, helpW, footerH)
    self:textIn(x + pad, cy, footerH, smallSize, helpText, helpHover and C.text or C.accent)
    self:addElement(x + pad, cy, helpW, footerH, function()
        CpGuiUtil.openHelpMenuGui()
    end)
    local menuText = t("CP_cc_settings_menu")
    local menuW = Draw.textWidth(smallSize, menuText) + self:w(12)
    local menuX = x + width - pad - menuW
    local menuHover = self:isHover(menuX, cy, menuW, footerH)
    self:textIn(x + width - pad, cy, footerH, smallSize, menuText, menuHover and C.text or C.accent,
            RenderText.ALIGN_RIGHT)
    self:addElement(menuX, cy, menuW, footerH, page.menu)
    self:drawMessage(x, cy, messageH)
end

------------------------------------------------------------------------------------------------------------------------
--- Keys: while the panel has the mouse cursor and the mouse is over it, it takes the game's menu keys (as Courseplay's menus do: Enter, Space,
--- Backspace, X, C, Q / E, the arrows and Esc, as the player has them bound), in an input context of its own, so they
--- don't also drive. The game's key help shows what they do. Esc or Courseplay's mouse key give them back.
------------------------------------------------------------------------------------------------------------------------

CpModernHud.INPUT_CONTEXT = "CP_COURSECORRECT_PANEL"
--- The panel that has the keys
CpModernHud.keysOwner = nil
--- The game's menu actions and the name the views give their handlers
CpModernHud.KEY_ACTIONS = {
    {"MENU_ACCEPT", "accept"}, {"MENU_ACTIVATE", "activate"}, {"MENU_CANCEL", "cancel"},
    {"MENU_EXTRA_1", "extra1"}, {"MENU_EXTRA_2", "extra2"}, {"MENU_PAGE_PREV", "pagePrev"},
    {"MENU_PAGE_NEXT", "pageNext"}, {"MENU_BACK", "back"},
    {"MENU_AXIS_UP_DOWN", "upDown"}, {"MENU_AXIS_LEFT_RIGHT", "leftRight"},
}

--- The panel is open for the vehicle the player is in, has the mouse cursor and the mouse is over it (or a list or
--- a question of it is open): only then it takes the keys, elsewhere they stay the game's (Tab, driving...)
function CpModernHud:wantsKeys()
    return self.isOpen and g_inputBinding:getShowMouseCursor() and CpUtil.getCurrentVehicle() == self.vehicle
            and not self.vehicle.isDeleted
            and (self:getIsHovered() or self.dropdown ~= nil or self.confirmClear ~= nil or self.confirmDelete ~= nil
                 or self.callingTruck ~= nil)
end

function CpModernHud:hasKeys()
    return CpModernHud.keysOwner == self
end

function CpModernHud:takeKeys()
    if CpModernHud.keysOwner == self or g_inputBinding:getContextName() == CpModernHud.INPUT_CONTEXT then
        return
    end
    if CpModernHud.keysOwner then
        CpModernHud.keysOwner:releaseKeys()
    end
    g_inputBinding:setContext(CpModernHud.INPUT_CONTEXT, true, false)
    CpModernHud.keysOwner = self
    self.keyEvents = {}
    for _, a in ipairs(CpModernHud.KEY_ACTIONS) do
        local action, name = InputAction[a[1]], a[2]
        if action then
            local _, eventId = g_inputBinding:registerActionEvent(action, self, function(_, _, value)
                self:onKey(name, value)
            end, false, true, false, true)
            if eventId then
                g_inputBinding:setActionEventTextVisibility(eventId, false)
                self.keyEvents[name] = {id = eventId}
            end
        end
    end
    -- Courseplay's mouse key and panel key work here too
    local vehicle = self.vehicle
    for _, a in ipairs({{InputAction.CP_TOGGLE_MOUSE, function()
        CpHud.actionEventMouse(vehicle)
    end}, {InputAction.CP_OPEN_CLOSE_VEHICLE_SETTING_DISPLAY, function()
        CpHud.openClose(vehicle)
    end}}) do
        if a[1] then
            local _, eventId = g_inputBinding:registerActionEvent(a[1], self, a[2], false, true, false, true)
            if eventId then
                g_inputBinding:setActionEventTextVisibility(eventId, false)
            end
        end
    end
end

function CpModernHud:releaseKeys()
    if CpModernHud.keysOwner ~= self then
        return
    end
    CpModernHud.keysOwner = nil
    self.keyEvents = nil
    -- (under a menu or a dialog: once it has closed, see updateKeys)
    if g_inputBinding:getContextName() == CpModernHud.INPUT_CONTEXT then
        g_inputBinding:revertContext(true)
        CpModernHud.refreshVehicleKeys(self.vehicle)
    end
end

--- The vehicle's own controls (camera zoom, camera switch, lights...) registered again, back in the game's context:
--- a vehicle that refreshed them while the panel had the keys registered them as not active for input, that is
--- without them, and the camera would not zoom any more till the player got out and in again.
function CpModernHud.refreshVehicleKeys(vehicle)
    local current = CpUtil.getCurrentVehicle()
    for _, v in pairs({vehicle or false, current ~= vehicle and current or false}) do
        if v and not v.isDeleted and v.requestActionEventUpdate then
            v:requestActionEventUpdate()
        end
    end
end

--- Every frame (also with the panel closed): the keys back to the game when the panel doesn't need them any more
function CpModernHud.updateKeys()
    local owner = CpModernHud.keysOwner
    if owner and not owner:wantsKeys() then
        owner:releaseKeys()
    end
    if CpModernHud.keysOwner == nil and g_inputBinding:getContextName() == CpModernHud.INPUT_CONTEXT then
        g_inputBinding:revertContext(true)
        CpModernHud.refreshVehicleKeys(nil)
    end
end

--- What a key does this frame (the views set them while drawing); keep: not over one set already
function CpModernHud:setKey(name, text, fn, keep)
    if self.keyHandlers == nil or (keep and self.keyHandlers[name]) then
        return
    end
    self.keyHandlers[name] = {text = text, fn = fn}
end

--- The game's key help: the keys that do something now, with what they do
function CpModernHud:updateKeyTexts()
    if not self:hasKeys() or self.keyEvents == nil then
        return
    end
    for name, event in pairs(self.keyEvents) do
        local handler = self.keyHandlers[name]
        local text = handler and handler.text
        if self.dropdown then
            text = (name == "upDown" and t("CP_cc_key_select")) or ((name == "accept" or name == "activate")
                    and t("CP_cc_key_pick")) or ((name == "back" or name == "cancel") and t("CP_cc_btn_cancel")) or nil
        end
        if event.text ~= text then
            event.text = text
            if text then
                g_inputBinding:setActionEventText(event.id, text)
            end
            g_inputBinding:setActionEventTextVisibility(event.id, text ~= nil)
        end
    end
end

function CpModernHud:onKey(name, value)
    local d = self.dropdown
    if d then
        -- an open list: up / down, pick, close
        if name == "upDown" and value ~= 0 then
            d.keyIx = math.max(1, math.min(#d.options, (d.keyIx or d.current or 1) + (value > 0 and -1 or 1)))
            local shown = math.min(#d.options, CpModernHud.DROPDOWN_ROWS)
            d.scroll = math.max(0, math.min(d.scroll or 0, d.keyIx - 1))
            if d.keyIx > d.scroll + shown then
                d.scroll = d.keyIx - shown
            end
        elseif name == "accept" or name == "activate" then
            local ix = d.keyIx or d.current
            self.dropdown = nil
            if ix and d.select then
                d.select(ix)
            end
        elseif name == "back" or name == "cancel" then
            self.dropdown = nil
        end
        return
    end
    local handler = self.keyHandlers and self.keyHandlers[name]
    if handler and handler.fn and (value == nil or value ~= 0) then
        handler.fn(value)
    end
end

--- Up / down through the setting rows (not the headings), left / right change, Space the list of values
function CpModernHud:addRowKeys(rows, shown, editable)
    local selectable = {}
    for i, row in ipairs(rows) do
        if not row.header then
            table.insert(selectable, i)
        end
    end
    if #selectable == 0 then
        return
    end
    if self.keyRow and (rows[self.keyRow] == nil or rows[self.keyRow].header) then
        self.keyRow = nil
    end
    self:setKey("upDown", t("CP_cc_key_select"), function(value)
        local pos = 0
        for k, i in ipairs(selectable) do
            if i == self.keyRow then
                pos = k
            end
        end
        if pos == 0 then
            pos = value > 0 and #selectable or 1
        else
            pos = math.max(1, math.min(#selectable, pos + (value > 0 and -1 or 1)))
        end
        self.keyRow = selectable[pos]
        -- (in view, with its heading)
        if self.keyRow <= (self.rowScroll or 0) then
            self.rowScroll = self.keyRow - 1
            if rows[self.keyRow - 1] and rows[self.keyRow - 1].header then
                self.rowScroll = self.keyRow - 2
            end
        elseif self.keyRow > (self.rowScroll or 0) + shown then
            self.rowScroll = self.keyRow - shown
        end
        self.rowScroll = math.max(0, self.rowScroll)
    end)
    local row = self.keyRow and rows[self.keyRow]
    if row and (editable or row.live) and not row.disabled then
        if row.dec and row.inc then
            self:setKey("leftRight", t("CP_cc_key_change"), function(value)
                if value > 0 then
                    row.inc()
                else
                    row.dec()
                end
            end)
        end
        if row.options then
            self:setKey("activate", t("CP_cc_key_list"), function()
                -- (the list opens at the row: its click, made while drawing the row)
                if row.click then
                    row.click()
                end
            end)
        end
    end
end

--- The saved courses: up / down select, X Load, Enter Go, C Save, Backspace Delete, Space a folder open / back
function CpModernHud:addSavedKeys(saved, shown, vehicle, editable, canGo)
    local items = saved.items
    if self.savedHighlight and items[self.savedHighlight] == nil then
        self.savedHighlight = nil
    end
    if #items > 0 then
        self:setKey("upDown", t("CP_cc_key_select"), function(value)
            local ix = self.savedHighlight
            if ix == nil then
                ix = value > 0 and #items or 1
            else
                ix = math.max(1, math.min(#items, ix + (value > 0 and -1 or 1)))
            end
            self.savedHighlight, self.confirmDelete = ix, nil
            if ix <= self.savedScroll then
                self.savedScroll = ix - 1
            elseif ix > self.savedScroll + shown then
                self.savedScroll = ix - shown
            end
        end)
    end
    local item = self.savedHighlight and items[self.savedHighlight]
    if self.confirmDelete then
        -- deleting asked: Enter deletes (the row's button), Backspace / Esc don't
        local cancel = function()
            self.confirmDelete = nil
        end
        self:setKey("cancel", t("CP_cc_btn_cancel"), cancel)
        self:setKey("back", t("CP_cc_btn_cancel"), cancel)
        return
    end
    if CpModernHud.savedFolder then
        self:setKey("activate", t("CP_cc_saved_allFolders"), function()
            CpModernHud.savedFolder, self.savedScroll, self.savedCache, self.savedHighlight = nil, 0, nil, nil
        end)
    end
    if vehicle:hasCpCourse() then
        self:setKey("extra2", t("CP_cc_saved_save"), function()
            self:askName(t("CP_cc_saved_saveTitle"), vehicle:getCurrentCpCourseName(), function(name)
                local file, created = saved.folder:addFile(name)
                if not created then
                    self:showMessage(t("CP_cc_saved_exists", name), true)
                elseif not vehicle:saveCpCourses(file, name) then
                    self:showMessage(t("CP_cc_saved_saveFailed", name), true)
                else
                    self:showMessage(t("CP_cc_saved_saved", name), false)
                end
            end)
        end)
    end
    if item == nil then
        return
    end
    if item.isFolder then
        self:setKey("activate", t("CP_cc_saved_open"), function()
            CpModernHud.savedFolder, self.savedScroll, self.savedCache, self.savedHighlight = item.name, 0, nil, nil
        end)
        return
    end
    if editable then
        self:setKey("extra1", t("CP_cc_saved_load"), function()
            if self:loadSavedCourse(vehicle, item) then
                self:showMessage(t("CP_cc_saved_loaded", item.name), false)
                self:showView(CpModernHud.VIEW_COURSE)
            end
        end)
    end
    if canGo then
        self:setKey("accept", t("CP_cc_saved_go"), function()
            self:goWithSavedCourse(vehicle, item)
        end)
    end
    self:setKey("cancel", t("CP_cc_saved_delete"), function()
        self.confirmDelete = item.name
    end)
end
