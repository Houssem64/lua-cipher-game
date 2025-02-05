local Window = {}

function Window:new(title, width, height, manager)
    local desktopWidth = 1920
    local desktopHeight = 1080
    
    -- Calculate the center position
    local x = 0
    local y = STATUSBAR_HEIGHT
    width = desktopWidth
    height = desktopHeight - STATUSBAR_HEIGHT
    local obj = {
        title = title,
        x = x,
        y = y,
        width = width,
        height = height,
        manager = manager,  -- Store reference to manager
        originalWidth = math.max(500, width),
        originalHeight = math.max(500, height),
        originalX = (desktopWidth - math.max(500, width)) / 2,
        originalY = (desktopHeight - math.max(500, height)) / 2 + STATUSBAR_HEIGHT,
        titleBarHeight = 35,
        isDragging = false,
        isResizing = false,
        isMinimized = false,
        isMaximized = true,
        dragOffsetX = 0,
        dragOffsetY = 0,
        backgroundColor = {0.3, 0.3, 0.3},
        titleBarColor = {0.4, 0.4, 0.4},
        buttonSize = 20,
        resizeHandleSize = 15,
        buttons = {
            close = {color = {0.8, 0.2, 0.2}},
            minimize = {color = {0.8, 0.8, 0.2}},
            maximize = {color = {0.2, 0.8, 0.2}}
        }
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Window:minimize()
    self.isMinimized = not self.isMinimized
    if self.isMinimized then
        self.originalHeight = self.height
        self.height = self.titleBarHeight
    else
        self.height = self.originalHeight
    end
end

function Window:maximize()
    self.isMaximized = not self.isMaximized
    if self.isMaximized then
        self.originalX = self.x
        self.originalY = self.y
        self.originalWidth = self.width
        self.originalHeight = self.height
        
        self.x = 0
        self.y = STATUSBAR_HEIGHT  -- Account for status bar
        self.width = 1920
        self.height = 1080 - STATUSBAR_HEIGHT
    else
        self.x = self.originalX
        self.y = self.originalY
        self.width = self.originalWidth
        self.height = self.originalHeight
    end
end

function Window:isMouseInTitleBar(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.titleBarHeight
end

function Window:isMouseInCloseButton(x, y)
    local buttonX = self.x + self.width - self.buttonSize - 5
    local buttonY = self.y + 3
    return x >= buttonX and x <= buttonX + self.buttonSize - 2 and
           y >= buttonY and y <= buttonY + self.buttonSize - 2
end

function Window:isMouseInResizeHandle(x, y)
    return x >= self.x + self.width - self.resizeHandleSize and
           x <= self.x + self.width and
           y >= self.y + self.height - self.resizeHandleSize and
           y <= self.y + self.height
end

function Window:isMouseInMinimizeButton(x, y)
    local buttonX = self.x + self.width - (self.buttonSize * 3) - 15
    local buttonY = self.y + 3
    return x >= buttonX and x <= buttonX + self.buttonSize - 2 and
           y >= buttonY and y <= buttonY + self.buttonSize - 2
end

function Window:isMouseInMaximizeButton(x, y)
    local buttonX = self.x + self.width - (self.buttonSize * 2) - 10
    local buttonY = self.y + 3
    return x >= buttonX and x <= buttonX + self.buttonSize - 2 and
           y >= buttonY and y <= buttonY + self.buttonSize - 2
end

function Window:draw()
    -- Draw window background with slightly different color if active
    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont("fonts/FiraCode.ttf", 21)
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)

    -- Draw base window background
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- Draw title bar
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.titleBarHeight)

    -- Draw active window highlights
    if self == self.manager.activeWindow then
        -- Highlight border
        love.graphics.setColor(0.5, 0.5, 0.8, 0.5)
        love.graphics.rectangle("line", self.x - 1, self.y - 1, self.width + 2, self.height + 2)
        
        -- Slightly lighter background
        love.graphics.setColor(0.35, 0.35, 0.35, 0.3)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        
        -- Lighter title bar
        love.graphics.setColor(0.45, 0.45, 0.45, 0.3)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.titleBarHeight)
    else
        -- Darken inactive windows
        love.graphics.setColor(0, 0, 0, 0.1)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end

    -- Draw title text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.title, self.x + 5, self.y + 5)

    -- Draw window buttons
    local buttonSpacing = 5
    local buttonX = self.x + self.width - self.buttonSize - buttonSpacing

    -- Close button
    love.graphics.setColor(self.buttons.close.color)
    love.graphics.rectangle("fill", buttonX, self.y + 3, self.buttonSize - 2, self.buttonSize - 2)

    -- Maximize button
    buttonX = buttonX - self.buttonSize - buttonSpacing
    love.graphics.setColor(self.buttons.maximize.color)
    love.graphics.rectangle("fill", buttonX, self.y + 3, self.buttonSize - 2, self.buttonSize - 2)

    -- Minimize button
    buttonX = buttonX - self.buttonSize - buttonSpacing
    love.graphics.setColor(self.buttons.minimize.color)
    love.graphics.rectangle("fill", buttonX, self.y + 3, self.buttonSize - 2, self.buttonSize - 2)

    -- Draw resize handle if not minimized
    if not self.isMinimized then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", 
            self.x + self.width - self.resizeHandleSize,
            self.y + self.height - self.resizeHandleSize,
            self.resizeHandleSize,
            self.resizeHandleSize
        )
    end

    if type(self.app) == "table" and type(self.app.draw) == "function" then
        local function stencilFunc()
            love.graphics.rectangle("fill", 
                self.x, 
                self.y + self.titleBarHeight, 
                self.width, 
                self.height - self.titleBarHeight
            )
        end

        love.graphics.stencil(stencilFunc, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        self.app:draw(
            self.x, 
            self.y + self.titleBarHeight, 
            self.width, 
            self.height - self.titleBarHeight
        )

        love.graphics.setStencilTest()
    else
        -- Draw a placeholder if no app or draw method
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 
            self.x, 
            self.y + self.titleBarHeight, 
            self.width, 
            self.height - self.titleBarHeight
        )
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("No app or draw method", 
            self.x, 
            self.y + self.height / 2, 
            self.width, 
            "center"
        )
    end
    love.graphics.setFont(default_font)
end

function Window:textinput(text)
    if self.app and type(self.app.textinput) == "function" then
        self.app:textinput(text)
    end
end

function Window:keypressed(key)
    if self.app and type(self.app.keypressed) == "function" then
        self.app:keypressed(key)
    end
end

function Window:update(dt)
    if self.app and type(self.app.update) == "function" then
        self.app:update(dt)
    end
end

function Window:mousepressed(x, y, button)
    -- Only process input if window is active
    if self ~= self.manager.activeWindow then
        return
    end
    
    if self.app and type(self.app.mousepressed) == "function" then
        self.app:mousepressed(x, y, button, self.x, self.y)
    end
end

function Window:mousemoved(x, y, dx, dy)
    if self.app and type(self.app.mousemoved) == "function" then
        local contentX = x - self.x
        local contentY = y - (self.y + self.titleBarHeight)
        self.app:mousemoved(contentX, contentY, self.x, self.y + self.titleBarHeight)
    end
end

-- WindowManager class
local MissionsManager = require("missions_manager")
local WindowManager = {}

function WindowManager:new()
    local obj = {
        windows = {},
        activeWindow = nil,
        missionsManager = MissionsManager:new()  -- Create instance of MissionsManager
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function WindowManager:createWindow(title, x, y, width, height, app)
    -- Deactivate current window if any
    if self.activeWindow then
        self.activeWindow = nil
    end
    
    local window = Window:new(title, width, height, self)
    if type(app) == "table" then
        window.app = app
    end
    table.insert(self.windows, window)
    self.activeWindow = window
    
    -- Restore mission state if it's a missions window
    if self.missionsManager then
        self.missionsManager:restoreWindowState(window)
    end
    
    return window
end

function WindowManager:bringToFront(window)
    -- First find and remove the window from its current position
    local found = false
    for i, w in ipairs(self.windows) do
        if w == window then
            table.remove(self.windows, i)
            found = true
            break
        end
    end

    -- Only proceed if we found the window
    if found then
        -- Add window to the end of the list (top of z-order)
        table.insert(self.windows, window)
        -- Set as active window
        if self.activeWindow ~= window then
            self.activeWindow = window
        end
    end
end

function WindowManager:update(dt)
    -- Update all windows but only send input to active window
    for _, window in ipairs(self.windows) do
        -- Always update window state
        if window.app and type(window.app.update) == "function" then
            window.app:update(dt)
        end
    end
end

function WindowManager:draw()
    -- Draw windows from back to front
    for i = 1, #self.windows do
        local window = self.windows[i]
        -- Draw window
        window:draw()
        -- Draw focus indicator for active window
        if window == self.activeWindow then
            love.graphics.setColor(0.5, 0.5, 0.8, 0.3)
            love.graphics.rectangle("line", window.x - 2, window.y - 2, window.width + 4, window.height + 4)
        end
    end
end

function WindowManager:mousepressed(x, y, button)
    if button == 1 then
        -- Check windows from top to bottom
        for i = #self.windows, 1, -1 do
            local window = self.windows[i]
            
            -- Check if click is within window bounds
            if x >= window.x and x <= window.x + window.width and
               y >= window.y and y <= window.y + window.height then
                
                -- Activate window if not already active
                if self.activeWindow ~= window then
                    self.activeWindow = window
                    self:bringToFront(window)
                end

                -- Handle window controls
                if window:isMouseInTitleBar(x, y) then
                    if window:isMouseInCloseButton(x, y) then
                        if self.missionsManager then
                            self.missionsManager:handleWindowClose(window)
                        end
                        table.remove(self.windows, i)
                        -- Set new active window after closing
                        if #self.windows > 0 then
                            self.activeWindow = self.windows[#self.windows]
                            self:bringToFront(self.activeWindow)
                        else
                            self.activeWindow = nil
                        end
                        return
                    elseif window:isMouseInMinimizeButton(x, y) then
                        window:minimize()
                        return
                    elseif window:isMouseInMaximizeButton(x, y) then
                        window:maximize()
                        return
                    end
                    
                    window.isDragging = true
                    window.dragOffsetX = x - window.x
                    window.dragOffsetY = y - window.y
                    return
                elseif not window.isMinimized and window:isMouseInResizeHandle(x, y) then
                    window.isResizing = true
                    window.dragOffsetX = window.width - (x - window.x)
                    window.dragOffsetY = window.height - (y - window.y)
                    return
                end

                -- Handle content area click
                local contentX = x - window.x
                local contentY = y - (window.y + window.titleBarHeight)
                if contentY >= 0 and window.app and type(window.app.mousepressed) == "function" then
                    window.app:mousepressed(contentX, contentY, button, window.x, window.y + window.titleBarHeight)
                end
                return
            end
        end
        
        -- Click was outside all windows, keep current window active
        -- This allows terminal to keep focus when clicking outside
    end
end


function WindowManager:mousereleased(x, y, button)
    if button == 1 then
        for _, window in ipairs(self.windows) do
            window.isDragging = false
            window.isResizing = false
        end
    end
end

function WindowManager:mousemoved(x, y, dx, dy)
    -- Handle dragging/resizing of active window first
    if self.activeWindow then
        if self.activeWindow.isDragging then
            self.activeWindow.x = x - self.activeWindow.dragOffsetX
            self.activeWindow.y = y - self.activeWindow.dragOffsetY
            return
        elseif self.activeWindow.isResizing then
            local newWidth = x - self.activeWindow.x + self.activeWindow.dragOffsetX
            local newHeight = y - self.activeWindow.y + self.activeWindow.dragOffsetY
            self.activeWindow.width = math.max(200, newWidth)
            self.activeWindow.height = math.max(100, newHeight)
            return
        end
    end

    -- Handle mousemoved for window under cursor
    for i = #self.windows, 1, -1 do
        local window = self.windows[i]
        local contentX = x - window.x
        local contentY = y - (window.y + window.titleBarHeight)
        local isInContent = contentX >= 0 and contentX <= window.width and
                           contentY >= 0 and contentY <= window.height - window.titleBarHeight
        
        if isInContent and window.app and type(window.app.mousemoved) == "function" then
            window.app:mousemoved(contentX, contentY, window.x, window.y + window.titleBarHeight)
            break
        end
    end
end

function WindowManager:textinput(text)
    -- Only route text input to active window
    if self.activeWindow and self.activeWindow.app and type(self.activeWindow.app.textinput) == "function" then
        self.activeWindow.app:textinput(text)
    end
end

function WindowManager:keypressed(key)
    -- Only route key presses to active window
    if self.activeWindow and self.activeWindow.app and type(self.activeWindow.app.keypressed) == "function" then
        self.activeWindow.app:keypressed(key)
    end
end

return WindowManager
