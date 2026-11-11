
--- Fieldwork Hud page
---@class CpFieldWorkHudPageElement : CpHudPageElement
---@field private parent CpBaseHud
CpFieldWorkHudPageElement = {}
local CpFieldWorkHudPageElement_mt = Class(CpFieldWorkHudPageElement, CpHudPageElement)

function CpFieldWorkHudPageElement.new(overlay, parentHudElement, customMt)
	local self = CpHudPageElement.new(overlay, parentHudElement, customMt or CpFieldWorkHudPageElement_mt)
	return self
end

function CpFieldWorkHudPageElement:setupElements(baseHud, vehicle, lines, wMargin, hMargin)
	
    --- Time remaining text
    local x, y = unpack(lines[7].right)
    self.timeRemainingText = CpTextHudElement.new(self, x - 2.5 * baseHud.wMargin, y,
        CpBaseHud.defaultFontSize, RenderText.ALIGN_RIGHT, CpBaseHud.SECONDARY_TEXT_COLOR)

    --- Toggle waypoint visibility.
    self.courseVisibilityBtn = baseHud:addToolbarButton(self, 2, "cpIconSprite.eye", 14)
    self.courseVisibilityBtn:setCallback("onClickPrimary", vehicle, function (vehicle)
        vehicle:getCpSettings().showCourse:setNextItem()
    end)
    self.reverseCourseBtn = baseHud:addToolbarButton(self, 4, "cpIconSprite.refresh", 13)
    self.reverseCourseBtn:setCallback("onClickPrimary", vehicle, function (vehicle)
        vehicle:cpReverseCurrentCourse()
    end)

    --- Starting point 
    self.startingPointBtn = baseHud:addLeftLineTextButton(self, 5, CpBaseHud.defaultFontSize, 
        function (vehicle)
            vehicle:getCpStartingPointSetting():setNextItem()
        end, vehicle)
   
    --- Work width
    self.workWidthBtn = baseHud:addLineTextButtonWithIncrementalButtons(self, 3, CpBaseHud.defaultFontSize, 
        vehicle:getCourseGeneratorSettings().workWidth)

    --- Tool offset x
    self.toolOffsetXBtn = baseHud:addLineTextButtonWithIncrementalButtons(self, 2, CpBaseHud.defaultFontSize, 
        vehicle:getCpSettings().toolOffsetX)

    --- Lane offset
    self.laneOffsetBtn = baseHud:addRightLineTextButton(self, 5, CpBaseHud.defaultFontSize, 
    function (vehicle)
        vehicle:getCpLaneOffsetSetting():setNextItem()
    end, vehicle)


     --- Course name
    self.courseNameBtn = baseHud:addLeftLineTextButton(self, 4, CpBaseHud.defaultFontSize, 
                                                        function(vehicle)
                                                            baseHud:openCourseGeneratorGui(vehicle)
                                                        end, vehicle)
    --- Leaves room for the waypoint progress.
    local progressWidth = getNormalizedScreenValues(80, 0)
    self.courseNameBtn:setTextLimitWidth(lines[4].right[1] - lines[4].left[1] - progressWidth)

	--- Waypoint progress
	self.waypointProgressBtn = baseHud:addRightLineTextButton(self, 4, CpBaseHud.defaultFontSize,
														function(vehicle)
															baseHud:openCourseManagerGui(vehicle)
														end, vehicle)
	self.waypointProgressBtn:setTextColorChannels(unpack(CpBaseHud.SECONDARY_TEXT_COLOR))
                                                        
    CpGuiUtil.addCopyCourseBtn(self, baseHud, vehicle, lines, wMargin, hMargin, 1)    												
end

function CpFieldWorkHudPageElement:update(dt)
	CpFieldWorkHudPageElement:superClass().update(self, dt)

end

function CpFieldWorkHudPageElement:updateContent(vehicle, status)

    self.timeRemainingText:setTextDetails(status:getTimeRemainingText())

    self.courseNameBtn:setTextDetails(vehicle:getCurrentCpCourseName())

	self.waypointProgressBtn:setTextDetails(status:getWaypointText())

    local startingPoint = vehicle:getCpStartingPointSetting()
    self.startingPointBtn:setTextDetails(startingPoint:getString())
    
	local laneOffset = vehicle:getCpLaneOffsetSetting()
    self.laneOffsetBtn:setVisible(laneOffset:getIsVisible())
    self.laneOffsetBtn:setDisabled(laneOffset:getIsDisabled())
    self.laneOffsetBtn:setTextDetails(laneOffset:getString())

    local workWidth = vehicle:getCourseGeneratorSettings().workWidth
    self.workWidthBtn:setTextDetails(workWidth:getTitle(), workWidth:getString())
    self.workWidthBtn:setVisible(workWidth:getIsVisible())

	local toolOffsetX = vehicle:getCpSettings().toolOffsetX
    local text = toolOffsetX:getIsDisabled() and CpBaseHud.automaticText or toolOffsetX:getString()
    self.toolOffsetXBtn:setTextDetails(toolOffsetX:getTitle(), text)
    self.toolOffsetXBtn:setDisabled(toolOffsetX:getIsDisabled())

	if vehicle:hasCpCourse() then 
        self.courseVisibilityBtn:setVisible(true)
        self.reverseCourseBtn:setVisible(not vehicle:getIsCpActive())
        local value = vehicle:getCpSettings().showCourse:getValue()
        if value == CpVehicleSettings.SHOW_COURSE_DEACTIVATED then 
            self.courseVisibilityBtn:setColor(unpack(CpBaseHud.OFF_COLOR))
        elseif value == CpVehicleSettings.SHOW_COURSE_START_STOP then 
            self.courseVisibilityBtn:setColor(unpack(CpBaseHud.SEMI_ON_COLOR))
        elseif value == CpVehicleSettings.SHOW_COURSE_AROUND_CURRENT_WP then 
            self.courseVisibilityBtn:setColor(unpack(CpBaseHud.BLUE_COLOR))
        else
            self.courseVisibilityBtn:setColor(unpack(CpBaseHud.ON_COLOR))
        end
    else 
        self.courseVisibilityBtn:setVisible(false)
        self.reverseCourseBtn:setVisible(false)
    end

    CpGuiUtil.updateCopyBtn(self, vehicle, status)
end
