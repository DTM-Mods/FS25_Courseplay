--- Base hud element.
---@class CpHudElement : HUDElement
CpHudElement = {}
local CpHudElement_mt = Class(CpHudElement, HUDElement)

function CpHudElement.new(overlay, parentHudElement, customMt)
    if customMt == nil then
        customMt = CpHudElement_mt
    end

    if overlay == nil then 
        --- Not used, but needed for inheritance form HUDElement, similar to HUDDisplayElement
        overlay = Overlay.new(nil, 0, 0, 0, 0)
        overlay:setColor(1, 1, 1, 1)
    end

    local self = HUDElement.new(overlay, parentHudElement, customMt)

    self.callbacks = {}
    self.visible = true
    self.disabled = false
    self.hovered = false
    return self
end

function CpHudElement:addChildReference(child)
    table.insert(self.children, child)
end

function CpHudElement:debug(str,...)
    CpUtil.debugFormat(CpDebug.DBG_HUD, 'Hud element: '..str, ...)
end

function CpHudElement:mouseEvent(posX, posY, isDown, isUp, button,wasUsed)
    if wasUsed == nil then 
        wasUsed = false
    end
        
    if self.visible and not self.disabled and self:isMouseOverArea(posX,posY) then 
        self:setHovered(true)
    else 
        self:setHovered(false)
    end

    for _, child in ipairs(self.children) do
        if child:mouseEvent(posX, posY, isDown, isUp, button,wasUsed) then 
            wasUsed = true
        end
    end
    return wasUsed
end

function CpHudElement:setHovered(hovered)
    if hovered ~= self.hovered then 
        self:debug("hover state changed to %s",tostring(hovered))
        self:raiseCallback("onHoveredChanged",{hovered})
    end
    self.hovered = hovered
end

function CpHudElement:getIsHovered()
    return self.hovered    
end

--- Is the mouse over the element ?
function CpHudElement:isMouseOverArea(posX,posY)
    local x = self.overlay.x
	local y = self.overlay.y
	local width = self.overlay.width
	local height = self.overlay.height
    local offsetX,offsetY = self.overlay.offsetX,self.overlay.offsetY
    return GuiUtils.checkOverlayOverlap(posX, posY, x + offsetX, y + offsetY, width, height)
end

function CpHudElement:setCallback(callbackStr,class,func)
    self.callbacks[callbackStr] = {
        class = class,
        func = func,
    }
end

function CpHudElement:raiseCallback(callbackStr,args)
    if self.callbacks[callbackStr] then 
        local func = self.callbacks[callbackStr].func
        local class = self.callbacks[callbackStr].class
        if args~= nil then
            func(class, self, unpack(args))
        else 
            func(class, self)
        end
    end
end

function CpHudElement:setVisible(visible)
    CpHudElement:superClass().setVisible(self,visible)
    self.visible = visible
    for _, child in pairs(self.children) do
        child:setVisible(visible)
    end
end

function CpHudElement:setDisabled(disabled)
    self.disabled = disabled
    for _, child in pairs(self.children) do
        child:setDisabled(disabled)
    end
end

function CpHudElement:getIsDisabled()
    return self.disabled
end

--- Hud page
---@class CpHudPageElement : CpHudElement
CpHudPageElement = {}
local CpHudPageElement_mt = Class(CpHudPageElement, CpHudElement)

function CpHudPageElement.new(overlay, parentHudElement, customMt)
    if customMt == nil then
        customMt = CpHudPageElement_mt
    end
    local self = CpHudElement.new(overlay, parentHudElement, customMt)
    return self
end

function CpHudPageElement:setupElements()

end

function CpHudPageElement:updateContent()
	
end

--- Generic Hud button element with overlay.
---@class CpHudButtonElement : CpHudElement
CpHudButtonElement = {}
local CpHudButtonElement_mt = Class(CpHudButtonElement, CpHudElement)
CpHudButtonElement.scrollDelayMs = 10
function CpHudButtonElement.new(overlay,parentHudElement,customMt)
    if customMt == nil then
        customMt = CpHudButtonElement_mt
    end
    local self = CpHudElement.new(overlay, parentHudElement, customMt)
    self.lastScrollTimeStamp = g_time
    return self
end

function CpHudButtonElement:mouseEvent(posX, posY, isDown, isUp, button,wasUsed)
    if self.visible and not self.disabled and self:isMouseOverArea(posX,posY) then 

        if button == Input.MOUSE_BUTTON_LEFT then
            if isDown then 
                self:onClickPrimary(posX,posY)
                wasUsed = true
            end
        end
        if self.lastScrollTimeStamp + self.scrollDelayMs < g_time then
            if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
                self.lastScrollTimeStamp =  g_time
                self:onClickMouseWheel(1,posX,posY)
            elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
                self.lastScrollTimeStamp =  g_time
                self:onClickMouseWheel(-1,posX,posY)
            end
        end
    end
    
   return CpHudButtonElement:superClass().mouseEvent(self,posX, posY, isDown, isUp, button,wasUsed)
end

function CpHudButtonElement:onClickPrimary(posX,posY)
    self:debug("onClickPrimary")
    self:raiseCallback("onClickPrimary")
end

function CpHudButtonElement:onClickMouseWheel(dir,posX,posY)
    self:debug("onClickMouseWheel")
    self:raiseCallback("onClickMouseWheel",{dir})
end

--- Icon button on a round background, which lights up while hovered.
---@class CpHudIconButtonElement : CpHudButtonElement
CpHudIconButtonElement = {}
local CpHudIconButtonElement_mt = Class(CpHudIconButtonElement, CpHudButtonElement)
CpHudIconButtonElement.BACKGROUND_COLOR = CpGuiUtil.getLinearColor(255, 255, 255, 0.07)
--- Only visible while hovered.
CpHudIconButtonElement.GHOST_COLOR = CpGuiUtil.getLinearColor(255, 255, 255, 0)

---@param iconOverlay table the background gets the same alignment
---@param parentHudElement table
---@param size number diameter of the background in pixels
---@param backgroundColor table|nil
function CpHudIconButtonElement.new(iconOverlay, parentHudElement, size, backgroundColor, customMt)
    local width, height = getNormalizedScreenValues(size, size)
    local background = CpGuiUtil.createCircleOverlay({width, height}, {1, 1, 1, 1},
        {iconOverlay.alignmentVertical, iconOverlay.alignmentHorizontal})
    local self = CpHudButtonElement.new(background, parentHudElement, customMt or CpHudIconButtonElement_mt)
    self.defaultBackgroundColor = backgroundColor or CpHudIconButtonElement.BACKGROUND_COLOR
    self.backgroundColor = self.defaultBackgroundColor

    --- Centers the icon on the background, the background is still at 0, 0.
    local dx, dy = (width - iconOverlay.width) / 2, (height - iconOverlay.height) / 2
    if iconOverlay.alignmentHorizontal == Overlay.ALIGN_HORIZONTAL_RIGHT then
        dx = -dx
    elseif iconOverlay.alignmentHorizontal == Overlay.ALIGN_HORIZONTAL_CENTER then
        dx = 0
    end
    if iconOverlay.alignmentVertical == Overlay.ALIGN_VERTICAL_TOP then
        dy = -dy
    elseif iconOverlay.alignmentVertical == Overlay.ALIGN_VERTICAL_MIDDLE then
        dy = 0
    end
    self.icon = CpHudElement.new(iconOverlay, self)
    self.icon:setPosition(dx, dy)
    return self
end

--- Colors the icon.
function CpHudIconButtonElement:setColor(r, g, b, a)
    self.icon:setColor(r, g, b, a)
end

---@param color table|nil nil for the default background
function CpHudIconButtonElement:setBackgroundColor(color)
    self.backgroundColor = color or self.defaultBackgroundColor
end

function CpHudIconButtonElement:draw()
    local r, g, b, a = unpack(self.backgroundColor)
    if self.hovered then
        r, g, b = r + (1 - r) * 0.3, g + (1 - g) * 0.3, b + (1 - b) * 0.3
        a = math.max(a, 0.1) + 0.1
    end
    self.overlay:setColor(r, g, b, a)
    CpHudIconButtonElement:superClass().draw(self)
end

--- Rectangle with round corners: a middle part, two side parts and four quarter circles.
---@class CpHudRoundedRectElement : CpHudElement
CpHudRoundedRectElement = {}
local CpHudRoundedRectElement_mt = Class(CpHudRoundedRectElement, CpHudElement)

---@param x number bottom left corner in screen space
---@param y number
---@param width number in screen space
---@param height number
---@param radius number in pixels
---@param color table
function CpHudRoundedRectElement.new(parentHudElement, x, y, width, height, radius, color, customMt)
    local rx, ry = getNormalizedScreenValues(radius, radius)
    rx, ry = math.min(rx, width / 2), math.min(ry, height / 2)
    local bottomLeft = {Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_LEFT}
    local middle = CpGuiUtil.createOverlay({width - 2 * rx, height}, {g_baseUIFilename, g_colorBgUVs},
        color, bottomLeft)
    local self = CpHudElement.new(middle, parentHudElement, customMt or CpHudRoundedRectElement_mt)
    self:setPosition(x + rx, y)

    local function addPart(overlay, partX, partY)
        local part = CpHudElement.new(overlay, self)
        part:setPosition(partX, partY)
    end
    if height > 2 * ry then
        addPart(CpGuiUtil.createOverlay({rx, height - 2 * ry}, {g_baseUIFilename, g_colorBgUVs}, color, bottomLeft),
            x, y + ry)
        addPart(CpGuiUtil.createOverlay({rx, height - 2 * ry}, {g_baseUIFilename, g_colorBgUVs}, color, bottomLeft),
            x + width - rx, y + ry)
    end
    addPart(CpGuiUtil.createCircleOverlay({rx, ry}, color, bottomLeft, {0, 64, 64, 64}), x, y)
    addPart(CpGuiUtil.createCircleOverlay({rx, ry}, color, bottomLeft, {64, 64, 64, 64}), x + width - rx, y)
    addPart(CpGuiUtil.createCircleOverlay({rx, ry}, color, bottomLeft, {0, 0, 64, 64}), x, y + height - ry)
    addPart(CpGuiUtil.createCircleOverlay({rx, ry}, color, bottomLeft, {64, 0, 64, 64}), x + width - rx, y + height - ry)
    return self
end

function CpHudRoundedRectElement:setColor(r, g, b, a)
    self.overlay:setColor(r, g, b, a)
    for _, child in ipairs(self.children) do
        child:setColor(r, g, b, a)
    end
end


--- Generic Hud text element.
---@class CpTextHudElement : CpHudButtonElement
CpTextHudElement = {}
local CpTextHudElement_mt = Class(CpTextHudElement, CpHudButtonElement)
CpTextHudElement.SHADOW_OFFSET_FACTOR = 0.05
CpTextHudElement.highlightedColor = CpGuiUtil.getLinearColor(110, 220, 160)
CpTextHudElement.disabledColor = CpGuiUtil.getLinearColor(110, 116, 124)
CpTextHudElement.defaultColor = CpGuiUtil.getLinearColor(236, 238, 240)
function CpTextHudElement.new(parentHudElement,posX, posY, textSize, textAlignment, textColor, textBold,customMt)
    if customMt == nil then
        customMt = CpTextHudElement_mt
    end
    --- Not used, but needed for inheritance form HUDElement, similar to HUDDisplayElement
    local backgroundOverlay = Overlay.new(nil, 0, 0, 0, 0)

	backgroundOverlay:setColor(1, 1, 1, 1)
    local self = CpHudButtonElement.new(backgroundOverlay, parentHudElement, customMt)
    self.maxWidth = 0.9
    self.text = ""
	self.textSize = textSize or 0
	self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
	self.textAlignment = textAlignment or RenderText.ALIGN_LEFT
	--- Copied, as setTextColorChannels() changes the table.
	self.textColor = {unpack(textColor or CpTextHudElement.defaultColor)}
	self.textBold = textBold or false
	self.hasShadow = false
	self.shadowColor = {
		0,
		0,
		0,
		1
	}
    if textAlignment == RenderText.ALIGN_RIGHT then
        self:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM,Overlay.ALIGN_HORIZONTAL_RIGHT)
    elseif textAlignment == RenderText.ALIGN_CENTER then
        self:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM,Overlay.ALIGN_HORIZONTAL_CENTER)
    end
    self:setTextDetails("")
    self:setPosition(posX, posY)
    return self
end

--- Longer texts are cut off with "...".
---@param width number|nil in screen space before ui scaling, nil for no limit
function CpTextHudElement:setTextLimitWidth(width)
    self.textLimitWidth = width
end

function CpTextHudElement:setTextDetails(text, textSize, textAlignment, textColor, textBold, maxWidth)
	self.text = text or self.text
	self.textSize = textSize or self.textSize
	self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
	self.textAlignment = textAlignment or self.textAlignment
	self.textColor = textColor or self.textColor
	self.textBold = textBold or self.textBold
    self.maxWidth = maxWidth or self.maxWidth
    setTextBold(self.textBold)
	setTextAlignment(self.textAlignment)
    setTextWrapWidth(self.maxWidth)
    setTextLineBounds(0,2)
    if self.textLimitWidth then
        local limitWidth = self.textLimitWidth * self.overlay.scaleWidth
        if getTextWidth(self.screenTextSize, self.text) > limitWidth then
            self.text = Utils.limitTextToWidth(self.text, self.screenTextSize, limitWidth, false, "...")
        end
    end
    local width = getTextWidth(self.screenTextSize, self.text)
	local height = getTextHeight(self.screenTextSize, self.text)
	self:setDimension(width, height)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextWrapWidth(0)
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
end

function CpTextHudElement:setHoveredText(text)
    self.hoveredText = text
end

function CpTextHudElement:setScale(uiScale,uiScale)
	CpTextHudElement:superClass().setScale(self, uiScale,uiScale)

	self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
end

function CpTextHudElement:setVisible(isVisible, animate)
	CpTextHudElement:superClass().setVisible(self, isVisible)

	if animate then
		if not isVisible or not self.animation:getFinished() then
			self.animation:reset()
		end

		if isVisible then
			self.animation:start()
		end
	end
end

function CpTextHudElement:setTextColorChannels(r, g, b, a)
	self.textColor[1] = r
	self.textColor[2] = g
	self.textColor[3] = b
	self.textColor[4] = a
end

function CpTextHudElement:setTextShadow(isShadowEnabled, shadowColor)
	self.hasShadow = isShadowEnabled or self.hasShadow
	self.shadowColor = shadowColor or self.shadowColor
end

function CpTextHudElement:setAnimation(animationTween)
	self:storeOriginalPosition()

	self.animation = animationTween or TweenSequence.NO_SEQUENCE
end

function CpTextHudElement:update(dt)
	if self:getVisible() then
		CpTextHudElement:superClass().update(self, dt)
	end
end

function CpTextHudElement:draw()
    if not self.visible then 
        return
    end

	setTextBold(self.textBold)

	local posX, posY = self:getPosition()

	setTextAlignment(self.textAlignment)
    setTextWrapWidth(self.maxWidth)
    setTextLineBounds(0,2)
   -- setTextLineHeightScale(HUDPopupMessage.TEXT_LINE_HEIGHT_SCALE)
	if self.hasShadow then
		local offset = self.screenTextSize * CpTextHudElement.SHADOW_OFFSET_FACTOR
		local r, g, b, a = unpack(self.shadowColor)

		setTextColor(r, g, b, a * self.overlay.a)
		renderText(posX + offset, posY - offset, self.screenTextSize, self.text)
	end
    local r, g, b, a
    if self.hovered then 
        r, g, b, a = unpack(CpTextHudElement.highlightedColor)
    elseif self.disabled then
        r, g, b, a = unpack(self.disabledColor)
    else 
        r, g, b, a = unpack(self.textColor)
    end
	setTextColor(r, g, b, a * self.overlay.a)
    local text = self.hovered and self.hoveredText or self.text
	renderText(posX, posY, self.screenTextSize, text)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextWrapWidth(0)
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
 --   setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
    CpTextHudElement:superClass().draw(self)
end

function CpTextHudElement:getScreenHeight()
    return self.screenTextSize   
end

function CpTextHudElement:getText()
    return self.text
end

--- Moveable Hud element.
---@class CpHudMoveableElement : CpHudElement
CpHudMoveableElement = {
    dragDelayMs = 15
}
local CpHudMoveableElement_mt = Class(CpHudMoveableElement, CpHudElement)

function CpHudMoveableElement.new(overlay, parentHudElement, isMovingDisabledCallback, customMt)
    if customMt == nil then
        customMt = CpHudMoveableElement_mt
    end
    local self = CpHudElement.new(overlay, parentHudElement, customMt)

    self.dragging = false
    self.dragStartX = nil
    self.dragOffsetX = nil
    self.dragStartY = nil
    self.dragOffsetY = nil
    self.lastDragTimeStamp = nil
    self.dragLimit = 2
    self.isMovingDisabledCallback = isMovingDisabledCallback
    return self
end

function CpHudMoveableElement:setPosition(x,y)
    self.x, self.y = x, y 
    CpHudMoveableElement:superClass().setPosition(self,x,y)
end

function CpHudMoveableElement:mouseEvent(posX, posY, isDown, isUp, button,wasUsed)
    if not self.dragging then 
        local wasUsed = CpHudMoveableElement:superClass().mouseEvent(self,posX, posY, isDown, isUp, button,wasUsed)
        if wasUsed then 
            return
        end
        if not self:isMouseOverArea(posX, posY) then 
            return 
        end
    end
    if not self.visible or self.disabled then 
        return
    end
    if self.isMovingDisabledCallback ~= nil and self.isMovingDisabledCallback(self) then 
        return
    end
    if button == Input.MOUSE_BUTTON_LEFT then
        --- Handles the start dragging and the end of the dragging.
        if isDown and self:isMouseOverArea(posX, posY) then
            if not self.dragging then
                self.dragStartX = posX
                self.dragOffsetX = posX - self.x
                self.dragStartY = posY
                self.dragOffsetY = posY - self.y
                self.dragging = true
                self.lastDragTimeStamp =  g_time
            end
        elseif isUp then
            if self.dragging and (math.abs(posX - self.dragStartX) > self.dragLimit / g_screenWidth or
                    math.abs(posY - self.dragStartY) > self.dragLimit / g_screenHeight) then
                self:moveTo(posX - self.dragOffsetX, posY - self.dragOffsetY)
            else 

            end
            self.dragging = false
        end
    end
    --- Handles the dragging
    if self.dragging and g_time > (self.lastDragTimeStamp + CpHudMoveableElement.dragDelayMs) then 
        if  math.abs(posX - self.dragStartX) > self.dragLimit / g_screenWidth or
        math.abs(posY - self.dragStartY) > self.dragLimit / g_screenHeight then
            self:moveTo(posX - self.dragOffsetX, posY - self.dragOffsetY)
            self.dragStartX = posX
            self.dragOffsetX = posX - self.x
            self.dragStartY = posY
            self.dragOffsetY = posY - self.y
            self.lastDragTimeStamp = g_time
        end
    end
end

function CpHudMoveableElement:moveTo(x, y)
    self:setPosition(x, y)
    self:raiseCallback("onMove", {x, y})
end


--- Hud element for setting list settings.
---@class CpHudSettingElement : CpHudButtonElement
CpHudSettingElement = {}
local CpHudSettingElement_mt = Class(CpHudSettingElement, CpHudButtonElement)
CpHudSettingElement.LABEL_COLOR = CpGuiUtil.getLinearColor(196, 201, 208)
CpHudSettingElement.PILL_COLOR = CpGuiUtil.getLinearColor(255, 255, 255, 0.07)
--- Size of the buttons and height of the pill in pixels.
CpHudSettingElement.BUTTON_SIZE = 20
--- The widest value expected between the buttons.
CpHudSettingElement.VALUE_WIDTH_TEXT = "-100.0 m"

--- The value is shown on a pill between the decremental (left) and incremental (right) button, if there are any.
---@param posBtnY number bottom of the buttons and the pill
---@param incrementalOverlay table|nil aligned bottom right
---@param decrementalOverlay table|nil aligned bottom left
function CpHudSettingElement.new(parentHudElement, posX, posY, maxPosX, posBtnY, incrementalOverlay, decrementalOverlay,
                                    labelTextSize, textSize, textAlignment, textColor, textBold, customMt)
    if customMt == nil then
        customMt = CpHudSettingElement_mt
    end
    --- Not used, but needed for inheritance form HUDElement, similar to HUDDisplayElement
    local backgroundOverlay = Overlay.new(nil, 0, 0, 0, 0)

	backgroundOverlay:setColor(1, 1, 1, 1)
    local self = CpHudButtonElement.new(backgroundOverlay, parentHudElement, customMt)
    self:setPosition(posX, posY)
    self.labelElement = CpTextHudElement.new(parentHudElement, posX, posY, labelTextSize, nil, CpHudSettingElement.LABEL_COLOR)
    self.labelElement:setTextDetails("Label")
    if incrementalOverlay then
        local btnSize = CpHudSettingElement.BUTTON_SIZE
        local btnWidth, btnHeight = getNormalizedScreenValues(btnSize, btnSize)
        local valueWidth = getTextWidth(self:scalePixelToScreenHeight(textSize), CpHudSettingElement.VALUE_WIDTH_TEXT)
        local pillWidth = 2 * btnWidth + valueWidth
        local pillX = maxPosX - pillWidth
        local gap = getNormalizedScreenValues(6, 0)
        self.labelElement:setTextLimitWidth(pillX - posX - gap)
        --- Created first to be drawn below the buttons and the text.
        self.pillElement = CpHudRoundedRectElement.new(parentHudElement, pillX, posBtnY, pillWidth, btnHeight,
            btnSize / 2, CpHudSettingElement.PILL_COLOR)
        self.incrementalElement = CpHudIconButtonElement.new(incrementalOverlay, parentHudElement, btnSize,
            CpHudIconButtonElement.GHOST_COLOR)
        self.incrementalElement:setPosition(maxPosX, posBtnY)
        self.textElement = CpTextHudElement.new(parentHudElement, pillX + pillWidth / 2, posY, textSize, RenderText.ALIGN_CENTER)
        if decrementalOverlay then
            self.decrementalElement = CpHudIconButtonElement.new(decrementalOverlay, parentHudElement, btnSize,
                CpHudIconButtonElement.GHOST_COLOR)
            self.decrementalElement:setPosition(pillX, posBtnY)
        end
    else
        self.textElement = CpTextHudElement.new(parentHudElement, maxPosX, posY, textSize, RenderText.ALIGN_RIGHT)
    end
    self.textElement:setTextDetails("100.00")
    return self
end

function CpHudSettingElement:setTextDetails(labelText, text, labelTextDetails, textDetails)
    labelTextDetails = labelTextDetails or {}
    textDetails = textDetails or {}
    self.textElement:setTextDetails(text, textDetails.textSize, textDetails.textAlignment,
                                     textDetails.textColor, textDetails.textBold, textDetails.maxWidth)
    self.labelElement:setTextDetails(labelText, labelTextDetails.textSize, labelTextDetails.textAlignment,
                                     labelTextDetails.textColor, labelTextDetails.textBold, labelTextDetails.maxWidth)
    
end

function CpHudSettingElement:setCallback(callbackLabel,callbackText,callbackIncremental,callbackDecremental)
    if callbackLabel then
        self.labelElement:setCallback(callbackLabel.callbackStr, 
                                    callbackLabel.class,
                                    callbackLabel.func
                                 --   unpack(callbackLabel.args)
                                )
    end
    if callbackText then
        self.textElement:setCallback(callbackText.callbackStr, 
                                    callbackText.class,
                                    callbackText.func
                                --    unpack(callbackText.args)
                            )
    end                 
    if callbackIncremental and self.incrementalElement then                        
        self.incrementalElement:setCallback(callbackIncremental.callbackStr, 
                                        callbackIncremental.class,
                                        callbackIncremental.func
                                   --     unpack(callbackIncremental.args)
                                    )
    end                 
    if callbackDecremental and self.decrementalElement then  
        self.decrementalElement:setCallback(callbackDecremental.callbackStr, 
                                        callbackDecremental.class,
                                        callbackDecremental.func
                                    --    unpack(callbackDecremental.args)
                                    )
    end
end

--- The buttons and the pill are only shown while the setting can be changed.
function CpHudSettingElement:setButtonsVisible(visible)
    if self.incrementalElement then
        self.incrementalElement:setVisible(visible)
    end
    if self.decrementalElement then
        self.decrementalElement:setVisible(visible)
    end
    if self.pillElement then
        self.pillElement:setVisible(visible)
    end
end

function CpHudSettingElement:setDisabled(disabled)
    if disabled then
        self:setButtonsVisible(false)
        self.textElement:setDisabled(true)
        self.labelElement:setDisabled(true)
    else
        self:setButtonsVisible(self.textElement:getVisible())
        self.textElement:setDisabled(false)
        self.labelElement:setDisabled(false)
    end
    CpHudSettingElement:superClass().setDisabled(self, disabled)
end

function CpHudSettingElement:setVisible(visible)
    self:setButtonsVisible(visible and not self.disabled)
    self.textElement:setVisible(visible)
    self.labelElement:setVisible(visible)
    CpHudSettingElement:superClass().setVisible(self, visible)
end

--- Hud element for setting list settings.
---@class CpHudTextSettingElement : CpHudButtonElement
CpHudTextSettingElement = {}
local CpHudTextSettingElement_mt = Class(CpHudTextSettingElement, CpHudButtonElement)
function CpHudTextSettingElement.new(parentHudElement, posX, posY, maxPosX, textSize, customMt)
    if customMt == nil then
        customMt = CpHudTextSettingElement_mt
    end
    --- Not used, but needed for inheritance form HUDElement, similar to HUDDisplayElement
    local backgroundOverlay = Overlay.new(nil, 0, 0, 0, 0)

	backgroundOverlay:setColor(1, 1, 1, 1)
    local self = CpHudButtonElement.new(backgroundOverlay, parentHudElement, customMt)
    self:setPosition(posX, posY)
    self.labelElement = CpTextHudElement.new(parentHudElement, posX, posY, textSize)
    self.labelElement:setTextDetails("Label")

    self.textElement = CpTextHudElement.new(parentHudElement, maxPosX, posY, textSize,RenderText.ALIGN_RIGHT)
    self.textElement:setTextDetails("100.00")
  

    return self
end

function CpHudTextSettingElement:setTextDetails(labelText, text, labelTextDetails, textDetails)
    labelTextDetails = labelTextDetails or {}
    textDetails = textDetails or {}
    self.textElement:setTextDetails(text, textDetails.textSize, textDetails.textAlignment,
                                     textDetails.textColor, textDetails.textBold)
    self.labelElement:setTextDetails(labelText, labelTextDetails.textSize, labelTextDetails.textAlignment,
                                     labelTextDetails.textColor, labelTextDetails.textBold)
    
end

function CpHudTextSettingElement:setCallback(callbackLabel,callbackText)
    if callbackLabel then
        self.labelElement:setCallback(callbackLabel.callbackStr, 
                                    callbackLabel.class,
                                    callbackLabel.func
                                 --   unpack(callbackLabel.args)
                                )
    end
    if callbackText then
        self.textElement:setCallback(callbackText.callbackStr, 
                                    callbackText.class,
                                    callbackText.func
                                --    unpack(callbackText.args)
                            )
    end                 
end

function CpHudTextSettingElement:setDisabled(disabled)
    if disabled then 
        self.textElement:setDisabled(true)
        self.labelElement:setDisabled(true)
    else 
        self.textElement:setDisabled(false)
        self.labelElement:setDisabled(false)
    end
    CpHudTextSettingElement:superClass().setDisabled(self, disabled)
end

function CpHudTextSettingElement:setVisible(visible)
    self.textElement:setVisible(visible)
    self.labelElement:setVisible(visible)
    CpHudTextSettingElement:superClass().setVisible(self, visible)
end

