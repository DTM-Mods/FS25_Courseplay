--- Drawing helpers of the CourseCorrect panel (CpModernHud): rectangles with round corners, lines, discs, text and
--- the course map, in screen coordinates (0..1, origin bottom left). Client only.
--- Ported from the CourseCorrect (FS25_Guidance) panel.
CpHudDraw = {}
local Draw = CpHudDraw

--- The panel's colors are written as they look on the screen (sRGB), the game takes overlay and text colors
--- as linear values, so they are converted (once per color table).
Draw.GAMMA = 2.2
local linearCache = setmetatable({}, {__mode = "k"})
local function linear(color)
    local c = linearCache[color]
    if c == nil then
        local g = Draw.GAMMA
        c = {(color[1] or 0) ^ g, (color[2] or 0) ^ g, (color[3] or 0) ^ g, color[4] or 1}
        linearCache[color] = c
    end
    return c
end
Draw.linear = linear

--- Colors of the course parts on the map: headland, row, turn and connecting path.
Draw.COLORS = {
    H = {0.24, 0.56, 0.95},
    R = {0.96, 0.70, 0.18},
    T = {0.93, 0.32, 0.48},
    C = {0.62, 0.64, 0.68},
}
Draw.OUTLINE_COLOR = {0.55, 0.75, 0.45, 0.6}
Draw.START_COLOR = {0.30, 0.85, 0.50, 1}
Draw.END_COLOR = {0.93, 0.36, 0.36, 1}
Draw.MARKER_BACKGROUND = {0.08, 0.10, 0.12, 0.9}

local pixelOverlay, circleOverlay, arrowOverlay, tintArrowOverlay

local function getPixel()
    if pixelOverlay == nil then
        pixelOverlay = createImageOverlay("dataS/menu/base/graph_pixel.dds")
    end
    return pixelOverlay
end

--- A white disc: the round corners are its quarters.
local function getCircle()
    if circleOverlay == nil then
        circleOverlay = createImageOverlay(Utils.getFilename(CpGuiUtil.HUD_CIRCLE_FILENAME, Courseplay.BASE_DIRECTORY))
    end
    return circleOverlay
end

--- The vehicle's arrow, in its own colors, pointing up.
local function getArrow()
    if arrowOverlay == nil then
        arrowOverlay = createImageOverlay(Utils.getFilename("img/hudArrow.dds", Courseplay.BASE_DIRECTORY))
    end
    return arrowOverlay
end

--- Another vehicle's arrow: white with a dark edge, drawn in its color.
local function getTintArrow()
    if tintArrowOverlay == nil then
        tintArrowOverlay = createImageOverlay(Utils.getFilename("img/hudArrowTint.dds", Courseplay.BASE_DIRECTORY))
    end
    return tintArrowOverlay
end

--- A texture loads in the background, drawing it before only fills the log with warnings.
local function isReady(id)
    return getIsOverlayReady == nil or getIsOverlayReady(id)
end

function Draw.delete()
    for _, id in pairs({pixelOverlay, circleOverlay, arrowOverlay, tintArrowOverlay}) do
        if id ~= nil then
            delete(id)
        end
    end
    pixelOverlay, circleOverlay, arrowOverlay, tintArrowOverlay = nil, nil, nil, nil
end

--- Part of the disc texture (u0..u1, v0..v1, v up) in a box.
local function circlePart(x, y, w, h, u0, v0, u1, v1, color)
    local id = getCircle()
    if not isReady(id) then
        return
    end
    local c = linear(color)
    setOverlayColor(id, c[1], c[2], c[3], c[4])
    setOverlayUVs(id, u0, v0, u0, v1, u1, v0, u1, v1)
    renderOverlay(id, x, y, w, h)
end

function Draw.rect(x, y, w, h, color)
    local id = getPixel()
    setOverlayRotation(id, 0, 0, 0)
    local c = linear(color)
    setOverlayColor(id, c[1], c[2], c[3], c[4])
    renderOverlay(id, x, y, w, h)
end

--- Rectangle with round corners, the radius in screen height units.
function Draw.roundRect(x, y, w, h, radius, color)
    local ry = math.min(radius, h / 2)
    local rx = math.min(ry / g_screenAspectRatio, w / 2)
    ry = rx * g_screenAspectRatio
    if rx <= 0 then
        return Draw.rect(x, y, w, h, color)
    end
    circlePart(x, y, rx, ry, 0, 0, 0.5, 0.5, color)
    circlePart(x, y + h - ry, rx, ry, 0, 0.5, 0.5, 1, color)
    circlePart(x + w - rx, y, rx, ry, 0.5, 0, 1, 0.5, color)
    circlePart(x + w - rx, y + h - ry, rx, ry, 0.5, 0.5, 1, 1, color)
    if w > 2 * rx then
        Draw.rect(x + rx, y, w - 2 * rx, h, color)
    end
    if h > 2 * ry then
        Draw.rect(x, y + ry, rx, h - 2 * ry, color)
        Draw.rect(x + w - rx, y + ry, rx, h - 2 * ry, color)
    end
end

--- Filled circle around (cx, cy), the radius in screen height units.
function Draw.disc(cx, cy, radius, color)
    local rx = radius / g_screenAspectRatio
    circlePart(cx - rx, cy - radius, 2 * rx, 2 * radius, 0, 0, 1, 1, color)
end

--- The vehicle's arrow centered on (cx, cy), 'size' high (screen height units), pointing at 'angle' (radians on the
--- screen, counterclockwise from the right). In a color: the white arrow tinted (another vehicle), else the green one.
function Draw.arrow(cx, cy, size, angle, color)
    local id = color and getTintArrow() or getArrow()
    if not isReady(id) then
        return
    end
    local w = size / g_screenAspectRatio
    local c = color and linear(color) or {1, 1, 1, 1}
    setOverlayColor(id, c[1], c[2], c[3], c[4])
    -- the texture points up, turned about its middle
    setOverlayRotation(id, angle - math.pi / 2, w / 2, size / 2)
    renderOverlay(id, cx - w / 2, cy - size / 2, w, size)
    setOverlayRotation(id, 0, 0, 0)
end

--- A turned overlay is turned in the game's own pixel shape, which on some screens isn't the one of the screen
--- units: a long turned line then ends short or long. Turned lines are drawn in short pieces, each from its exact
--- start and a little longer than needed.
Draw.LINE_PIECE = 10 -- px
Draw.LINE_OVERLAP = 0.2 -- of a piece

--- Line between two screen points, the thickness in screen height units.
function Draw.line(x1, y1, x2, y2, thickness, color)
    local dx = x2 - x1
    local dy = (y2 - y1) / g_screenAspectRatio
    local length = math.sqrt(dx * dx + dy * dy)
    if length <= 0 then
        return
    end
    local id = getPixel()
    local c = linear(color)
    setOverlayColor(id, c[1], c[2], c[3], c[4])
    local angle = math.atan2(dy, dx)
    -- flat lines aren't turned: one piece
    local pieces = 1
    if math.abs(angle) > 0.002 and math.abs(math.abs(angle) - math.pi) > 0.002 then
        pieces = math.max(1, math.ceil(length * g_screenWidth / Draw.LINE_PIECE))
    end
    setOverlayRotation(id, angle, 0, thickness / 2)
    local step = length / pieces
    local drawn = pieces > 1 and step * (1 + Draw.LINE_OVERLAP) or step
    for i = 0, pieces - 1 do
        local f = i / pieces
        local px = x1 + (x2 - x1) * f
        local py = y1 + (y2 - y1) * f
        renderOverlay(id, px, py - thickness / 2, i == pieces - 1 and step or drawn, thickness)
    end
    setOverlayRotation(id, 0, 0, 0)
end

function Draw.text(x, y, size, text, color, align, bold)
    setTextBold(bold or false)
    setTextAlignment(align or RenderText.ALIGN_LEFT)
    local c = linear(color)
    setTextColor(c[1], c[2], c[3], c[4])
    renderText(x, y, size, text)
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
end

function Draw.textWidth(size, text, bold)
    setTextBold(bold or false)
    local w = getTextWidth(size, text)
    setTextBold(false)
    return w
end

--- The text, cut short with "..." to fit the width.
function Draw.fit(text, size, width, bold)
    if Draw.textWidth(size, text, bold) <= width then
        return text
    end
    while #text > 4 and Draw.textWidth(size, text .. "...", bold) > width do
        -- the last whole character off (not half of an ä)
        text = text:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
    end
    return text .. "..."
end

------------------------------------------------------------------------------------------------------------------------
--- The course map
------------------------------------------------------------------------------------------------------------------------

--- Douglas-Peucker on screen points {x, y, ix}
local function simplifyRun(pts, tolerance)
    if #pts <= 2 then
        return pts
    end
    local keep = {[1] = true, [#pts] = true}
    local function dp(first, last)
        local maxD, index = 0, nil
        local a, b = pts[first], pts[last]
        local dx, dy = b.x - a.x, b.y - a.y
        local len = math.sqrt(dx * dx + dy * dy)
        for i = first + 1, last - 1 do
            local p = pts[i]
            local d
            if len < 1e-9 then
                d = math.sqrt((p.x - a.x) ^ 2 + (p.y - a.y) ^ 2)
            else
                d = math.abs(dx * (a.y - p.y) - dy * (a.x - p.x)) / len
            end
            if d > maxD then
                maxD, index = d, i
            end
        end
        if index and maxD > tolerance then
            keep[index] = true
            dp(first, index)
            dp(index, last)
        end
    end
    dp(1, #pts)
    local out = {}
    for i = 1, #pts do
        if keep[i] then
            table.insert(out, pts[i])
        end
    end
    return out
end

--- The plot of a course in the box x, y, w, h (screen): the field outline and the course as runs of the same part,
--- simplified to what can be seen at that size. The whole course, or zoom times closer around center {x, z} (world).
---@param course table {waypoints = {{x, z, t}}, outline = {{x, z}}}, t is the part the waypoint ends (H, R, T, C)
function Draw.makePlot(course, x, y, w, h, zoom, center)
    local outline = course.outline or {}
    local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
    for _, p in ipairs(outline) do
        minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
        minZ, maxZ = math.min(minZ, p.z), math.max(maxZ, p.z)
    end
    for _, p in ipairs(course.waypoints) do
        minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
        minZ, maxZ = math.min(minZ, p.z), math.max(maxZ, p.z)
    end
    -- pixels per meter, the same in both directions
    local pxW, pxH = w * g_screenWidth, h * g_screenHeight
    zoom = zoom or 1
    local scale = math.min(pxW / math.max(maxX - minX, 1), pxH / math.max(maxZ - minZ, 1)) * 0.94 * zoom
    local cx, cz = (minX + maxX) / 2, (minZ + maxZ) / 2
    if zoom > 1 and center then
        cx, cz = center.x, center.z
    end
    local function toScreen(wx, wz)
        -- north up: the world z grows to the south, the screen y to the top
        return x + w / 2 + (wx - cx) * scale / g_screenWidth, y + h / 2 - (wz - cz) * scale / g_screenHeight
    end
    local plot = {toScreen = toScreen, outline = {}, runs = {}, course = course,
                  box = {x = x, y = y, w = w, h = h}, zoom = zoom, span = pxW / scale}
    for _, p in ipairs(outline) do
        local sx, sy = toScreen(p.x, p.z)
        table.insert(plot.outline, {x = sx, y = sy})
    end
    local tolerance = 0.8 / g_screenHeight
    local wps = course.waypoints
    local run
    for i = 1, #wps do
        local p = wps[i]
        local sx, sy = toScreen(p.x, p.z)
        local t = i > 1 and p.t or (wps[2] and wps[2].t or p.t)
        if run == nil or run.t ~= t then
            local start = run and run.pts[#run.pts]
            run = {t = t, pts = {}}
            if start then
                table.insert(run.pts, start)
            end
            table.insert(plot.runs, run)
        end
        table.insert(run.pts, {x = sx, y = sy, ix = i})
    end
    for _, r in ipairs(plot.runs) do
        r.pts = simplifyRun(r.pts, tolerance)
    end
    return plot
end

--- The part of the line a-b inside the box (Liang-Barsky), or nil
local function clipToBox(ax, ay, bx, by, box)
    local t0, t1 = 0, 1
    local dx, dy = bx - ax, by - ay
    for _, e in ipairs({{-dx, ax - box.x}, {dx, box.x + box.w - ax}, {-dy, ay - box.y}, {dy, box.y + box.h - ay}}) do
        local p, q = e[1], e[2]
        if p == 0 then
            if q < 0 then
                return nil
            end
        else
            local r = q / p
            if p < 0 then
                if r > t1 then
                    return nil
                end
                if r > t0 then
                    t0 = r
                end
            else
                if r < t0 then
                    return nil
                end
                if r < t1 then
                    t1 = r
                end
            end
        end
    end
    return ax + dx * t0, ay + dy * t0, ax + dx * t1, ay + dy * t1
end

--- Draws the plot: the outline, the course (done part dimmed), its start and end, the vehicle and the other vehicles
--- ({vehicle, color, awayColor}, off the map at its edge in awayColor).
function Draw.drawPlot(plot, progressIx, vehicle, thickness, others)
    local box = plot.box
    -- zoomed in, the map is bigger than its box: only what is inside it
    local clip = (plot.zoom or 1) > 1
    local function line(ax, ay, bx, by, width, color)
        if clip then
            ax, ay, bx, by = clipToBox(ax, ay, bx, by, box)
            if ax == nil then
                return
            end
        end
        Draw.line(ax, ay, bx, by, width, color)
    end
    local function inBox(sx, sy)
        return not clip or (sx >= box.x and sx <= box.x + box.w and sy >= box.y and sy <= box.y + box.h)
    end
    local o = plot.outline
    for i = 1, #o do
        local a, b = o[i], o[i % #o + 1]
        line(a.x, a.y, b.x, b.y, thickness, Draw.OUTLINE_COLOR)
    end
    for _, run in ipairs(plot.runs) do
        local c = Draw.COLORS[run.t] or Draw.COLORS.C
        local mainPart = run.t == "R" or run.t == "H"
        run.done = run.done or {c[1], c[2], c[3], 0.3}
        run.todo = run.todo or {c[1], c[2], c[3], mainPart and 0.95 or 0.7}
        local width = mainPart and thickness or thickness * 0.7
        for i = 2, #run.pts do
            local a, b = run.pts[i - 1], run.pts[i]
            line(a.x, a.y, b.x, b.y, width, b.ix <= progressIx and run.done or run.todo)
        end
    end
    -- where the course starts and ends
    local wps = plot.course.waypoints
    if #wps > 0 then
        local sx0, sy0 = plot.toScreen(wps[1].x, wps[1].z)
        local sx1, sy1 = plot.toScreen(wps[#wps].x, wps[#wps].z)
        if inBox(sx0, sy0) then
            Draw.disc(sx0, sy0, thickness * 3.2, Draw.MARKER_BACKGROUND)
            Draw.disc(sx0, sy0, thickness * 2.2, Draw.START_COLOR)
        end
        if inBox(sx1, sy1) then
            Draw.disc(sx1, sy1, thickness * 3.2, Draw.MARKER_BACKGROUND)
            Draw.disc(sx1, sy1, thickness * 2.2, Draw.END_COLOR)
        end
    end
    -- the vehicle: an arrow where it's heading
    if vehicle then
        local vx, _, vz = getWorldTranslation(vehicle.rootNode)
        local dx, _, dz = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
        local sx, sy = plot.toScreen(vx, vz)
        local ax, ay = plot.toScreen(vx + dx, vz + dz)
        -- the direction on the screen (y squeezed by the aspect ratio)
        local ux, uy = (ax - sx) * g_screenAspectRatio, ay - sy
        -- off the map (away from the field): at its edge, like the other vehicles, never out on the screen
        local margin = thickness * 8
        sx = math.max(box.x + margin / g_screenAspectRatio, math.min(box.x + box.w - margin / g_screenAspectRatio, sx))
        sy = math.max(box.y + margin, math.min(box.y + box.h - margin, sy))
        Draw.arrow(sx, sy, thickness * 20, math.atan2(uy, ux))
    end
    -- the others' arrows; where each one is on the screen, for a click on it: plot.markers = {{vehicle, x, y, size}}
    local markers = {}
    for _, o in ipairs(others or {}) do
        local v = o.vehicle
        if v.rootNode and not v.isDeleted then
            local vx, _, vz = getWorldTranslation(v.rootNode)
            local dx, _, dz = localDirectionToWorld(v.rootNode, 0, 0, 1)
            local sx, sy = plot.toScreen(vx, vz)
            local ax, ay = plot.toScreen(vx + dx, vz + dz)
            local ux, uy = (ax - sx) * g_screenAspectRatio, ay - sy
            local margin = thickness * 6
            local inside = sx >= box.x and sx <= box.x + box.w and sy >= box.y and sy <= box.y + box.h
            sx = math.max(box.x + margin / g_screenAspectRatio, math.min(box.x + box.w - margin / g_screenAspectRatio, sx))
            sy = math.max(box.y + margin, math.min(box.y + box.h - margin, sy))
            Draw.arrow(sx, sy, thickness * 17, math.atan2(uy, ux), inside and o.color or o.awayColor or o.color)
            table.insert(markers, {vehicle = v, x = sx, y = sy, size = thickness * 17, inside = inside})
        end
    end
    plot.markers = markers
end
