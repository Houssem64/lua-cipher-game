local ReelsApp = {
    config = {
        button_radius = 20,  -- Radius of the toggle button
        panel_width = 400,   -- Width of the sliding panel
        slide_speed = 1000,  -- Speed of the sliding animation
        button_color = {0.1176, 0.84313, 0.3764},  -- Green color for the toggle button
        panel_color = {0.1333, 0.1333, 0.1333, 1},  -- Dark background for the panel
        text_color = {1, 1, 1},  -- White text for the panel
    }
}
ReelsApp.__index = ReelsApp

function ReelsApp:new()
    local obj = setmetatable({}, ReelsApp)

    -- Merge provided config with defaults
    obj.config = setmetatable({}, {__index = ReelsApp.config})

    -- Initialize state using virtual resolution
    obj.gameWidth = 1920
    obj.gameHeight = 1080

    -- Toggle button properties
    obj.button = {
        x = obj.gameWidth - 60,  -- Position from the right edge
        y = 240,  -- Position from the top
        radius = obj.config.button_radius
    }

    -- Sliding panel properties
    obj.panel = {
        x = obj.gameWidth,  -- Start off-screen
        target_x = obj.gameWidth - obj.config.panel_width,  -- Target position when open
        y = 0,  -- Align with the top of the screen
        width = obj.config.panel_width,
        height = obj.gameHeight,
        visible = false  -- Panel starts closed
    }

    -- Reels (videos) data
    obj.reels = {
        {title = "Reel 1", video = "reel.ogv"}
    }
    obj.currentReelIndex = 1
    obj.isPlaying = false

    -- UI elements
    obj.backgroundColor = {0.1, 0.1, 0.1}  -- Dark background
    obj.textColor = {1, 1, 1}  -- White text
    obj.buttonColor = {0.3, 0.3, 0.3}  -- Gray buttons
    obj.activeColor = {0.2, 0.6, 1}  -- Blue for active items
    obj.padding = 10
    obj.buttonSize = 40

    -- Video source for the current reel
    obj.currentVideo = nil

    -- Load the first reel
    obj:loadReel(obj.currentReelIndex)

    return obj
end

function ReelsApp:loadReel(index)
    -- Stop the current video if playing
    if self.currentVideo then
        self.currentVideo:stop()
    end

    -- Load the new video
    local reel = self.reels[index]
    self.currentVideo = love.graphics.newVideo(reel.video)

    -- Play the video if the app is in playing state
    if self.isPlaying then
        self.currentVideo:play()
    end
end

function ReelsApp:playPause()
    self.isPlaying = not self.isPlaying
    if self.isPlaying then
        self.currentVideo:play()
    else
        self.currentVideo:pause()
    end
end

function ReelsApp:nextReel()
    self.currentReelIndex = (self.currentReelIndex % #self.reels) + 1
    self:loadReel(self.currentReelIndex)
end

function ReelsApp:previousReel()
    self.currentReelIndex = self.currentReelIndex - 1
    if self.currentReelIndex < 1 then
        self.currentReelIndex = #self.reels
    end
    self:loadReel(self.currentReelIndex)
end

function ReelsApp:update(dt)
    -- Update sliding panel position
    if self.panel.visible then
        self.panel.x = math.max(self.panel.target_x, self.panel.x - self.config.slide_speed * dt)
    else
        self.panel.x = math.min(self.gameWidth, self.panel.x + self.config.slide_speed * dt)
    end

    -- Update playback logic
    if self.isPlaying and self.currentVideo and not self.currentVideo:isPlaying() then
        self:nextReel()  -- Automatically play the next reel when the current one ends
    end
end

function ReelsApp:draw(x, y, width, height)
    -- Store the window dimensions for use in other methods
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont("joty.otf", 18)  -- Font size
    font:setFilter("nearest", "nearest")  -- Crisp text
    love.graphics.setFont(font)

    -- Draw background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw sliding panel
    if self.panel.x < self.gameWidth then
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle("fill", self.panel.x, self.panel.y, self.panel.width, self.panel.height)

        -- Draw current video
        local videoWidth = self.panel.width
        local videoHeight = self.panel.height
        local videoX = self.panel.x
        local videoY = self.panel.y

        if self.currentVideo then
            love.graphics.draw(self.currentVideo, videoX, videoY, 0, videoWidth / self.currentVideo:getWidth(), videoHeight / self.currentVideo:getHeight())
        end

        -- Draw playback controls
        local controlsY = videoY + videoHeight - 100
        local totalButtonsWidth = self.buttonSize * 3 + 20 * 2  -- Width of all buttons including spacing
        local playPauseX = self.panel.x + (self.panel.width - totalButtonsWidth) / 2 + 60

        -- Previous button
        local prevButtonX = playPauseX - self.buttonSize - 20
        local prevButtonY = controlsY
        local outlinePadding = 5  -- Padding around the button for the outline

        -- Draw outline for Previous button
        love.graphics.setColor(1, 1, 1)  -- White outline
        love.graphics.rectangle("line", prevButtonX - outlinePadding, prevButtonY - outlinePadding,
                               self.buttonSize + 2 * outlinePadding, self.buttonSize + 2 * outlinePadding)

        -- Draw Previous button
        love.graphics.setColor(0.3, 0.3, 0.3)  -- Gray color for the button
        love.graphics.polygon("fill", prevButtonX, prevButtonY + self.buttonSize / 2,
                              prevButtonX + self.buttonSize, prevButtonY,
                              prevButtonX + self.buttonSize, prevButtonY + self.buttonSize)

        -- Play/Pause button
        local playPauseButtonX = playPauseX
        local playPauseButtonY = controlsY

        -- Draw outline for Play/Pause button
        love.graphics.setColor(1, 1, 1)  -- White outline
        love.graphics.rectangle("line", playPauseButtonX - outlinePadding, playPauseButtonY - outlinePadding,
                               self.buttonSize + 2 * outlinePadding, self.buttonSize + 2 * outlinePadding)

        -- Draw Play/Pause button
        love.graphics.setColor(0.3, 0.3, 0.3)  -- Gray color for the button
        if self.isPlaying then
            love.graphics.rectangle("fill", playPauseButtonX, playPauseButtonY, self.buttonSize, self.buttonSize)
        else
            love.graphics.polygon("fill", playPauseButtonX, playPauseButtonY,
                                  playPauseButtonX + self.buttonSize, playPauseButtonY + self.buttonSize / 2,
                                  playPauseButtonX, playPauseButtonY + self.buttonSize)
        end

        -- Next button
        local nextButtonX = playPauseX + self.buttonSize + 20
        local nextButtonY = controlsY

        -- Draw outline for Next button
        love.graphics.setColor(1, 1, 1)  -- White outline
        love.graphics.rectangle("line", nextButtonX - outlinePadding, nextButtonY - outlinePadding,
                               self.buttonSize + 2 * outlinePadding, self.buttonSize + 2 * outlinePadding)

        -- Draw Next button
        love.graphics.setColor(0.3, 0.3, 0.3)  -- Gray color for the button
        love.graphics.polygon("fill", nextButtonX, nextButtonY,
                              nextButtonX + self.buttonSize, nextButtonY + self.buttonSize / 2,
                              nextButtonX, nextButtonY + self.buttonSize)

        -- Draw reels list
        love.graphics.setColor(unpack(self.config.text_color))
        love.graphics.print("Reels", self.panel.x + 10, controlsY + self.buttonSize + 20)

        local reelsY = controlsY + self.buttonSize + 50
        for i, reel in ipairs(self.reels) do
            if i == self.currentReelIndex then
                love.graphics.setColor(self.activeColor)  -- Highlight the current reel
            else
                love.graphics.setColor(self.textColor)
            end
            love.graphics.print(reel.title, self.panel.x + 10, reelsY)
            reelsY = reelsY + 30
        end
    end

    -- Draw toggle button with reels icon
    love.graphics.setColor(unpack(self.config.button_color))
    love.graphics.circle("fill", self.button.x + self.button.radius, self.button.y + self.button.radius, self.button.radius)

    -- Draw reels icon (simplified version)
    local iconX = self.button.x + self.button.radius - 10  -- Center the icon horizontally
    local iconY = self.button.y + self.button.radius - 10  -- Center the icon vertically
    local lineWidth = 3  -- Width of each line
    local lineHeights = {5, 10, 15, 10, 5}  -- Heights of the lines (small to big to small)

    love.graphics.setColor(1, 1, 1)  -- White color for the icon
    for i, height in ipairs(lineHeights) do
        love.graphics.rectangle("fill", iconX + (i - 1) * (lineWidth + 2), iconY + (15 - height) / 2, lineWidth, height)
    end

    -- Reset font
    love.graphics.setFont(default_font)
end

function ReelsApp:mousepressed(x, y, button)
    -- Handle toggle button click
    local dx = x - (self.button.x + self.button.radius)
    local dy = y - (self.button.y + self.button.radius)
    if dx * dx + dy * dy <= self.button.radius * self.button.radius then
        self.panel.visible = not self.panel.visible
        return true
    end

    -- Handle reels item clicks
    if self.panel.visible and x >= self.panel.x and x <= self.panel.x + self.panel.width then
        -- Calculate the starting Y position of the reels list
        local controlsY = self.panel.y + 20 + 150 + 20  -- Y position of playback controls
        local reelsStartY = controlsY + self.buttonSize + 50  -- Starting Y position of the reels list

        -- Check if the click is within the reels list area
        if y >= reelsStartY and y <= reelsStartY + (#self.reels * 30) then
            -- Calculate which reel was clicked
            local reelIndex = math.floor((y - reelsStartY) / 30) + 1
            if reelIndex >= 1 and reelIndex <= #self.reels then
                self.currentReelIndex = reelIndex
                self:loadReel(reelIndex)
            end
        end
    end

    -- Handle playback controls
    if self.panel.visible then
        local controlsY = self.panel.y + 20 + 150 + 20
        local playPauseX = self.panel.x + (self.panel.width - self.buttonSize * 3 - 20 * 2) / 2 + 60

        -- Check if previous button is clicked
        if x >= playPauseX - self.buttonSize - 20 and x <= playPauseX - 20 and
           y >= controlsY and y <= controlsY + self.buttonSize then
            self:previousReel()
        end

        -- Check if play/pause button is clicked
        if x >= playPauseX and x <= playPauseX + self.buttonSize and
           y >= controlsY and y <= controlsY + self.buttonSize then
            self:playPause()
        end

        -- Check if next button is clicked
        if x >= playPauseX + self.buttonSize + 20 and x <= playPauseX + self.buttonSize * 2 + 20 and
           y >= controlsY and y <= controlsY + self.buttonSize then
            self:nextReel()
        end
    end
end

function ReelsApp:mousemoved(x, y, dx, dy)
    -- Handle mouse movement (e.g., dragging)
end

function ReelsApp:mousereleased(x, y, button)
    -- Handle mouse release (e.g., stop dragging)
end

function ReelsApp:keypressed(key)
    -- Handle shortcut keys
    if key == "f1" then
        self:previousReel()
    elseif key == "f2" then
        self:playPause()
    elseif key == "f3" then
        self:nextReel()
    end
end

return ReelsApp